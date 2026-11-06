// Perfil do utilizador autenticado (RF04–RF08).
const express = require('express');
const db = require('../db');
const { ErroApi, exigir } = require('../utils/erros');
const { NIVEIS } = require('../utils/compatibilidade');

const router = express.Router();

// GET /perfil  → dados, modalidades e disponibilidade
router.get('/', async (req, res) => {
  const id = req.utilizadorId;
  const [utilizadores] = await db.query(
    `SELECT id, nome, email, localidade, latitude, longitude, raio_km, objetivo, avaliacao
     FROM utilizadores WHERE id = ?`,
    [id],
  );
  if (utilizadores.length === 0) throw new ErroApi(404, 'Utilizador não encontrado.');

  const [modalidades] = await db.query(
    `SELECT m.id, m.nome, um.nivel
     FROM utilizador_modalidades um JOIN modalidades m ON m.id = um.modalidade_id
     WHERE um.utilizador_id = ? ORDER BY m.id`,
    [id],
  );
  const [disponibilidade] = await db.query(
    `SELECT dia_semana, TIME_FORMAT(hora_inicio, '%H:%i') AS hora_inicio, TIME_FORMAT(hora_fim, '%H:%i') AS hora_fim
     FROM disponibilidades WHERE utilizador_id = ? ORDER BY dia_semana, hora_inicio`,
    [id],
  );
  res.json({ ...utilizadores[0], modalidades, disponibilidade });
});

// PUT /perfil  { nome?, localidade?, latitude?, longitude?, raio_km?, objetivo? }
router.put('/', async (req, res) => {
  const permitidos = ['nome', 'localidade', 'latitude', 'longitude', 'raio_km', 'objetivo'];
  const campos = permitidos.filter((c) => req.body[c] !== undefined);
  if (campos.length === 0) throw new ErroApi(400, 'Nada para atualizar.');

  // Monta "nome = ?, localidade = ?" só com os campos enviados.
  const sets = campos.map((c) => `${c} = ?`).join(', ');
  const valores = campos.map((c) => req.body[c]);
  await db.query(`UPDATE utilizadores SET ${sets} WHERE id = ?`, [...valores, req.utilizadorId]);
  res.json({ ok: true });
});

// PUT /perfil/modalidades  { modalidades: [{ modalidade_id, nivel }] }
// Substitui a lista inteira (usado no onboarding e no "Editar").
router.put('/modalidades', async (req, res) => {
  exigir(req.body, ['modalidades']);
  const lista = req.body.modalidades;
  if (!Array.isArray(lista)) throw new ErroApi(400, '"modalidades" tem de ser uma lista.');
  for (const m of lista) {
    if (!NIVEIS.includes(m.nivel ?? 'Iniciante')) throw new ErroApi(400, `Nível inválido: ${m.nivel}.`);
  }

  // Transação: ou corre tudo, ou não fica nada a meio.
  const ligacao = await db.getConnection();
  try {
    await ligacao.beginTransaction();
    await ligacao.query('DELETE FROM utilizador_modalidades WHERE utilizador_id = ?', [req.utilizadorId]);
    for (const m of lista) {
      await ligacao.query(
        'INSERT INTO utilizador_modalidades (utilizador_id, modalidade_id, nivel) VALUES (?, ?, ?)',
        [req.utilizadorId, m.modalidade_id, m.nivel ?? 'Iniciante'],
      );
    }
    await ligacao.commit();
  } catch (erro) {
    await ligacao.rollback();
    throw erro;
  } finally {
    ligacao.release();
  }
  res.json({ ok: true });
});

// PUT /perfil/disponibilidade  { disponibilidade: [{ dia_semana, hora_inicio, hora_fim }] }
router.put('/disponibilidade', async (req, res) => {
  exigir(req.body, ['disponibilidade']);
  const lista = req.body.disponibilidade;
  if (!Array.isArray(lista)) throw new ErroApi(400, '"disponibilidade" tem de ser uma lista.');
  for (const d of lista) {
    const dia = Number(d.dia_semana);
    if (!(dia >= 1 && dia <= 7)) throw new ErroApi(400, 'dia_semana tem de ser de 1 (segunda) a 7 (domingo).');
    if (!(String(d.hora_fim) > String(d.hora_inicio))) {
      throw new ErroApi(400, 'A hora de fim tem de ser depois da hora de início.');
    }
  }

  const ligacao = await db.getConnection();
  try {
    await ligacao.beginTransaction();
    await ligacao.query('DELETE FROM disponibilidades WHERE utilizador_id = ?', [req.utilizadorId]);
    for (const d of lista) {
      await ligacao.query(
        'INSERT INTO disponibilidades (utilizador_id, dia_semana, hora_inicio, hora_fim) VALUES (?, ?, ?, ?)',
        [req.utilizadorId, d.dia_semana, d.hora_inicio, d.hora_fim],
      );
    }
    await ligacao.commit();
  } catch (erro) {
    await ligacao.rollback();
    throw erro;
  } finally {
    ligacao.release();
  }
  res.json({ ok: true });
});

module.exports = router;

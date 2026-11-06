// Criar jogos, entrar em jogos e check-in por QR Code.
const crypto = require('node:crypto');
const express = require('express');
const db = require('../db');
const { ErroApi, exigir } = require('../utils/erros');
const { quando, paraMysql } = require('../utils/datas');
const { distanciaKm } = require('../utils/compatibilidade');

const router = express.Router();

// Base comum: dados do jogo + quantos lugares já estão ocupados.
const SELECT_JOGO = `
  SELECT j.id, j.organizador_id, o.nome AS organizador, j.modalidade_id, m.nome AS modalidade,
         j.data_hora, j.local_nome, j.latitude, j.longitude, j.nivel, j.formato,
         j.capacidade, j.preco, j.estado,
         j.jogadores_externos + (SELECT COUNT(*) FROM jogo_participantes p WHERE p.jogo_id = j.id) AS ocupados
  FROM jogos j
  JOIN modalidades m  ON m.id = j.modalidade_id
  JOIN utilizadores o ON o.id = j.organizador_id`;

async function minhaPosicao(id) {
  const [linhas] = await db.query('SELECT nome, latitude, longitude FROM utilizadores WHERE id = ?', [id]);
  return linhas[0];
}

// Acrescenta as vagas e a distância a que o jogo fica de mim.
function completar(jogo, eu) {
  const distancia =
    eu.latitude !== null && jogo.latitude !== null
      ? Math.round(distanciaKm(eu.latitude, eu.longitude, jogo.latitude, jogo.longitude) * 10) / 10
      : null;
  return { ...jogo, vagas: jogo.capacidade - jogo.ocupados, distancia_km: distancia };
}

// GET /jogos?modalidade=1  → jogos abertos e futuros
router.get('/', async (req, res) => {
  const modalidade = Number(req.query.modalidade) || null;
  const [jogos] = await db.query(
    `${SELECT_JOGO}
     WHERE j.estado = 'aberto' AND j.data_hora > NOW() ${modalidade ? 'AND j.modalidade_id = ?' : ''}
     ORDER BY j.data_hora`,
    modalidade ? [modalidade] : [],
  );
  const eu = await minhaPosicao(req.utilizadorId);
  res.json(jogos.map((j) => completar(j, eu)));
});

// POST /jogos/checkin  { codigo }  → o organizador lê o QR e confirma a presença
router.post('/checkin', async (req, res) => {
  exigir(req.body, ['codigo']);
  const [linhas] = await db.query(
    `SELECT p.jogo_id, p.utilizador_id, p.checkin_em, j.organizador_id, u.nome
     FROM jogo_participantes p
     JOIN jogos j        ON j.id = p.jogo_id
     JOIN utilizadores u ON u.id = p.utilizador_id
     WHERE p.codigo_checkin = ?`,
    [req.body.codigo],
  );
  const participante = linhas[0];
  if (!participante) throw new ErroApi(404, 'QR Code desconhecido.');
  if (participante.organizador_id !== req.utilizadorId) {
    throw new ErroApi(403, 'Só o organizador pode confirmar presenças.');
  }
  await db.query(
    `UPDATE jogo_participantes SET checkin_em = COALESCE(checkin_em, NOW())
     WHERE jogo_id = ? AND utilizador_id = ?`,
    [participante.jogo_id, participante.utilizador_id],
  );
  res.json({ ok: true, jogo_id: participante.jogo_id, nome: participante.nome });
});

// GET /jogos/1  → detalhe + quem vai
router.get('/:id', async (req, res) => {
  const [jogos] = await db.query(`${SELECT_JOGO} WHERE j.id = ?`, [req.params.id]);
  if (jogos.length === 0) throw new ErroApi(404, 'Jogo não encontrado.');

  const [participantes] = await db.query(
    `SELECT u.id, u.nome, (u.id = j.organizador_id) AS organizador, um.nivel, p.checkin_em
     FROM jogo_participantes p
     JOIN jogos j        ON j.id = p.jogo_id
     JOIN utilizadores u ON u.id = p.utilizador_id
     LEFT JOIN utilizador_modalidades um ON um.utilizador_id = u.id AND um.modalidade_id = j.modalidade_id
     WHERE p.jogo_id = ?
     ORDER BY organizador DESC, p.entrou_em, u.id`,
    [req.params.id],
  );

  const eu = await minhaPosicao(req.utilizadorId);
  res.json({
    ...completar(jogos[0], eu),
    participantes: participantes.map((p) => ({ ...p, organizador: Boolean(p.organizador) })),
    eu_participo: participantes.some((p) => p.id === req.utilizadorId),
  });
});

// POST /jogos  { modalidade_id, data_hora, local_nome, nivel, formato, capacidade, vagas_abertas, preco }
router.post('/', async (req, res) => {
  exigir(req.body, ['modalidade_id', 'data_hora', 'local_nome', 'nivel', 'capacidade', 'vagas_abertas']);
  const capacidade = Number(req.body.capacidade);
  const vagas = Number(req.body.vagas_abertas);
  // O organizador ocupa 1 lugar; o resto que não está em vagas são pessoas de fora da app.
  const externos = capacidade - vagas - 1;
  if (vagas < 1 || externos < 0) throw new ErroApi(400, 'Número de vagas inválido para esta capacidade.');

  const eu = await minhaPosicao(req.utilizadorId);
  const ligacao = await db.getConnection();
  let jogoId;
  try {
    await ligacao.beginTransaction();
    const [resultado] = await ligacao.query(
      `INSERT INTO jogos (organizador_id, modalidade_id, data_hora, local_nome, latitude, longitude,
                          nivel, formato, capacidade, jogadores_externos, preco)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        req.utilizadorId,
        req.body.modalidade_id,
        paraMysql(req.body.data_hora),
        req.body.local_nome,
        req.body.latitude ?? eu.latitude, // sem coordenadas do local, usa as do organizador
        req.body.longitude ?? eu.longitude,
        req.body.nivel,
        req.body.formato ?? 'Amigável',
        capacidade,
        externos,
        Number(req.body.preco) || 0,
      ],
    );
    jogoId = resultado.insertId;
    await ligacao.query(
      'INSERT INTO jogo_participantes (jogo_id, utilizador_id, codigo_checkin) VALUES (?, ?, ?)',
      [jogoId, req.utilizadorId, crypto.randomUUID()],
    );
    await ligacao.commit();
  } catch (erro) {
    await ligacao.rollback();
    throw erro;
  } finally {
    ligacao.release();
  }
  res.status(201).json({ id: jogoId });
});

// POST /jogos/1/entrar  → ocupa uma vaga e devolve o código do QR
router.post('/:id/entrar', async (req, res) => {
  const jogoId = Number(req.params.id);
  const ligacao = await db.getConnection();
  try {
    await ligacao.beginTransaction();
    // FOR UPDATE bloqueia o jogo até ao fim da transação: 2 pessoas não ficam com a última vaga.
    const [jogos] = await ligacao.query(
      `SELECT j.id, j.organizador_id, j.estado, j.capacidade, j.data_hora, m.nome AS modalidade,
              j.jogadores_externos + (SELECT COUNT(*) FROM jogo_participantes p WHERE p.jogo_id = j.id) AS ocupados
       FROM jogos j JOIN modalidades m ON m.id = j.modalidade_id
       WHERE j.id = ? FOR UPDATE`,
      [jogoId],
    );
    const jogo = jogos[0];
    if (!jogo) throw new ErroApi(404, 'Jogo não encontrado.');

    const [jaEstou] = await ligacao.query(
      'SELECT codigo_checkin FROM jogo_participantes WHERE jogo_id = ? AND utilizador_id = ?',
      [jogoId, req.utilizadorId],
    );
    if (jaEstou.length > 0) {
      await ligacao.commit();
      return res.json({ codigo_checkin: jaEstou[0].codigo_checkin });
    }
    if (jogo.estado !== 'aberto') throw new ErroApi(409, 'Este jogo já não está aberto.');
    if (jogo.ocupados >= jogo.capacidade) throw new ErroApi(409, 'Já não há vagas neste jogo.');

    const codigo = crypto.randomUUID();
    await ligacao.query(
      'INSERT INTO jogo_participantes (jogo_id, utilizador_id, codigo_checkin) VALUES (?, ?, ?)',
      [jogoId, req.utilizadorId, codigo],
    );
    const [eu] = await ligacao.query('SELECT nome FROM utilizadores WHERE id = ?', [req.utilizadorId]);
    await ligacao.query(
      'INSERT INTO notificacoes (utilizador_id, titulo, detalhe) VALUES (?, ?, ?)',
      [jogo.organizador_id, `${eu[0].nome} entrou no teu jogo`, `${jogo.modalidade} · ${quando(jogo.data_hora)}`],
    );
    await ligacao.commit();
    res.status(201).json({ codigo_checkin: codigo });
  } catch (erro) {
    await ligacao.rollback();
    throw erro;
  } finally {
    ligacao.release();
  }
});

// GET /jogos/1/checkin  → o meu código QR para este jogo
router.get('/:id/checkin', async (req, res) => {
  const [linhas] = await db.query(
    'SELECT codigo_checkin, checkin_em FROM jogo_participantes WHERE jogo_id = ? AND utilizador_id = ?',
    [req.params.id, req.utilizadorId],
  );
  if (linhas.length === 0) throw new ErroApi(404, 'Ainda não entraste neste jogo.');
  res.json(linhas[0]);
});

module.exports = router;

// Procurar jogadores compatíveis (RF09, RF10).
const express = require('express');
const db = require('../db');
const { ErroApi } = require('../utils/erros');
const { diaDeHoje } = require('../utils/datas');
const { distanciaKm, calcularCompatibilidade, estatisticas } = require('../utils/compatibilidade');

const router = express.Router();

// Disponibilidades de vários utilizadores de uma vez → Map(id → lista)
async function carregarDisponibilidades(ids) {
  const [linhas] = await db.query(
    `SELECT utilizador_id, dia_semana,
            TIME_FORMAT(hora_inicio, '%H:%i') AS hora_inicio, TIME_FORMAT(hora_fim, '%H:%i') AS hora_fim
     FROM disponibilidades WHERE utilizador_id IN (?) ORDER BY hora_inicio`,
    [ids],
  );
  const mapa = new Map(ids.map((id) => [id, []]));
  for (const linha of linhas) mapa.get(linha.utilizador_id).push(linha);
  return mapa;
}

// Compara o utilizador autenticado com os outros jogadores de uma modalidade.
// Com `apenasId`, devolve só esse jogador (e não filtra pelo raio).
async function avaliarJogadores(meuId, modalidadeId, raioPedido, apenasId = null) {
  const [eus] = await db.query(
    `SELECT u.id, u.latitude, u.longitude, u.raio_km, u.objetivo, um.nivel
     FROM utilizadores u
     LEFT JOIN utilizador_modalidades um ON um.utilizador_id = u.id AND um.modalidade_id = ?
     WHERE u.id = ?`,
    [modalidadeId, meuId],
  );
  const eu = eus[0];
  if (!eu) throw new ErroApi(404, 'Utilizador não encontrado.');
  if (eu.latitude === null) throw new ErroApi(400, 'Define primeiro a tua localização no perfil.');
  const raioKm = Number(raioPedido) || eu.raio_km;

  const parametros = [modalidadeId, meuId];
  if (apenasId) parametros.push(apenasId);
  const [outros] = await db.query(
    `SELECT u.id, u.nome, u.latitude, u.longitude, u.objetivo, u.avaliacao, um.nivel, m.nome AS modalidade
     FROM utilizadores u
     JOIN utilizador_modalidades um ON um.utilizador_id = u.id AND um.modalidade_id = ?
     JOIN modalidades m ON m.id = um.modalidade_id
     WHERE u.id <> ? AND u.latitude IS NOT NULL ${apenasId ? 'AND u.id = ?' : ''}`,
    parametros,
  );

  const disponibilidades = await carregarDisponibilidades([meuId, ...outros.map((o) => o.id)]);
  eu.disponibilidade = disponibilidades.get(meuId);
  const hoje = diaDeHoje();

  const resultado = [];
  for (const outro of outros) {
    const distancia = distanciaKm(eu.latitude, eu.longitude, outro.latitude, outro.longitude);
    if (!apenasId && distancia > raioKm) continue;

    outro.disponibilidade = disponibilidades.get(outro.id);
    const { total, criterios } = calcularCompatibilidade({ eu, outro, distancia, raioKm });
    const hojeLivre = outro.disponibilidade.find((d) => d.dia_semana === hoje);

    resultado.push({
      id: outro.id,
      nome: outro.nome,
      modalidade: outro.modalidade,
      nivel: outro.nivel,
      distancia_km: Math.round(distancia * 10) / 10,
      latitude: Number(outro.latitude),
      longitude: Number(outro.longitude),
      compatibilidade: total,
      criterios,
      avaliacao: outro.avaliacao,
      objetivo: outro.objetivo,
      disponivel_hoje: hojeLivre ? `${hojeLivre.hora_inicio} – ${hojeLivre.hora_fim}` : null,
    });
  }
  resultado.sort((a, b) => b.compatibilidade - a.compatibilidade);
  return resultado;
}

// GET /jogadores?modalidade=1&raio=5
router.get('/', async (req, res) => {
  const modalidade = Number(req.query.modalidade) || 1;
  const jogadores = await avaliarJogadores(req.utilizadorId, modalidade, req.query.raio);
  res.json({
    jogadores,
    estatisticas: estatisticas(jogadores.map((j) => j.compatibilidade)),
  });
});

// GET /jogadores/2?modalidade=1
router.get('/:id', async (req, res) => {
  const modalidade = Number(req.query.modalidade) || 1;
  const [jogador] = await avaliarJogadores(req.utilizadorId, modalidade, null, Number(req.params.id));
  if (!jogador) throw new ErroApi(404, 'Jogador não encontrado nesta modalidade.');
  res.json(jogador);
});

module.exports = router;

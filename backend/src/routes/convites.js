
// Convites entre jogadores (ecrã Convites).

const express = require('express');
const db = require('../db');
const { ErroApi, exigir } = require('../utils/erros');
const { quando, paraMysql } = require('../utils/datas');
const { distanciaKm } = require('../utils/compatibilidade');

const router = express.Router();

// GET /convites
// Devolve os convites enviados e recebidos que ainda estão pendentes.
router.get('/', async (req, res) => {
  const id = req.utilizadorId;

  const [enviados] = await db.query(
    `SELECT
       c.id,
       c.estado,
       c.data_hora,
       m.nome AS modalidade,
       u.id AS jogador_id,
       u.nome
     FROM convites c
     JOIN utilizadores u ON u.id = c.destinatario_id
     JOIN modalidades m ON m.id = c.modalidade_id
     WHERE c.remetente_id = ?
       AND c.estado = 'pendente'
     ORDER BY c.data_hora`,
    [id],
  );

  const [recebidos] = await db.query(
    `SELECT
       c.id,
       c.estado,
       c.data_hora,
       m.nome AS modalidade,
       u.id AS jogador_id,
       u.nome,
       u.latitude,
       u.longitude,
       eu.latitude AS minha_lat,
       eu.longitude AS minha_lon
     FROM convites c
     JOIN utilizadores u ON u.id = c.remetente_id
     JOIN utilizadores eu ON eu.id = c.destinatario_id
     JOIN modalidades m ON m.id = c.modalidade_id
     WHERE c.destinatario_id = ?
       AND c.estado = 'pendente'
     ORDER BY c.data_hora`,
    [id],
  );

  res.json({
    enviados,
    recebidos: recebidos.map(
      ({ latitude, longitude, minha_lat, minha_lon, ...convite }) => ({
        ...convite,
        distancia_km:
          latitude != null && longitude != null &&
          minha_lat != null && minha_lon != null
            ? Math.round(
                distanciaKm(
                  minha_lat,
                  minha_lon,
                  latitude,
                  longitude,
                ) * 10,
              ) / 10
            : null,
      }),
    ),
  });
});

// POST /convites
// Corpo: { destinatario_id, modalidade_id, data_hora }
router.post('/', async (req, res) => {
  exigir(req.body, [
    'destinatario_id',
    'modalidade_id',
    'data_hora',
  ]);

  const destinatario = Number(req.body.destinatario_id);
  const modalidadeId = Number(req.body.modalidade_id);

  if (
    !Number.isInteger(destinatario) ||
    destinatario <= 0 ||
    !Number.isInteger(modalidadeId) ||
    modalidadeId <= 0
  ) {
    throw new ErroApi(400, 'Dados do convite inválidos.');
  }

  if (destinatario === req.utilizadorId) {
    throw new ErroApi(
      400,
      'Não te podes convidar a ti próprio.',
    );
  }

  const [pessoas] = await db.query(
    `SELECT id, nome
     FROM utilizadores
     WHERE id IN (?, ?)`,
    [req.utilizadorId, destinatario],
  );

  const eu = pessoas.find(
    (pessoa) => pessoa.id === req.utilizadorId,
  );

  if (!pessoas.some((pessoa) => pessoa.id === destinatario)) {
    throw new ErroApi(404, 'Jogador não encontrado.');
  }

  // Impedir convites pendentes duplicados entre os mesmos jogadores.
  const [existentes] = await db.query(
    `SELECT id
     FROM convites
     WHERE estado = 'pendente'
       AND (
         (remetente_id = ? AND destinatario_id = ?)
         OR
         (remetente_id = ? AND destinatario_id = ?)
       )
     LIMIT 1`,
    [
      req.utilizadorId,
      destinatario,
      destinatario,
      req.utilizadorId,
    ],
  );

  if (existentes.length > 0) {
    throw new ErroApi(
      409,
      'Já existe um convite pendente entre estes jogadores.',
    );
  }

  const [modalidades] = await db.query(
    'SELECT nome FROM modalidades WHERE id = ?',
    [modalidadeId],
  );

  if (modalidades.length === 0) {
    throw new ErroApi(404, 'Modalidade não encontrada.');
  }

  const dataHora = paraMysql(req.body.data_hora);

  const [resultado] = await db.query(
    `INSERT INTO convites
      (remetente_id, destinatario_id, modalidade_id, data_hora)
     VALUES (?, ?, ?, ?)`,
    [
      req.utilizadorId,
      destinatario,
      modalidadeId,
      dataHora,
    ],
  );

  await db.query(
    `INSERT INTO notificacoes
      (utilizador_id, titulo, detalhe)
     VALUES (?, ?, ?)`,
    [
      destinatario,
      `${eu.nome} convidou-te para jogar`,
      `${modalidades[0].nome} · ${quando(dataHora)}`,
    ],
  );

  res.status(201).json({
    id: resultado.insertId,
    mensagem: 'Convite enviado com sucesso.',
  });
});

// Aceitar ou recusar um convite recebido.
async function responder(req, res, estado) {
  const [convites] = await db.query(
    `SELECT
       c.id,
       c.remetente_id,
       c.estado,
       u.nome AS eu
     FROM convites c
     JOIN utilizadores u ON u.id = c.destinatario_id
     WHERE c.id = ?
       AND c.destinatario_id = ?`,
    [req.params.id, req.utilizadorId],
  );

  const convite = convites[0];

  if (!convite) {
    throw new ErroApi(404, 'Convite não encontrado.');
  }

  if (convite.estado !== 'pendente') {
    throw new ErroApi(
      409,
      'Este convite já foi respondido.',
    );
  }

  await db.query(
    `UPDATE convites
     SET estado = ?, respondido_em = NOW()
     WHERE id = ?`,
    [estado, convite.id],
  );

  const verbo = estado === 'aceite' ? 'aceitou' : 'recusou';

  await db.query(
    `INSERT INTO notificacoes (utilizador_id, titulo)
     VALUES (?, ?)`,
    [
      convite.remetente_id,
      `O ${convite.eu} ${verbo} o teu convite`,
    ],
  );

  res.json({
    ok: true,
    estado,
  });
}

// POST /convites/:id/aceitar
router.post('/:id/aceitar', (req, res) =>
  responder(req, res, 'aceite'),
);

// POST /convites/:id/recusar
router.post('/:id/recusar', (req, res) =>
  responder(req, res, 'recusado'),
);

module.exports = router;

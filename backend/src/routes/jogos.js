
// =============================================================
// WhoPlay — Jogos, participantes, check-in, histórico e estatísticas
// =============================================================

const crypto = require('node:crypto');
const express = require('express');
const db = require('../db');
const { ErroApi, exigir } = require('../utils/erros');
const { quando, paraMysql } = require('../utils/datas');
const { distanciaKm } = require('../utils/compatibilidade');

const router = express.Router();

// =============================================================
// CONSULTA BASE DOS JOGOS
// =============================================================

const SELECT_JOGO = `
  SELECT j.id, j.organizador_id, o.nome AS organizador,
         j.modalidade_id, m.nome AS modalidade,
         j.data_hora, j.local_nome, j.latitude, j.longitude,
         j.nivel, j.formato, j.capacidade, j.preco, j.estado,
         j.jogadores_externos +
           (SELECT COUNT(*)
            FROM jogo_participantes p
            WHERE p.jogo_id = j.id) AS ocupados
  FROM jogos j
  JOIN modalidades m ON m.id = j.modalidade_id
  JOIN utilizadores o ON o.id = j.organizador_id`;

async function minhaPosicao(id) {
  const [linhas] = await db.query(
    'SELECT nome, latitude, longitude FROM utilizadores WHERE id = ?',
    [id],
  );

  return linhas[0];
}

function completar(jogo, eu) {
  const distancia =
    eu.latitude !== null && jogo.latitude !== null
      ? Math.round(
          distanciaKm(
            eu.latitude,
            eu.longitude,
            jogo.latitude,
            jogo.longitude,
          ) * 10,
        ) / 10
      : null;

  return {
    ...jogo,
    vagas: jogo.capacidade - jogo.ocupados,
    distancia_km: distancia,
  };
}

// =============================================================
// 1. LISTAR JOGOS ABERTOS
// GET /jogos?modalidade=1
// =============================================================

router.get('/', async (req, res) => {
  const modalidade = Number(req.query.modalidade) || null;

  const [jogos] = await db.query(
    `${SELECT_JOGO}
     WHERE j.estado = 'aberto'
       AND j.data_hora > NOW()
       ${modalidade ? 'AND j.modalidade_id = ?' : ''}
     ORDER BY j.data_hora`,
    modalidade ? [modalidade] : [],
  );

  const eu = await minhaPosicao(req.utilizadorId);

  res.json(jogos.map((j) => completar(j, eu)));
});

// =============================================================
// 2. HISTÓRICO DE JOGOS
// GET /jogos/historico
// GET /jogos/historico?tipo=organizados
// GET /jogos/historico?tipo=participados
// =============================================================

router.get('/historico', async (req, res) => {
  const tipo = req.query.tipo;

  if (tipo && !['organizados', 'participados'].includes(tipo)) {
    throw new ErroApi(400, 'Tipo de histórico inválido.');
  }

  let filtro = `
    AND (p.utilizador_id = ? OR j.organizador_id = ?)
  `;

  let parametros = [
    req.utilizadorId,
    req.utilizadorId,
    req.utilizadorId,
  ];

  if (tipo === 'organizados') {
    filtro = 'AND j.organizador_id = ?';
    parametros = [req.utilizadorId, req.utilizadorId];
  } else if (tipo === 'participados') {
    filtro = 'AND p.utilizador_id = ?';
    parametros = [req.utilizadorId, req.utilizadorId];
  }

  const [jogos] = await db.query(
    `SELECT
       j.id,
       j.organizador_id,
       o.nome AS organizador,
       m.nome AS modalidade,
       j.data_hora,
       j.local_nome,
       j.nivel,
       j.formato,
       j.capacidade,
       j.preco,
       j.estado,

       CASE
         WHEN j.estado = 'cancelado' THEN 'cancelado'
         WHEN j.estado = 'terminado'
              OR j.data_hora <= NOW() THEN 'terminado'
         ELSE 'próximo'
       END AS estado_historico,

       CASE
         WHEN j.organizador_id = ? THEN 'organizador'
         ELSE 'participante'
       END AS papel,

       (SELECT COUNT(*)
        FROM jogo_participantes jp
        WHERE jp.jogo_id = j.id) AS participantes,

       (SELECT COUNT(*)
        FROM jogo_participantes jp
        WHERE jp.jogo_id = j.id
          AND jp.checkin_em IS NOT NULL) AS presentes

     FROM jogos j
     JOIN modalidades m ON m.id = j.modalidade_id
     JOIN utilizadores o ON o.id = j.organizador_id
     JOIN jogo_participantes p ON p.jogo_id = j.id

     WHERE (
       j.data_hora <= NOW()
       OR j.estado IN ('terminado', 'cancelado')
     )
     ${filtro}

     GROUP BY j.id
     ORDER BY j.data_hora DESC`,
    parametros,
  );

  res.json({
    total: jogos.length,
    jogos,
  });
});

// =============================================================
// 3. ESTATÍSTICAS DO UTILIZADOR
// GET /jogos/estatisticas
// =============================================================

router.get('/estatisticas', async (req, res) => {
  const [resumo] = await db.query(
    `SELECT
       COUNT(DISTINCT j.id) AS jogos_realizados,

       COUNT(DISTINCT CASE
         WHEN j.organizador_id = ? THEN j.id
       END) AS jogos_organizados,

       COUNT(DISTINCT CASE
         WHEN p.checkin_em IS NOT NULL THEN j.id
       END) AS jogos_com_presenca,

       COUNT(CASE
         WHEN p.checkin_em IS NOT NULL THEN 1
       END) AS total_presencas,

       COUNT(p.jogo_id) AS total_participacoes

     FROM jogo_participantes p
     JOIN jogos j ON j.id = p.jogo_id

     WHERE p.utilizador_id = ?
       AND j.data_hora <= NOW()
       AND j.estado != 'cancelado'`,
    [req.utilizadorId, req.utilizadorId],
  );

  const [modalidades] = await db.query(
    `SELECT
       m.nome AS modalidade,
       COUNT(*) AS total

     FROM jogo_participantes p
     JOIN jogos j ON j.id = p.jogo_id
     JOIN modalidades m ON m.id = j.modalidade_id

     WHERE p.utilizador_id = ?
       AND p.checkin_em IS NOT NULL

     GROUP BY m.id, m.nome
     ORDER BY total DESC
     LIMIT 1`,
    [req.utilizadorId],
  );

  const dados = resumo[0];

  const totalParticipacoes = Number(dados.total_participacoes);
  const totalPresencas = Number(dados.total_presencas);

  res.json({
    jogos_realizados: Number(dados.jogos_realizados),
    jogos_organizados: Number(dados.jogos_organizados),
    jogos_com_presenca: Number(dados.jogos_com_presenca),
    total_presencas: totalPresencas,
    total_participacoes: totalParticipacoes,

    taxa_presenca: totalParticipacoes > 0
      ? Math.round(
          (totalPresencas / totalParticipacoes) * 100,
        )
      : 0,

    modalidade_mais_praticada:
      modalidades[0]?.modalidade ?? null,
  });
});

// =============================================================
// 4. CHECK-IN POR QR CODE
// POST /jogos/checkin
// Apenas o organizador pode confirmar a presença.
// Cada QR Code só pode ser utilizado uma vez.
// =============================================================

router.post('/checkin', async (req, res) => {
  exigir(req.body, ['codigo']);

  const codigo = String(req.body.codigo).trim();

  if (!codigo) {
    throw new ErroApi(400, 'Código QR inválido.');
  }

  const ligacao = await db.getConnection();

  try {
    await ligacao.beginTransaction();

    const [linhas] = await ligacao.query(
      `SELECT
         p.jogo_id,
         p.utilizador_id,
         p.checkin_em,
         j.organizador_id,
         u.nome

       FROM jogo_participantes p
       JOIN jogos j ON j.id = p.jogo_id
       JOIN utilizadores u ON u.id = p.utilizador_id

       WHERE p.codigo_checkin = ?
       FOR UPDATE`,
      [codigo],
    );

    const participante = linhas[0];

    if (!participante) {
      throw new ErroApi(404, 'QR Code desconhecido.');
    }

    if (
      Number(participante.organizador_id) !==
      Number(req.utilizadorId)
    ) {
      throw new ErroApi(
        403,
        'Só o organizador pode confirmar presenças.',
      );
    }

    if (participante.checkin_em !== null) {
      throw new ErroApi(
        409,
        'Este QR Code já foi utilizado. A presença já está confirmada.',
      );
    }

    await ligacao.query(
      `UPDATE jogo_participantes
       SET checkin_em = NOW()
       WHERE jogo_id = ?
         AND utilizador_id = ?
         AND checkin_em IS NULL`,
      [
        participante.jogo_id,
        participante.utilizador_id,
      ],
    );

    await ligacao.commit();

    res.json({
      ok: true,
      jogo_id: participante.jogo_id,
      nome: participante.nome,
      mensagem: 'Presença confirmada com sucesso.',
    });
  } catch (erro) {
    await ligacao.rollback();
    throw erro;
  } finally {
    ligacao.release();
  }
});

// =============================================================
// 5. DETALHES DO JOGO
// GET /jogos/1
// =============================================================

router.get('/:id', async (req, res) => {
  const [jogos] = await db.query(
    `${SELECT_JOGO} WHERE j.id = ?`,
    [req.params.id],
  );

  if (jogos.length === 0) {
    throw new ErroApi(404, 'Jogo não encontrado.');
  }

  const [participantes] = await db.query(
    `SELECT
       u.id,
       u.nome,
       (u.id = j.organizador_id) AS organizador,
       um.nivel,
       p.checkin_em

     FROM jogo_participantes p
     JOIN jogos j ON j.id = p.jogo_id
     JOIN utilizadores u ON u.id = p.utilizador_id

     LEFT JOIN utilizador_modalidades um
       ON um.utilizador_id = u.id
       AND um.modalidade_id = j.modalidade_id

     WHERE p.jogo_id = ?

     ORDER BY organizador DESC, p.entrou_em, u.id`,
    [req.params.id],
  );

  const eu = await minhaPosicao(req.utilizadorId);

  res.json({
    ...completar(jogos[0], eu),

    participantes: participantes.map((p) => ({
      ...p,
      organizador: Boolean(p.organizador),
    })),

    eu_participo: participantes.some(
      (p) => Number(p.id) === Number(req.utilizadorId),
    ),
  });
});

// =============================================================
// 6. GESTÃO DE PRESENÇAS
// GET /jogos/1/presencas
// Apenas o organizador pode consultar.
// =============================================================

router.get('/:id/presencas', async (req, res) => {
  const jogoId = Number(req.params.id);

  if (!Number.isInteger(jogoId) || jogoId <= 0) {
    throw new ErroApi(400, 'Identificador de jogo inválido.');
  }

  const [jogos] = await db.query(
    `SELECT id, organizador_id, data_hora, estado
     FROM jogos
     WHERE id = ?`,
    [jogoId],
  );

  const jogo = jogos[0];

  if (!jogo) {
    throw new ErroApi(404, 'Jogo não encontrado.');
  }

  if (
    Number(jogo.organizador_id) !==
    Number(req.utilizadorId)
  ) {
    throw new ErroApi(
      403,
      'Só o organizador pode consultar as presenças.',
    );
  }

  const [participantes] = await db.query(
    `SELECT
       u.id,
       u.nome,
       u.email,
       p.entrou_em,
       p.checkin_em,

       CASE
         WHEN p.checkin_em IS NOT NULL THEN 'presente'
         ELSE 'por confirmar'
       END AS estado_presenca

     FROM jogo_participantes p
     JOIN utilizadores u ON u.id = p.utilizador_id

     WHERE p.jogo_id = ?

     ORDER BY p.checkin_em DESC, u.nome`,
    [jogoId],
  );

  const presentes = participantes.filter(
    (p) => p.checkin_em !== null,
  ).length;

  res.json({
    jogo_id: jogoId,
    data_hora: jogo.data_hora,
    estado: jogo.estado,
    total_participantes: participantes.length,
    presentes,
    ausentes: participantes.length - presentes,
    participantes,
  });
});

// =============================================================
// 7. CRIAR JOGO
// POST /jogos
// =============================================================

router.post('/', async (req, res) => {
  exigir(req.body, [
    'modalidade_id',
    'data_hora',
    'local_nome',
    'nivel',
    'capacidade',
    'vagas_abertas',
  ]);

  const capacidade = Number(req.body.capacidade);
  const vagas = Number(req.body.vagas_abertas);

  // O organizador ocupa 1 lugar.
  const externos = capacidade - vagas - 1;

  if (
    !Number.isInteger(capacidade) ||
    !Number.isInteger(vagas) ||
    vagas < 1 ||
    externos < 0
  ) {
    throw new ErroApi(
      400,
      'Número de vagas inválido para esta capacidade.',
    );
  }

  const eu = await minhaPosicao(req.utilizadorId);
  const ligacao = await db.getConnection();

  let jogoId;

  try {
    await ligacao.beginTransaction();

    const [resultado] = await ligacao.query(
      `INSERT INTO jogos (
         organizador_id,
         modalidade_id,
         data_hora,
         local_nome,
         latitude,
         longitude,
         nivel,
         formato,
         capacidade,
         jogadores_externos,
         preco
       )
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        req.utilizadorId,
        req.body.modalidade_id,
        paraMysql(req.body.data_hora),
        req.body.local_nome,
        req.body.latitude ?? eu.latitude,
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
      `INSERT INTO jogo_participantes (
         jogo_id,
         utilizador_id,
         codigo_checkin
       )
       VALUES (?, ?, ?)`,
      [
        jogoId,
        req.utilizadorId,
        crypto.randomUUID(),
      ],
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

// =============================================================
// 8. ENTRAR NUM JOGO
// POST /jogos/1/entrar
// =============================================================

router.post('/:id/entrar', async (req, res) => {
  const jogoId = Number(req.params.id);

  if (!Number.isInteger(jogoId) || jogoId <= 0) {
    throw new ErroApi(400, 'Identificador de jogo inválido.');
  }

  const ligacao = await db.getConnection();

  try {
    await ligacao.beginTransaction();

    const [jogos] = await ligacao.query(
      `SELECT
         j.id,
         j.organizador_id,
         j.estado,
         j.capacidade,
         j.data_hora,
         m.nome AS modalidade,

         j.jogadores_externos +
           (SELECT COUNT(*)
            FROM jogo_participantes p
            WHERE p.jogo_id = j.id) AS ocupados

       FROM jogos j
       JOIN modalidades m ON m.id = j.modalidade_id

       WHERE j.id = ?
       FOR UPDATE`,
      [jogoId],
    );

    const jogo = jogos[0];

    if (!jogo) {
      throw new ErroApi(404, 'Jogo não encontrado.');
    }

    const [jaEstou] = await ligacao.query(
      `SELECT codigo_checkin
       FROM jogo_participantes
       WHERE jogo_id = ?
         AND utilizador_id = ?`,
      [jogoId, req.utilizadorId],
    );

    if (jaEstou.length > 0) {
      await ligacao.commit();

      return res.json({
        codigo_checkin: jaEstou[0].codigo_checkin,
      });
    }

    if (jogo.estado !== 'aberto') {
      throw new ErroApi(409, 'Este jogo já não está aberto.');
    }

    if (new Date(jogo.data_hora) <= new Date()) {
      throw new ErroApi(
        409,
        'Este jogo já começou ou terminou.',
      );
    }

    if (jogo.ocupados >= jogo.capacidade) {
      throw new ErroApi(409, 'Já não há vagas neste jogo.');
    }

    const codigo = crypto.randomUUID();

    await ligacao.query(
      `INSERT INTO jogo_participantes (
         jogo_id,
         utilizador_id,
         codigo_checkin
       )
       VALUES (?, ?, ?)`,
      [jogoId, req.utilizadorId, codigo],
    );

    const [eu] = await ligacao.query(
      'SELECT nome FROM utilizadores WHERE id = ?',
      [req.utilizadorId],
    );

    await ligacao.query(
      `INSERT INTO notificacoes (
         utilizador_id,
         titulo,
         detalhe
       )
       VALUES (?, ?, ?)`,
      [
        jogo.organizador_id,
        `${eu[0].nome} entrou no teu jogo`,
        `${jogo.modalidade} · ${quando(jogo.data_hora)}`,
      ],
    );

    await ligacao.commit();

    res.status(201).json({
      codigo_checkin: codigo,
    });
  } catch (erro) {
    await ligacao.rollback();
    throw erro;
  } finally {
    ligacao.release();
  }
});

// =============================================================
// 9. OBTER O MEU QR CODE
// GET /jogos/1/checkin
// =============================================================

router.get('/:id/checkin', async (req, res) => {
  const [linhas] = await db.query(
    `SELECT codigo_checkin, checkin_em
     FROM jogo_participantes
     WHERE jogo_id = ?
       AND utilizador_id = ?`,
    [req.params.id, req.utilizadorId],
  );

  if (linhas.length === 0) {
    throw new ErroApi(
      404,
      'Ainda não entraste neste jogo.',
    );
  }

  res.json(linhas[0]);
});

// =============================================================
// EXPORTAÇÃO
// =============================================================

module.exports = router;

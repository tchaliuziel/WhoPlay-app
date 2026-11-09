// Avisos (notificações dentro da app).
const express = require('express');
const db = require('../db');

const router = express.Router();

// GET /avisos  → os 30 mais recentes
router.get('/', async (req, res) => {
  const [avisos] = await db.query(
    `SELECT id, titulo, detalhe, lida, criado_em
     FROM notificacoes WHERE utilizador_id = ?
     ORDER BY criado_em DESC LIMIT 30`,
    [req.utilizadorId],
  );
  res.json(avisos.map((a) => ({ ...a, lida: Boolean(a.lida) })));
});

// POST /avisos/lidos  → marca todos como lidos
router.post('/lidos', async (req, res) => {
  await db.query('UPDATE notificacoes SET lida = TRUE WHERE utilizador_id = ?', [req.utilizadorId]);
  res.json({ ok: true });
});

// POST /avisos/5/lido  → marca um como lido
router.post('/:id/lido', async (req, res) => {
  await db.query('UPDATE notificacoes SET lida = TRUE WHERE id = ? AND utilizador_id = ?', [
    req.params.id,
    req.utilizadorId,
  ]);
  res.json({ ok: true });
});

module.exports = router;

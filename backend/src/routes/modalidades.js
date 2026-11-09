// Lista de desportos (pública: o onboarding precisa dela antes do login acabar).
const express = require('express');
const db = require('../db');

const router = express.Router();

// GET /modalidades
router.get('/', async (req, res) => {
  const [linhas] = await db.query('SELECT id, nome, descricao FROM modalidades ORDER BY id');
  res.json(linhas);
});

module.exports = router;

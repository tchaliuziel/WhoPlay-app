// Registo e login (RF01, RF02). O logout (RF03) é feito na app: basta apagar o token.
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../db');
const config = require('../config');
const autenticar = require('../middleware/auth');
const { ErroApi, exigir } = require('../utils/erros');

const router = express.Router();

function criarToken(id) {
  return jwt.sign({ id }, config.jwtSecret, { expiresIn: config.jwtExpiresIn });
}

// POST /auth/registo  { nome, email, password }
router.post('/registo', async (req, res) => {
  exigir(req.body, ['nome', 'email', 'password']);
  const nome = String(req.body.nome).trim();
  const email = String(req.body.email).trim().toLowerCase();
  const password = String(req.body.password);
  if (password.length < 8) throw new ErroApi(400, 'A palavra-passe precisa de pelo menos 8 caracteres.');

  const [existe] = await db.query('SELECT id FROM utilizadores WHERE email = ?', [email]);
  if (existe.length > 0) throw new ErroApi(409, 'Já existe uma conta com este email.');

  const hash = await bcrypt.hash(password, 10);
  const [resultado] = await db.query(
    'INSERT INTO utilizadores (nome, email, password_hash) VALUES (?, ?, ?)',
    [nome, email, hash],
  );
  const id = resultado.insertId;
  res.status(201).json({ token: criarToken(id), utilizador: { id, nome, email } });
});

// POST /auth/login  { email, password }
router.post('/login', async (req, res) => {
  exigir(req.body, ['email', 'password']);
  const email = String(req.body.email).trim().toLowerCase();
  const [linhas] = await db.query(
    'SELECT id, nome, email, password_hash FROM utilizadores WHERE email = ?',
    [email],
  );
  const utilizador = linhas[0];
  const certa = utilizador && (await bcrypt.compare(String(req.body.password), utilizador.password_hash));
  if (!certa) throw new ErroApi(401, 'Email ou palavra-passe incorretos.');

  res.json({
    token: criarToken(utilizador.id),
    utilizador: { id: utilizador.id, nome: utilizador.nome, email: utilizador.email },
  });
});

// GET /auth/eu  → quem está autenticado
router.get('/eu', autenticar, async (req, res) => {
  const [linhas] = await db.query('SELECT id, nome, email FROM utilizadores WHERE id = ?', [req.utilizadorId]);
  if (linhas.length === 0) throw new ErroApi(404, 'Utilizador não encontrado.');
  res.json(linhas[0]);
});

module.exports = router;

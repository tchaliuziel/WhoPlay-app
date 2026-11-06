// Protege as rotas: só deixa passar pedidos com um token JWT válido
// no cabeçalho "Authorization: Bearer <token>".
const jwt = require('jsonwebtoken');
const config = require('../config');

function autenticar(req, res, next) {
  const cabecalho = req.headers.authorization || '';
  const token = cabecalho.startsWith('Bearer ') ? cabecalho.slice(7) : null;
  if (!token) {
    return res.status(401).json({ erro: 'Sessão em falta. Faz login.' });
  }
  try {
    const dados = jwt.verify(token, config.jwtSecret);
    req.utilizadorId = dados.id; // as rotas usam isto para saber quem é
    next();
  } catch {
    res.status(401).json({ erro: 'Sessão inválida ou expirada. Faz login outra vez.' });
  }
}

module.exports = autenticar;

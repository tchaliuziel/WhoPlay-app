const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
const app = express();
app.use(cors()); // deixa a app no Chrome falar com a API
app.use(express.json()); // lê o corpo dos pedidos em JSON
// Ligação ao MySQL do XAMPP (utilizador root, sem palavra-passe)
const db = mysql.createPool({
host: 'localhost',
user: 'root',
password: '',
database: 'whoplay_login',
});
// POST /login → { "email": "...", "password": "..." }
app.post('/login', async (req, res) => {
const { email, password } = req.body;
if (!email || !password) {
return res.status(400).json({ erro: 'Preenche o email e a palavra-passe.'
});
}
const [linhas] = await db.query(
'SELECT id, nome, password_hash FROM utilizadores WHERE email = ?',
[email],
);
const utilizador = linhas[0];
if (!utilizador || !(await bcrypt.compare(password,
utilizador.password_hash))) {
return res.status(401).json({ erro: 'Email ou palavra-passe errados.' });
}
res.json({ id: utilizador.id, nome: utilizador.nome });
});

// POST /registo → { "nome": "...", "email": "...", "password": "..." }
app.post('/registo', async (req, res) => {
const { nome, email, password } = req.body;
if (!nome || !email || !password) {
return res.status(400).json({ erro: 'Preenche o nome, o email e a palavra-passe.' });
}
if (password.length < 8) {
return res.status(400).json({ erro: 'A palavra-passe tem de ter pelo menos 8 caracteres.' });
}
// Nunca guardar a palavra-passe: guarda-se só o hash
const hash = await bcrypt.hash(password, 10);
try {
const [resultado] = await db.query(
'INSERT INTO utilizadores (nome, email, password_hash) VALUES (?, ?, ?)',
[nome, email, hash],
);
res.status(201).json({ id: resultado.insertId, nome });
} catch (erro) {
// A coluna email é UNIQUE: o MySQL recusa um email repetido
if (erro.code === 'ER_DUP_ENTRY') {
return res.status(409).json({ erro: 'Já existe uma conta com este email.' });
}
throw erro;
}
});

// POST /onboarding → { "utilizador_id": 1, "desportos": [...], "disponibilidade": [...] }
app.post('/onboarding', async (req, res) => {
const { utilizador_id, desportos, disponibilidade } = req.body;
if (!utilizador_id) {
return res.status(400).json({ erro: 'Falta saber quem és. Entra outra vez.' });
}
if (!Array.isArray(desportos) || desportos.length === 0) {
return res.status(400).json({ erro: 'Escolhe pelo menos um desporto.' });
}
// O onboarding do WhoPlay só pede desportos: se não vierem horários, ficam os que já havia
if (disponibilidade !== undefined && (!Array.isArray(disponibilidade) || disponibilidade.length === 0)) {
return res.status(400).json({ erro: 'Escolhe pelo menos um horário.' });
}
// Uma transação: ou grava tudo, ou não grava nada
const ligacao = await db.getConnection();
try {
await ligacao.beginTransaction();
// Apaga o que havia antes, para se poder repetir o onboarding
await ligacao.query('DELETE FROM utilizador_desportos WHERE utilizador_id = ?', [utilizador_id]);
if (disponibilidade) {
await ligacao.query('DELETE FROM disponibilidades WHERE utilizador_id = ?', [utilizador_id]);
}
for (const d of desportos) {
await ligacao.query(
'INSERT INTO utilizador_desportos (utilizador_id, desporto, nivel) VALUES (?, ?, ?)',
[utilizador_id, d.desporto, d.nivel],
);
}
for (const h of disponibilidade || []) {
await ligacao.query(
'INSERT INTO disponibilidades (utilizador_id, dia, periodo) VALUES (?, ?, ?)',
[utilizador_id, h.dia, h.periodo],
);
}
await ligacao.commit();
res.json({ ok: true });
} catch (erro) {
await ligacao.rollback();
// O utilizador_id não existe na tabela utilizadores
if (erro.code === 'ER_NO_REFERENCED_ROW_2') {
return res.status(404).json({ erro: 'Esse utilizador não existe. Entra outra vez.' });
}
throw erro;
} finally {
ligacao.release();
}
});

// GET /perfil/1 → nome, email, desportos e disponibilidade do utilizador 1
app.get('/perfil/:id', async (req, res) => {
const id = req.params.id;
const [utilizadores] = await db.query(
'SELECT id, nome, email FROM utilizadores WHERE id = ?',
[id],
);
if (utilizadores.length === 0) {
return res.status(404).json({ erro: 'Esse utilizador não existe. Entra outra vez.' });
}
const [desportos] = await db.query(
'SELECT desporto, nivel FROM utilizador_desportos WHERE utilizador_id = ? ORDER BY desporto',
[id],
);
// Ordena pelos dias da semana e pelos períodos do dia (e não por ordem alfabética)
const [disponibilidade] = await db.query(`SELECT dia, periodo FROM disponibilidades WHERE utilizador_id = ? ORDER BY FIELD(dia, 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'), FIELD(periodo, 'Manhã', 'Tarde', 'Noite')`, [id], );
res.json({ ...utilizadores[0], desportos, disponibilidade });
});

const porta = Number(process.env.PORT) || 3000;
app.listen(porta, () => {
console.log(`API a correr em http://localhost:${porta}`);
});

// Ponto de entrada da API: `npm run dev`
const express = require('express');
const cors = require('cors');
const config = require('./config');
const db = require('./db');
const autenticar = require('./middleware/auth');

const app = express();
app.use(cors()); // deixa a app Flutter (web) chamar a API
app.use(express.json()); // lê o corpo dos pedidos em JSON

// Rotas públicas
app.get('/', (req, res) => res.json({ app: 'WhoPlay API', estado: 'ok' }));
app.get('/saude', async (req, res) => {
  await db.query('SELECT 1');
  res.json({ api: 'ok', base_de_dados: 'ok' });
});
app.use('/auth', require('./routes/auth'));
app.use('/modalidades', require('./routes/modalidades'));

// Rotas protegidas (precisam de token)
app.use('/perfil', autenticar, require('./routes/perfil'));
app.use('/jogadores', autenticar, require('./routes/jogadores'));
app.use('/jogos', autenticar, require('./routes/jogos'));
app.use('/convites', autenticar, require('./routes/convites'));
app.use('/avisos', autenticar, require('./routes/avisos'));

// Rota que não existe → 404
app.use((req, res) => res.status(404).json({ erro: 'Rota não encontrada.' }));

// Erros do MySQL que são culpa do pedido (dados errados) e não do servidor.
const ERROS_MYSQL = {
  ER_DUP_ENTRY: [409, 'Esse registo já existe.'],
  ER_NO_REFERENCED_ROW_2: [400, 'Um dos ids enviados não existe.'],
  ER_CHECK_CONSTRAINT_VIOLATED: [400, 'Valores fora das regras da base de dados.'], // MySQL
  ER_CONSTRAINT_FAILED: [400, 'Valores fora das regras da base de dados.'], // MariaDB
  WARN_DATA_TRUNCATED: [400, 'Um dos valores enviados não é válido.'],
  ER_TRUNCATED_WRONG_VALUE: [400, 'Um dos valores enviados não é válido.'],
};

// Qualquer erro lançado numa rota chega aqui.
app.use((erro, req, res, next) => {
  const conhecido = ERROS_MYSQL[erro.code];
  const status = erro.status || (conhecido ? conhecido[0] : 500);
  if (status === 500) console.error(erro);
  const mensagem = erro.status ? erro.message : conhecido ? conhecido[1] : 'Erro interno do servidor.';
  res.status(status).json({ erro: mensagem });
});

app.listen(config.port, () => {
  console.log(`WhoPlay API a correr em http://localhost:${config.port}`);
});

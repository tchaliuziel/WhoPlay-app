// Lê o ficheiro .env e junta todas as configurações num só sítio.
require('dotenv').config({ quiet: true });

module.exports = {
  port: Number(process.env.PORT) || 3000,
  db: {
    host: process.env.DB_HOST || 'localhost',
    port: Number(process.env.DB_PORT) || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'whoplay',
  },
  jwtSecret: process.env.JWT_SECRET || 'so-para-desenvolvimento',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
};

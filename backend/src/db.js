// Ligação ao MySQL. Um "pool" mantém várias ligações abertas e reutiliza-as.
const mysql = require('mysql2/promise');
const config = require('./config');

const pool = mysql.createPool({
  ...config.db,
  charset: 'utf8mb4',
  dateStrings: true, // datas chegam como texto "2026-10-31 10:00:00"
  decimalNumbers: true, // DECIMAL chega como número (8.00 → 8)
  connectionLimit: 10,
});

module.exports = pool;

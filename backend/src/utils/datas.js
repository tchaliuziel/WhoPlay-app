// Ajudas para mostrar datas em português nos avisos.
const DIAS = ['domingo', 'segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado'];

// "2026-10-31 10:00:00" → "sábado às 10:00"
function quando(dataHora) {
  const data = new Date(dataHora.replace(' ', 'T'));
  return `${DIAS[data.getDay()]} às ${dataHora.slice(11, 16)}`;
}

// Dia da semana de hoje no formato da BD: 1 = segunda … 7 = domingo
function diaDeHoje() {
  return ((new Date().getDay() + 6) % 7) + 1;
}

// Aceita "2026-10-31T10:00" ou "2026-10-31 10:00:00" e devolve o formato do MySQL.
function paraMysql(dataHora) {
  const texto = String(dataHora).replace('T', ' ');
  return texto.length === 16 ? `${texto}:00` : texto.slice(0, 19);
}

module.exports = { quando, diaDeHoje, paraMysql };

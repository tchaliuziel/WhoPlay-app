// Cálculo da compatibilidade entre 2 jogadores (RF10).
// Total máximo = 100 pontos, repartidos por 5 critérios.
const PESOS = { desporto: 30, nivel: 25, disponibilidade: 20, distancia: 15, objetivo: 10 };
const NIVEIS = ['Iniciante', 'Intermédio', 'Avançado'];
const RAIO_TERRA_KM = 6371;

// Método numérico: fórmula de Haversine (distância sobre a superfície da Terra).
function distanciaKm(lat1, lon1, lat2, lon2) {
  const rad = (graus) => (graus * Math.PI) / 180;
  const dLat = rad(lat2 - lat1);
  const dLon = rad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(rad(lat1)) * Math.cos(rad(lat2)) * Math.sin(dLon / 2) ** 2;
  return 2 * RAIO_TERRA_KM * Math.asin(Math.sqrt(a));
}

// "18:30:00" → 1110 minutos desde a meia-noite
function minutos(hora) {
  const [h, m] = hora.split(':').map(Number);
  return h * 60 + m;
}

// Minutos em que os 2 estão livres ao mesmo tempo, somados na semana inteira.
function minutosEmComum(minhas, dele) {
  let total = 0;
  for (const a of minhas) {
    for (const b of dele) {
      if (a.dia_semana !== b.dia_semana) continue;
      const inicio = Math.max(minutos(a.hora_inicio), minutos(b.hora_inicio));
      const fim = Math.min(minutos(a.hora_fim), minutos(b.hora_fim));
      total += Math.max(0, fim - inicio);
    }
  }
  return total;
}

// Devolve { total, criterios: [{ nome, pontos, maximo }] }.
function calcularCompatibilidade({ eu, outro, distancia, raioKm }) {
  // 1. Mesmo desporto: os 2 jogam a modalidade escolhida.
  const desporto = eu.nivel && outro.nivel ? PESOS.desporto : 0;

  // 2. Nível: igual = 25, 1 nível de diferença = 13, 2 níveis = 0.
  let nivel = 0;
  if (eu.nivel && outro.nivel) {
    const diferenca = Math.abs(NIVEIS.indexOf(eu.nivel) - NIVEIS.indexOf(outro.nivel));
    nivel = PESOS.nivel * (1 - diferenca / 2);
  }

  // 3. Disponibilidade: parte do MEU tempo livre em que o outro também está livre.
  const meusMinutos = eu.disponibilidade.reduce(
    (soma, d) => soma + minutos(d.hora_fim) - minutos(d.hora_inicio),
    0,
  );
  const disponibilidade =
    meusMinutos > 0
      ? PESOS.disponibilidade * (minutosEmComum(eu.disponibilidade, outro.disponibilidade) / meusMinutos)
      : 0;

  // 4. Distância: 0 km = 15 pontos, desce até 0 ao dobro do raio.
  const distanciaPontos = PESOS.distancia * Math.max(0, 1 - distancia / (2 * raioKm));

  // 5. Objetivo: igual = 10, diferente = 4.
  const objetivo = eu.objetivo === outro.objetivo ? PESOS.objetivo : 4;

  const criterios = [
    { nome: 'Mesmo desporto', pontos: Math.round(desporto), maximo: PESOS.desporto },
    { nome: 'Nível', pontos: Math.round(nivel), maximo: PESOS.nivel },
    { nome: 'Disponibilidade', pontos: Math.round(disponibilidade), maximo: PESOS.disponibilidade },
    { nome: 'Distância', pontos: Math.round(distanciaPontos), maximo: PESOS.distancia },
    { nome: 'Objetivo', pontos: Math.round(objetivo), maximo: PESOS.objetivo },
  ];
  const total = criterios.reduce((soma, c) => soma + c.pontos, 0);
  return { total, criterios };
}

// Estatística: média e desvio-padrão das compatibilidades encontradas.
function estatisticas(valores) {
  if (valores.length === 0) return { total: 0, media: 0, desvio_padrao: 0 };
  const media = valores.reduce((s, v) => s + v, 0) / valores.length;
  const variancia = valores.reduce((s, v) => s + (v - media) ** 2, 0) / valores.length;
  return {
    total: valores.length,
    media: Math.round(media * 10) / 10,
    desvio_padrao: Math.round(Math.sqrt(variancia) * 10) / 10,
  };
}

module.exports = { distanciaKm, calcularCompatibilidade, estatisticas, NIVEIS };

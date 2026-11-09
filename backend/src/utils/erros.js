// Erro com código HTTP. Lançar `new ErroApi(404, 'Jogo não encontrado.')`
// numa rota faz a API responder { "erro": "Jogo não encontrado." } com 404.
class ErroApi extends Error {
  constructor(status, mensagem) {
    super(mensagem);
    this.status = status;
  }
}

// Confirma que o corpo do pedido tem todos os campos obrigatórios.
function exigir(corpo, campos) {
  const emFalta = campos.filter((c) => corpo[c] === undefined || corpo[c] === null || corpo[c] === '');
  if (emFalta.length > 0) {
    throw new ErroApi(400, `Campos obrigatórios em falta: ${emFalta.join(', ')}.`);
  }
}

module.exports = { ErroApi, exigir };

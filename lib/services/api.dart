import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../data/dados_exemplo.dart';
import '../data/models.dart';

/// Erro mostrado ao utilizador (ex.: dados em falta no formulário).
class ApiException implements Exception {
  const ApiException(this.message, [this.status]);

  final String message;
  final int? status;

  @override
  String toString() => message;
}

/// API da app.
///
/// - Login, registo, desportos do onboarding e perfil: vão à API em
///   `api_login/` (Node + MySQL do XAMPP, base de dados `whoplay_login`).
/// - Jogadores, jogos, convites e avisos: continuam em memória, a partir de
///   lib/data/dados_exemplo.dart.
abstract final class Api {
  /// Para um telemóvel real: flutter run --dart-define=API_URL=http://192.168.1.10:3000
  static const _urlDefinido = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_urlDefinido.isNotEmpty) return _urlDefinido;
    // O emulador Android vê o PC no endereço 10.0.2.2 (localhost seria o próprio emulador).
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  /// O id de quem entrou (fica guardado depois do login ou do registo).
  static int? _utilizadorId;

  static bool get autenticado => _utilizadorId != null;

  /// RF03 — terminar sessão: a app esquece quem entrou.
  static void terminarSessao() {
    _utilizadorId = null;
    _perfil = DadosExemplo.perfil;
  }

  /// Faz um pedido à API e devolve o JSON da resposta. Se a API devolver
  /// {"erro": "..."}, lança ApiException com essa mensagem.
  static Future<dynamic> _pedido(String metodo, String caminho, {Object? corpo}) async {
    final uri = Uri.parse('$baseUrl$caminho');
    const cabecalhos = {'Content-Type': 'application/json'};
    final http.Response resposta;
    try {
      final pedido = metodo == 'POST'
          ? http.post(uri, headers: cabecalhos, body: jsonEncode(corpo))
          : http.get(uri, headers: cabecalhos);
      resposta = await pedido.timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const ApiException('O servidor demorou demasiado a responder.');
    } on http.ClientException {
      throw const ApiException('Não foi possível ligar ao servidor. A API está a correr?');
    }
    final dados = resposta.bodyBytes.isEmpty ? null : jsonDecode(utf8.decode(resposta.bodyBytes));
    if (resposta.statusCode >= 400) {
      final mensagem = dados is Map && dados['erro'] is String ? dados['erro'] as String : 'Erro ${resposta.statusCode}';
      throw ApiException(mensagem, resposta.statusCode);
    }
    return dados;
  }

  // Na base de dados os horários são dia ('Seg'…'Dom') + período ('Manhã', 'Tarde', 'Noite').
  static const _dias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  static const _periodos = {
    'Manhã': ('08:00', '12:00'),
    'Tarde': ('12:00', '18:00'),
    'Noite': ('18:00', '22:00'),
  };

  /// Converte o JSON de GET /perfil/:id no Perfil usado pelos ecrãs. Os campos
  /// que a base de dados ainda não tem (localidade, raio…) ficam como estavam.
  static Perfil _perfilDaApi(Map<String, dynamic> json) => Perfil(
        id: json['id'] as int,
        nome: json['nome'] as String,
        email: json['email'] as String,
        localidade: _perfil.localidade,
        raioKm: _perfil.raioKm,
        objetivo: _perfil.objetivo,
        avaliacao: _perfil.avaliacao,
        modalidades: [
          for (final d in json['desportos'] as List)
            ModalidadeNivel(
              id: DadosExemplo.modalidades
                  .firstWhere((m) => m.nome == d['desporto'],
                      orElse: () => const Modalidade(id: 0, nome: '', descricao: ''))
                  .id,
              nome: d['desporto'] as String,
              nivel: d['nivel'] as String,
            ),
        ],
        disponibilidade: [
          for (final h in json['disponibilidade'] as List)
            if (_dias.contains(h['dia']) && _periodos.containsKey(h['periodo']))
              Disponibilidade(
                diaSemana: _dias.indexOf(h['dia'] as String) + 1,
                horaInicio: _periodos[h['periodo']]!.$1,
                horaFim: _periodos[h['periodo']]!.$2,
              ),
        ],
      );

  /// Pequena pausa para os ecrãs mostrarem o "A carregar…" como com o servidor.
  static Future<void> _espera() => Future.delayed(const Duration(milliseconds: 250));

  static Perfil _perfil = DadosExemplo.perfil;
  static final List<Jogo> _jogos = [DadosExemplo.jogo];
  static final List<Convite> _enviados = DadosExemplo.convitesEnviados;
  static final List<Convite> _recebidos = DadosExemplo.convitesRecebidos;
  static final List<Aviso> _avisos = DadosExemplo.avisos;
  static int _proximoId = 100;

  // ---------------------------------------------------------------- autenticação

  /// POST /login → { id, nome }
  static Future<void> login(String email, String password) async {
    final dados = await _pedido('POST', '/login', corpo: {'email': email, 'password': password});
    _utilizadorId = dados['id'] as int;
    _perfil = DadosExemplo.perfil;
    await perfil();
  }

  /// POST /registo → { id, nome }
  static Future<void> registo(String nome, String email, String password) async {
    final dados = await _pedido('POST', '/registo', corpo: {'nome': nome, 'email': email, 'password': password});
    _utilizadorId = dados['id'] as int;
    _perfil = Perfil(
      id: _utilizadorId!,
      nome: dados['nome'] as String,
      email: email,
      localidade: null,
      raioKm: 5,
      objetivo: 'Jogos amigáveis',
      avaliacao: null,
      modalidades: const [],
      disponibilidade: const [],
    );
  }

  // ---------------------------------------------------------------- perfil

  static Future<List<Modalidade>> modalidades() async {
    await _espera();
    return DadosExemplo.modalidades;
  }

  /// GET /perfil/:id → nome, email, desportos e disponibilidade de quem entrou.
  static Future<Perfil> perfil() async {
    if (_utilizadorId == null) throw const ApiException('Falta saber quem és. Entra outra vez.');
    final dados = await _pedido('GET', '/perfil/$_utilizadorId');
    _perfil = _perfilDaApi(dados as Map<String, dynamic>);
    return _perfil;
  }

  static Future<void> atualizarPerfil(Map<String, Object?> campos) async {
    await _espera();
    _perfil = Perfil(
      id: _perfil.id,
      nome: _perfil.nome,
      email: _perfil.email,
      localidade: campos['localidade'] as String? ?? _perfil.localidade,
      raioKm: _perfil.raioKm,
      objetivo: _perfil.objetivo,
      avaliacao: _perfil.avaliacao,
      modalidades: _perfil.modalidades,
      disponibilidade: _perfil.disponibilidade,
    );
  }

  /// POST /onboarding → grava os desportos escolhidos (os horários ficam como estavam).
  static Future<void> atualizarModalidades(List<int> ids, {String nivel = 'Iniciante'}) async {
    if (_utilizadorId == null) throw const ApiException('Falta saber quem és. Entra outra vez.');
    if (ids.isEmpty) throw const ApiException('Escolhe pelo menos um desporto.');
    await _pedido('POST', '/onboarding', corpo: {
      'utilizador_id': _utilizadorId,
      'desportos': [
        for (final m in DadosExemplo.modalidades)
          if (ids.contains(m.id)) {'desporto': m.nome, 'nivel': nivel},
      ],
    });
    _perfil = Perfil(
      id: _perfil.id,
      nome: _perfil.nome,
      email: _perfil.email,
      localidade: _perfil.localidade,
      raioKm: _perfil.raioKm,
      objetivo: _perfil.objetivo,
      avaliacao: _perfil.avaliacao,
      modalidades: [
        for (final m in DadosExemplo.modalidades)
          if (ids.contains(m.id)) ModalidadeNivel(id: m.id, nome: m.nome, nivel: nivel),
      ],
      disponibilidade: _perfil.disponibilidade,
    );
  }

  // ---------------------------------------------------------------- jogadores

  static Future<List<Jogador>> jogadores({required int modalidadeId, int? raioKm}) async {
    await _espera();
    return [
      for (final j in DadosExemplo.jogadores)
        if (raioKm == null || j.distanciaKm <= raioKm) j,
    ];
  }

  // ---------------------------------------------------------------- jogos

  static Future<List<Jogo>> jogos() async {
    await _espera();
    return List.of(_jogos);
  }

  static Future<Jogo> jogo(int id) async {
    await _espera();
    return _jogos.firstWhere((j) => j.id == id, orElse: () => throw const ApiException('Jogo não encontrado.'));
  }

  static Future<int> criarJogo({
    required int modalidadeId,
    required DateTime dataHora,
    required String local,
    required String nivel,
    required String formato,
    required int capacidade,
    required int vagasAbertas,
    required double preco,
  }) async {
    await _espera();
    if (local.isEmpty) throw const ApiException('Indica o local do jogo.');
    final modalidade = DadosExemplo.modalidades.firstWhere((m) => m.id == modalidadeId);
    final ocupados = capacidade - vagasAbertas;
    final jogo = Jogo(
      id: _proximoId++,
      organizador: _perfil.nome,
      modalidadeId: modalidadeId,
      modalidade: modalidade.nome,
      dataHora: dataHora,
      localNome: local,
      nivel: nivel,
      formato: formato,
      capacidade: capacidade,
      ocupados: ocupados,
      vagas: vagasAbertas,
      preco: preco,
      distanciaKm: 0,
      participantes: [Participante(id: _perfil.id, nome: _perfil.nome, organizador: true, nivel: nivel)],
      euParticipo: true,
    );
    _jogos.add(jogo);
    return jogo.id;
  }

  /// Entra no jogo (ou, se já lá estiver, devolve o código que já tinha).
  static Future<String> entrarNoJogo(int id) async {
    final jogo = await Api.jogo(id);
    final codigo = 'WHOPLAY-${jogo.id}-${_perfil.id}';
    if (jogo.euParticipo) return codigo;
    if (jogo.vagas == 0) throw const ApiException('Este jogo já está cheio.');
    _jogos[_jogos.indexOf(jogo)] = Jogo(
      id: jogo.id,
      organizador: jogo.organizador,
      modalidadeId: jogo.modalidadeId,
      modalidade: jogo.modalidade,
      dataHora: jogo.dataHora,
      localNome: jogo.localNome,
      nivel: jogo.nivel,
      formato: jogo.formato,
      capacidade: jogo.capacidade,
      ocupados: jogo.ocupados + 1,
      vagas: jogo.vagas - 1,
      preco: jogo.preco,
      distanciaKm: jogo.distanciaKm,
      participantes: [
        ...jogo.participantes,
        Participante(id: _perfil.id, nome: _perfil.nome, organizador: false, nivel: jogo.nivel),
      ],
      euParticipo: true,
    );
    return codigo;
  }

  // ---------------------------------------------------------------- convites e avisos

  static Future<({List<Convite> enviados, List<Convite> recebidos})> convites() async {
    await _espera();
    return (enviados: List.of(_enviados), recebidos: List.of(_recebidos));
  }

  static Future<void> enviarConvite({required int jogadorId, required int modalidadeId, required DateTime dataHora}) async {
    await _espera();
    if (_enviados.any((c) => c.jogadorId == jogadorId)) {
      throw const ApiException('Já tens um convite à espera de resposta deste jogador.');
    }
    final jogador = DadosExemplo.jogadores.firstWhere((j) => j.id == jogadorId);
    _enviados.add(Convite(
      id: _proximoId++,
      estado: 'pendente',
      dataHora: dataHora,
      modalidade: DadosExemplo.modalidades.firstWhere((m) => m.id == modalidadeId).nome,
      jogadorId: jogadorId,
      nome: jogador.nome,
      distanciaKm: jogador.distanciaKm,
    ));
  }

  static Future<void> responderConvite(int id, {required bool aceitar}) async {
    await _espera();
    final convite = _recebidos.firstWhere((c) => c.id == id);
    _recebidos.remove(convite);
    _avisos.insert(
      0,
      Aviso(
        id: _proximoId++,
        titulo: aceitar ? 'Aceitaste o convite de ${convite.nome}' : 'Recusaste o convite de ${convite.nome}',
        detalhe: '',
        lida: false,
        criadoEm: DateTime.now(),
      ),
    );
  }

  static Future<List<Aviso>> avisos() async {
    await _espera();
    return List.of(_avisos);
  }
}

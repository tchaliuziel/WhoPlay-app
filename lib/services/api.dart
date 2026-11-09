
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../data/dados_exemplo.dart';
import '../data/models.dart';

/// Erro apresentado ao utilizador.
class ApiException implements Exception {
  const ApiException(this.message, [this.status]);

  final String message;
  final int? status;

  @override
  String toString() => message;
}

/// Serviço de comunicação com a API WhoPlay.
abstract final class Api {
  /// Para um telemóvel real:
  /// flutter run --dart-define=API_URL=http://192.168.1.10:3000
  static const _urlDefinido = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_urlDefinido.isNotEmpty) return _urlDefinido;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }

    return 'http://localhost:3000';
  }

  static int? _utilizadorId;
  static String? _token;

  /// ID do utilizador atualmente autenticado.
  static int? get utilizadorId => _utilizadorId;

  static bool get autenticado =>
      _utilizadorId != null && _token != null;

  /// Termina a sessão local.
  static void terminarSessao() {
    _utilizadorId = null;
    _token = null;
    _perfil = DadosExemplo.perfil;
  }

  /// Executa pedidos HTTP e envia o JWT nas rotas protegidas.
  static Future<dynamic> _pedido(
    String metodo,
    String caminho, {
    Object? corpo,
  }) async {
    final uri = Uri.parse('$baseUrl$caminho');

    final cabecalhos = <String, String>{
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };

    final http.Response resposta;

    try {
      final body = corpo == null ? null : jsonEncode(corpo);

      final pedido = switch (metodo) {
        'POST' => http.post(uri, headers: cabecalhos, body: body),
        'PUT' => http.put(uri, headers: cabecalhos, body: body),
        'GET' => http.get(uri, headers: cabecalhos),
        _ => throw ArgumentError('Método HTTP não suportado: $metodo'),
      };

      resposta = await pedido.timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const ApiException('O servidor demorou demasiado a responder.');
    } on http.ClientException {
      throw const ApiException(
        'Não foi possível ligar ao servidor. A API está a correr?',
      );
    }

    final texto = utf8.decode(resposta.bodyBytes);
    final dados = texto.isEmpty ? null : jsonDecode(texto);

    if (resposta.statusCode >= 400) {
      final mensagem = dados is Map && dados['erro'] is String
          ? dados['erro'] as String
          : 'Erro ${resposta.statusCode}';

      throw ApiException(mensagem, resposta.statusCode);
    }

    return dados;
  }

  /// Converte a resposta de GET /perfil para o modelo Perfil.
  static Perfil _perfilDaApi(Map<String, dynamic> json) {
    final modalidadesJson = json['modalidades'] as List? ?? const [];
    final disponibilidadeJson =
        json['disponibilidade'] as List? ?? const [];

    return Perfil(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String,
      email: json['email'] as String,
      localidade: json['localidade'] as String?,
      raioKm: (json['raio_km'] as num?)?.toInt() ?? _perfil.raioKm,
      objetivo: json['objetivo'] as String? ?? _perfil.objetivo,
      avaliacao: (json['avaliacao'] as num?)?.toDouble(),
      modalidades: [
        for (final item in modalidadesJson)
          ModalidadeNivel(
            id: (item['id'] as num).toInt(),
            nome: item['nome'] as String,
            nivel: item['nivel'] as String,
          ),
      ],
      disponibilidade: [
        for (final item in disponibilidadeJson)
          Disponibilidade(
            diaSemana: (item['dia_semana'] as num).toInt(),
            horaInicio: item['hora_inicio'] as String,
            horaFim: item['hora_fim'] as String,
          ),
      ],
    );
  }

  static Perfil _perfil = DadosExemplo.perfil;

  // ---------------------------------------------------------------------------
  // Autenticação
  // ---------------------------------------------------------------------------

  /// POST /auth/login.
  static Future<void> login(String email, String password) async {
    final dados = await _pedido(
      'POST',
      '/auth/login',
      corpo: {
        'email': email,
        'password': password,
      },
    ) as Map<String, dynamic>;

    final utilizador = dados['utilizador'] as Map<String, dynamic>;

    _token = dados['token'] as String;
    _utilizadorId = (utilizador['id'] as num).toInt();

    await perfil();
  }

  /// POST /auth/registo.
  static Future<void> registo(
    String nome,
    String email,
    String password,
  ) async {
    final dados = await _pedido(
      'POST',
      '/auth/registo',
      corpo: {
        'nome': nome,
        'email': email,
        'password': password,
      },
    ) as Map<String, dynamic>;

    final utilizador = dados['utilizador'] as Map<String, dynamic>;

    _token = dados['token'] as String;
    _utilizadorId = (utilizador['id'] as num).toInt();

    await perfil();
  }

  // ---------------------------------------------------------------------------
  // Perfil e modalidades
  // ---------------------------------------------------------------------------

  /// GET /modalidades.
  static Future<List<Modalidade>> modalidades() async {
    final dados = await _pedido('GET', '/modalidades') as List;

    return [
      for (final item in dados)
        Modalidade(
          id: (item['id'] as num).toInt(),
          nome: item['nome'] as String,
          descricao: item['descricao'] as String? ?? '',
        ),
    ];
  }

  /// GET /perfil.
  static Future<Perfil> perfil() async {
    if (!autenticado) {
      throw const ApiException('Falta saber quem és. Entra outra vez.');
    }

    final dados = await _pedido('GET', '/perfil') as Map<String, dynamic>;

    _perfil = _perfilDaApi(dados);
    return _perfil;
  }

  /// PUT /perfil.
  static Future<void> atualizarPerfil(Map<String, Object?> campos) async {
    if (!autenticado) {
      throw const ApiException('Falta saber quem és. Entra outra vez.');
    }

    await _pedido('PUT', '/perfil', corpo: campos);
    await perfil();
  }

  /// PUT /perfil/modalidades.
  static Future<void> atualizarModalidades(
    List<int> ids, {
    String nivel = 'Iniciante',
  }) async {
    if (!autenticado) {
      throw const ApiException('Falta saber quem és. Entra outra vez.');
    }

    if (ids.isEmpty) {
      throw const ApiException('Escolhe pelo menos um desporto.');
    }

    await _pedido(
      'PUT',
      '/perfil/modalidades',
      corpo: {
        'modalidades': [
          for (final id in ids)
            {
              'modalidade_id': id,
              'nivel': nivel,
            },
        ],
      },
    );

    await perfil();
  }

  /// PUT /perfil/disponibilidade.
  /// Substitui a disponibilidade semanal do utilizador.
  static Future<void> atualizarDisponibilidade(
    List<Map<String, Object?>> disponibilidade,
  ) async {
    if (!autenticado) {
      throw const ApiException('Inicia sessão para editar a disponibilidade.');
    }

    await _pedido(
      'PUT',
      '/perfil/disponibilidade',
      corpo: {
        'disponibilidade': disponibilidade,
      },
    );

    await perfil();
  }

  /// PUT /perfil/modalidades.
  /// Atualiza cada modalidade com o respetivo nível individual.
  static Future<void> atualizarModalidadesDetalhadas(
    Map<int, String> modalidades,
  ) async {
    if (!autenticado) {
      throw const ApiException('Inicia sessão para editar as modalidades.');
    }

    if (modalidades.isEmpty) {
      throw const ApiException('Escolhe pelo menos um desporto.');
    }

    await _pedido(
      'PUT',
      '/perfil/modalidades',
      corpo: {
        'modalidades': [
          for (final entrada in modalidades.entries)
            {
              'modalidade_id': entrada.key,
              'nivel': entrada.value,
            },
        ],
      },
    );

    await perfil();
  }

  // ---------------------------------------------------------------------------
  // Jogadores
  // ---------------------------------------------------------------------------

  /// GET /jogadores.
  static Future<List<Jogador>> jogadores({
    required int modalidadeId,
    int? raioKm,
  }) async {
    if (!autenticado) {
      throw const ApiException('Inicia sessão para procurar jogadores.');
    }

    final parametros = <String, String>{
      'modalidade': modalidadeId.toString(),
      if (raioKm != null) 'raio': raioKm.toString(),
    };

    final query = Uri(queryParameters: parametros).query;

    final dados = await _pedido(
      'GET',
      '/jogadores?$query',
    ) as Map<String, dynamic>;

    final lista = dados['jogadores'] as List? ?? const [];

    return [
      for (final item in lista)
        Jogador.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }

  // ---------------------------------------------------------------------------
  // Jogos (API + MySQL)
  // ---------------------------------------------------------------------------

  /// GET /jogos ou GET /jogos?modalidade=ID.
  static Future<List<Jogo>> jogos({int? modalidadeId}) async {
    if (!autenticado) {
      throw const ApiException('Inicia sessão para consultar os jogos.');
    }

    final query = modalidadeId == null
        ? ''
        : '?modalidade=${Uri.encodeQueryComponent(modalidadeId.toString())}';

    final dados = await _pedido('GET', '/jogos$query') as List;

    return [
      for (final item in dados)
        Jogo.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }

  /// GET /jogos/historico.
  /// Filtros: todos, organizados ou participados.
  static Future<List<dynamic>> historicoJogos({
    String filtro = 'todos',
  }) async {
    if (!autenticado) {
      throw const ApiException('Inicia sessão para consultar o histórico.');
    }

    final query = Uri(
      queryParameters: {'filtro': filtro},
    ).query;

    final dados = await _pedido(
      'GET',
      '/jogos/historico?$query',
    ) as List;

    return dados;
  }

  /// GET /jogos/estatisticas.
  static Future<Map<String, dynamic>> estatisticasJogos() async {
    if (!autenticado) {
      throw const ApiException(
        'Inicia sessão para consultar as estatísticas.',
      );
    }

    final dados = await _pedido(
      'GET',
      '/jogos/estatisticas',
    ) as Map<String, dynamic>;

    return dados;
  }

  /// GET /jogos/:id/presencas.
  static Future<Map<String, dynamic>> presencasJogo(int jogoId) async {
    if (!autenticado) {
      throw const ApiException(
        'Inicia sessão para consultar as presenças.',
      );
    }

    final dados = await _pedido(
      'GET',
      '/jogos/$jogoId/presencas',
    ) as Map<String, dynamic>;

    return dados;
  }

  /// GET /jogos/:id.
  static Future<Jogo> jogo(int id) async {
    if (!autenticado) {
      throw const ApiException('Inicia sessão para consultar este jogo.');
    }

    final dados = await _pedido(
      'GET',
      '/jogos/$id',
    ) as Map<String, dynamic>;

    return Jogo.fromJson(dados);
  }

  /// POST /jogos.
  /// O organizador ocupa automaticamente um lugar.
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
    if (!autenticado) {
      throw const ApiException('Inicia sessão para criar um jogo.');
    }

    if (local.trim().isEmpty) {
      throw const ApiException('Indica o local do jogo.');
    }

    if (capacidade < 2 || vagasAbertas < 1 || vagasAbertas >= capacidade) {
      throw const ApiException('O número de vagas não é válido.');
    }

    if (dataHora.isBefore(DateTime.now())) {
      throw const ApiException('A data do jogo tem de ser futura.');
    }

    final dados = await _pedido(
      'POST',
      '/jogos',
      corpo: {
        'modalidade_id': modalidadeId,
        'data_hora': dataHora.toIso8601String(),
        'local_nome': local.trim(),
        'nivel': nivel,
        'formato': formato,
        'capacidade': capacidade,
        'vagas_abertas': vagasAbertas,
        'preco': preco,
      },
    ) as Map<String, dynamic>;

    return (dados['id'] as num).toInt();
  }

  /// POST /jogos/:id/entrar.
  /// Devolve o código de check-in associado à inscrição.
  static Future<String> entrarNoJogo(int id) async {
    if (!autenticado) {
      throw const ApiException('Inicia sessão para entrar num jogo.');
    }

    final dados = await _pedido(
      'POST',
      '/jogos/$id/entrar',
    ) as Map<String, dynamic>;

    final codigo = dados['codigo_checkin'] as String?;

    if (codigo == null || codigo.isEmpty) {
      throw const ApiException('A API não devolveu o código de check-in.');
    }

    return codigo;
  }

  /// GET /jogos/:id/checkin.
  /// Devolve o código QR e a data de check-in, se já foi confirmado.
  static Future<Map<String, dynamic>> codigoCheckin(int jogoId) async {
    if (!autenticado) {
      throw const ApiException('Inicia sessão para consultar o QR Code.');
    }

    return await _pedido(
      'GET',
      '/jogos/$jogoId/checkin',
    ) as Map<String, dynamic>;
  }

  /// POST /jogos/checkin.
  /// O organizador envia o código lido do QR Code.
  static Future<Map<String, dynamic>> confirmarCheckin(String codigo) async {
    if (!autenticado) {
      throw const ApiException('Inicia sessão para confirmar presenças.');
    }

    if (codigo.trim().isEmpty) {
      throw const ApiException('Código de check-in inválido.');
    }

    return await _pedido(
      'POST',
      '/jogos/checkin',
      corpo: {'codigo': codigo.trim()},
    ) as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // Convites (API + MySQL)
  // ---------------------------------------------------------------------------

  static Convite _conviteDaApi(Map<String, dynamic> json) {
    final dataHora = json['data_hora'];

    return Convite(
      id: (json['id'] as num).toInt(),
      estado: json['estado'] as String,
      dataHora: dataHora is DateTime
          ? dataHora
          : DateTime.parse(dataHora.toString()),
      modalidade: json['modalidade'] as String,
      jogadorId: (json['jogador_id'] as num).toInt(),
      nome: json['nome'] as String,
      distanciaKm: (json['distancia_km'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// GET /convites.
  static Future<({List<Convite> enviados, List<Convite> recebidos})>
      convites() async {
    if (!autenticado) {
      throw const ApiException('Inicia sessão para consultar os convites.');
    }

    final dados = await _pedido(
      'GET',
      '/convites',
    ) as Map<String, dynamic>;

    final enviadosJson = dados['enviados'] as List? ?? const [];
    final recebidosJson = dados['recebidos'] as List? ?? const [];

    return (
      enviados: [
        for (final item in enviadosJson)
          _conviteDaApi(Map<String, dynamic>.from(item as Map)),
      ],
      recebidos: [
        for (final item in recebidosJson)
          _conviteDaApi(Map<String, dynamic>.from(item as Map)),
      ],
    );
  }

  /// POST /convites.
  static Future<void> enviarConvite({
    required int jogadorId,
    required int modalidadeId,
    required DateTime dataHora,
  }) async {
    if (!autenticado) {
      throw const ApiException('Inicia sessão para enviar convites.');
    }

    await _pedido(
      'POST',
      '/convites',
      corpo: {
        'destinatario_id': jogadorId,
        'modalidade_id': modalidadeId,
        'data_hora': dataHora.toIso8601String(),
      },
    );
  }

  /// POST /convites/:id/aceitar ou /convites/:id/recusar.
  static Future<void> responderConvite(
    int id, {
    required bool aceitar,
  }) async {
    if (!autenticado) {
      throw const ApiException('Inicia sessão para responder a convites.');
    }

    final acao = aceitar ? 'aceitar' : 'recusar';

    await _pedido(
      'POST',
      '/convites/$id/$acao',
    );
  }

  // ---------------------------------------------------------------------------
  // Avisos (API + MySQL)
  // ---------------------------------------------------------------------------

  static Aviso _avisoDaApi(Map<String, dynamic> json) {
    return Aviso(
      id: (json['id'] as num).toInt(),
      titulo: json['titulo'] as String,
      detalhe: json['detalhe'] as String? ?? '',
      lida: json['lida'] == true || json['lida'] == 1,
      criadoEm: DateTime.parse(json['criado_em'].toString()),
    );
  }

  /// GET /avisos.
  static Future<List<Aviso>> avisos() async {
    if (!autenticado) {
      throw const ApiException('Inicia sessão para consultar os avisos.');
    }

    final dados = await _pedido('GET', '/avisos') as List;

    return [
      for (final item in dados)
        _avisoDaApi(Map<String, dynamic>.from(item as Map)),
    ];
  }

  /// POST /avisos/lidos.
  static Future<void> marcarAvisosLidos() async {
    if (!autenticado) {
      throw const ApiException('Inicia sessão para atualizar os avisos.');
    }

    await _pedido('POST', '/avisos/lidos');
  }

  /// POST /avisos/:id/lido.
  static Future<void> marcarAvisoLido(int id) async {
    if (!autenticado) {
      throw const ApiException('Inicia sessão para atualizar os avisos.');
    }

    await _pedido('POST', '/avisos/$id/lido');
  }
}

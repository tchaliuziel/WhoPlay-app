import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../data/models.dart';
import '../utils/formatos.dart';

/// Erro devolvido pela API ({"erro": "..."}) ou falha de ligação.
class ApiException implements Exception {
  const ApiException(this.message, [this.status]);

  final String message;
  final int? status;

  @override
  String toString() => message;
}

/// Todas as chamadas à API do WhoPlay passam por aqui.
abstract final class Api {
  /// Para um telemóvel real: flutter run --dart-define=API_URL=http://192.168.1.10:3000
  static const _urlDefinido = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_urlDefinido.isNotEmpty) return _urlDefinido;
    // O emulador Android vê o PC no endereço 10.0.2.2 (localhost seria o próprio emulador).
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  static String? _token;

  static bool get autenticado => _token != null;

  /// RF03 — terminar sessão: basta esquecer o token.
  static void terminarSessao() => _token = null;

  // ---------------------------------------------------------------- base

  static Future<dynamic> _pedido(String metodo, String caminho, {Object? corpo}) async {
    final uri = Uri.parse('$baseUrl$caminho');
    final cabecalhos = {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
    final body = corpo == null ? null : jsonEncode(corpo);

    final http.Response resposta;
    try {
      final pedido = switch (metodo) {
        'GET' => http.get(uri, headers: cabecalhos),
        'POST' => http.post(uri, headers: cabecalhos, body: body),
        'PUT' => http.put(uri, headers: cabecalhos, body: body),
        _ => throw ArgumentError('Método desconhecido: $metodo'),
      };
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

  static List<T> _lista<T>(Object? dados, T Function(Map<String, dynamic>) converter) =>
      [for (final item in dados as List) converter(item as Map<String, dynamic>)];

  // ---------------------------------------------------------------- autenticação

  static Future<void> login(String email, String password) async {
    final dados = await _pedido('POST', '/auth/login', corpo: {'email': email, 'password': password});
    _token = dados['token'] as String;
  }

  static Future<void> registo(String nome, String email, String password) async {
    final dados = await _pedido('POST', '/auth/registo', corpo: {'nome': nome, 'email': email, 'password': password});
    _token = dados['token'] as String;
  }

  // ---------------------------------------------------------------- perfil

  static Future<List<Modalidade>> modalidades() async =>
      _lista(await _pedido('GET', '/modalidades'), Modalidade.fromJson);

  static Future<Perfil> perfil() async =>
      Perfil.fromJson(await _pedido('GET', '/perfil') as Map<String, dynamic>);

  static Future<void> atualizarPerfil(Map<String, Object?> campos) => _pedido('PUT', '/perfil', corpo: campos);

  static Future<void> atualizarModalidades(List<int> ids, {String nivel = 'Iniciante'}) => _pedido(
        'PUT',
        '/perfil/modalidades',
        corpo: {
          'modalidades': [for (final id in ids) {'modalidade_id': id, 'nivel': nivel}],
        },
      );

  // ---------------------------------------------------------------- jogadores

  static Future<List<Jogador>> jogadores({required int modalidadeId, int? raioKm}) async {
    final raio = raioKm == null ? '' : '&raio=$raioKm';
    final dados = await _pedido('GET', '/jogadores?modalidade=$modalidadeId$raio');
    return _lista(dados['jogadores'], Jogador.fromJson);
  }

  // ---------------------------------------------------------------- jogos

  static Future<List<Jogo>> jogos() async => _lista(await _pedido('GET', '/jogos'), Jogo.fromJson);

  static Future<Jogo> jogo(int id) async => Jogo.fromJson(await _pedido('GET', '/jogos/$id') as Map<String, dynamic>);

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
    final dados = await _pedido('POST', '/jogos', corpo: {
      'modalidade_id': modalidadeId,
      'data_hora': paraApi(dataHora),
      'local_nome': local,
      'nivel': nivel,
      'formato': formato,
      'capacidade': capacidade,
      'vagas_abertas': vagasAbertas,
      'preco': preco,
    });
    return dados['id'] as int;
  }

  /// Entra no jogo (ou, se já lá estiver, devolve o código que já tinha).
  static Future<String> entrarNoJogo(int id) async {
    final dados = await _pedido('POST', '/jogos/$id/entrar');
    return dados['codigo_checkin'] as String;
  }

  // ---------------------------------------------------------------- convites e avisos

  static Future<({List<Convite> enviados, List<Convite> recebidos})> convites() async {
    final dados = await _pedido('GET', '/convites');
    return (
      enviados: _lista(dados['enviados'], Convite.fromJson),
      recebidos: _lista(dados['recebidos'], Convite.fromJson),
    );
  }

  static Future<void> enviarConvite({required int jogadorId, required int modalidadeId, required DateTime dataHora}) =>
      _pedido('POST', '/convites', corpo: {
        'destinatario_id': jogadorId,
        'modalidade_id': modalidadeId,
        'data_hora': paraApi(dataHora),
      });

  static Future<void> responderConvite(int id, {required bool aceitar}) =>
      _pedido('POST', '/convites/$id/${aceitar ? 'aceitar' : 'recusar'}');

  static Future<List<Aviso>> avisos() async => _lista(await _pedido('GET', '/avisos'), Aviso.fromJson);
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'api.dart';

/// Um ponto no mapa, com o nome do sítio quando o conhecemos.
class Local {
  const Local(this.latitude, this.longitude, {this.nome});

  final double latitude;
  final double longitude;
  final String? nome;
}

/// Localização do utilizador (GPS) e conversão morada ⇄ coordenadas.
///
/// - GPS: pacote `geolocator` (Android, iOS e browser).
/// - Morada ⇄ coordenadas: API Nominatim do OpenStreetMap (gratuita, sem chave).
///   Regras de uso: no máximo 1 pedido por segundo e identificar a app.
abstract final class Localizacao {
  /// Centro de Lisboa — usado quando não há GPS nem localização no perfil.
  static const lisboa = Local(38.7223, -9.1393, nome: 'Lisboa');

  static const _nominatim = 'nominatim.openstreetmap.org';

  /// O browser não deixa mudar o User-Agent, por isso só o enviamos fora da web.
  static Map<String, String> get _cabecalhos => {
        'Accept-Language': 'pt-PT,pt',
        if (!kIsWeb) 'User-Agent': 'WhoPlay/1.0 (projeto escolar)',
      };

  /// Pede permissão e devolve a posição atual do dispositivo.
  /// Lança [ApiException] com uma mensagem clara se não for possível.
  static Future<Local> posicaoAtual() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const ApiException('A localização do dispositivo está desligada.');
    }

    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.denied) {
      throw const ApiException('Sem permissão para usar a localização.');
    }
    if (permissao == LocationPermission.deniedForever) {
      throw const ApiException(
        'A localização está bloqueada. Ativa-a nas definições da app ou do browser.',
      );
    }

    final posicao = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return Local(posicao.latitude, posicao.longitude);
  }

  /// Coordenadas → nome do bairro/cidade (ex.: "Moscavide").
  static Future<String?> nomeDoSitio(double latitude, double longitude) async {
    try {
      final uri = Uri.https(_nominatim, '/reverse', {
        'format': 'jsonv2',
        'lat': '$latitude',
        'lon': '$longitude',
        'zoom': '14',
      });
      final resposta = await http.get(uri, headers: _cabecalhos).timeout(const Duration(seconds: 8));
      if (resposta.statusCode != 200) return null;

      final morada = (jsonDecode(resposta.body) as Map<String, dynamic>)['address'] as Map<String, dynamic>?;
      if (morada == null) return null;
      for (final chave in ['suburb', 'neighbourhood', 'city_district', 'town', 'village', 'city', 'municipality']) {
        final valor = morada[chave];
        if (valor is String && valor.isNotEmpty) return valor;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Texto ("Padel Club Lisboa", "Parque das Nações") → coordenadas.
  /// Procura primeiro perto de [perto] e depois em Portugal inteiro.
  static Future<Local?> procurar(String texto, {Local? perto}) async {
    final consulta = texto.trim();
    if (consulta.isEmpty) return null;

    Future<Local?> pedir(Map<String, String> extra) async {
      final uri = Uri.https(_nominatim, '/search', {
        'format': 'jsonv2',
        'q': consulta,
        'countrycodes': 'pt',
        'limit': '1',
        ...extra,
      });
      final resposta = await http.get(uri, headers: _cabecalhos).timeout(const Duration(seconds: 8));
      if (resposta.statusCode != 200) return null;
      final lista = jsonDecode(resposta.body) as List;
      if (lista.isEmpty) return null;
      final r = lista.first as Map<String, dynamic>;
      return Local(
        double.parse(r['lat'] as String),
        double.parse(r['lon'] as String),
        nome: r['name'] as String?,
      );
    }

    try {
      if (perto != null) {
        // Caixa de ~20 km à volta do utilizador.
        const d = 0.18;
        final caixa = '${perto.longitude - d},${perto.latitude + d},${perto.longitude + d},${perto.latitude - d}';
        final local = await pedir({'viewbox': caixa, 'bounded': '1'});
        if (local != null) return local;
      }
      return await pedir({});
    } catch (_) {
      return null;
    }
  }

  /// Lê o GPS, descobre o nome do sítio e guarda tudo no perfil (PUT /perfil).
  static Future<Local> atualizarPerfil() async {
    final posicao = await posicaoAtual();
    final nome = await nomeDoSitio(posicao.latitude, posicao.longitude);
    await Api.atualizarPerfil({
      'latitude': _arredondar(posicao.latitude),
      'longitude': _arredondar(posicao.longitude),
      if (nome != null) 'localidade': nome,
    });
    return Local(posicao.latitude, posicao.longitude, nome: nome);
  }

  /// A base de dados guarda DECIMAL(9,6) — 6 casas decimais (~10 cm).
  static double _arredondar(double v) => double.parse(v.toStringAsFixed(6));
}

import 'package:flutter_test/flutter_test.dart';
import 'package:whoplay/data/models.dart';
import 'package:whoplay/utils/formatos.dart';

void main() {
  test('Lê um jogador tal como a API o devolve', () {
    final jogador = Jogador.fromJson({
      'id': 2,
      'nome': 'Tchali',
      'modalidade': 'Padel',
      'nivel': 'Intermédio',
      'distancia_km': 1.8,
      'compatibilidade': 93,
      'criterios': [
        {'nome': 'Mesmo desporto', 'pontos': 30, 'maximo': 30},
        {'nome': 'Nível', 'pontos': 25, 'maximo': 25},
        {'nome': 'Disponibilidade', 'pontos': 16, 'maximo': 20},
        {'nome': 'Distância', 'pontos': 12, 'maximo': 15},
        {'nome': 'Objetivo', 'pontos': 10, 'maximo': 10},
      ],
      'avaliacao': 4.7,
      'objetivo': 'Jogos amigáveis',
      'disponivel_hoje': '19:00 – 21:00',
    });

    final soma = jogador.criterios.fold<int>(0, (total, c) => total + c.pontos);
    expect(soma, jogador.compatibilidade);
    expect(km(jogador.distanciaKm), '1,8 km');
  });

  test('Formata datas como no mockup', () {
    final sabado = DateTime(2026, 10, 3, 10);
    expect(dataLonga(sabado), 'Sábado, 3 de outubro às 10:00');
    expect(dataCurta(sabado), 'Sáb, 3 Out · 10:00');
    expect(paraApi(sabado), '2026-10-03 10:00:00');
    expect(euros(8), '8 €');
    expect(horaCurta('13:30'), '13h30');
  });
}

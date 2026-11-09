/// Dados fixos para a versão estática da app (os mesmos do database/seed.sql).
library;

import 'models.dart';

abstract final class DadosExemplo {
  static const perfil = Perfil(
    id: 1,
    nome: 'Sebastião',
    email: 'sebastiao@email.com',
    localidade: 'Moscavide',
    raioKm: 5,
    objetivo: 'Jogos amigáveis',
    avaliacao: 4.8,
    modalidades: [
      ModalidadeNivel(id: 1, nome: 'Padel', nivel: 'Intermédio'),
      ModalidadeNivel(id: 2, nome: 'Ténis', nivel: 'Iniciante'),
    ],
    disponibilidade: [
      Disponibilidade(diaSemana: 1, horaInicio: '18:00', horaFim: '21:00'),
      Disponibilidade(diaSemana: 3, horaInicio: '18:00', horaFim: '22:00'),
      Disponibilidade(diaSemana: 6, horaInicio: '10:00', horaFim: '15:00'),
    ],
  );

  static const jogadores = [
    Jogador(
      id: 2,
      nome: 'Tchali',
      modalidade: 'Padel',
      nivel: 'Intermédio',
      distanciaKm: 1.8,
      compatibilidade: 93,
      criterios: [
        Criterio(nome: 'Mesmo desporto', pontos: 30, maximo: 30),
        Criterio(nome: 'Nível', pontos: 25, maximo: 25),
        Criterio(nome: 'Disponibilidade', pontos: 16, maximo: 20),
        Criterio(nome: 'Distância', pontos: 12, maximo: 15),
        Criterio(nome: 'Objetivo', pontos: 10, maximo: 10),
      ],
      avaliacao: 4.7,
      objetivo: 'Jogos amigáveis',
      disponivelHoje: '19:00 – 21:00',
    ),
    Jogador(
      id: 3,
      nome: 'Helio',
      modalidade: 'Padel',
      nivel: 'Intermédio',
      distanciaKm: 3.1,
      compatibilidade: 86,
      criterios: [
        Criterio(nome: 'Mesmo desporto', pontos: 30, maximo: 30),
        Criterio(nome: 'Nível', pontos: 25, maximo: 25),
        Criterio(nome: 'Disponibilidade', pontos: 12, maximo: 20),
        Criterio(nome: 'Distância', pontos: 9, maximo: 15),
        Criterio(nome: 'Objetivo', pontos: 10, maximo: 10),
      ],
      avaliacao: 4.5,
      objetivo: 'Jogos amigáveis',
      disponivelHoje: '18:00 – 20:00',
    ),
    Jogador(
      id: 4,
      nome: 'Cristiano',
      modalidade: 'Padel',
      nivel: 'Avançado',
      distanciaKm: 4.2,
      compatibilidade: 61,
      criterios: [
        Criterio(nome: 'Mesmo desporto', pontos: 30, maximo: 30),
        Criterio(nome: 'Nível', pontos: 12, maximo: 25),
        Criterio(nome: 'Disponibilidade', pontos: 8, maximo: 20),
        Criterio(nome: 'Distância', pontos: 7, maximo: 15),
        Criterio(nome: 'Objetivo', pontos: 4, maximo: 10),
      ],
      avaliacao: 4.2,
      objetivo: 'Jogos competitivos',
      disponivelHoje: null,
    ),
  ];

  /// Jogo de Padel no próximo sábado às 10:00.
  static Jogo get jogo {
    final hoje = DateTime.now();
    final sabado = DateTime(hoje.year, hoje.month, hoje.day + (DateTime.saturday - hoje.weekday + 7) % 7, 10);
    return Jogo(
      id: 1,
      organizador: 'Sebastião',
      modalidadeId: 1,
      modalidade: 'Padel',
      dataHora: sabado,
      localNome: 'Padel Club X',
      nivel: 'Intermédio',
      formato: 'Amigável',
      capacidade: 4,
      ocupados: 3,
      vagas: 1,
      preco: 8,
      distanciaKm: 2.4,
      participantes: const [
        Participante(id: 1, nome: 'Sebastião', organizador: true, nivel: 'Intermédio'),
        Participante(id: 3, nome: 'Helio', organizador: false, nivel: 'Intermédio'),
        Participante(id: 4, nome: 'Cristiano', organizador: false, nivel: 'Avançado'),
      ],
      euParticipo: true,
    );
  }

  static const modalidades = [
    Modalidade(id: 1, nome: 'Padel', descricao: '2 ou 4 jogadores'),
    Modalidade(id: 2, nome: 'Ténis', descricao: '2 ou 4 jogadores'),
    Modalidade(id: 3, nome: 'Futebol', descricao: '5, 7 ou 11 por equipa'),
    Modalidade(id: 4, nome: 'BJJ', descricao: 'Parceiro de treino'),
    Modalidade(id: 5, nome: 'Basquetebol', descricao: '3x3 ou 5x5'),
    Modalidade(id: 6, nome: 'Voleibol', descricao: 'Praia ou pavilhão'),
    Modalidade(id: 7, nome: 'Running', descricao: 'Companhia de corrida'),
    Modalidade(id: 8, nome: 'Ginásio', descricao: 'Parceiro de treino'),
  ];

  static DateTime get _hoje {
    final agora = DateTime.now();
    return DateTime(agora.year, agora.month, agora.day);
  }

  /// O Sebastião convidou o Tchali para hoje às 19:00 (à espera).
  static List<Convite> get convitesEnviados => [
        Convite(
          id: 1,
          estado: 'pendente',
          dataHora: _hoje.add(const Duration(hours: 19)),
          modalidade: 'Padel',
          jogadorId: 2,
          nome: 'Tchali',
          distanciaKm: 1.8,
        ),
      ];

  /// O Cristiano convidou o Sebastião para quarta às 18:00 (por responder).
  static List<Convite> get convitesRecebidos => [
        Convite(
          id: 2,
          estado: 'pendente',
          dataHora: _hoje.add(Duration(days: (DateTime.wednesday - _hoje.weekday + 7) % 7, hours: 18)),
          modalidade: 'Padel',
          jogadorId: 4,
          nome: 'Cristiano',
          distanciaKm: 4.2,
        ),
      ];

  static List<Aviso> get avisos {
    final agora = DateTime.now();
    return [
      Aviso(
        id: 1,
        titulo: 'O Helio aceitou o teu convite',
        detalhe: '',
        lida: false,
        criadoEm: agora.subtract(const Duration(minutes: 5)),
      ),
      Aviso(
        id: 2,
        titulo: 'Falta 1 jogador para o teu jogo',
        detalhe: 'Padel · sábado às 10:00',
        lida: false,
        criadoEm: agora.subtract(const Duration(hours: 1)),
      ),
      Aviso(
        id: 3,
        titulo: 'Encontrámos 3 jogadores compatíveis perto de ti',
        detalhe: '',
        lida: true,
        criadoEm: agora.subtract(const Duration(days: 1)),
      ),
    ];
  }
}

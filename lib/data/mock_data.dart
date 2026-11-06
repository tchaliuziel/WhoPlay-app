/// Dados de exemplo usados nos ecrãs (iguais ao mockup).
/// Substituir por dados reais quando houver backend.
library;

class Player {
  const Player({
    required this.name,
    required this.sport,
    required this.level,
    required this.distance,
    required this.compatibility,
    required this.availability,
    this.availableHighlight = true,
    this.showActions = true,
  });

  final String name;
  final String sport;
  final String level;
  final String distance;
  final int compatibility;
  final String availability;
  final bool availableHighlight;
  final bool showActions;

  String get initial => name.substring(0, 1);
  String get summary => '$sport · $level · $distance';
}

const nearbyPlayers = <Player>[
  Player(
    name: 'Tchali',
    sport: 'Padel',
    level: 'Intermédio',
    distance: '1,8 km',
    compatibility: 91,
    availability: 'Disponível hoje 19:00 – 21:00',
  ),
  Player(
    name: 'Helio',
    sport: 'Padel',
    level: 'Intermédio',
    distance: '3,1 km',
    compatibility: 84,
    availability: 'Disponível hoje 18:00 – 20:00',
  ),
  Player(
    name: 'Cristiano',
    sport: 'Padel',
    level: 'Avançado',
    distance: '4,2 km',
    compatibility: 72,
    availability: 'Disponível hoje 20:00 – 22:00',
    availableHighlight: false,
    showActions: false,
  ),
];

class Sport {
  const Sport(this.name, this.subtitle);

  final String name;
  final String subtitle;
}

const sports = <Sport>[
  Sport('Padel', '2 ou 4 jogadores'),
  Sport('Ténis', '2 ou 4 jogadores'),
  Sport('Futebol', '5, 7 ou 11 por equipa'),
  Sport('BJJ', 'Parceiro de treino'),
  Sport('Basquetebol', '3x3 ou 5x5'),
  Sport('Voleibol', 'Praia ou pavilhão'),
  Sport('Running', 'Companhia de corrida'),
  Sport('Ginásio', 'Parceiro de treino'),
];

/// Pontuação de compatibilidade (ecrã "Perfil do jogador").
const compatibilityBreakdown = <(String, int, int)>[
  ('Mesmo desporto', 30, 30),
  ('Nível', 25, 25),
  ('Disponibilidade', 16, 20),
  ('Distância', 12, 15),
  ('Objetivo', 8, 10),
];

class GameParticipant {
  const GameParticipant(this.name, this.detail, {this.organizer = false});

  final String name;
  final String detail;
  final bool organizer;
}

const gameParticipants = <GameParticipant>[
  GameParticipant('Sebastião', 'Organizador', organizer: true),
  GameParticipant('Helio', 'Intermédio'),
  GameParticipant('Cristiano', 'Avançado'),
];

const levels = ['Iniciante', 'Intermédio', 'Avançado'];
const formats = ['Amigável', 'Competitivo'];

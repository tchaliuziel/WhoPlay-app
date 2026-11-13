/// Modelos com os dados que chegam da API (JSON → objetos Dart).
library;

double? _duplo(Object? valor) {
  if (valor == null) return null;
  if (valor is num) return valor.toDouble();
  return double.tryParse(valor.toString());
}

int _inteiro(Object? valor, {int padrao = 0}) {
  if (valor is num) return valor.toInt();
  return int.tryParse(valor?.toString() ?? '') ?? padrao;
}

bool _booleano(Object? valor) {
  if (valor is bool) return valor;
  if (valor is num) return valor != 0;
  final texto = valor?.toString().toLowerCase();
  return texto == 'true' || texto == '1';
}

DateTime _dataHora(Object? valor) {
  if (valor is DateTime) return valor;
  return DateTime.parse(valor.toString());
}

class Modalidade {
  const Modalidade({required this.id, required this.nome, required this.descricao});

  factory Modalidade.fromJson(Map<String, dynamic> json) => Modalidade(
        id: _inteiro(json['id']),
        nome: json['nome'] as String,
        descricao: json['descricao'] as String? ?? '',
      );

  final int id;
  final String nome;
  final String descricao;
}

class ModalidadeNivel {
  const ModalidadeNivel({required this.id, required this.nome, required this.nivel});

  factory ModalidadeNivel.fromJson(Map<String, dynamic> json) => ModalidadeNivel(
        id: _inteiro(json['id']),
        nome: json['nome'] as String,
        nivel: json['nivel'] as String,
      );

  final int id;
  final String nome;
  final String nivel;
}

class Disponibilidade {
  const Disponibilidade({required this.diaSemana, required this.horaInicio, required this.horaFim});

  factory Disponibilidade.fromJson(Map<String, dynamic> json) => Disponibilidade(
        diaSemana: _inteiro(json['dia_semana']),
        horaInicio: json['hora_inicio'] as String,
        horaFim: json['hora_fim'] as String,
      );

  /// 1 = segunda … 7 = domingo.
  final int diaSemana;
  final String horaInicio;
  final String horaFim;
}

class Perfil {
  const Perfil({
    required this.id,
    required this.nome,
    required this.email,
    required this.localidade,
    required this.raioKm,
    required this.objetivo,
    required this.avaliacao,
    required this.modalidades,
    required this.disponibilidade,
    this.latitude,
    this.longitude,
  });

  factory Perfil.fromJson(Map<String, dynamic> json) => Perfil(
        id: _inteiro(json['id']),
        nome: json['nome'] as String,
        email: json['email'] as String,
        localidade: json['localidade'] as String?,
        raioKm: _inteiro(json['raio_km']),
        objetivo: json['objetivo'] as String? ?? '',
        avaliacao: _duplo(json['avaliacao']),
        modalidades: [
          for (final item in json['modalidades'] as List? ?? const [])
            ModalidadeNivel.fromJson(Map<String, dynamic>.from(item as Map)),
        ],
        disponibilidade: [
          for (final item in json['disponibilidade'] as List? ?? const [])
            Disponibilidade.fromJson(Map<String, dynamic>.from(item as Map)),
        ],
        latitude: _duplo(json['latitude']),
        longitude: _duplo(json['longitude']),
      );

  final int id;
  final String nome;
  final String email;
  final String? localidade;
  final int raioKm;
  final String objetivo;
  final double? avaliacao;
  final List<ModalidadeNivel> modalidades;
  final List<Disponibilidade> disponibilidade;

  /// Posição guardada no perfil (null enquanto não for definida).
  final double? latitude;
  final double? longitude;
}

class Criterio {
  const Criterio({required this.nome, required this.pontos, required this.maximo});

  factory Criterio.fromJson(Map<String, dynamic> json) => Criterio(
        nome: json['nome'] as String,
        pontos: _inteiro(json['pontos']),
        maximo: _inteiro(json['maximo']),
      );

  final String nome;
  final int pontos;
  final int maximo;
}

class Jogador {
  const Jogador({
    required this.id,
    required this.nome,
    required this.modalidade,
    required this.nivel,
    required this.distanciaKm,
    required this.compatibilidade,
    required this.criterios,
    required this.avaliacao,
    required this.objetivo,
    required this.disponivelHoje,
    this.latitude,
    this.longitude,
  });

  factory Jogador.fromJson(Map<String, dynamic> json) => Jogador(
        id: _inteiro(json['id']),
        nome: json['nome'] as String,
        modalidade: json['modalidade'] as String,
        nivel: json['nivel'] as String,
        distanciaKm: _duplo(json['distancia_km']) ?? 0,
        compatibilidade: _inteiro(json['compatibilidade']),
        criterios: [
          for (final item in json['criterios'] as List? ?? const [])
            Criterio.fromJson(Map<String, dynamic>.from(item as Map)),
        ],
        avaliacao: _duplo(json['avaliacao']),
        objetivo: json['objetivo'] as String? ?? '',
        disponivelHoje: json['disponivel_hoje'] as String?,
        latitude: _duplo(json['latitude']),
        longitude: _duplo(json['longitude']),
      );

  final int id;
  final String nome;
  final String modalidade;
  final String nivel;
  final double distanciaKm;
  final int compatibilidade;
  final List<Criterio> criterios;
  final double? avaliacao;
  final String objetivo;
  final String? disponivelHoje;
  final double? latitude;
  final double? longitude;

  String get inicial => nome.isNotEmpty ? nome.substring(0, 1) : '?';
}

class Participante {
  const Participante({
    required this.id,
    required this.nome,
    required this.organizador,
    required this.nivel,
  });

  factory Participante.fromJson(Map<String, dynamic> json) => Participante(
        id: _inteiro(json['id']),
        nome: json['nome'] as String,
        organizador: _booleano(json['organizador']),
        nivel: json['nivel'] as String?,
      );

  final int id;
  final String nome;
  final bool organizador;
  final String? nivel;
}

class Jogo {
  const Jogo({
    required this.id,
    required this.organizador,
    required this.modalidadeId,
    required this.modalidade,
    required this.dataHora,
    required this.localNome,
    required this.nivel,
    required this.formato,
    required this.capacidade,
    required this.ocupados,
    required this.vagas,
    required this.preco,
    required this.distanciaKm,
    this.participantes = const [],
    this.euParticipo = false,
    this.latitude,
    this.longitude,
  });

  factory Jogo.fromJson(Map<String, dynamic> json) => Jogo(
        id: _inteiro(json['id']),
        organizador: json['organizador'] as String? ?? '',
        modalidadeId: _inteiro(json['modalidade_id']),
        modalidade: json['modalidade'] as String? ?? '',
        dataHora: _dataHora(json['data_hora']),
        localNome: json['local_nome'] as String? ?? '',
        nivel: json['nivel'] as String? ?? '',
        formato: json['formato'] as String? ?? 'Amigável',
        capacidade: _inteiro(json['capacidade']),
        ocupados: _inteiro(json['ocupados']),
        vagas: _inteiro(json['vagas']),
        preco: _duplo(json['preco']) ?? 0,
        distanciaKm: _duplo(json['distancia_km']),
        participantes: [
          for (final item in json['participantes'] as List? ?? const [])
            Participante.fromJson(Map<String, dynamic>.from(item as Map)),
        ],
        euParticipo: _booleano(json['eu_participo']),
        latitude: _duplo(json['latitude']),
        longitude: _duplo(json['longitude']),
      );

  final int id;
  final String organizador;
  final int modalidadeId;
  final String modalidade;
  final DateTime dataHora;
  final String localNome;
  final String nivel;
  final String formato;
  final int capacidade;
  final int ocupados;
  final int vagas;
  final double preco;
  final double? distanciaKm;
  final List<Participante> participantes;
  final bool euParticipo;
  final double? latitude;
  final double? longitude;
}

class Convite {
  const Convite({
    required this.id,
    required this.estado,
    required this.dataHora,
    required this.modalidade,
    required this.jogadorId,
    required this.nome,
    required this.distanciaKm,
  });

  factory Convite.fromJson(Map<String, dynamic> json) => Convite(
        id: _inteiro(json['id']),
        estado: json['estado'] as String,
        dataHora: _dataHora(json['data_hora']),
        modalidade: json['modalidade'] as String,
        jogadorId: _inteiro(json['jogador_id']),
        nome: json['nome'] as String,
        distanciaKm: _duplo(json['distancia_km']),
      );

  final int id;
  final String estado;
  final DateTime dataHora;
  final String modalidade;
  final int jogadorId;
  final String nome;
  final double? distanciaKm;
}

class Aviso {
  const Aviso({
    required this.id,
    required this.titulo,
    required this.detalhe,
    required this.lida,
    required this.criadoEm,
  });

  factory Aviso.fromJson(Map<String, dynamic> json) => Aviso(
        id: _inteiro(json['id']),
        titulo: json['titulo'] as String,
        detalhe: json['detalhe'] as String? ?? '',
        lida: _booleano(json['lida']),
        criadoEm: _dataHora(json['criado_em']),
      );

  final int id;
  final String titulo;
  final String detalhe;
  final bool lida;
  final DateTime criadoEm;
}

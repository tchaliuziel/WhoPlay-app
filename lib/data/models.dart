/// Modelos com os dados que chegam da API (JSON → objetos Dart).
library;

double? _duplo(Object? valor) => valor == null ? null : (valor as num).toDouble();

class Modalidade {
  const Modalidade({required this.id, required this.nome, required this.descricao});

  factory Modalidade.fromJson(Map<String, dynamic> json) => Modalidade(
        id: json['id'] as int,
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
        id: json['id'] as int,
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
        diaSemana: json['dia_semana'] as int,
        horaInicio: json['hora_inicio'] as String,
        horaFim: json['hora_fim'] as String,
      );

  /// 1 = segunda … 7 = domingo
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
  });

  factory Perfil.fromJson(Map<String, dynamic> json) => Perfil(
        id: json['id'] as int,
        nome: json['nome'] as String,
        email: json['email'] as String,
        localidade: json['localidade'] as String?,
        raioKm: json['raio_km'] as int,
        objetivo: json['objetivo'] as String,
        avaliacao: _duplo(json['avaliacao']),
        modalidades: [
          for (final m in json['modalidades'] as List) ModalidadeNivel.fromJson(m as Map<String, dynamic>),
        ],
        disponibilidade: [
          for (final d in json['disponibilidade'] as List) Disponibilidade.fromJson(d as Map<String, dynamic>),
        ],
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
}

class Criterio {
  const Criterio({required this.nome, required this.pontos, required this.maximo});

  factory Criterio.fromJson(Map<String, dynamic> json) => Criterio(
        nome: json['nome'] as String,
        pontos: json['pontos'] as int,
        maximo: json['maximo'] as int,
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
  });

  factory Jogador.fromJson(Map<String, dynamic> json) => Jogador(
        id: json['id'] as int,
        nome: json['nome'] as String,
        modalidade: json['modalidade'] as String,
        nivel: json['nivel'] as String,
        distanciaKm: _duplo(json['distancia_km'])!,
        compatibilidade: json['compatibilidade'] as int,
        criterios: [
          for (final c in json['criterios'] as List) Criterio.fromJson(c as Map<String, dynamic>),
        ],
        avaliacao: _duplo(json['avaliacao']),
        objetivo: json['objetivo'] as String,
        disponivelHoje: json['disponivel_hoje'] as String?,
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

  /// Ex.: "19:00 – 21:00", ou null se hoje não está disponível.
  final String? disponivelHoje;

  String get inicial => nome.substring(0, 1);
}

class Participante {
  const Participante({required this.id, required this.nome, required this.organizador, required this.nivel});

  factory Participante.fromJson(Map<String, dynamic> json) => Participante(
        id: json['id'] as int,
        nome: json['nome'] as String,
        organizador: json['organizador'] as bool,
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
  });

  factory Jogo.fromJson(Map<String, dynamic> json) => Jogo(
        id: json['id'] as int,
        organizador: json['organizador'] as String,
        modalidadeId: json['modalidade_id'] as int,
        modalidade: json['modalidade'] as String,
        dataHora: DateTime.parse(json['data_hora'] as String),
        localNome: json['local_nome'] as String,
        nivel: json['nivel'] as String,
        formato: json['formato'] as String,
        capacidade: json['capacidade'] as int,
        ocupados: json['ocupados'] as int,
        vagas: json['vagas'] as int,
        preco: _duplo(json['preco'])!,
        distanciaKm: _duplo(json['distancia_km']),
        participantes: [
          for (final p in json['participantes'] as List? ?? const [])
            Participante.fromJson(p as Map<String, dynamic>),
        ],
        euParticipo: json['eu_participo'] as bool? ?? false,
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
        id: json['id'] as int,
        estado: json['estado'] as String,
        dataHora: DateTime.parse(json['data_hora'] as String),
        modalidade: json['modalidade'] as String,
        jogadorId: json['jogador_id'] as int,
        nome: json['nome'] as String,
        distanciaKm: _duplo(json['distancia_km']),
      );

  final int id;
  final String estado;
  final DateTime dataHora;
  final String modalidade;

  /// A outra pessoa: o destinatário (enviados) ou o remetente (recebidos).
  final int jogadorId;
  final String nome;
  final double? distanciaKm;
}

class Aviso {
  const Aviso({required this.id, required this.titulo, required this.detalhe, required this.lida, required this.criadoEm});

  factory Aviso.fromJson(Map<String, dynamic> json) => Aviso(
        id: json['id'] as int,
        titulo: json['titulo'] as String,
        detalhe: json['detalhe'] as String? ?? '',
        lida: json['lida'] as bool,
        criadoEm: DateTime.parse(json['criado_em'] as String),
      );

  final int id;
  final String titulo;
  final String detalhe;
  final bool lida;
  final DateTime criadoEm;
}

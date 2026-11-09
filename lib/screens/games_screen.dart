
import 'package:flutter/material.dart';

import '../data/models.dart';
import '../services/api.dart';
import '../theme/app_colors.dart';
import 'game_detail_screen.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late Future<List<Jogo>> _jogosFuture;
  late Future<List<dynamic>> _historicoFuture;
  late Future<Map<String, dynamic>> _estatisticasFuture;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);
    _carregarDados();
  }

  void _carregarDados() {
    _jogosFuture = Api.jogos();
    _historicoFuture = Api.historicoJogos();
    _estatisticasFuture = Api.estatisticasJogos();
  }

  Future<void> _recarregar() async {
    setState(_carregarDados);

    try {
      await Future.wait([
        _jogosFuture,
        _historicoFuture,
        _estatisticasFuture,
      ]);
    } catch (_) {}
  }

  void _abrirJogo(Jogo jogo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameDetailScreen(jogoId: jogo.id),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cabecalho(),
            const SizedBox(height: 20),
            _tabs(),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _disponiveisView(),
                  _historicoView(),
                  _estatisticasView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cabecalho() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Os meus jogos',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF171923),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Descobre jogos e acompanha a tua atividade.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _recarregar,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFEDEFF3),
          borderRadius: BorderRadius.circular(13),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          tabs: const [
            Tab(text: 'Disponíveis'),
            Tab(text: 'Histórico'),
            Tab(text: 'Estatísticas'),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DISPONÍVEIS
  // ============================================================

  Widget _disponiveisView() {
    return FutureBuilder<List<Jogo>>(
      future: _jogosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _erroView(
            'Não foi possível carregar os jogos.',
          );
        }

        final jogos = snapshot.data ?? [];

        if (jogos.isEmpty) {
          return _vazioView(
            Icons.sports_basketball_rounded,
            'Ainda não existem jogos',
            'Os jogos disponíveis aparecerão aqui.',
          );
        }

        return RefreshIndicator(
          onRefresh: _recarregar,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 25),
            itemCount: jogos.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final jogo = jogos[index];

              return _JogoCard(
                jogo: jogo,
                onTap: () => _abrirJogo(jogo),
              );
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // HISTÓRICO
  // ============================================================

  Widget _historicoView() {
    return FutureBuilder<List<dynamic>>(
      future: _historicoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _erroView(
            'Não foi possível carregar o histórico.',
          );
        }

        final historico = snapshot.data ?? [];

        if (historico.isEmpty) {
          return _vazioView(
            Icons.history_rounded,
            'Sem histórico de jogos',
            'Os jogos em que participares ou que organizares aparecerão aqui.',
          );
        }

        return RefreshIndicator(
          onRefresh: _recarregar,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 25),
            itemCount: historico.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _converterMapa(historico[index]);

              return _HistoricoCard(
                dados: item,
                onPresencas: () {
                  final id = _converterInt(
                    item['id'] ?? item['jogo_id'],
                  );

                  if (id != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PresencasScreen(jogoId: id),
                      ),
                    );
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // ESTATÍSTICAS
  // ============================================================

  Widget _estatisticasView() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _estatisticasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _erroView(
            'Não foi possível carregar as estatísticas.',
          );
        }

        final dados = snapshot.data ?? {};

        final jogos = _converterInt(
              dados['jogos_realizados'] ??
                  dados['total_jogos'] ??
                  dados['realizados'],
            ) ??
            0;

        final participacoes = _converterInt(
              dados['total_participacoes'] ??
                  dados['participacoes'],
            ) ??
            0;

        final presencas = _converterInt(
              dados['total_presencas'] ??
                  dados['presencas'],
            ) ??
            0;

        final taxa = _converterDouble(
              dados['taxa_presenca'] ??
                  dados['percentagem_presenca'],
            ) ??
            0;

        return RefreshIndicator(
          onRefresh: _recarregar,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 25),
            children: [
              const Text(
                'O teu desempenho',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF171923),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Resumo da tua atividade no WhoPlay.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _EstatisticaCard(
                      titulo: 'Jogos realizados',
                      valor: '$jogos',
                      icon: Icons.sports_score_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _EstatisticaCard(
                      titulo: 'Participações',
                      valor: '$participacoes',
                      icon: Icons.groups_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _EstatisticaCard(
                      titulo: 'Presenças',
                      valor: '$presencas',
                      icon: Icons.verified_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _EstatisticaCard(
                      titulo: 'Taxa de presença',
                      valor: '${taxa.toStringAsFixed(0)}%',
                      icon: Icons.trending_up_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              _cartaoPresenca(taxa),
            ],
          ),
        );
      },
    );
  }

  Widget _cartaoPresenca(double taxa) {
    final progresso = (taxa / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Taxa de presença',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF171923),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Acompanha a tua assiduidade nos jogos.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 10,
              backgroundColor: const Color(0xFFEDEFF3),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${taxa.toStringAsFixed(1)}% de presença',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ESTADOS
  // ============================================================

  Widget _vazioView(
    IconData icon,
    String titulo,
    String descricao,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 55,
              color: AppColors.muted,
            ),
            const SizedBox(height: 18),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF171923),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              descricao,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _erroView(String mensagem) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 45,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 15),
            Text(
              mensagem,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            OutlinedButton.icon(
              onPressed: _recarregar,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// CARTÃO DE JOGO
// ================================================================

class _JogoCard extends StatelessWidget {
  final Jogo jogo;
  final VoidCallback onTap;

  const _JogoCard({
    required this.jogo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      jogo.modalidade,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF171923),
                      ),
                    ),
                  ),
                  _TagEstado(
                    texto: jogo.euParticipo
                        ? 'Inscrito'
                        : 'Disponível',
                    cor: jogo.euParticipo
                        ? Colors.green
                        : AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _LinhaInfo(
                icon: Icons.calendar_today_rounded,
                texto: _formatarData(jogo.dataHora),
              ),
              const SizedBox(height: 9),
              _LinhaInfo(
                icon: Icons.location_on_outlined,
                texto: jogo.localNome,
              ),
              const SizedBox(height: 9),
              _LinhaInfo(
                icon: Icons.groups_outlined,
                texto:
                    '${jogo.ocupados}/${jogo.capacidade} jogadores',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _TagInfo(texto: jogo.nivel),
                  const SizedBox(width: 7),
                  _TagInfo(texto: jogo.formato),
                  const Spacer(),
                  Text(
                    '${jogo.vagas} vagas',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: const Text(
                    'Ver detalhes',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// CARTÃO DE HISTÓRICO
// ================================================================

class _HistoricoCard extends StatelessWidget {
  final Map<String, dynamic> dados;
  final VoidCallback onPresencas;

  const _HistoricoCard({
    required this.dados,
    required this.onPresencas,
  });

  @override
  Widget build(BuildContext context) {
    final modalidade =
        dados['modalidade']?.toString() ?? 'Jogo';

    final local =
        dados['local_nome']?.toString() ?? 'Local não indicado';

    final data = dados['data_hora'];

    final papel = dados['papel']?.toString() ??
        dados['tipo_participacao']?.toString() ??
        'Participante';

    final presente = dados['checkin_em'] != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  modalidade,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF171923),
                  ),
                ),
              ),
              _TagEstado(
                texto: presente ? 'Presença confirmada' : 'Por confirmar',
                cor: presente ? Colors.green : Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 13),
          _LinhaInfo(
            icon: Icons.calendar_today_rounded,
            texto: _formatarData(data),
          ),
          const SizedBox(height: 8),
          _LinhaInfo(
            icon: Icons.location_on_outlined,
            texto: local,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _TagInfo(texto: papel),
              const Spacer(),
              TextButton(
                onPressed: onPresencas,
                child: const Text('Ver presenças'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ================================================================
// ESTATÍSTICAS
// ================================================================

class _EstatisticaCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icon;

  const _EstatisticaCard({
    required this.titulo,
    required this.valor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 23,
            color: AppColors.primary,
          ),
          const SizedBox(height: 15),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: Color(0xFF171923),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// PRESENÇAS
// ================================================================

class PresencasScreen extends StatefulWidget {
  final int jogoId;

  const PresencasScreen({
    super.key,
    required this.jogoId,
  });

  @override
  State<PresencasScreen> createState() => _PresencasScreenState();
}

class _PresencasScreenState extends State<PresencasScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = Api.presencasJogo(widget.jogoId);
  }

  Future<void> _atualizar() async {
    setState(() {
      _future = Api.presencasJogo(widget.jogoId);
    });

    try {
      await _future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Presenças',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.white,
        foregroundColor: const Color(0xFF171923),
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Não foi possível carregar as presenças.',
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _atualizar,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          final dados = snapshot.data ?? {};

          final lista =
              dados['participantes'] ?? dados['presencas'] ?? [];

          final participantes =
              lista is List ? lista : [];

          if (participantes.isEmpty) {
            return const Center(
              child: Text('Ainda não existem participantes.'),
            );
          }

          return RefreshIndicator(
            onRefresh: _atualizar,
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: participantes.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final pessoa =
                    _converterMapa(participantes[index]);

                final nome =
                    pessoa['nome']?.toString() ?? 'Participante';

                final checkin = pessoa['checkin_em'];
                final estado = pessoa['estado']?.toString();

                final presente = checkin != null ||
                    estado == 'presente' ||
                    estado == 'confirmado';

                final organizador =
                    pessoa['organizador'] == true;

                return Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            const Color(0xFFEDEFF3),
                        child: Text(
                          nome.isNotEmpty
                              ? nome[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              nome,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF171923),
                              ),
                            ),
                            if (organizador)
                              Text(
                                'Organizador',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      _TagEstado(
                        texto: presente ? 'Presente' : 'Por confirmar',
                        cor: presente ? Colors.green : Colors.orange,
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ================================================================
// COMPONENTES AUXILIARES
// ================================================================

class _LinhaInfo extends StatelessWidget {
  final IconData icon;
  final String texto;

  const _LinhaInfo({
    required this.icon,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.muted,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.muted,
            ),
          ),
        ),
      ],
    );
  }
}

class _TagInfo extends StatelessWidget {
  final String texto;

  const _TagInfo({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF555B69),
        ),
      ),
    );
  }
}

class _TagEstado extends StatelessWidget {
  final String texto;
  final Color cor;

  const _TagEstado({
    required this.texto,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: cor,
        ),
      ),
    );
  }
}

// ================================================================
// FUNÇÕES AUXILIARES
// ================================================================

Map<String, dynamic> _converterMapa(dynamic valor) {
  if (valor is Map<String, dynamic>) {
    return valor;
  }

  if (valor is Map) {
    return Map<String, dynamic>.from(valor);
  }

  return {};
}

int? _converterInt(dynamic valor) {
  if (valor is int) return valor;
  if (valor is num) return valor.toInt();

  return int.tryParse(valor?.toString() ?? '');
}

double? _converterDouble(dynamic valor) {
  if (valor is num) return valor.toDouble();

  return double.tryParse(valor?.toString() ?? '');
}

String _formatarData(dynamic valor) {
  if (valor == null) return 'Data não indicada';

  final data = DateTime.tryParse(valor.toString());

  if (data == null) return valor.toString();

  final local = data.toLocal();

  final dia = local.day.toString().padLeft(2, '0');
  final mes = local.month.toString().padLeft(2, '0');
  final ano = local.year.toString();

  final hora = local.hour.toString().padLeft(2, '0');
  final minuto = local.minute.toString().padLeft(2, '0');

  return '$dia/$mes/$ano às $hora:$minuto';
}

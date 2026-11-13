import 'package:flutter/material.dart';

import '../data/models.dart';
import '../services/api.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatos.dart';
import '../widgets/app_icons.dart';
import '../widgets/async_view.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import 'game_detail_screen.dart';

enum _Aba { disponiveis, historico, estatisticas }

/// Jogos — disponíveis, histórico e estatísticas, no estilo dos mockups
/// (pílulas de filtro, cartões brancos de 18px, botões de 44px).
class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  _Aba _aba = _Aba.disponiveis;

  late Future<List<Jogo>> _jogos;
  late Future<List<dynamic>> _historico;
  late Future<Map<String, dynamic>> _estatisticas;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    _jogos = Api.jogos();
    _historico = Api.historicoJogos();
    _estatisticas = Api.estatisticasJogos();
  }

  Future<void> _recarregar() async {
    setState(_carregar);
    try {
      await Future.wait([_jogos, _historico, _estatisticas]);
    } catch (_) {}
  }

  void _abrirJogo(int id) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => GameDetailScreen(jogoId: id)))
        .then((_) {
      if (mounted) _recarregar();
    });
  }

  void _abrirPresencas(int id) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PresencasScreen(jogoId: id)));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _recarregar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, topInset(context, 52), 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(child: ScreenTitle('Jogos')),
                CircleIconButton(
                  semanticLabel: 'Atualizar',
                  onPressed: _recarregar,
                  child: const SvgIcon(AppIcon.refresh, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  _pilula('Disponíveis', _Aba.disponiveis),
                  const SizedBox(width: 8),
                  _pilula('Histórico', _Aba.historico),
                  const SizedBox(width: 8),
                  _pilula('Estatísticas', _Aba.estatisticas),
                ],
              ),
            ),
            const SizedBox(height: 14),
            switch (_aba) {
              _Aba.disponiveis => _disponiveis(),
              _Aba.historico => _historicoView(),
              _Aba.estatisticas => _estatisticasView(),
            },
          ],
        ),
      ),
    );
  }

  Widget _pilula(String label, _Aba aba) => PillChip(
        label: label,
        selected: _aba == aba,
        onTap: () => setState(() => _aba = aba),
      );

  // ---------------------------------------------------------------- Disponíveis

  Widget _disponiveis() {
    return AsyncView<List<Jogo>>(
      future: _jogos,
      onRetry: _recarregar,
      builder: (context, jogos) {
        if (jogos.isEmpty) {
          return const _Vazio(
            icon: AppIcon.ball,
            titulo: 'Ainda não há jogos',
            texto: 'Os jogos abertos perto de ti aparecem aqui.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              jogos.length == 1 ? '1 jogo aberto' : '${jogos.length} jogos abertos',
              style: AppText.body(14, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            for (final jogo in jogos) ...[
              _JogoCard(jogo: jogo, onTap: () => _abrirJogo(jogo.id)),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------- Histórico

  Widget _historicoView() {
    return AsyncView<List<dynamic>>(
      future: _historico,
      onRetry: _recarregar,
      builder: (context, historico) {
        if (historico.isEmpty) {
          return const _Vazio(
            icon: AppIcon.history,
            titulo: 'Sem histórico',
            texto: 'Os jogos em que participas ou que organizas aparecem aqui.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final item in historico) ...[
              Builder(builder: (context) {
                final dados = _mapa(item);
                final id = _inteiro(dados['id'] ?? dados['jogo_id']);
                return _HistoricoCard(
                  dados: dados,
                  onPresencas: id == null ? null : () => _abrirPresencas(id),
                );
              }),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------- Estatísticas

  Widget _estatisticasView() {
    return AsyncView<Map<String, dynamic>>(
      future: _estatisticas,
      onRetry: _recarregar,
      builder: (context, dados) {
        final jogos = _inteiro(dados['jogos_realizados'] ?? dados['total_jogos'] ?? dados['realizados']) ?? 0;
        final participacoes = _inteiro(dados['total_participacoes'] ?? dados['participacoes']) ?? 0;
        final presencas = _inteiro(dados['total_presencas'] ?? dados['presencas']) ?? 0;
        final taxa = _duplo(dados['taxa_presenca'] ?? dados['percentagem_presenca']) ?? 0;

        return Section(
          title: 'O teu desempenho',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: _Estatistica(icon: AppIcon.trophy, valor: '$jogos', titulo: 'Jogos realizados')),
                  const SizedBox(width: 12),
                  Expanded(child: _Estatistica(icon: AppIcon.users, valor: '$participacoes', titulo: 'Participações')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _Estatistica(icon: AppIcon.checkCircle, valor: '$presencas', titulo: 'Presenças')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Estatistica(
                      icon: AppIcon.trendUp,
                      valor: '${taxa.toStringAsFixed(0)}%',
                      titulo: 'Taxa de presença',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SurfaceCard(
                radius: 18,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Assiduidade', style: AppText.body(16, weight: FontWeight.w700)),
                        Tag(
                          '${taxa.toStringAsFixed(0)}%',
                          background: taxa >= 50 ? AppColors.lime : AppColors.chip,
                          display: true,
                          fontSize: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ThinBar(value: taxa / 100, color: AppColors.primary, track: AppColors.track),
                    const SizedBox(height: 10),
                    Text(
                      'Percentagem de jogos em que fizeste check-in.',
                      style: AppText.body(14, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==================================================================== Cartões

class _JogoCard extends StatelessWidget {
  const _JogoCard({required this.jogo, required this.onTap});

  final Jogo jogo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completo = jogo.vagas <= 0;
    final vagas = jogo.vagas == 1 ? '1 vaga' : '${jogo.vagas} vagas';
    final detalhe = [
      jogo.nivel,
      jogo.formato,
      if (jogo.distanciaKm != null) km(jogo.distanciaKm!),
    ].where((t) => t.isNotEmpty).join(' · ');

    return SurfaceCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(jogo.modalidade, style: AppText.body(17, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(detalhe, style: AppText.body(14, color: AppColors.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Tag(
                jogo.euParticipo ? 'Inscrito' : (completo ? 'Completo' : vagas),
                background: jogo.euParticipo || !completo ? AppColors.lime : AppColors.chip,
                fontSize: 13,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Info(icon: AppIcon.clock, texto: dataMedia(jogo.dataHora), destaque: true),
          const SizedBox(height: 6),
          _Info(icon: AppIcon.pin, texto: jogo.localNome),
          const SizedBox(height: 6),
          _Info(
            icon: AppIcon.users,
            texto: '${jogo.ocupados} de ${jogo.capacidade} jogadores'
                '${jogo.preco > 0 ? ' · ${euros(jogo.preco)} por pessoa' : ''}',
          ),
          const SizedBox(height: 12),
          AppButton.small(label: 'Ver jogo', onPressed: onTap),
        ],
      ),
    );
  }
}

class _HistoricoCard extends StatelessWidget {
  const _HistoricoCard({required this.dados, required this.onPresencas});

  final Map<String, dynamic> dados;
  final VoidCallback? onPresencas;

  @override
  Widget build(BuildContext context) {
    final modalidade = dados['modalidade']?.toString() ?? 'Jogo';
    final local = dados['local_nome']?.toString() ?? 'Local não indicado';
    final data = DateTime.tryParse(dados['data_hora']?.toString() ?? '')?.toLocal();
    final papelBruto = (dados['papel'] ?? dados['tipo_participacao'])?.toString() ?? 'participante';
    final papel = papelBruto.isEmpty ? '' : papelBruto[0].toUpperCase() + papelBruto.substring(1);
    final presente = dados['checkin_em'] != null;

    return SurfaceCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(modalidade, style: AppText.body(17, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(papel, style: AppText.body(14, color: AppColors.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Tag(
                presente ? 'Presente' : 'Por confirmar',
                background: presente ? AppColors.lime : AppColors.chip,
                fontSize: 13,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Info(icon: AppIcon.calendar, texto: data == null ? 'Data não indicada' : dataMedia(data)),
          const SizedBox(height: 6),
          _Info(icon: AppIcon.pin, texto: local),
          const SizedBox(height: 12),
          AppButton.small(label: 'Ver presenças', outlined: true, onPressed: onPresencas),
        ],
      ),
    );
  }
}

class _Estatistica extends StatelessWidget {
  const _Estatistica({required this.icon, required this.valor, required this.titulo});

  final AppIcon icon;
  final String valor;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.chip, borderRadius: BorderRadius.circular(10)),
            child: SvgIcon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(valor, style: AppText.display(28, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(titulo, style: AppText.body(14, color: AppColors.muted)),
        ],
      ),
    );
  }
}

/// Linha com ícone de 16px, como "Disponível hoje 19:00 – 21:00" no mockup.
class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.texto, this.destaque = false});

  final AppIcon icon;
  final String texto;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final cor = destaque ? AppColors.primary : AppColors.muted;
    return Row(
      children: [
        SvgIcon(icon, size: 16, color: cor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: AppText.body(14, weight: destaque ? FontWeight.w600 : FontWeight.w400, color: cor),
          ),
        ),
      ],
    );
  }
}

class _Vazio extends StatelessWidget {
  const _Vazio({required this.icon, required this.titulo, required this.texto});

  final AppIcon icon;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          SvgIcon(icon, size: 48, color: AppColors.muted, strokeWidth: 1.6),
          const SizedBox(height: 14),
          Text(titulo, textAlign: TextAlign.center, style: AppText.body(17, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(texto, textAlign: TextAlign.center, style: AppText.body(14, color: AppColors.muted)),
        ],
      ),
    );
  }
}

// ==================================================================== Presenças

class PresencasScreen extends StatefulWidget {
  const PresencasScreen({super.key, required this.jogoId});

  final int jogoId;

  @override
  State<PresencasScreen> createState() => _PresencasScreenState();
}

class _PresencasScreenState extends State<PresencasScreen> {
  late Future<Map<String, dynamic>> _future = Api.presencasJogo(widget.jogoId);

  Future<void> _atualizar() async {
    setState(() => _future = Api.presencasJogo(widget.jogoId));
    try {
      await _future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: AppTheme.darkStatusIcons,
      child: Scaffold(
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _atualizar,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, topInset(context, 48), 20, 28 + bottomInset(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleIconButton(
                      semanticLabel: 'Voltar',
                      onPressed: () => Navigator.of(context).pop(),
                      child: const SvgIcon(AppIcon.back),
                    ),
                    const SizedBox(width: 12),
                    const ScreenTitle('Presenças'),
                  ],
                ),
                const SizedBox(height: 18),
                AsyncView<Map<String, dynamic>>(
                  future: _future,
                  onRetry: _atualizar,
                  builder: (context, dados) {
                    final lista = dados['participantes'] ?? dados['presencas'] ?? [];
                    final pessoas = lista is List ? lista.map(_mapa).toList() : <Map<String, dynamic>>[];
                    if (pessoas.isEmpty) {
                      return const EmptyText('Ainda não existem participantes.');
                    }
                    final confirmados = pessoas.where(_presente).length;
                    return Section(
                      title: 'Quem vai · $confirmados de ${pessoas.length} confirmados',
                      child: ListCard(
                        children: [
                          for (final p in pessoas) _LinhaPresenca(pessoa: p),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

bool _presente(Map<String, dynamic> p) =>
    p['checkin_em'] != null || p['estado'] == 'presente' || p['estado'] == 'confirmado';

class _LinhaPresenca extends StatelessWidget {
  const _LinhaPresenca({required this.pessoa});

  final Map<String, dynamic> pessoa;

  @override
  Widget build(BuildContext context) {
    final nome = pessoa['nome']?.toString() ?? 'Participante';
    final organizador = pessoa['organizador'] == true || pessoa['organizador'] == 1;
    final presente = _presente(pessoa);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Avatar(nome.isNotEmpty ? nome[0].toUpperCase() : '?', size: 40, fontSize: 17),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nome, style: AppText.body(16, weight: FontWeight.w700)),
                if (organizador) Text('Organizador', style: AppText.body(13, color: AppColors.muted)),
              ],
            ),
          ),
          Tag(
            presente ? 'Presente' : 'Por confirmar',
            background: presente ? AppColors.lime : AppColors.chip,
            fontSize: 13,
          ),
        ],
      ),
    );
  }
}

// ==================================================================== Auxiliares

Map<String, dynamic> _mapa(dynamic valor) {
  if (valor is Map<String, dynamic>) return valor;
  if (valor is Map) return Map<String, dynamic>.from(valor);
  return {};
}

int? _inteiro(dynamic valor) {
  if (valor is num) return valor.toInt();
  return int.tryParse(valor?.toString() ?? '');
}

double? _duplo(dynamic valor) {
  if (valor is num) return valor.toDouble();
  return double.tryParse(valor?.toString() ?? '');
}

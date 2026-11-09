
import 'package:flutter/material.dart';

import '../services/api.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatos.dart';
import '../widgets/async_view.dart';
import '../widgets/common.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filtro = 'todos';

  late Future<List<dynamic>> _historico = Api.historicoJogos();

  void _alterarFiltro(String filtro) {
    setState(() {
      _filtro = filtro;
      _historico = Api.historicoJogos(filtro: filtro);
    });
  }

  Future<void> _recarregar() async {
    final pedido = Api.historicoJogos(filtro: _filtro);

    setState(() {
      _historico = pedido;
    });

    await pedido;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _recarregar,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20,
          topInset(context, 52),
          20,
          24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ScreenTitle('Histórico'),
            const SizedBox(height: 8),
            Text(
              'Consulta os jogos em que participaste ou que organizaste.',
              style: AppText.body(14, color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              children: [
                _filtroChip('Todos', 'todos'),
                _filtroChip('Organizados', 'organizados'),
                _filtroChip('Participados', 'participados'),
              ],
            ),
            const SizedBox(height: 20),
            AsyncView<List<dynamic>>(
              future: _historico,
              onRetry: _recarregar,
              builder: (context, jogos) {
                if (jogos.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: EmptyText(
                      'Ainda não tens jogos no histórico.',
                    ),
                  );
                }

                return Column(
                  children: [
                    for (final jogo in jogos)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _HistoryCard(
                          jogo: Map<String, dynamic>.from(jogo as Map),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _filtroChip(String texto, String valor) {
    final ativo = _filtro == valor;

    return ChoiceChip(
      label: Text(texto),
      selected: ativo,
      onSelected: (_) => _alterarFiltro(valor),
      selectedColor: AppColors.lime,
      backgroundColor: AppColors.chip,
      labelStyle: AppText.body(
        13,
        weight: FontWeight.w700,
        color: AppColors.ink,
      ),
      side: BorderSide.none,
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.jogo});

  final Map<String, dynamic> jogo;

  @override
  Widget build(BuildContext context) {
    final data = DateTime.parse(jogo['data_hora'].toString());

    final estado =
        jogo['estado_historico']?.toString() ?? 'terminado';

    final papel = jogo['papel']?.toString() ?? '';

    final participantes =
        (jogo['participantes'] as num?)?.toInt() ?? 0;

    final presentes =
        (jogo['presentes'] as num?)?.toInt() ?? 0;

    final estadoTexto = switch (estado) {
      'cancelado' => 'Cancelado',
      'próximo' => 'Próximo',
      _ => 'Terminado',
    };

    return SurfaceCard(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  jogo['modalidade']?.toString() ?? 'Jogo',
                  style: AppText.body(18, weight: FontWeight.w800),
                ),
              ),
              Tag(
                estadoTexto,
                background: estado == 'cancelado'
                    ? AppColors.chip
                    : AppColors.lime,
                radius: 12,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _HistoryInfo(
            icon: Icons.calendar_today_outlined,
            text: diaHora(data),
          ),
          const SizedBox(height: 8),
          _HistoryInfo(
            icon: Icons.location_on_outlined,
            text: jogo['local_nome']?.toString() ?? 'Local não indicado',
          ),
          const SizedBox(height: 8),
          _HistoryInfo(
            icon: Icons.person_outline,
            text: papel == 'organizador'
                ? 'Organizaste este jogo'
                : 'Participaste neste jogo',
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$participantes participantes',
                style: AppText.body(13, color: AppColors.muted),
              ),
              Text(
                '$presentes presenças',
                style: AppText.body(13, weight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryInfo extends StatelessWidget {
  const _HistoryInfo({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppText.body(14, color: AppColors.muted),
          ),
        ),
      ],
    );
  }
}

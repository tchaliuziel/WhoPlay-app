import 'package:flutter/material.dart';

import '../data/models.dart';
import '../services/api.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatos.dart';
import '../widgets/app_icons.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';

/// 05 Perfil do jogador. Devolve `true` ao fazer pop se o convite foi enviado.
class PlayerProfileScreen extends StatefulWidget {
  const PlayerProfileScreen({super.key, required this.jogador, required this.modalidadeId});

  final Jogador jogador;
  final int modalidadeId;

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  bool _aEnviar = false;

  Future<void> _enviarConvite() async {
    setState(() => _aEnviar = true);
    try {
      await Api.enviarConvite(
        jogadorId: widget.jogador.id,
        modalidadeId: widget.modalidadeId,
        dataHora: inicioConvite(widget.jogador.disponivelHoje),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (erro) {
      if (mounted) showInfo(context, erro.message);
    } finally {
      if (mounted) setState(() => _aEnviar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jogador = widget.jogador;
    final avaliacao = jogador.avaliacao;
    return AnnotatedRegion(
      value: AppTheme.darkStatusIcons,
      child: Scaffold(
        body: FillScrollView(
          padding: EdgeInsets.fromLTRB(20, topInset(context, 48), 20, 28 + bottomInset(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: CircleIconButton(
                  semanticLabel: 'Voltar',
                  onPressed: () => Navigator.of(context).pop(),
                  child: const SvgIcon(AppIcon.back),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Avatar(jogador.inicial, size: 72, fontSize: 30),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(jogador.nome, style: AppText.display(28, letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text(
                          '${jogador.modalidade} · ${jogador.nivel} · ${km(jogador.distanciaKm)}',
                          style: AppText.body(15, color: AppColors.muted),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const SvgIcon(AppIcon.star, size: 16, strokeWidth: 1.5),
                            const SizedBox(width: 5),
                            Text(
                              avaliacao == null
                                  ? 'Sem avaliações'
                                  : '${avaliacao.toString().replaceAll('.', ',')} de avaliação',
                              style: AppText.body(15, weight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _CompatibilityCard(jogador: jogador),
              const SizedBox(height: 16),
              ListCard(
                children: [
                  _InfoRow('Disponível hoje', jogador.disponivelHoje ?? '—'),
                  _InfoRow('Objetivo', jogador.objetivo),
                ],
              ),
              const SizedBox(height: 16),
              const Spacer(),
              AppButton(
                label: _aEnviar ? 'A enviar…' : 'Enviar convite',
                onPressed: _aEnviar ? null : _enviarConvite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompatibilityCard extends StatelessWidget {
  const _CompatibilityCard({required this.jogador});

  final Jogador jogador;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.forest, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Compatibilidade contigo',
                style: AppText.body(15, weight: FontWeight.w600, color: AppColors.white),
              ),
              Text(
                '${jogador.compatibilidade}%',
                style: AppText.display(44, weight: FontWeight.w800, color: AppColors.lime, height: 1),
              ),
            ],
          ),
          for (final criterio in jogador.criterios) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(criterio.nome, style: AppText.body(14, color: AppColors.white)),
                Text(
                  '${criterio.pontos} / ${criterio.maximo}',
                  style: AppText.body(14, weight: FontWeight.w700, color: AppColors.white),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ThinBar(
              value: criterio.pontos / criterio.maximo,
              color: AppColors.lime,
              track: AppColors.forestLight,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(label, style: AppText.body(15, color: AppColors.muted)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppText.body(15, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

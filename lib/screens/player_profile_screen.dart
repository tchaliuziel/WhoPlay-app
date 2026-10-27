import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';

/// 05 Perfil do jogador. Devolve `true` ao fazer pop se o convite foi enviado.
class PlayerProfileScreen extends StatelessWidget {
  const PlayerProfileScreen({super.key, required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
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
                  Avatar(player.initial, size: 72, fontSize: 30),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(player.name, style: AppText.display(28, letterSpacing: -0.5)),
                        const SizedBox(height: 4),
                        Text(player.summary, style: AppText.body(15, color: AppColors.muted)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const SvgIcon(AppIcon.star, size: 16, strokeWidth: 1.5),
                            const SizedBox(width: 5),
                            Text('4,7 de avaliação', style: AppText.body(15, weight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _CompatibilityCard(total: player.compatibility),
              const SizedBox(height: 16),
              ListCard(
                children: [
                  _InfoRow('Disponível hoje', player.availability.replaceFirst('Disponível hoje ', '')),
                  const _InfoRow('Objetivo', 'Procura parceiro para jogo'),
                ],
              ),
              const SizedBox(height: 16),
              const Spacer(),
              AppButton(
                label: 'Enviar convite',
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompatibilityCard extends StatelessWidget {
  const _CompatibilityCard({required this.total});

  final int total;

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
                '$total%',
                style: AppText.display(44, weight: FontWeight.w800, color: AppColors.lime, height: 1),
              ),
            ],
          ),
          for (final (label, score, max) in compatibilityBreakdown) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: AppText.body(14, color: AppColors.white)),
                Text(
                  '$score / $max',
                  style: AppText.body(14, weight: FontWeight.w700, color: AppColors.white),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ThinBar(value: score / max, color: AppColors.lime, track: AppColors.forestLight),
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

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';

/// 03 Perfil
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, topInset(context, 52), 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ScreenTitle('Perfil'),
              AppButton.pill(
                label: 'Editar',
                onPressed: () => showInfo(context, 'Edição do perfil em breve.'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.forest, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Avatar('S', size: 64, fontSize: 28, background: AppColors.lime, foreground: AppColors.ink),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sebastião', style: AppText.display(22, color: AppColors.white)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const SvgIcon(AppIcon.pin, size: 16, color: AppColors.white),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Moscavide · raio até 5 km',
                              style: AppText.body(14, color: AppColors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Section(
            title: 'Desportos e nível',
            child: ListCard(
              children: [
                _SportLevelRow('Padel', 'Intermédio', highlight: true),
                _SportLevelRow('Ténis', 'Iniciante'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Section(
            title: 'Disponibilidade',
            child: ListCard(
              children: [
                _AvailabilityRow('Segunda', '18h – 21h'),
                _AvailabilityRow('Quarta', '18h – 22h'),
                _AvailabilityRow('Sábado', '10h – 15h'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Section(
            title: 'Objetivo',
            child: SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text('Jogos amigáveis', style: AppText.body(16, weight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SportLevelRow extends StatelessWidget {
  const _SportLevelRow(this.sport, this.level, {this.highlight = false});

  final String sport;
  final String level;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(sport, style: AppText.body(17, weight: FontWeight.w700)),
          Tag(
            level,
            background: highlight ? AppColors.lime : AppColors.chip,
            radius: 14,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityRow extends StatelessWidget {
  const _AvailabilityRow(this.day, this.hours);

  final String day;
  final String hours;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day, style: AppText.body(16, weight: FontWeight.w600)),
          Text(hours, style: AppText.body(16, color: AppColors.muted)),
        ],
      ),
    );
  }
}

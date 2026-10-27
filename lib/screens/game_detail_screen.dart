import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import 'checkin_screen.dart';

/// 09 Detalhe do jogo
class GameDetailScreen extends StatelessWidget {
  const GameDetailScreen({super.key});

  static const _capacity = 4;

  @override
  Widget build(BuildContext context) {
    final openSlots = _capacity - gameParticipants.length;

    return AnnotatedRegion(
      value: AppTheme.lightStatusIcons,
      child: Scaffold(
        body: FillScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: AppColors.forest,
                padding: EdgeInsets.fromLTRB(20, topInset(context, 48), 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleIconButton(
                      semanticLabel: 'Voltar',
                      background: AppColors.forestLight,
                      bordered: false,
                      onPressed: () => Navigator.of(context).pop(),
                      child: const SvgIcon(AppIcon.back, color: AppColors.white),
                    ),
                    const SizedBox(height: 14),
                    const SectionLabel('Padel · Amigável', color: AppColors.lime, letterSpacing: 1.2),
                    const SizedBox(height: 14),
                    Text(
                      'Sábado, 3 de outubro às 10:00',
                      style: AppText.display(
                        34,
                        weight: FontWeight.w800,
                        color: AppColors.white,
                        letterSpacing: -0.8,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const SvgIcon(AppIcon.pin, size: 18, color: AppColors.white),
                        const SizedBox(width: 6),
                        Text(
                          'Padel Club X · a 2,4 km de ti',
                          style: AppText.body(15, color: AppColors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 28 + bottomInset(context)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Expanded(child: _StatCell('Nível', 'Intermédio')),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatCell('Jogadores', '${gameParticipants.length} de $_capacity'),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(child: _StatCell('Preço', '8 € / pessoa')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Section(
                        title: 'Quem vai',
                        child: ListCard(
                          children: [
                            for (final p in gameParticipants) _ParticipantRow(p),
                            if (openSlots > 0) _OpenSlotRow(openSlots),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Spacer(),
                      Text(
                        'O organizador é avisado assim que entrares.',
                        textAlign: TextAlign.center,
                        style: AppText.body(14, color: AppColors.muted),
                      ),
                      const SizedBox(height: 10),
                      AppButton(
                        label: 'Entrar no jogo',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CheckInScreen()),
                        ),
                      ),
                    ],
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

class _StatCell extends StatelessWidget {
  const _StatCell(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      radius: 14,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.body(12, color: AppColors.muted)),
          const SizedBox(height: 4),
          Text(value, style: AppText.body(15, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow(this.participant);

  final GameParticipant participant;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Avatar(participant.name.substring(0, 1), size: 40, fontSize: 17),
          const SizedBox(width: 12),
          Expanded(child: Text(participant.name, style: AppText.body(16, weight: FontWeight.w700))),
          if (participant.organizer)
            Tag(participant.detail, fontSize: 13, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5))
          else
            Text(participant.detail, style: AppText.body(14, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _OpenSlotRow extends StatelessWidget {
  const _OpenSlotRow(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const CustomPaint(
            painter: _DashedCirclePainter(color: AppColors.primary),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: SvgIcon(AppIcon.plus, size: 20, color: AppColors.primary, strokeWidth: 2.2),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            count == 1 ? '1 vaga livre' : '$count vagas livres',
            style: AppText.body(16, weight: FontWeight.w700, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

/// Círculo tracejado (border: 2px dashed) da vaga livre.
class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 2.0;
    const dashes = 14;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    const sweep = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * sweep, sweep * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) => oldDelegate.color != color;
}

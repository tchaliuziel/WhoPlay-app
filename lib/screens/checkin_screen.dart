import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';

/// 10 Check-in por QR Code
class CheckInScreen extends StatelessWidget {
  const CheckInScreen({super.key, this.checkInCode = 'whoplay://checkin/padel-club-x/2026-10-03T10:00'});

  final String checkInCode;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: AppTheme.lightStatusIcons,
      child: Scaffold(
        backgroundColor: AppColors.night,
        body: FillScrollView(
          padding: EdgeInsets.fromLTRB(20, topInset(context, 48), 20, 28 + bottomInset(context)),
          child: Column(
            children: [
              Row(
                children: [
                  CircleIconButton(
                    semanticLabel: 'Fechar',
                    background: AppColors.nightLight,
                    bordered: false,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const SvgIcon(AppIcon.close, color: AppColors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 56),
                      child: Text(
                        'Check-in no jogo',
                        textAlign: TextAlign.center,
                        style: AppText.display(22, color: AppColors.white, letterSpacing: -0.3),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const SectionLabel('Padel · Amigável', color: AppColors.lime, letterSpacing: 1.2),
              const SizedBox(height: 6),
              Text(
                'Sáb, 3 de outubro · 10:00',
                textAlign: TextAlign.center,
                style: AppText.display(24, color: AppColors.white),
              ),
              const SizedBox(height: 6),
              Text('Padel Club X', style: AppText.body(15, color: AppColors.softText)),
              const SizedBox(height: 36),
              SizedBox(
                width: 300,
                height: 300,
                child: CustomPaint(
                  painter: const _ScanCornersPainter(color: AppColors.lime),
                  child: Center(
                    child: Container(
                      width: 256,
                      height: 256,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: QrImageView(
                        data: checkInCode,
                        size: 220,
                        padding: EdgeInsets.zero,
                        backgroundColor: AppColors.white,
                        semanticsLabel: 'QR Code de check-in',
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.night),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppColors.night,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  'Mostra este QR Code no local para confirmar a tua presença.',
                  textAlign: TextAlign.center,
                  style: AppText.body(17, color: AppColors.white, height: 1.45),
                ),
              ),
              const SizedBox(height: 32),
              const Spacer(),
              AppButton(
                label: 'Guardar QR Code',
                outlined: true,
                foreground: AppColors.white,
                onPressed: () => showInfo(context, 'QR Code guardado.'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Os quatro cantos de "mira" à volta do QR Code (44px, 4px, raio 18).
class _ScanCornersPainter extends CustomPainter {
  const _ScanCornersPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const length = 44.0;
    const stroke = 4.0;
    const radius = 18.0;
    const inset = stroke / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    // Canto superior esquerdo; os outros são reflexões deste.
    final corner = Path()
      ..moveTo(inset, length)
      ..lineTo(inset, radius)
      ..arcToPoint(const Offset(radius, inset), radius: const Radius.circular(radius - inset))
      ..lineTo(length, inset);

    for (final (sx, sy) in [(1.0, 1.0), (-1.0, 1.0), (1.0, -1.0), (-1.0, -1.0)]) {
      canvas.save();
      canvas.translate(sx < 0 ? size.width : 0, sy < 0 ? size.height : 0);
      canvas.scale(sx, sy);
      canvas.drawPath(corner, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ScanCornersPainter oldDelegate) => oldDelegate.color != color;
}

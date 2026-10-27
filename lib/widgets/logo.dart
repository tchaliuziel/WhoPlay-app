import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

const _logoSvg = '<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">'
    '<circle cx="12" cy="4.2" r="2.4" fill="currentColor"/>'
    '<path d="M4 9.5l3.6 10.5L12 11.5l4.4 8.5L20 9.5" stroke="currentColor" '
    'stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round"/></svg>';

/// Símbolo do WhoPlay (jogador a celebrar / "W").
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 60, this.color = AppColors.lime});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SvgPicture.string(
        _logoSvg,
        width: size,
        height: size,
        theme: SvgTheme(currentColor: color),
      );
}

/// Símbolo + palavra "WhoPlay".
class WhoPlayLogo extends StatelessWidget {
  const WhoPlayLogo({
    super.key,
    this.markSize = 60,
    this.fontSize = 52,
    this.markColor = AppColors.lime,
    this.textColor = AppColors.white,
  });

  final double markSize;
  final double fontSize;
  final Color markColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LogoMark(size: markSize, color: markColor),
        const SizedBox(width: 10),
        Text(
          'WhoPlay',
          style: AppText.display(
            fontSize,
            weight: FontWeight.w800,
            color: textColor,
            letterSpacing: -1.5,
            height: 1,
          ),
        ),
      ],
    );
  }
}

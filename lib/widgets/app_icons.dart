import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Ícones do mockup (SVG 24x24, traço arredondado).
enum AppIcon { users, pin, plus, bell, user, check, clock, back, star, close }

const _paths = <AppIcon, String>{
  AppIcon.users:
      '<path d="M16 19v-1a4 4 0 0 0-4-4H7a4 4 0 0 0-4 4v1"/><circle cx="9.5" cy="7" r="3.5"/><path d="M21 19v-1a4 4 0 0 0-3-3.8M15.5 3.7a3.5 3.5 0 0 1 0 6.6"/>',
  AppIcon.pin:
      '<path d="M12 21s7-6.2 7-11a7 7 0 1 0-14 0c0 4.8 7 11 7 11z"/><circle cx="12" cy="10" r="2.5"/>',
  AppIcon.plus: '<path d="M12 5v14M5 12h14"/>',
  AppIcon.bell:
      '<path d="M6 9a6 6 0 1 1 12 0c0 6 2.5 7 2.5 7h-17S6 15 6 9z"/><path d="M10 20a2 2 0 0 0 4 0"/>',
  AppIcon.user:
      '<circle cx="12" cy="8" r="4"/><path d="M4 21v-1a6 6 0 0 1 6-6h4a6 6 0 0 1 6 6v1"/>',
  AppIcon.check: '<path d="M5 12.5l4.5 4.5L19 7.5"/>',
  AppIcon.clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
  AppIcon.back: '<path d="M15 5l-7 7 7 7"/>',
  AppIcon.star:
      '<path fill="currentColor" d="M12 3.5l2.6 5.4 5.9.8-4.3 4.1 1 5.8L12 16.9 6.8 19.6l1-5.8L3.5 9.7l5.9-.8z"/>',
  AppIcon.close: '<path d="M6 6l12 12M18 6L6 18"/>',
};

class SvgIcon extends StatelessWidget {
  const SvgIcon(
    this.icon, {
    super.key,
    this.size = 22,
    this.color = const Color(0xFF10201A),
    this.strokeWidth = 2,
  });

  final AppIcon icon;
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final svg = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" '
        'stroke-width="$strokeWidth" stroke-linecap="round" stroke-linejoin="round" '
        'xmlns="http://www.w3.org/2000/svg">${_paths[icon]}</svg>';
    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      theme: SvgTheme(currentColor: color),
    );
  }
}

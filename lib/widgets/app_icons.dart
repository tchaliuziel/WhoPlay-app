
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Ícones do mockup (SVG 24x24, traço arredondado).
enum AppIcon {
  users,
  pin,
  plus,
  bell,
  user,
  check,
  clock,
  back,
  star,
  close,
  calendar,
  refresh,
  history,
  trophy,
  checkCircle,
  trendUp,
  alert,
  scan,
  ball,
}

const _paths = <AppIcon, String>{
  AppIcon.users:
      '<path d="M16 19v-1a4 4 0 0 0-4-4H7a4 4 0 0 0-4 4v1"/><circle cx="9.5" cy="7" r="3.5"/><path d="M21 19v-1a4 4 0 0 0-3-3.8M15.5 3.7a3.5 3.5 0 0 1 0 6.6"/>',

  AppIcon.pin:
      '<path d="M12 21s7-6.2 7-11a7 7 0 1 0-14 0c0 4.8 7 11 7 11z"/><circle cx="12" cy="10" r="2.5"/>',

  AppIcon.plus:
      '<path d="M12 5v14M5 12h14"/>',

  AppIcon.bell:
      '<path d="M6 9a6 6 0 1 1 12 0c0 6 2.5 7 2.5 7h-17S6 15 6 9z"/><path d="M10 20a2 2 0 0 0 4 0"/>',

  AppIcon.user:
      '<circle cx="12" cy="8" r="4"/><path d="M4 21v-1a6 6 0 0 1 6-6h4a6 6 0 0 1 6 6v1"/>',

  AppIcon.check:
      '<path d="M5 12.5l4.5 4.5L19 7.5"/>',

  AppIcon.clock:
      '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',

  AppIcon.back:
      '<path d="M15 5l-7 7 7 7"/>',

  AppIcon.star:
      '<path fill="currentColor" d="M12 3.5l2.6 5.4 5.9.8-4.3 4.1 1 5.8L12 16.9 6.8 19.6l1-5.8L3.5 9.7l5.9-.8z"/>',

  AppIcon.close:
      '<path d="M6 6l12 12M18 6L6 18"/>',

  AppIcon.calendar:
      '<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M16 3v4M8 3v4M3 10h18"/>',

  AppIcon.refresh:
      '<path d="M20 11a8 8 0 0 0-14.6-4.5L4 8"/><path d="M4 4v4h4"/><path d="M4 13a8 8 0 0 0 14.6 4.5L20 16"/><path d="M20 20v-4h-4"/>',

  AppIcon.history:
      '<path d="M3 12a9 9 0 1 0 2.6-6.4L3 8"/><path d="M3 3v5h5"/><path d="M12 7v5l3 2"/>',

  AppIcon.trophy:
      '<path d="M8 4h8v5a4 4 0 0 1-8 0z"/><path d="M8 6H5a3 3 0 0 0 3 4M16 6h3a3 3 0 0 1-3 4"/><path d="M12 13v4M8.5 20h7M10 17h4"/>',

  AppIcon.checkCircle:
      '<circle cx="12" cy="12" r="9"/><path d="M8 12.5l2.8 2.8L16.5 9.5"/>',

  AppIcon.trendUp:
      '<path d="M3 17l6-6 4 4 8-8"/><path d="M15 7h6v6"/>',

  AppIcon.alert:
      '<circle cx="12" cy="12" r="9"/><path d="M12 7.5v5.5M12 16.5h.01"/>',

  AppIcon.scan:
      '<path d="M4 8V5a1 1 0 0 1 1-1h3M16 4h3a1 1 0 0 1 1 1v3M20 16v3a1 1 0 0 1-1 1h-3M8 20H5a1 1 0 0 1-1-1v-3"/><path d="M4 12h16"/>',

  AppIcon.ball:
      '<circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3v18"/><path d="M5.6 5.6a9 9 0 0 1 0 12.8M18.4 5.6a9 9 0 0 0 0 12.8"/>',
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

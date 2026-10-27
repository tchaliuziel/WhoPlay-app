import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import 'game_detail_screen.dart';

/// Ilustração do mapa (igual ao mockup). Substituir por um mapa real
/// (ex.: google_maps_flutter / flutter_map) quando houver localização.
const _mapSvg = '''
<svg width="390" height="768" viewBox="0 0 390 768" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect width="390" height="768" fill="#E2E9DD"/>
<path d="M-20 520C80 470 150 560 250 520S380 430 420 450V620C340 610 300 690 200 680S60 640-20 690z" fill="#CBDDE6"/>
<rect x="232" y="118" width="120" height="96" rx="14" fill="#CFE3C4"/>
<rect x="28" y="230" width="92" height="70" rx="14" fill="#CFE3C4"/>
<path d="M-10 190L400 150M-10 400L400 360M70-10L130 780M260-10L300 780M-10 90L400 300M150 780L400 520" stroke="#FFFFFF" stroke-width="14" stroke-linecap="round"/>
<path d="M-10 290L400 250M180-10L200 780" stroke="#FFFFFF" stroke-width="7" stroke-linecap="round"/>
<circle cx="195" cy="350" r="150" fill="#1F7A4D" fill-opacity="0.08" stroke="#1F7A4D" stroke-width="2" stroke-dasharray="6 8"/>
</svg>
''';

/// 08 Mapa
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _within5km = false;

  void _openGame() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const GameDetailScreen()),
      );

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.mapLand,
      child: Stack(
        children: [
          // Mapa desenhado em 390x768 (área do mockup) e escalado para cobrir o ecrã.
          Positioned.fill(
            child: ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 390,
                  height: 768,
                  child: Stack(
                    children: [
                      SvgPicture.string(_mapSvg, width: 390, height: 768),
                      const Positioned(left: 236, top: 228, child: _PlayerMarker('S', 'Sebastião · 1,2 km')),
                      const Positioned(left: 40, top: 150, child: _PlayerMarker('H', 'Helio · 3,1 km')),
                      Positioned(
                        left: 70,
                        top: 404,
                        child: GestureDetector(onTap: _openGame, child: const _VenueMarker('Padel Club X · 1 vaga')),
                      ),
                      const Positioned(left: 167, top: 322, child: _YouMarker()),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: topInset(context, 52),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const PillChip(label: 'Padel', selected: true),
                  const SizedBox(width: 8),
                  PillChip(
                    label: 'Raio 5 km',
                    selected: _within5km,
                    onTap: () => setState(() => _within5km = !_within5km),
                  ),
                  const SizedBox(width: 8),
                  const PillChip(label: 'Jogos e jogadores'),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SurfaceCard(
              radius: 20,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Jogo de Padel', style: AppText.display(20)),
                            const SizedBox(height: 3),
                            Text(
                              'Sáb, 3 Out · 10:00 · Padel Club X',
                              style: AppText.body(14, color: AppColors.muted),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Intermédio · a 2,4 km de ti',
                              style: AppText.body(14, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Tag('3 / 4', background: AppColors.lime),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppButton(label: 'Ver jogo', height: 48, radius: 12, fontSize: 16, onPressed: _openGame),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _YouMarker extends StatelessWidget {
  const _YouMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 4),
      ),
      child: Text('Tu', style: AppText.body(15, weight: FontWeight.w700, color: AppColors.white)),
    );
  }
}

class _MarkerLabel extends StatelessWidget {
  const _MarkerLabel(this.text, {this.dark = false});

  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: dark ? AppColors.ink : AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: AppText.body(12, weight: FontWeight.w700, color: dark ? AppColors.white : AppColors.ink),
      ),
    );
  }
}

class _PlayerMarker extends StatelessWidget {
  const _PlayerMarker(this.initial, this.label);

  final String initial;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Avatar(initial, size: 40, fontSize: 16, borderWidth: 3),
        const SizedBox(height: 4),
        _MarkerLabel(label),
      ],
    );
  }
}

class _VenueMarker extends StatelessWidget {
  const _VenueMarker(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.lime,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.ink, width: 3),
          ),
          child: const SvgIcon(AppIcon.pin, size: 24),
        ),
        const SizedBox(height: 4),
        _MarkerLabel(label, dark: true),
      ],
    );
  }
}

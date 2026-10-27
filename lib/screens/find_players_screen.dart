import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import 'player_profile_screen.dart';

/// 04 Encontrar jogadores
class FindPlayersScreen extends StatefulWidget {
  const FindPlayersScreen({super.key, this.onInviteSent});

  final VoidCallback? onInviteSent;

  @override
  State<FindPlayersScreen> createState() => _FindPlayersScreenState();
}

class _FindPlayersScreenState extends State<FindPlayersScreen> {
  String _sport = 'Padel';
  bool _within5km = false;
  bool _today = false;

  Future<void> _openProfile(Player player) async {
    final invited = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PlayerProfileScreen(player: player)),
    );
    if (invited == true) widget.onInviteSent?.call();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, topInset(context, 52), 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenTitle('Encontrar jogadores'),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                for (final s in ['Padel', 'Ténis']) ...[
                  PillChip(label: s, selected: _sport == s, onTap: () => setState(() => _sport = s)),
                  const SizedBox(width: 8),
                ],
                PillChip(
                  label: 'Até 5 km',
                  selected: _within5km,
                  onTap: () => setState(() => _within5km = !_within5km),
                ),
                const SizedBox(width: 8),
                PillChip(label: 'Hoje', selected: _today, onTap: () => setState(() => _today = !_today)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${nearbyPlayers.length} jogadores compatíveis perto de ti',
            style: AppText.body(14, color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < nearbyPlayers.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            PlayerCard(
              player: nearbyPlayers[i],
              onViewProfile: () => _openProfile(nearbyPlayers[i]),
              onInvite: () => showInfo(context, 'Convite enviado a ${nearbyPlayers[i].name}.'),
            ),
          ],
        ],
      ),
    );
  }
}

class PlayerCard extends StatelessWidget {
  const PlayerCard({super.key, required this.player, this.onViewProfile, this.onInvite});

  final Player player;
  final VoidCallback? onViewProfile;
  final VoidCallback? onInvite;

  @override
  Widget build(BuildContext context) {
    final availabilityColor = player.availableHighlight ? AppColors.primary : AppColors.muted;
    return SurfaceCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Avatar(player.initial),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(player.name, style: AppText.body(17, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(player.summary, style: AppText.body(14, color: AppColors.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Tag(
                '${player.compatibility}%',
                display: true,
                fontSize: 18,
                background: player.compatibility >= 80 ? AppColors.lime : AppColors.chip,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SvgIcon(AppIcon.clock, size: 16, color: availabilityColor),
              const SizedBox(width: 6),
              Text(
                player.availability,
                style: AppText.body(14, weight: FontWeight.w600, color: availabilityColor),
              ),
            ],
          ),
          if (player.showActions) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: AppButton.small(label: 'Ver perfil', outlined: true, onPressed: onViewProfile)),
                const SizedBox(width: 8),
                Expanded(child: AppButton.small(label: 'Convidar', onPressed: onInvite)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

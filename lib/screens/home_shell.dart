import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import 'create_game_screen.dart';
import 'find_players_screen.dart';
import 'invites_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';

/// Estrutura principal com a barra de navegação inferior.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialTab = playersTab});

  static const playersTab = 0;
  static const mapTab = 1;
  static const invitesTab = 3;
  static const profileTab = 4;

  final int initialTab;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _tab = widget.initialTab;

  static const _stackIndex = {
    HomeShell.playersTab: 0,
    HomeShell.mapTab: 1,
    HomeShell.invitesTab: 2,
    HomeShell.profileTab: 3,
  };

  void _onNavTap(int index) {
    if (index == AppBottomNav.createIndex) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateGameScreen()));
      return;
    }
    setState(() => _tab = index);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: AppTheme.darkStatusIcons,
      child: Scaffold(
        body: IndexedStack(
          index: _stackIndex[_tab]!,
          children: [
            FindPlayersScreen(onInviteSent: () => setState(() => _tab = HomeShell.invitesTab)),
            const MapScreen(),
            const InvitesScreen(),
            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: AppBottomNav(currentIndex: _tab, onTap: _onNavTap),
      ),
    );
  }
}

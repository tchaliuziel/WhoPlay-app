
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import 'create_game_screen.dart';
import 'find_players_screen.dart';
import 'games_screen.dart';
import 'invites_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';

/// Estrutura principal com a barra de navegação inferior.
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    this.initialTab = playersTab,
  });

  static const playersTab = 0;
  static const mapTab = 1;
  static const createTab = 2;
  static const gamesTab = 3;
  static const invitesTab = 4;
  static const profileTab = 5;

  final int initialTab;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _tab = widget.initialTab;

  int _gamesVersion = 0;
  int _invitesVersion = 0;
  int _profileVersion = 0;

  static const _stackIndex = {
    HomeShell.playersTab: 0,
    HomeShell.mapTab: 1,
    HomeShell.gamesTab: 2,
    HomeShell.invitesTab: 3,
    HomeShell.profileTab: 4,
  };

  void _onNavTap(int index) {
    if (index == AppBottomNav.createIndex) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const CreateGameScreen(),
        ),
      ).then((_) {
        if (mounted) {
          _openTab(HomeShell.gamesTab);
        }
      });
      return;
    }

    _openTab(index);
  }

  void _openTab(int index) {
    setState(() {
      _tab = index;

      if (index == HomeShell.gamesTab) {
        _gamesVersion++;
      }

      if (index == HomeShell.invitesTab) {
        _invitesVersion++;
      }

      if (index == HomeShell.profileTab) {
        _profileVersion++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: AppTheme.darkStatusIcons,
      child: Scaffold(
        body: IndexedStack(
          index: _stackIndex[_tab]!,
          children: [
            FindPlayersScreen(
              onInviteSent: () => _openTab(HomeShell.invitesTab),
            ),
            const MapScreen(),
            GamesScreen(
              key: ValueKey(_gamesVersion),
            ),
            InvitesScreen(
              key: ValueKey(_invitesVersion),
            ),
            ProfileScreen(
              key: ValueKey(_profileVersion),
            ),
          ],
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: _tab,
          onTap: _onNavTap,
        ),
      ),
    );
  }
}

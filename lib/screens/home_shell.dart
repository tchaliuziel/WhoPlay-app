
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import 'create_game_screen.dart';
import 'find_players_screen.dart';
import 'games_screen.dart';
import 'invites_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';

/// Navegação principal do WhoPlay com cinco posições.
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    this.initialTab = exploreTab,
  });

  static const exploreTab = 0;
  static const gamesTab = 1;
  static const createTab = 2;
  static const inboxTab = 3;
  static const profileTab = 4;

  final int initialTab;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _tab = widget.initialTab;

  int _gamesVersion = 0;
  int _inboxVersion = 0;
  int _profileVersion = 0;

  static const _stackIndex = {
    HomeShell.exploreTab: 0,
    HomeShell.gamesTab: 1,
    HomeShell.inboxTab: 2,
    HomeShell.profileTab: 3,
  };

  void _onNavTap(int index) {
    if (index == AppBottomNav.createIndex) {
      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (_) => const CreateGameScreen(),
        ),
      )
          .then((_) {
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

      if (index == HomeShell.inboxTab) {
        _inboxVersion++;
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
            _SectionTabs(
              key: const ValueKey('explorar'),
              tabs: const ['Jogadores', 'Mapa'],
              children: [
                FindPlayersScreen(
                  onInviteSent: () => _openTab(HomeShell.inboxTab),
                ),
                const MapScreen(),
              ],
            ),
            GamesScreen(
              key: ValueKey('games_$_gamesVersion'),
            ),
            InvitesScreen(
              key: ValueKey(_inboxVersion),
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

/// Agrupa ecrãs relacionados através de separadores internos.
class _SectionTabs extends StatelessWidget {
  const _SectionTabs({
    super.key,
    required this.tabs,
    required this.children,
  });

  final List<String> tabs;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBar(
              tabs: [
                for (final tab in tabs)
                  Tab(text: tab),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

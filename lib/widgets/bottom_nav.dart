
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_icons.dart';

/// Navegação principal do WhoPlay: cinco posições.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const createIndex = 2;

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = <(AppIcon, String)?>[
    (AppIcon.users, 'Explorar'),
    (AppIcon.calendar, 'Jogos'),
    null,
    (AppIcon.bell, 'Inbox'),
    (AppIcon.user, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: SizedBox(
        height: 68,
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: _buildItem(i, _items[i]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(int index, (AppIcon, String)? item) {
    if (item == null) {
      return Semantics(
        button: true,
        label: 'Criar jogo',
        child: InkResponse(
          onTap: () => onTap(index),
          radius: 32,
          child: Center(
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const SvgIcon(
                AppIcon.plus,
                size: 23,
                color: AppColors.white,
                strokeWidth: 2.2,
              ),
            ),
          ),
        ),
      );
    }

    final active = index == currentIndex;
    final color = active ? AppColors.primary : AppColors.muted;

    return InkResponse(
      onTap: () => onTap(index),
      radius: 30,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgIcon(
            item.$1,
            size: 21,
            color: color,
            strokeWidth: active ? 2.2 : 1.8,
          ),
          const SizedBox(height: 3),
          Text(
            item.$2,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(
              10,
              weight: active ? FontWeight.w700 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Botão principal (verde) ou contornado, como no mockup.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.height = 56,
    this.radius = 14,
    this.fontSize = 17,
    this.foreground,
    this.expand = true,
    this.horizontalPadding = 0,
  });

  /// Botão pequeno usado nos cartões (44px, raio 12, 15px).
  const AppButton.small({
    super.key,
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.foreground,
  })  : height = 44,
        radius = 12,
        fontSize = 15,
        expand = true,
        horizontalPadding = 0;

  /// Botão em forma de pílula (ex.: "Editar").
  const AppButton.pill({
    super.key,
    required this.label,
    required this.onPressed,
    this.foreground,
  })  : outlined = true,
        height = 44,
        radius = 22,
        fontSize = 15,
        expand = false,
        horizontalPadding = 18;

  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  final double height;
  final double radius;
  final double fontSize;
  final Color? foreground;
  final bool expand;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? (outlined ? AppColors.ink : AppColors.white);
    return SizedBox(
      height: height,
      width: expand ? double.infinity : null,
      child: Material(
        color: outlined ? Colors.transparent : AppColors.primary,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: outlined ? BorderSide(color: fg, width: 1.5) : BorderSide.none,
        ),
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Center(
              widthFactor: expand ? null : 1,
              child: Text(
                label,
                style: AppText.body(fontSize, weight: FontWeight.w700, color: fg),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão redondo de 44px (voltar / fechar).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.background = AppColors.white,
    this.bordered = true,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final Color background;
  final bool bordered;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: background,
        shape: CircleBorder(
          side: bordered ? const BorderSide(color: AppColors.border) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(width: 44, height: 44, child: Center(child: child)),
        ),
      ),
    );
  }
}

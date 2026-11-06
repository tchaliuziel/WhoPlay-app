import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// O mockup tem 390x844 com ~44px de barra de estado incluídos no padding
/// superior. Aqui convertemos esse valor para o inset real do dispositivo.
double topInset(BuildContext context, double mockupTop) =>
    MediaQuery.paddingOf(context).top + mockupTop - 44;

double bottomInset(BuildContext context) => MediaQuery.paddingOf(context).bottom;

void showInfo(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Conteúdo que preenche o ecrã (para botões "colados" ao fundo) mas que
/// faz scroll em ecrãs mais pequenos.
class FillScrollView extends StatelessWidget {
  const FillScrollView({super.key, required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(padding: padding, child: child),
        ),
      ],
    );
  }
}

class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppText.display(28, letterSpacing: -0.5));
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color = AppColors.muted, this.letterSpacing = 0.8});

  final String text;
  final Color color;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: AppText.body(13, weight: FontWeight.w700, color: color, letterSpacing: letterSpacing),
      );
}

/// Secção com título em maiúsculas e conteúdo a 10px.
class Section extends StatelessWidget {
  const Section({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [SectionLabel(title), const SizedBox(height: 10), child],
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar(
    this.letter, {
    super.key,
    this.size = 48,
    this.fontSize = 20,
    this.background = AppColors.forest,
    this.foreground = AppColors.lime,
    this.borderWidth = 0,
  });

  final String letter;
  final double size;
  final double fontSize;
  final Color background;
  final Color foreground;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: borderWidth > 0 ? Border.all(color: AppColors.white, width: borderWidth) : null,
      ),
      child: Text(
        letter,
        style: AppText.display(fontSize, weight: FontWeight.w800, color: foreground, height: 1),
      ),
    );
  }
}

/// Etiqueta arredondada (nível, compatibilidade, estado...).
class Tag extends StatelessWidget {
  const Tag(
    this.text, {
    super.key,
    this.background = AppColors.chip,
    this.foreground = AppColors.ink,
    this.fontSize = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.radius = 12,
    this.display = false,
  });

  final String text;
  final Color background;
  final Color foreground;
  final double fontSize;
  final EdgeInsets padding;
  final double radius;
  final bool display;

  @override
  Widget build(BuildContext context) {
    final style = display
        ? AppText.display(fontSize, weight: FontWeight.w800, color: foreground)
        : AppText.body(fontSize, weight: FontWeight.w700, color: foreground);
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(radius)),
      child: Text(text, style: style, softWrap: false),
    );
  }
}

/// Cartão branco com contorno.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child, this.padding = EdgeInsets.zero, this.radius = 16});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}

/// Cartão branco com linhas separadas por um traço de 1px.
class ListCard extends StatelessWidget {
  const ListCard({super.key, required this.children, this.radius = 16});

  final List<Widget> children;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      radius: radius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const ColoredBox(color: AppColors.border, child: SizedBox(height: 1)),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Filtro em pílula (44px). Selecionado = fundo escuro.
class PillChip extends StatelessWidget {
  const PillChip({super.key, required this.label, this.selected = false, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.ink : AppColors.white,
      shape: StadiumBorder(
        side: selected
            ? const BorderSide(color: AppColors.ink, width: 1.5)
            : const BorderSide(color: AppColors.inputBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppText.body(
              14,
              weight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? AppColors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Opção de escolha (nível / formato). Selecionado = lima com contorno de 2px.
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.lime : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected
            ? const BorderSide(color: AppColors.ink, width: 2)
            : const BorderSide(color: AppColors.inputBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Center(
            child: Text(
              label,
              style: AppText.body(14, weight: selected ? FontWeight.w700 : FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

/// Barra de progresso fina (6px).
class ThinBar extends StatelessWidget {
  const ThinBar({super.key, required this.value, required this.color, required this.track});

  final double value;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 6,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: track),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0, 1).toDouble(),
              child: DecoratedBox(
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

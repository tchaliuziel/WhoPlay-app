import 'package:flutter/material.dart';

import '../data/models.dart';
import '../services/api.dart';
import '../services/localizacao.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/async_view.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import 'home_shell.dart';

/// 02 Onboarding — desportos (passo 1 de 3)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late Future<List<Modalidade>> _modalidades = Api.modalidades();
  final _selected = <int>{};
  bool _aGuardar = false;

  void _toggle(int id) => setState(() {
        if (!_selected.remove(id)) _selected.add(id);
      });

  Future<void> _continuar() async {
    setState(() => _aGuardar = true);
    try {
      await Api.atualizarModalidades(_selected.toList());
      // Localização real (GPS + nome do sítio). Se o utilizador recusar ou
      // não houver GPS, fica o centro de Lisboa e pode mudar depois no perfil.
      try {
        await Localizacao.atualizarPerfil();
      } catch (_) {
        const l = Localizacao.lisboa;
        await Api.atualizarPerfil({'localidade': l.nome, 'latitude': l.latitude, 'longitude': l.longitude});
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell(initialTab: HomeShell.profileTab)),
        (_) => false,
      );
    } on ApiException catch (erro) {
      if (mounted) showInfo(context, erro.message);
    } finally {
      if (mounted) setState(() => _aGuardar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _selected.length;
    final countLabel = count == 1 ? '1 desporto escolhido' : '$count desportos escolhidos';

    return AnnotatedRegion(
      value: AppTheme.darkStatusIcons,
      child: Scaffold(
        body: FillScrollView(
          padding: EdgeInsets.fromLTRB(24, topInset(context, 56), 24, 28 + bottomInset(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _StepProgress(step: 1, total: 3),
              const SizedBox(height: 28),
              Text(
                'Que desportos queres jogar?',
                style: AppText.display(30, letterSpacing: -0.6, height: 1.12),
              ),
              const SizedBox(height: 8),
              Text(
                'Escolhe um ou mais. Podes mudar isto no teu perfil.',
                style: AppText.body(16, color: AppColors.muted, height: 1.45),
              ),
              const SizedBox(height: 24),
              AsyncView<List<Modalidade>>(
                future: _modalidades,
                onRetry: () => setState(() => _modalidades = Api.modalidades()),
                builder: (context, modalidades) => Column(
                  children: [
                    for (var i = 0; i < modalidades.length; i += 2) ...[
                      if (i > 0) const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _tile(modalidades[i])),
                          const SizedBox(width: 12),
                          Expanded(
                            child: i + 1 < modalidades.length ? _tile(modalidades[i + 1]) : const SizedBox(),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Spacer(),
              Text(
                '$countLabel · a seguir: nível e disponibilidade',
                textAlign: TextAlign.center,
                style: AppText.body(14, color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              AppButton(
                label: _aGuardar ? 'A guardar…' : 'Continuar',
                onPressed: count == 0 || _aGuardar ? null : _continuar,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(Modalidade modalidade) => _SportTile(
        modalidade: modalidade,
        selected: _selected.contains(modalidade.id),
        onTap: () => _toggle(modalidade.id),
      );
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              for (var i = 0; i < total; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: i < step ? AppColors.primary : AppColors.track,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Passo $step de $total',
          style: AppText.body(13, weight: FontWeight.w600, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _SportTile extends StatelessWidget {
  const _SportTile({required this.modalidade, required this.selected, required this.onTap});

  final Modalidade modalidade;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.lime : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: selected
              ? const BorderSide(color: AppColors.ink, width: 2)
              : const BorderSide(color: AppColors.inputBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 88,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        modalidade.nome,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.display(19),
                      ),
                    ),
                    if (selected)
                      const SvgIcon(AppIcon.check, size: 20, color: AppColors.ink, strokeWidth: 2.4),
                  ],
                ),
                Text(
                  modalidade.descricao,
                  style: AppText.body(
                    13,
                    weight: FontWeight.w500,
                    color: selected ? AppColors.ink : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

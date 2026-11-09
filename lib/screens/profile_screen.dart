
import 'package:flutter/material.dart';

import '../data/models.dart';
import '../services/api.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatos.dart';
import '../widgets/app_icons.dart';
import '../widgets/async_view.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import 'login_screen.dart';
import 'profile_edit_screen.dart';

/// 03 Perfil
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Perfil> _perfil = Api.perfil();

  Future<void> _editarPerfil(Perfil perfil) async {
    final atualizado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProfileEditScreen(perfil: perfil),
      ),
    );

    if (!mounted) return;

    if (atualizado == true) {
      setState(() {
        _perfil = Api.perfil();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<Perfil>(
      future: _perfil,
      onRetry: () => setState(() => _perfil = Api.perfil()),
      builder: (context, perfil) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            topInset(context, 52),
            20,
            20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const ScreenTitle('Perfil'),
                  AppButton.pill(
                    label: 'Editar',
                    onPressed: () => _editarPerfil(perfil),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _ProfileBody(perfil: perfil),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.perfil});

  final Perfil perfil;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.forest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Avatar(
                perfil.nome.isNotEmpty
                    ? perfil.nome.substring(0, 1)
                    : '?',
                size: 64,
                fontSize: 28,
                background: AppColors.lime,
                foreground: AppColors.ink,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      perfil.nome,
                      style: AppText.display(
                        22,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const SvgIcon(
                          AppIcon.pin,
                          size: 16,
                          color: AppColors.white,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${perfil.localidade ?? 'Sem localização'} · raio até ${perfil.raioKm} km',
                            style: AppText.body(
                              14,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Section(
          title: 'Desportos e nível',
          child: perfil.modalidades.isEmpty
              ? const EmptyText('Ainda não escolheste desportos.')
              : ListCard(
                  children: [
                    for (final m in perfil.modalidades)
                      _SportLevelRow(
                        m.nome,
                        m.nivel,
                        highlight: m.nivel != 'Iniciante',
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 18),
        Section(
          title: 'Disponibilidade',
          child: perfil.disponibilidade.isEmpty
              ? const EmptyText('Ainda não indicaste horários.')
              : ListCard(
                  children: [
                    for (final d in perfil.disponibilidade)
                      _AvailabilityRow(
                        nomeDoDia(d.diaSemana),
                        '${horaCurta(d.horaInicio)} – ${horaCurta(d.horaFim)}',
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 18),
        Section(
          title: 'Objetivo',
          child: SurfaceCard(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            child: Text(
              perfil.objetivo,
              style: AppText.body(
                16,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        AppButton.small(
          label: 'Terminar sessão',
          outlined: true,
          onPressed: () {
            Api.terminarSessao();

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => const LoginScreen(),
              ),
              (_) => false,
            );
          },
        ),
      ],
    );
  }
}

class _SportLevelRow extends StatelessWidget {
  const _SportLevelRow(
    this.sport,
    this.level, {
    this.highlight = false,
  });

  final String sport;
  final String level;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            sport,
            style: AppText.body(
              17,
              weight: FontWeight.w700,
            ),
          ),
          Tag(
            level,
            background: highlight ? AppColors.lime : AppColors.chip,
            radius: 14,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityRow extends StatelessWidget {
  const _AvailabilityRow(this.day, this.hours);

  final String day;
  final String hours;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: AppText.body(
              16,
              weight: FontWeight.w600,
            ),
          ),
          Text(
            hours,
            style: AppText.body(
              16,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

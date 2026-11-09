import 'package:flutter/material.dart';

import '../data/models.dart';
import '../services/api.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatos.dart';
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
  static const _modalidadeId = 1;
  static const _raioKm = 5;

  late Future<List<Jogador>> _jogadoresFuture;

  @override
  void initState() {
    super.initState();
    _carregarJogadores();
  }

  void _carregarJogadores() {
    _jogadoresFuture = Api.jogadores(
      modalidadeId: _modalidadeId,
      raioKm: _raioKm,
    );
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
          const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                PillChip(label: 'Padel', selected: true),
                SizedBox(width: 8),
                PillChip(label: 'Ténis'),
                SizedBox(width: 8),
                PillChip(label: 'Até 5 km'),
                SizedBox(width: 8),
                PillChip(label: 'Hoje'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<Jogador>>(
            future: _jogadoresFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                final mensagem = snapshot.error is ApiException
                    ? (snapshot.error as ApiException).message
                    : 'Não foi possível carregar os jogadores.';

                return Column(
                  children: [
                    Text(
                      mensagem,
                      textAlign: TextAlign.center,
                      style: AppText.body(14, color: AppColors.muted),
                    ),
                    const SizedBox(height: 12),
                    AppButton.small(
                      label: 'Tentar novamente',
                      onPressed: () {
                        setState(_carregarJogadores);
                      },
                    ),
                  ],
                );
              }

              final jogadores = snapshot.data ?? const <Jogador>[];

              if (jogadores.isEmpty) {
                return Column(
                  children: [
                    Text(
                      'Ainda não encontrámos jogadores compatíveis nesta modalidade e raio.',
                      textAlign: TextAlign.center,
                      style: AppText.body(14, color: AppColors.muted),
                    ),
                    const SizedBox(height: 12),
                    AppButton.small(
                      label: 'Atualizar pesquisa',
                      outlined: true,
                      onPressed: () {
                        setState(_carregarJogadores);
                      },
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${jogadores.length} jogadores compatíveis perto de ti',
                    style: AppText.body(14, color: AppColors.muted),
                  ),
                  const SizedBox(height: 14),
                  for (var i = 0; i < jogadores.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    PlayerCard(
                      jogador: jogadores[i],
                      modalidadeId: _modalidadeId,
                      onInviteSent: widget.onInviteSent,
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class PlayerCard extends StatelessWidget {
  const PlayerCard({
    super.key,
    required this.jogador,
    required this.modalidadeId,
    this.onInviteSent,
  });

  final Jogador jogador;
  final int modalidadeId;
  final VoidCallback? onInviteSent;

  Future<void> _verPerfil(BuildContext context) async {
    final enviado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PlayerProfileScreen(
          jogador: jogador,
          modalidadeId: modalidadeId,
        ),
      ),
    );

    if (enviado == true && context.mounted) {
      showInfo(context, 'Convite enviado a ${jogador.nome}.');
      onInviteSent?.call();
    }
  }

  Future<void> _convidar(BuildContext context) async {
    try {
      await Api.enviarConvite(
        jogadorId: jogador.id,
        modalidadeId: modalidadeId,
        dataHora: inicioConvite(jogador.disponivelHoje),
      );

      if (!context.mounted) return;

      showInfo(context, 'Convite enviado a ${jogador.nome}.');
      onInviteSent?.call();
    } on ApiException catch (erro) {
      if (context.mounted) {
        showInfo(context, erro.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final destaque = jogador.compatibilidade >= 80;
    final hoje = jogador.disponivelHoje;

    final availabilityColor =
        destaque && hoje != null ? AppColors.primary : AppColors.muted;

    return SurfaceCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Avatar(jogador.inicial),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jogador.nome,
                      style: AppText.body(17, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${jogador.modalidade} · ${jogador.nivel} · ${km(jogador.distanciaKm)}',
                      style: AppText.body(14, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Tag(
                '${jogador.compatibilidade}%',
                display: true,
                fontSize: 18,
                background: destaque ? AppColors.lime : AppColors.chip,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SvgIcon(
                AppIcon.clock,
                size: 16,
                color: availabilityColor,
              ),
              const SizedBox(width: 6),
              Text(
                hoje != null
                    ? 'Disponível hoje $hoje'
                    : 'Sem disponibilidade hoje',
                style: AppText.body(
                  14,
                  weight: FontWeight.w600,
                  color: availabilityColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton.small(
                  label: 'Ver perfil',
                  outlined: true,
                  onPressed: () => _verPerfil(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton.small(
                  label: 'Convidar',
                  onPressed: () => _convidar(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
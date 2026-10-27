import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';

/// 06 Convites e avisos
class InvitesScreen extends StatefulWidget {
  const InvitesScreen({super.key});

  @override
  State<InvitesScreen> createState() => _InvitesScreenState();
}

class _InvitesScreenState extends State<InvitesScreen> {
  String? _receivedAnswer;

  void _answer(bool accepted) {
    setState(() => _receivedAnswer = accepted ? 'Aceitaste o convite' : 'Recusaste o convite');
    showInfo(context, accepted ? 'Convite aceite.' : 'Convite recusado.');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, topInset(context, 52), 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenTitle('Convites'),
          const SizedBox(height: 16),
          const Section(
            title: 'Enviados',
            child: SurfaceCard(
              radius: 18,
              padding: EdgeInsets.all(14),
              child: Row(
                children: [
                  Avatar('T'),
                  SizedBox(width: 12),
                  Expanded(
                    child: _TitleSubtitle(title: 'Tchali', subtitle: 'Padel · hoje às 19:00'),
                  ),
                  SizedBox(width: 12),
                  Tag('A aguardar', fontSize: 13),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Section(
            title: 'Recebidos',
            child: SurfaceCard(
              radius: 18,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Avatar('C'),
                      SizedBox(width: 12),
                      Expanded(
                        child: _TitleSubtitle(
                          title: 'Cristiano convidou-te para jogar',
                          subtitle: 'Padel · quarta às 18:00 · 4,2 km',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_receivedAnswer == null)
                    Row(
                      children: [
                        Expanded(
                          child: AppButton.small(label: 'Recusar', outlined: true, onPressed: () => _answer(false)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: AppButton.small(label: 'Aceitar', onPressed: () => _answer(true))),
                      ],
                    )
                  else
                    SizedBox(
                      height: 44,
                      child: Center(
                        child: Text(
                          _receivedAnswer!,
                          style: AppText.body(15, weight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Section(
            title: 'Avisos',
            child: ListCard(
              radius: 18,
              children: [
                _NoticeRow('O Helio aceitou o teu convite', 'Há 5 minutos'),
                _NoticeRow('Falta 1 jogador para o teu jogo', 'Padel · sábado às 10:00'),
                _NoticeRow('Encontrámos 3 jogadores compatíveis perto de ti', 'Ontem', unread: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleSubtitle extends StatelessWidget {
  const _TitleSubtitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.body(16, weight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(subtitle, style: AppText.body(14, color: AppColors.muted)),
      ],
    );
  }
}

class _NoticeRow extends StatelessWidget {
  const _NoticeRow(this.title, this.subtitle, {this.unread = true});

  final String title;
  final String subtitle;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: unread ? AppColors.primary : AppColors.track,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.body(15, weight: unread ? FontWeight.w700 : FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppText.body(13, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

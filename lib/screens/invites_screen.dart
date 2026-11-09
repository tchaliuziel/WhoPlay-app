import 'package:flutter/material.dart';

import '../data/models.dart';
import '../services/api.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatos.dart';
import '../widgets/async_view.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';

typedef _DadosConvites = ({
  List<Convite> enviados,
  List<Convite> recebidos,
  List<Aviso> avisos,
});

/// 06 Convites e avisos.
class InvitesScreen extends StatefulWidget {
  const InvitesScreen({super.key});

  @override
  State<InvitesScreen> createState() => _InvitesScreenState();
}

class _InvitesScreenState extends State<InvitesScreen> {
  late Future<_DadosConvites> _dados = _carregar();

  Future<_DadosConvites> _carregar() async {
    final convites = await Api.convites();
    final avisos = await Api.avisos();

    return (
      enviados: convites.enviados,
      recebidos: convites.recebidos,
      avisos: avisos,
    );
  }

  void _recarregar() {
    setState(() {
      _dados = _carregar();
    });
  }

  Future<void> _answer(Convite convite, bool accepted) async {
    try {
      await Api.responderConvite(convite.id, aceitar: accepted);

      if (!mounted) return;

      showInfo(
        context,
        accepted ? 'Convite aceite.' : 'Convite recusado.',
      );

      _recarregar();
    } on ApiException catch (erro) {
      if (mounted) showInfo(context, erro.message);
    }
  }

  Future<void> _marcarAvisoLido(Aviso aviso) async {
    if (aviso.lida) return;

    try {
      await Api.marcarAvisoLido(aviso.id);

      if (!mounted) return;

      _recarregar();
    } on ApiException catch (erro) {
      if (mounted) showInfo(context, erro.message);
    }
  }

  Future<void> _marcarTodosLidos(List<Aviso> avisos) async {
    if (avisos.every((aviso) => aviso.lida)) return;

    try {
      await Api.marcarAvisosLidos();

      if (!mounted) return;

      showInfo(context, 'Todos os avisos foram marcados como lidos.');
      _recarregar();
    } on ApiException catch (erro) {
      if (mounted) showInfo(context, erro.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        _recarregar();
        await _dados;
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, topInset(context, 52), 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ScreenTitle('Convites'),
            const SizedBox(height: 16),
            AsyncView<_DadosConvites>(
              future: _dados,
              onRetry: _recarregar,
              builder: (context, dados) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Section(
                    title: 'Enviados',
                    child: dados.enviados.isEmpty
                        ? const EmptyText(
                            'Nenhum convite à espera de resposta.',
                          )
                        : Column(
                            children: [
                              for (final convite in dados.enviados) ...[
                                if (convite != dados.enviados.first)
                                  const SizedBox(height: 10),
                                _SentCard(convite),
                              ],
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  Section(
                    title: 'Recebidos',
                    child: dados.recebidos.isEmpty
                        ? const EmptyText(
                            'Não tens convites por responder.',
                          )
                        : Column(
                            children: [
                              for (final convite in dados.recebidos) ...[
                                if (convite != dados.recebidos.first)
                                  const SizedBox(height: 10),
                                _ReceivedCard(
                                  convite,
                                  onDecline: () => _answer(convite, false),
                                  onAccept: () => _answer(convite, true),
                                ),
                              ],
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  Section(
                    title: 'Avisos',
                    child: dados.avisos.isEmpty
                        ? const EmptyText('Sem avisos.')
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: dados.avisos.every((a) => a.lida)
                                      ? null
                                      : () => _marcarTodosLidos(dados.avisos),
                                  child: const Text('Marcar todos como lidos'),
                                ),
                              ),
                              ListCard(
                                radius: 18,
                                children: [
                                  for (final aviso in dados.avisos)
                                    _NoticeRow(
                                      aviso,
                                      onTap: () => _marcarAvisoLido(aviso),
                                    ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SentCard extends StatelessWidget {
  const _SentCard(this.convite);

  final Convite convite;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Avatar(convite.nome.isNotEmpty ? convite.nome.substring(0, 1) : '?'),
          const SizedBox(width: 12),
          Expanded(
            child: _TitleSubtitle(
              title: convite.nome,
              subtitle:
                  '${convite.modalidade} · ${diaHora(convite.dataHora)}',
            ),
          ),
          const SizedBox(width: 12),
          const Tag('A aguardar', fontSize: 13),
        ],
      ),
    );
  }
}

class _ReceivedCard extends StatelessWidget {
  const _ReceivedCard(
    this.convite, {
    required this.onDecline,
    required this.onAccept,
  });

  final Convite convite;
  final VoidCallback onDecline;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final distancia = convite.distanciaKm;

    return SurfaceCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Avatar(convite.nome.isNotEmpty ? convite.nome.substring(0, 1) : '?'),
              const SizedBox(width: 12),
              Expanded(
                child: _TitleSubtitle(
                  title: '${convite.nome} convidou-te para jogar',
                  subtitle: [
                    convite.modalidade,
                    diaHora(convite.dataHora),
                    if (distancia != null) km(distancia),
                  ].join(' · '),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton.small(
                  label: 'Recusar',
                  outlined: true,
                  onPressed: onDecline,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton.small(
                  label: 'Aceitar',
                  onPressed: onAccept,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TitleSubtitle extends StatelessWidget {
  const _TitleSubtitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppText.body(16, weight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: AppText.body(14, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _NoticeRow extends StatelessWidget {
  const _NoticeRow(
    this.aviso, {
    required this.onTap,
  });

  final Aviso aviso;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = aviso.detalhe.isNotEmpty
        ? aviso.detalhe
        : tempoRelativo(aviso.criadoEm);

    return InkWell(
      onTap: aviso.lida ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: aviso.lida ? AppColors.track : AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    aviso.titulo,
                    style: AppText.body(
                      15,
                      weight: aviso.lida
                          ? FontWeight.w600
                          : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppText.body(
                      13,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (!aviso.lida)
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 18,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

import 'dart:math' as math;

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
import 'checkin_screen.dart';
import 'scan_checkin_screen.dart';

/// 09 Detalhe do jogo
class GameDetailScreen extends StatefulWidget {
  const GameDetailScreen({super.key, required this.jogoId});

  final int jogoId;

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  late Future<Jogo> _jogo = Api.jogo(widget.jogoId);
  bool _aEntrar = false;

  void _recarregar() => setState(() => _jogo = Api.jogo(widget.jogoId));

  Future<void> _entrar(Jogo jogo) async {
    setState(() => _aEntrar = true);
    try {
      final codigo = await Api.entrarNoJogo(jogo.id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CheckInScreen(jogo: jogo, codigo: codigo),
        ),
      );
      _recarregar();
    } on ApiException catch (erro) {
      if (mounted) showInfo(context, erro.message);
    } finally {
      if (mounted) setState(() => _aEntrar = false);
    }
  }

  void _abrirLeitor(Jogo jogo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScanCheckInScreen(jogoId: jogo.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: AppTheme.lightStatusIcons,
      child: Scaffold(
        body: AsyncView<Jogo>(
          future: _jogo,
          onRetry: _recarregar,
          builder: (context, jogo) {
            final souOrganizador = jogo.participantes.any(
              (p) => p.organizador && p.id == Api.utilizadorId,
            );

            return _GameDetailBody(
              jogo: jogo,
              aEntrar: _aEntrar,
              souOrganizador: souOrganizador,
              onEnter: () => _entrar(jogo),
              onScanCheckIn: () => _abrirLeitor(jogo),
            );
          },
        ),
      ),
    );
  }
}

class _GameDetailBody extends StatelessWidget {
  const _GameDetailBody({
    required this.jogo,
    required this.aEntrar,
    required this.souOrganizador,
    required this.onEnter,
    required this.onScanCheckIn,
  });

  final Jogo jogo;
  final bool aEntrar;
  final bool souOrganizador;
  final VoidCallback onEnter;
  final VoidCallback onScanCheckIn;

  @override
  Widget build(BuildContext context) {
    final distancia = jogo.distanciaKm;
    // Lugares ocupados por pessoas que vão ao jogo mas não usam a app.
    final externos = jogo.ocupados - jogo.participantes.length;

    final String botao;
    if (jogo.euParticipo) {
      botao = 'Ver o meu QR Code';
    } else if (jogo.vagas > 0) {
      botao = aEntrar ? 'A entrar…' : 'Entrar no jogo';
    } else {
      botao = 'Jogo cheio';
    }

    final podeCarregar = !aEntrar && (jogo.euParticipo || jogo.vagas > 0);

    return FillScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.forest,
            padding: EdgeInsets.fromLTRB(20, topInset(context, 48), 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleIconButton(
                  semanticLabel: 'Voltar',
                  background: AppColors.forestLight,
                  bordered: false,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const SvgIcon(AppIcon.back, color: AppColors.white),
                ),
                const SizedBox(height: 14),
                SectionLabel(
                  '${jogo.modalidade} · ${jogo.formato}',
                  color: AppColors.lime,
                  letterSpacing: 1.2,
                ),
                const SizedBox(height: 14),
                Text(
                  dataLonga(jogo.dataHora),
                  style: AppText.display(
                    34,
                    weight: FontWeight.w800,
                    color: AppColors.white,
                    letterSpacing: -0.8,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const SvgIcon(AppIcon.pin, size: 18, color: AppColors.white),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        distancia == null || distancia < 0.1
                            ? jogo.localNome
                            : '${jogo.localNome} · a ${km(distancia)} de ti',
                        style: AppText.body(15, color: AppColors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                28 + bottomInset(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _StatCell('Nível', jogo.nivel)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatCell(
                            'Jogadores',
                            '${jogo.ocupados} de ${jogo.capacidade}',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatCell(
                            'Preço',
                            '${euros(jogo.preco)} / pessoa',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Section(
                    title: 'Quem vai',
                    child: ListCard(
                      children: [
                        for (final p in jogo.participantes) _ParticipantRow(p),
                        if (externos > 0) _ExternalRow(externos),
                        if (jogo.vagas > 0) _OpenSlotRow(jogo.vagas),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Spacer(),
                  Text(
                    jogo.euParticipo
                        ? 'Já estás neste jogo.'
                        : 'O organizador é avisado assim que entrares.',
                    textAlign: TextAlign.center,
                    style: AppText.body(14, color: AppColors.muted),
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: botao,
                    onPressed: podeCarregar ? onEnter : null,
                  ),
                  if (souOrganizador) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: onScanCheckIn,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Validar QR Code dos participantes'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.forest,
                        side: const BorderSide(color: AppColors.forest),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      radius: 14,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.body(12, color: AppColors.muted)),
          const SizedBox(height: 4),
          Text(value, style: AppText.body(15, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow(this.participante);

  final Participante participante;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Avatar(participante.nome.substring(0, 1), size: 40, fontSize: 17),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              participante.nome,
              style: AppText.body(16, weight: FontWeight.w700),
            ),
          ),
          if (participante.organizador)
            const Tag(
              'Organizador',
              fontSize: 13,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            )
          else
            Text(
              participante.nivel ?? '',
              style: AppText.body(14, color: AppColors.muted),
            ),
        ],
      ),
    );
  }
}

class _ExternalRow extends StatelessWidget {
  const _ExternalRow(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Avatar(
            '+$count',
            size: 40,
            fontSize: 15,
            background: AppColors.chip,
            foreground: AppColors.muted,
          ),
          const SizedBox(width: 12),
          Text(
            count == 1
                ? '1 jogador de fora da app'
                : '$count jogadores de fora da app',
            style: AppText.body(
              16,
              weight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenSlotRow extends StatelessWidget {
  const _OpenSlotRow(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const CustomPaint(
            painter: _DashedCirclePainter(color: AppColors.primary),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: SvgIcon(
                  AppIcon.plus,
                  size: 20,
                  color: AppColors.primary,
                  strokeWidth: 2.2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            count == 1 ? '1 vaga livre' : '$count vagas livres',
            style: AppText.body(
              16,
              weight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Círculo tracejado (border: 2px dashed) da vaga livre.
class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 2.0;
    const dashes = 14;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    const sweep = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * sweep, sweep * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}

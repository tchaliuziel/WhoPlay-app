import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/models.dart';
import '../services/api.dart';
import '../services/localizacao.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatos.dart';
import '../widgets/app_icons.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import 'game_detail_screen.dart';
import 'player_profile_screen.dart';

/// 08 Mapa — mapa real do OpenStreetMap com a tua posição, os jogos abertos
/// e os jogadores compatíveis dentro do teu raio.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _raios = [2, 5, 10, 20, 50];

  final _mapa = MapController();

  Perfil? _perfil;
  List<Modalidade> _modalidades = [];
  List<Jogo> _jogos = [];
  List<Jogador> _jogadores = [];

  int? _modalidadeId;
  int _raioKm = 5;
  bool _verJogos = true;
  bool _verJogadores = true;

  bool _aCarregar = true;
  bool _aLocalizar = false;
  String? _erro;

  /// Marcador escolhido (um [Jogo] ou um [Jogador]).
  Object? _escolhido;

  @override
  void initState() {
    super.initState();
    _carregar(primeiraVez: true);
  }

  LatLng get _centro {
    final p = _perfil;
    if (p?.latitude != null && p?.longitude != null) return LatLng(p!.latitude!, p.longitude!);
    return const LatLng(38.7223, -9.1393);
  }

  bool get _temPosicao => _perfil?.latitude != null;

  /// Zoom que mostra mais ou menos o círculo do raio inteiro.
  double get _zoom => switch (_raioKm) {
        <= 2 => 14.2,
        <= 5 => 12.9,
        <= 10 => 11.9,
        <= 20 => 10.9,
        _ => 9.6,
      };

  Future<void> _carregar({bool primeiraVez = false}) async {
    setState(() {
      _aCarregar = true;
      _erro = null;
    });
    try {
      final perfil = await Api.perfil();
      if (primeiraVez) {
        _modalidades = await Api.modalidades();
        _raioKm = _raios.firstWhere((r) => r >= perfil.raioKm, orElse: () => _raios.last);
        _modalidadeId = perfil.modalidades.isNotEmpty ? perfil.modalidades.first.id : _modalidades.first.id;
      }
      final modalidade = _modalidadeId ?? 1;

      final jogos = await Api.jogos(modalidadeId: modalidade);
      var jogadores = <Jogador>[];
      if (perfil.latitude != null) {
        try {
          jogadores = await Api.jogadores(modalidadeId: modalidade, raioKm: _raioKm);
        } on ApiException {
          jogadores = [];
        }
      }

      if (!mounted) return;
      setState(() {
        _perfil = perfil;
        _jogos = jogos.where((j) => j.latitude != null && j.longitude != null).toList();
        _jogadores = jogadores.where((j) => j.latitude != null && j.longitude != null).toList();
        _escolhido = null;
        _aCarregar = false;
      });
      if (primeiraVez) _mapa.move(_centro, _zoom);
    } on ApiException catch (erro) {
      if (mounted) {
        setState(() {
          _erro = erro.message;
          _aCarregar = false;
        });
      }
    }
  }

  Future<void> _localizar() async {
    setState(() => _aLocalizar = true);
    try {
      final local = await Localizacao.atualizarPerfil();
      if (!mounted) return;
      showInfo(context, local.nome == null ? 'Localização atualizada.' : 'Estás em ${local.nome}.');
      await _carregar();
      _mapa.move(_centro, _zoom);
    } on ApiException catch (erro) {
      if (mounted) showInfo(context, erro.message);
    } catch (_) {
      if (mounted) showInfo(context, 'Não foi possível obter a localização.');
    } finally {
      if (mounted) setState(() => _aLocalizar = false);
    }
  }

  void _mudarRaio() {
    final i = _raios.indexOf(_raioKm);
    setState(() => _raioKm = _raios[(i + 1) % _raios.length]);
    _mapa.move(_centro, _zoom);
    _carregar();
  }

  void _escolher(Object item, LatLng ponto) {
    setState(() => _escolhido = item);
    _mapa.move(ponto, _mapa.camera.zoom);
  }

  @override
  Widget build(BuildContext context) {
    final nomeModalidade =
        _modalidades.where((m) => m.id == _modalidadeId).map((m) => m.nome).firstOrNull ?? 'Desporto';

    return ColoredBox(
      color: AppColors.mapLand,
      child: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapa,
              options: MapOptions(
                initialCenter: _centro,
                initialZoom: _zoom,
                minZoom: 5,
                maxZoom: 18,
                backgroundColor: AppColors.mapLand,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onTap: (_, __) => setState(() => _escolhido = null),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'pt.whoplay.app',
                  maxZoom: 19,
                ),
                if (_temPosicao)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _centro,
                        radius: _raioKm * 1000,
                        useRadiusInMeter: true,
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderColor: AppColors.primary,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (_verJogadores)
                      for (final j in _jogadores)
                        Marker(
                          point: LatLng(j.latitude!, j.longitude!),
                          width: 46,
                          height: 46,
                          child: GestureDetector(
                            onTap: () => _escolher(j, LatLng(j.latitude!, j.longitude!)),
                            child: _MarcadorJogador(
                              inicial: j.nome.isEmpty ? '?' : j.nome[0].toUpperCase(),
                              ativo: identical(_escolhido, j),
                            ),
                          ),
                        ),
                    if (_verJogos)
                      for (final j in _jogos)
                        Marker(
                          point: LatLng(j.latitude!, j.longitude!),
                          width: 52,
                          height: 52,
                          child: GestureDetector(
                            onTap: () => _escolher(j, LatLng(j.latitude!, j.longitude!)),
                            child: _MarcadorJogo(ativo: identical(_escolhido, j)),
                          ),
                        ),
                    if (_temPosicao)
                      Marker(point: _centro, width: 56, height: 56, child: const _MarcadorTu()),
                  ],
                ),
              ],
            ),
          ),

          // Filtros (pílulas), como no mockup.
          Positioned(
            left: 0,
            right: 0,
            top: topInset(context, 52),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  PopupMenuButton<int>(
                    tooltip: 'Escolher desporto',
                    color: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    onSelected: (id) {
                      setState(() => _modalidadeId = id);
                      _carregar();
                    },
                    itemBuilder: (_) => [
                      for (final m in _modalidades)
                        PopupMenuItem(value: m.id, child: Text(m.nome, style: AppText.body(15, weight: FontWeight.w600))),
                    ],
                    child: IgnorePointer(child: PillChip(label: '$nomeModalidade ▾', selected: true)),
                  ),
                  const SizedBox(width: 8),
                  PillChip(label: 'Raio $_raioKm km', onTap: _mudarRaio),
                  const SizedBox(width: 8),
                  PillChip(
                    label: 'Jogos',
                    selected: _verJogos,
                    onTap: () => setState(() => _verJogos = !_verJogos),
                  ),
                  const SizedBox(width: 8),
                  PillChip(
                    label: 'Jogadores',
                    selected: _verJogadores,
                    onTap: () => setState(() => _verJogadores = !_verJogadores),
                  ),
                ],
              ),
            ),
          ),

          // Botão "onde estou" + créditos do OpenStreetMap (obrigatórios).
          Positioned(
            right: 16,
            top: topInset(context, 52) + 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CircleIconButton(
                  semanticLabel: 'Usar a minha localização',
                  onPressed: _aLocalizar ? null : _localizar,
                  child: _aLocalizar
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      : const SvgIcon(AppIcon.pin, size: 20, color: AppColors.primary),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            top: topInset(context, 52) + 58,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('© OpenStreetMap', style: AppText.body(11, color: AppColors.muted)),
            ),
          ),

          Positioned(left: 16, right: 16, bottom: 16, child: _cartao()),
        ],
      ),
    );
  }

  Widget _cartao() {
    if (_aCarregar && _perfil == null) {
      return const SurfaceCard(
        radius: 20,
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_erro != null) {
      return _CartaoBase(
        titulo: 'Não foi possível carregar o mapa',
        texto: _erro!,
        botao: AppButton.small(label: 'Tentar outra vez', outlined: true, onPressed: () => _carregar(primeiraVez: _perfil == null)),
      );
    }

    if (!_temPosicao) {
      return _CartaoBase(
        titulo: 'Onde estás?',
        texto: 'Partilha a tua localização para veres jogos e jogadores perto de ti.',
        botao: AppButton.small(
          label: _aLocalizar ? 'A obter localização…' : 'Usar a minha localização',
          onPressed: _aLocalizar ? null : _localizar,
        ),
      );
    }

    final item = _escolhido;
    if (item is Jogo) return _CartaoJogo(jogo: item);
    if (item is Jogador) return _CartaoJogador(jogador: item, modalidadeId: _modalidadeId ?? 1);

    final jogos = _verJogos ? _jogos.length : 0;
    final jogadores = _verJogadores ? _jogadores.length : 0;
    return _CartaoBase(
      titulo: _perfil?.localidade ?? 'A tua zona',
      texto: '${jogos == 1 ? '1 jogo' : '$jogos jogos'} e '
          '${jogadores == 1 ? '1 jogador' : '$jogadores jogadores'} até $_raioKm km. '
          'Toca num marcador para ver mais.',
    );
  }
}

// ==================================================================== Cartões

class _CartaoBase extends StatelessWidget {
  const _CartaoBase({required this.titulo, required this.texto, this.botao});

  final String titulo;
  final String texto;
  final Widget? botao;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(titulo, style: AppText.display(20)),
          const SizedBox(height: 4),
          Text(texto, style: AppText.body(14, color: AppColors.muted, height: 1.4)),
          if (botao != null) ...[const SizedBox(height: 12), botao!],
        ],
      ),
    );
  }
}

class _CartaoJogo extends StatelessWidget {
  const _CartaoJogo({required this.jogo});

  final Jogo jogo;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jogo de ${jogo.modalidade}', style: AppText.display(20)),
                    const SizedBox(height: 3),
                    Text(
                      '${dataCurta(jogo.dataHora)} · ${jogo.localNome}',
                      style: AppText.body(14, color: AppColors.muted),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        jogo.nivel,
                        if (jogo.distanciaKm != null) 'a ${km(jogo.distanciaKm!)} de ti',
                      ].join(' · '),
                      style: AppText.body(14, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Tag('${jogo.ocupados} / ${jogo.capacidade}', background: AppColors.lime),
            ],
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Ver jogo',
            height: 48,
            radius: 12,
            fontSize: 16,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => GameDetailScreen(jogoId: jogo.id)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoJogador extends StatelessWidget {
  const _CartaoJogador({required this.jogador, required this.modalidadeId});

  final Jogador jogador;
  final int modalidadeId;

  @override
  Widget build(BuildContext context) {
    final alta = jogador.compatibilidade >= 80;
    return SurfaceCard(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Avatar(jogador.nome.isEmpty ? '?' : jogador.nome[0].toUpperCase()),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(jogador.nome, style: AppText.body(17, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      '${jogador.modalidade} · ${jogador.nivel} · ${km(jogador.distanciaKm)}',
                      style: AppText.body(14, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Tag(
                '${jogador.compatibilidade}%',
                background: alta ? AppColors.lime : AppColors.chip,
                display: true,
                fontSize: 18,
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Ver perfil',
            height: 48,
            radius: 12,
            fontSize: 16,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PlayerProfileScreen(jogador: jogador, modalidadeId: modalidadeId),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================== Marcadores

class _MarcadorTu extends StatelessWidget {
  const _MarcadorTu();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 4),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Text('Tu', style: AppText.body(15, weight: FontWeight.w700, color: AppColors.white)),
    );
  }
}

class _MarcadorJogador extends StatelessWidget {
  const _MarcadorJogador({required this.inicial, required this.ativo});

  final String inicial;
  final bool ativo;

  @override
  Widget build(BuildContext context) {
    return Avatar(
      inicial,
      size: 46,
      fontSize: 18,
      borderWidth: 3,
      background: ativo ? AppColors.lime : AppColors.forest,
      foreground: ativo ? AppColors.ink : AppColors.lime,
    );
  }
}

class _MarcadorJogo extends StatelessWidget {
  const _MarcadorJogo({required this.ativo});

  final bool ativo;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ativo ? AppColors.ink : AppColors.lime,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ink, width: 3),
      ),
      child: SvgIcon(AppIcon.pin, size: 24, color: ativo ? AppColors.lime : AppColors.ink),
    );
  }
}

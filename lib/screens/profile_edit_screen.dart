import 'package:flutter/material.dart';

import '../data/models.dart';
import '../services/api.dart';
import '../services/localizacao.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatos.dart';
import '../widgets/app_icons.dart';
import '../widgets/async_view.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import '../widgets/fields.dart';

/// 03b Editar perfil — mesmo estilo visual do Perfil e do Criar jogo.
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key, required this.perfil});

  final Perfil perfil;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late final TextEditingController _nome;
  late final TextEditingController _localidade;

  late int _raioKm;
  late String _objetivo;

  List<Modalidade> _modalidadesDisponiveis = [];
  final Map<int, String> _modalidadesSelecionadas = {};

  final Map<int, bool> _diasSelecionados = {};
  final Map<int, TimeOfDay> _horasInicio = {};
  final Map<int, TimeOfDay> _horasFim = {};

  /// Coordenadas escolhidas com "Usar a minha localização".
  Local? _posicao;
  bool _aLocalizar = false;

  bool _aCarregar = true;
  bool _aGuardar = false;
  String? _erro;

  static const _niveis = ['Iniciante', 'Intermédio', 'Avançado'];

  /// Valores aceites pela coluna `objetivo` da base de dados.
  static const _objetivos = ['Jogos amigáveis', 'Jogos competitivos', 'Treino'];

  @override
  void initState() {
    super.initState();

    _nome = TextEditingController(text: widget.perfil.nome);
    _localidade = TextEditingController(text: widget.perfil.localidade ?? '');
    _raioKm = widget.perfil.raioKm.clamp(1, 50).toInt();
    _objetivo = _objetivos.contains(widget.perfil.objetivo) ? widget.perfil.objetivo : _objetivos.first;

    for (final modalidade in widget.perfil.modalidades) {
      _modalidadesSelecionadas[modalidade.id] = modalidade.nivel;
    }

    for (var dia = 1; dia <= 7; dia++) {
      _diasSelecionados[dia] = false;
      _horasInicio[dia] = const TimeOfDay(hour: 18, minute: 0);
      _horasFim[dia] = const TimeOfDay(hour: 20, minute: 0);
    }

    for (final d in widget.perfil.disponibilidade) {
      if (d.diaSemana < 1 || d.diaSemana > 7) continue;
      _diasSelecionados[d.diaSemana] = true;
      _horasInicio[d.diaSemana] = _lerHora(d.horaInicio);
      _horasFim[d.diaSemana] = _lerHora(d.horaFim);
    }

    _carregarModalidades();
  }

  TimeOfDay _lerHora(String hora) {
    final partes = hora.split(':');
    return TimeOfDay(
      hour: int.tryParse(partes[0]) ?? 18,
      minute: partes.length > 1 ? int.tryParse(partes[1]) ?? 0 : 0,
    );
  }

  Future<void> _carregarModalidades() async {
    setState(() {
      _aCarregar = true;
      _erro = null;
    });
    try {
      final modalidades = await Api.modalidades();
      if (!mounted) return;
      setState(() {
        _modalidadesDisponiveis = modalidades;
        _aCarregar = false;
      });
    } on ApiException catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = erro.message;
        _aCarregar = false;
      });
    }
  }

  String _formatarHora(TimeOfDay hora) =>
      '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';

  int _minutos(TimeOfDay hora) => hora.hour * 60 + hora.minute;

  Future<void> _escolherHora(int dia, bool inicio) async {
    final escolhida = await showTimePicker(
      context: context,
      initialTime: inicio ? _horasInicio[dia]! : _horasFim[dia]!,
    );
    if (escolhida == null || !mounted) return;
    setState(() => (inicio ? _horasInicio : _horasFim)[dia] = escolhida);
  }

  Future<void> _usarLocalizacao() async {
    setState(() => _aLocalizar = true);
    try {
      final posicao = await Localizacao.posicaoAtual();
      final nome = await Localizacao.nomeDoSitio(posicao.latitude, posicao.longitude);
      if (!mounted) return;
      setState(() {
        _posicao = posicao;
        if (nome != null) _localidade.text = nome;
      });
      showInfo(context, nome == null ? 'Localização obtida.' : 'Estás em $nome.');
    } on ApiException catch (erro) {
      if (mounted) showInfo(context, erro.message);
    } catch (_) {
      if (mounted) showInfo(context, 'Não foi possível obter a localização.');
    } finally {
      if (mounted) setState(() => _aLocalizar = false);
    }
  }

  void _alternarModalidade(int id) => setState(() {
        if (_modalidadesSelecionadas.remove(id) == null) {
          _modalidadesSelecionadas[id] = 'Iniciante';
        }
      });

  Future<void> _guardar() async {
    if (_nome.text.trim().isEmpty) {
      showInfo(context, 'Indica o teu nome.');
      return;
    }
    if (_modalidadesSelecionadas.isEmpty) {
      showInfo(context, 'Escolhe pelo menos um desporto.');
      return;
    }

    final disponibilidade = <Map<String, Object?>>[];
    for (var dia = 1; dia <= 7; dia++) {
      if (_diasSelecionados[dia] != true) continue;
      final inicio = _horasInicio[dia]!;
      final fim = _horasFim[dia]!;
      if (_minutos(fim) <= _minutos(inicio)) {
        showInfo(context, 'Em ${nomeDoDia(dia)}, a hora de fim tem de ser depois da de início.');
        return;
      }
      disponibilidade.add({
        'dia_semana': dia,
        'hora_inicio': _formatarHora(inicio),
        'hora_fim': _formatarHora(fim),
      });
    }

    setState(() => _aGuardar = true);
    try {
      // Sem GPS mas com a localidade mudada à mão → procurar as coordenadas.
      final localidade = _localidade.text.trim();
      var posicao = _posicao;
      if (posicao == null && localidade.isNotEmpty && localidade != (widget.perfil.localidade ?? '')) {
        posicao = await Localizacao.procurar(localidade);
      }

      await Api.atualizarPerfil({
        'nome': _nome.text.trim(),
        'localidade': localidade.isEmpty ? null : localidade,
        if (posicao != null) 'latitude': double.parse(posicao.latitude.toStringAsFixed(6)),
        if (posicao != null) 'longitude': double.parse(posicao.longitude.toStringAsFixed(6)),
        'raio_km': _raioKm,
        'objetivo': _objetivo,
      });
      await Api.atualizarModalidadesDetalhadas(_modalidadesSelecionadas);
      await Api.atualizarDisponibilidade(disponibilidade);

      if (!mounted) return;
      showInfo(context, 'Perfil atualizado.');
      Navigator.of(context).pop(true);
    } on ApiException catch (erro) {
      if (mounted) showInfo(context, erro.message);
    } catch (erro) {
      if (mounted) showInfo(context, 'Não foi possível atualizar o perfil.');
    } finally {
      if (mounted) setState(() => _aGuardar = false);
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _localidade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: AppTheme.darkStatusIcons,
      child: Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, topInset(context, 48), 20, 28 + bottomInset(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleIconButton(
                    semanticLabel: 'Voltar',
                    onPressed: () => Navigator.of(context).pop(),
                    child: const SvgIcon(AppIcon.back),
                  ),
                  const SizedBox(width: 12),
                  const ScreenTitle('Editar perfil'),
                ],
              ),
              const SizedBox(height: 18),
              if (_aCarregar)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              else if (_erro != null)
                _Erro(mensagem: _erro!, onRetry: _carregarModalidades)
              else
                ..._formulario(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _formulario() {
    final escolhidas = _modalidadesDisponiveis.where((m) => _modalidadesSelecionadas.containsKey(m.id)).toList();

    return [
      Section(
        title: 'Dados pessoais',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(label: 'Nome', controller: _nome, weight: FontWeight.w600),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Email (não pode ser alterado)',
              initialValue: widget.perfil.email,
              readOnly: true,
            ),
            const SizedBox(height: 16),
            AppTextField(label: 'Localidade', controller: _localidade, weight: FontWeight.w600),
            const SizedBox(height: 10),
            AppButton.small(
              label: _aLocalizar
                  ? 'A obter localização…'
                  : (_posicao == null ? 'Usar a minha localização atual' : 'Localização atualizada ✓'),
              outlined: true,
              onPressed: _aLocalizar ? null : _usarLocalizacao,
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Section(
        title: 'Raio de procura',
        child: SurfaceCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Procurar jogadores até', style: AppText.body(16, weight: FontWeight.w600)),
                  Tag('$_raioKm km', background: AppColors.lime, radius: 14),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.track,
                  thumbColor: AppColors.primary,
                  overlayColor: AppColors.primary.withValues(alpha: 0.12),
                  trackHeight: 6,
                  showValueIndicator: ShowValueIndicator.never,
                ),
                child: Slider(
                  value: _raioKm.toDouble(),
                  min: 1,
                  max: 50,
                  divisions: 49,
                  onChanged: (v) => setState(() => _raioKm = v.round()),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      Section(
        title: 'Objetivo',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < _objetivos.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              ChoiceTile(
                label: _objetivos[i],
                selected: _objetivo == _objetivos[i],
                onTap: () => setState(() => _objetivo = _objetivos[i]),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 24),
      Section(
        title: 'Desportos e nível',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in _modalidadesDisponiveis)
                  PillChip(
                    label: m.nome,
                    selected: _modalidadesSelecionadas.containsKey(m.id),
                    onTap: () => _alternarModalidade(m.id),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (escolhidas.isEmpty)
              const EmptyText('Escolhe pelo menos um desporto.')
            else
              ListCard(
                children: [
                  for (final m in escolhidas)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(m.nome, style: AppText.body(17, weight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              for (var i = 0; i < _niveis.length; i++) ...[
                                if (i > 0) const SizedBox(width: 8),
                                Expanded(
                                  child: ChoiceTile(
                                    label: _niveis[i],
                                    selected: _modalidadesSelecionadas[m.id] == _niveis[i],
                                    onTap: () => setState(() => _modalidadesSelecionadas[m.id] = _niveis[i]),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Section(
        title: 'Disponibilidade',
        child: ListCard(
          children: [
            for (var dia = 1; dia <= 7; dia++) _linhaDia(dia),
          ],
        ),
      ),
      const SizedBox(height: 28),
      AppButton(
        label: _aGuardar ? 'A guardar…' : 'Guardar alterações',
        onPressed: _aGuardar ? null : _guardar,
      ),
      const SizedBox(height: 12),
      AppButton.small(
        label: 'Cancelar',
        outlined: true,
        onPressed: _aGuardar ? null : () => Navigator.of(context).pop(),
      ),
    ];
  }

  Widget _linhaDia(int dia) {
    final ativo = _diasSelecionados[dia] == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _diasSelecionados[dia] = !ativo),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(child: Text(nomeDoDia(dia), style: AppText.body(16, weight: FontWeight.w600))),
                _Visto(ativo: ativo),
              ],
            ),
          ),
        ),
        if (ativo)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _CampoHora(
                    label: 'Das',
                    valor: _formatarHora(_horasInicio[dia]!),
                    onTap: () => _escolherHora(dia, true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CampoHora(
                    label: 'Às',
                    valor: _formatarHora(_horasFim[dia]!),
                    onTap: () => _escolherHora(dia, false),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Caixa de verificação no estilo dos cartões de desporto (lima + visto).
class _Visto extends StatelessWidget {
  const _Visto({required this.ativo});

  final bool ativo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: ativo ? AppColors.lime : AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ativo ? AppColors.ink : AppColors.inputBorder, width: ativo ? 2 : 1),
      ),
      child: ativo ? const Center(child: SvgIcon(AppIcon.check, size: 16, color: AppColors.ink, strokeWidth: 2.6)) : null,
    );
  }
}

class _CampoHora extends StatelessWidget {
  const _CampoHora({required this.label, required this.valor, required this.onTap});

  final String label;
  final String valor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: FieldBox(
          child: Row(
            children: [
              Expanded(child: Text(valor, style: AppText.body(16, weight: FontWeight.w600))),
              const SvgIcon(AppIcon.clock, size: 18, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Erro extends StatelessWidget {
  const _Erro({required this.mensagem, required this.onRetry});

  final String mensagem;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Text(mensagem, textAlign: TextAlign.center, style: AppText.body(16, color: AppColors.muted)),
          const SizedBox(height: 16),
          AppButton.small(label: 'Tentar novamente', outlined: true, onPressed: onRetry),
        ],
      ),
    );
  }
}

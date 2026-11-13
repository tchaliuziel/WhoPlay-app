import 'package:flutter/material.dart';

import '../data/models.dart';
import '../services/api.dart';
import '../services/localizacao.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatos.dart';
import '../widgets/app_icons.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import '../widgets/fields.dart';
import 'game_detail_screen.dart';

const _levels = ['Iniciante', 'Intermédio', 'Avançado'];
const _formats = ['Amigável', 'Competitivo'];

/// 07 Criar jogo
class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key});

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  static const _capacity = 4;

  final Future<List<Modalidade>> _modalidades = Api.modalidades();
  int _modalidadeId = 1;
  DateTime _date = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  String _level = 'Intermédio';
  String _format = 'Amigável';
  int _openSlots = 1;
  bool _aCriar = false;

  late final _dateCtrl = TextEditingController(text: dataCampo(_date));
  late final _timeCtrl = TextEditingController(text: _formatTime(_time));
  final _localCtrl = TextEditingController(text: 'Padel Club X');
  final _precoCtrl = TextEditingController(text: '8 €');

  @override
  void dispose() {
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    _localCtrl.dispose();
    _precoCtrl.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateUtils.dateOnly(DateTime.now()),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _dateCtrl.text = dataCampo(picked);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked == null) return;
    setState(() {
      _time = picked;
      _timeCtrl.text = _formatTime(picked);
    });
  }

  Future<void> _criar() async {
    // "8 €" → 8.0 · "7,50" → 7.5
    final preco = double.tryParse(_precoCtrl.text.replaceAll(RegExp(r'[^0-9,.]'), '').replaceAll(',', '.')) ?? 0;
    setState(() => _aCriar = true);
    try {
      // Converte o texto do "Local" em coordenadas (Nominatim), procurando
      // primeiro perto de ti. Se não encontrar, a API usa a tua posição.
      final eu = await Api.perfil();
      final sitio = await Localizacao.procurar(
        _localCtrl.text,
        perto: eu.latitude == null ? null : Local(eu.latitude!, eu.longitude!),
      );
      final id = await Api.criarJogo(
        modalidadeId: _modalidadeId,
        dataHora: DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute),
        local: _localCtrl.text.trim(),
        nivel: _level,
        formato: _format,
        capacidade: _capacity,
        vagasAbertas: _openSlots,
        preco: preco,
        latitude: sitio?.latitude,
        longitude: sitio?.longitude,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => GameDetailScreen(jogoId: id)));
    } on ApiException catch (erro) {
      if (mounted) showInfo(context, erro.message);
    } finally {
      if (mounted) setState(() => _aCriar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: AppTheme.darkStatusIcons,
      child: Scaffold(
        body: FillScrollView(
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
                  const ScreenTitle('Criar jogo'),
                ],
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Modalidade>>(
                future: _modalidades,
                builder: (context, snapshot) {
                  final lista = snapshot.data ?? const [Modalidade(id: 1, nome: 'Padel', descricao: '')];
                  return AppDropdown<int>(
                    label: 'Desporto',
                    value: _modalidadeId,
                    items: {for (final m in lista) m.id: m.nome},
                    onChanged: (v) => setState(() => _modalidadeId = v ?? _modalidadeId),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: AppTextField(
                      label: 'Data',
                      controller: _dateCtrl,
                      weight: FontWeight.w600,
                      readOnly: true,
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AppTextField(
                      label: 'Hora',
                      controller: _timeCtrl,
                      weight: FontWeight.w600,
                      readOnly: true,
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(label: 'Local', controller: _localCtrl, weight: FontWeight.w600),
              const SizedBox(height: 16),
              _ChoiceGroup(
                label: 'Nível',
                options: _levels,
                selected: _level,
                onSelected: (v) => setState(() => _level = v),
              ),
              const SizedBox(height: 16),
              _ChoiceGroup(
                label: 'Formato',
                options: _formats,
                selected: _format,
                onSelected: (v) => setState(() => _format = v),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 3,
                    child: LabeledField(
                      label: 'Vagas abertas',
                      child: FieldBox(
                        horizontalPadding: 4,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _StepperButton(
                              label: '−',
                              semanticLabel: 'Menos uma vaga',
                              onTap: _openSlots > 1 ? () => setState(() => _openSlots--) : null,
                            ),
                            Text('$_openSlots de $_capacity', style: AppText.body(16, weight: FontWeight.w700)),
                            _StepperButton(
                              label: '+',
                              semanticLabel: 'Mais uma vaga',
                              onTap: _openSlots < _capacity - 1 ? () => setState(() => _openSlots++) : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AppTextField(
                      label: 'Preço por pessoa',
                      controller: _precoCtrl,
                      weight: FontWeight.w600,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Spacer(),
              AppButton(label: _aCriar ? 'A criar…' : 'Criar jogo', onPressed: _aCriar ? null : _criar),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceGroup extends StatelessWidget {
  const _ChoiceGroup({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: label,
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: ChoiceTile(
                label: options[i],
                selected: options[i] == selected,
                onTap: () => onSelected(options[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.label, required this.semanticLabel, this.onTap});

  final String label;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Text(
                label,
                style: AppText.body(
                  20,
                  weight: FontWeight.w700,
                  color: onTap == null ? AppColors.muted : AppColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

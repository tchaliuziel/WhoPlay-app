import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import '../widgets/fields.dart';
import 'game_detail_screen.dart';

/// 07 Criar jogo
class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key});

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  static const _weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  static const _months = [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
  ];
  static const _capacity = 4;

  String _sport = 'Padel';
  DateTime _date = DateTime(2026, 10, 3);
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  String _level = 'Intermédio';
  String _format = 'Amigável';
  int _openSlots = 1;

  late final _dateCtrl = TextEditingController(text: _formatDate(_date));
  late final _timeCtrl = TextEditingController(text: _formatTime(_time));

  @override
  void dispose() {
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) => '${_weekdays[d.weekday - 1]}, ${d.day} de ${_months[d.month - 1]}';

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _dateCtrl.text = _formatDate(picked);
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
              AppDropdown<String>(
                label: 'Desporto',
                value: _sport,
                items: {for (final s in sports) s.name: s.name},
                onChanged: (v) => setState(() => _sport = v ?? _sport),
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
              const AppTextField(label: 'Local', initialValue: 'Padel Club X', weight: FontWeight.w600),
              const SizedBox(height: 16),
              _ChoiceGroup(
                label: 'Nível',
                options: levels,
                selected: _level,
                onSelected: (v) => setState(() => _level = v),
              ),
              const SizedBox(height: 16),
              _ChoiceGroup(
                label: 'Formato',
                options: formats,
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
                  const Expanded(
                    flex: 2,
                    child: AppTextField(
                      label: 'Preço por pessoa',
                      initialValue: '8 €',
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Spacer(),
              AppButton(
                label: 'Criar jogo',
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const GameDetailScreen()),
                ),
              ),
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

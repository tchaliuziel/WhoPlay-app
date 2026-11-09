
import 'package:flutter/material.dart';

import '../data/models.dart';
import '../services/api.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key, required this.perfil});

  final Perfil perfil;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nome;
  late final TextEditingController _localidade;
  late final TextEditingController _objetivo;

  late int _raioKm;

  List<Modalidade> _modalidadesDisponiveis = [];
  final Map<int, String> _modalidadesSelecionadas = {};

  final Map<int, bool> _diasSelecionados = {};
  final Map<int, TimeOfDay> _horasInicio = {};
  final Map<int, TimeOfDay> _horasFim = {};

  bool _aCarregar = true;
  bool _aGuardar = false;
  String? _erro;

  static const List<String> _niveis = [
    'Iniciante',
    'Intermédio',
    'Avançado',
  ];

  static const List<String> _dias = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();

    _nome = TextEditingController(text: widget.perfil.nome);
    _localidade = TextEditingController(
      text: widget.perfil.localidade ?? '',
    );
    _objetivo = TextEditingController(
      text: widget.perfil.objetivo,
    );

    _raioKm = widget.perfil.raioKm.clamp(1, 100);

    for (final modalidade in widget.perfil.modalidades) {
      _modalidadesSelecionadas[modalidade.id] = modalidade.nivel;
    }

    for (var dia = 1; dia <= 7; dia++) {
      _diasSelecionados[dia] = false;
      _horasInicio[dia] = const TimeOfDay(hour: 18, minute: 0);
      _horasFim[dia] = const TimeOfDay(hour: 20, minute: 0);
    }

    for (final disponibilidade in widget.perfil.disponibilidade) {
      final dia = disponibilidade.diaSemana;

      if (dia < 1 || dia > 7) continue;

      _diasSelecionados[dia] = true;

      _horasInicio[dia] = _lerHora(
        disponibilidade.horaInicio,
      );

      _horasFim[dia] = _lerHora(
        disponibilidade.horaFim,
      );
    }

    _carregarModalidades();
  }

  TimeOfDay _lerHora(String hora) {
    final partes = hora.split(':');

    return TimeOfDay(
      hour: int.tryParse(partes[0]) ?? 18,
      minute: partes.length > 1
          ? int.tryParse(partes[1]) ?? 0
          : 0,
    );
  }

  Future<void> _carregarModalidades() async {
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

  String _formatarHora(TimeOfDay hora) {
    return '${hora.hour.toString().padLeft(2, '0')}:'
        '${hora.minute.toString().padLeft(2, '0')}';
  }

  int _minutos(TimeOfDay hora) {
    return hora.hour * 60 + hora.minute;
  }

  Future<void> _escolherHora(
    int dia,
    bool inicio,
  ) async {
    final atual = inicio
        ? _horasInicio[dia]!
        : _horasFim[dia]!;

    final escolhida = await showTimePicker(
      context: context,
      initialTime: atual,
    );

    if (escolhida == null || !mounted) return;

    setState(() {
      if (inicio) {
        _horasInicio[dia] = escolhida;
      } else {
        _horasFim[dia] = escolhida;
      }
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_modalidadesSelecionadas.isEmpty) {
      _mensagem('Escolhe pelo menos uma modalidade.');
      return;
    }

    final disponibilidade = <Map<String, Object?>>[];

    for (var dia = 1; dia <= 7; dia++) {
      if (_diasSelecionados[dia] != true) continue;

      final inicio = _horasInicio[dia]!;
      final fim = _horasFim[dia]!;

      if (_minutos(fim) <= _minutos(inicio)) {
        _mensagem(
          'A hora de fim tem de ser posterior à hora de início '
          'em ${_dias[dia - 1]}.',
        );
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
      // 1. Atualizar informações pessoais.
      await Api.atualizarPerfil({
        'nome': _nome.text.trim(),
        'localidade': _localidade.text.trim().isEmpty
            ? null
            : _localidade.text.trim(),
        'raio_km': _raioKm,
        'objetivo': _objetivo.text.trim(),
      });

      // 2. Atualizar modalidades e respetivos níveis.
      await Api.atualizarModalidadesDetalhadas(
        _modalidadesSelecionadas,
      );

      // 3. Atualizar disponibilidade semanal.
      await Api.atualizarDisponibilidade(
        disponibilidade,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } on ApiException catch (erro) {
      _mensagem(erro.message);
    } catch (erro) {
      _mensagem('Não foi possível atualizar o perfil: $erro');
    } finally {
      if (mounted) {
        setState(() => _aGuardar = false);
      }
    }
  }

  void _mensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  void dispose() {
    _nome.dispose();
    _localidade.dispose();
    _objetivo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_aCarregar) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_erro != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar perfil')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_erro!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _aCarregar = true;
                      _erro = null;
                    });
                    _carregarModalidades();
                  },
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil'),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _titulo('Informações pessoais'),

            TextFormField(
              controller: _nome,
              decoration: const InputDecoration(
                labelText: 'Nome completo',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return 'Indica o teu nome.';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              initialValue: widget.perfil.email,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
                helperText: 'O email não pode ser alterado aqui.',
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _localidade,
              decoration: const InputDecoration(
                labelText: 'Localidade',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            _titulo('Raio de procura'),

            Text(
              'Procurar jogadores até $_raioKm km de distância',
            ),

            Slider(
              value: _raioKm.toDouble(),
              min: 1,
              max: 100,
              divisions: 99,
              label: '$_raioKm km',
              onChanged: (valor) {
                setState(() => _raioKm = valor.round());
              },
            ),

            const SizedBox(height: 16),

            _titulo('Objetivo desportivo'),

            TextFormField(
              controller: _objetivo,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ex.: Melhorar a técnica e competir...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            _titulo('Modalidades e níveis'),

            const Text(
              'Seleciona os desportos que praticas e define o teu nível.',
            ),

            const SizedBox(height: 12),

            for (final modalidade in _modalidadesDisponiveis)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          modalidade.nome,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        value: _modalidadesSelecionadas.containsKey(
                          modalidade.id,
                        ),
                        onChanged: (selecionada) {
                          setState(() {
                            if (selecionada == true) {
                              _modalidadesSelecionadas[
                                modalidade.id
                              ] = 'Iniciante';
                            } else {
                              _modalidadesSelecionadas.remove(
                                modalidade.id,
                              );
                            }
                          });
                        },
                      ),

                      if (_modalidadesSelecionadas.containsKey(
                        modalidade.id,
                      ))
                        DropdownButtonFormField<String>(
                          value: _modalidadesSelecionadas[
                            modalidade.id
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Nível de experiência',
                            border: OutlineInputBorder(),
                          ),
                          items: _niveis.map((nivel) {
                            return DropdownMenuItem(
                              value: nivel,
                              child: Text(nivel),
                            );
                          }).toList(),
                          onChanged: (nivel) {
                            if (nivel == null) return;

                            setState(() {
                              _modalidadesSelecionadas[
                                modalidade.id
                              ] = nivel;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            _titulo('Disponibilidade semanal'),

            const Text(
              'Seleciona os dias em que estás disponível.',
            ),

            const SizedBox(height: 12),

            for (var dia = 1; dia <= 7; dia++)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _dias[dia - 1],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        value: _diasSelecionados[dia],
                        onChanged: (valor) {
                          setState(() {
                            _diasSelecionados[dia] = valor ?? false;
                          });
                        },
                      ),

                      if (_diasSelecionados[dia] == true)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _escolherHora(dia, true),
                                icon: const Icon(Icons.access_time),
                                label: Text(
                                  'Início: ${_formatarHora(_horasInicio[dia]!)}',
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _escolherHora(dia, false),
                                icon: const Icon(Icons.access_time),
                                label: Text(
                                  'Fim: ${_formatarHora(_horasFim[dia]!)}',
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _aGuardar ? null : _guardar,
                icon: _aGuardar
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _aGuardar
                      ? 'A guardar...'
                      : 'Guardar alterações',
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _titulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

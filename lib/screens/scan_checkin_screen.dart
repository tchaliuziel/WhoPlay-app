
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/api.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/buttons.dart';

class ScanCheckInScreen extends StatefulWidget {
  const ScanCheckInScreen({
    super.key,
    required this.jogoId,
  });

  final int jogoId;

  @override
  State<ScanCheckInScreen> createState() => _ScanCheckInScreenState();
}

class _ScanCheckInScreenState extends State<ScanCheckInScreen> {
  final MobileScannerController _controller =
      MobileScannerController();

  bool _aProcessar = false;
  bool _confirmado = false;
  String? _mensagem;
  bool _sucesso = false;

  Future<void> _lerCodigo(BarcodeCapture capture) async {
    if (_aProcessar || _confirmado) return;

    final codigo = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .firstWhere(
          (value) => value != null && value.isNotEmpty,
          orElse: () => null,
        );

    if (codigo == null) return;

    setState(() {
      _aProcessar = true;
      _mensagem = 'A validar presença...';
    });

    await _controller.stop();

    try {
      final resultado = await Api.confirmarCheckin(codigo);

      if (!mounted) return;

      setState(() {
        _confirmado = true;
        _sucesso = true;
        _mensagem = resultado['mensagem'] as String? ??
            'Presença confirmada com sucesso!';
      });
    } on ApiException catch (erro) {
      if (!mounted) return;

      setState(() {
        _sucesso = false;
        _mensagem = erro.message;
      });

      await _controller.start();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _sucesso = false;
        _mensagem = 'Ocorreu um erro ao validar o QR Code.';
      });

      await _controller.start();
    } finally {
      if (mounted) {
        setState(() {
          _aProcessar = false;
        });
      }
    }
  }

  Future<void> _voltarAoScanner() async {
    setState(() {
      _mensagem = null;
      _sucesso = false;
      _confirmado = false;
    });

    await _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: AppTheme.darkStatusIcons,
      child: Scaffold(
        backgroundColor: AppColors.night,
        appBar: AppBar(
          backgroundColor: AppColors.night,
          foregroundColor: AppColors.white,
          title: Text(
            'Validar presença',
            style: AppText.display(
              21,
              color: AppColors.white,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  'Aponta a câmara para o QR Code do participante.',
                  textAlign: TextAlign.center,
                  style: AppText.body(
                    16,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _confirmado
                        ? _resultado()
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              MobileScanner(
                                controller: _controller,
                                onDetect: _lerCodigo,
                              ),
                              if (_aProcessar)
                                Container(
                                  color: Colors.black54,
                                  alignment: Alignment.center,
                                  child:
                                      const CircularProgressIndicator(),
                                ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_mensagem != null) ...[
                  Text(
                    _mensagem!,
                    textAlign: TextAlign.center,
                    style: AppText.body(
                      15,
                      color: _sucesso
                          ? AppColors.lime
                          : AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_confirmado)
                  AppButton(
                    label: 'Ler outro QR Code',
                    onPressed: _voltarAoScanner,
                  ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Voltar',
                  outlined: true,
                  foreground: AppColors.white,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultado() {
    return Container(
      color: AppColors.nightLight,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgIcon(
            _sucesso ? AppIcon.checkCircle : AppIcon.alert,
            color: _sucesso ? AppColors.lime : Colors.redAccent,
            size: 76,
            strokeWidth: 1.6,
          ),
          const SizedBox(height: 18),
          Text(
            _sucesso
                ? 'Presença confirmada!'
                : 'Não foi possível validar',
            textAlign: TextAlign.center,
            style: AppText.display(
              22,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

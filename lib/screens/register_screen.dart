import 'package:flutter/material.dart';

import '../services/api.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import '../widgets/fields.dart';
import 'onboarding_screen.dart';

/// Criar conta (RF01). Não está no mockup: segue o estilo do ecrã "Criar jogo".
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _aGuardar = false;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _criarConta() async {
    setState(() => _aGuardar = true);
    try {
      await Api.registo(_nome.text.trim(), _email.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const OnboardingScreen()));
    } on ApiException catch (erro) {
      if (mounted) showInfo(context, erro.message);
    } finally {
      if (mounted) setState(() => _aGuardar = false);
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
                  const ScreenTitle('Criar conta'),
                ],
              ),
              const SizedBox(height: 24),
              AppTextField(label: 'Nome', controller: _nome),
              const SizedBox(height: 18),
              AppTextField(label: 'Email', controller: _email, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 18),
              AppTextField(label: 'Palavra-passe (mínimo 8 caracteres)', controller: _password, obscureText: true),
              const SizedBox(height: 24),
              const Spacer(),
              AppButton(
                label: _aGuardar ? 'A criar…' : 'Criar conta',
                onPressed: _aGuardar ? null : _criarConta,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

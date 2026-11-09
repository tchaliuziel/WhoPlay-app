
import 'package:flutter/material.dart';

import '../services/api.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import '../widgets/fields.dart';
import '../widgets/logo.dart';
import 'home_shell.dart';
import 'register_screen.dart';

/// 01 Login
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Campos vazios por defeito
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _aEntrar = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (_email.text.trim().isEmpty ||
        _password.text.isEmpty) {
      showInfo(context, 'Preenche o email e a palavra-passe.');
      return;
    }

    setState(() => _aEntrar = true);

    try {
      await Api.login(
        _email.text.trim(),
        _password.text,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomeShell(),
        ),
      );
    } on ApiException catch (erro) {
      if (mounted) {
        showInfo(context, erro.message);
      }
    } finally {
      if (mounted) {
        setState(() => _aEntrar = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: AppTheme.lightStatusIcons,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: AppColors.forest,
                  padding: const EdgeInsets.fromLTRB(28, 44, 28, 44),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const WhoPlayLogo(),
                      const SizedBox(height: 14),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 250,
                        ),
                        child: Text(
                          'Encontra pessoas. Marca o jogo. Vai jogar.',
                          style: AppText.body(
                            19,
                            color: AppColors.white,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Entrar',
                        style: AppText.display(
                          28,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 18),

                      AppTextField(
                        label: 'Email',
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 18),

                      AppTextField(
                        label: 'Palavra-passe',
                        controller: _password,
                        obscureText: true,
                      ),

                      const SizedBox(height: 18),

                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: () => showInfo(
                            context,
                            'Recuperação de palavra-passe em breve.',
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                            ),
                            child: Text(
                              'Esqueci-me da palavra-passe',
                              style: AppText.body(
                                14,
                                weight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      AppButton(
                        label: _aEntrar ? 'A entrar…' : 'Entrar',
                        onPressed: _aEntrar ? null : _entrar,
                      ),

                      const SizedBox(height: 28),

                      Text(
                        'Ainda não tens conta?',
                        textAlign: TextAlign.center,
                        style: AppText.body(
                          14,
                          color: AppColors.muted,
                        ),
                      ),

                      const SizedBox(height: 12),

                      AppButton(
                        label: 'Criar conta',
                        outlined: true,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

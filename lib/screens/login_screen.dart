import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/buttons.dart';
import '../widgets/common.dart';
import '../widgets/fields.dart';
import '../widgets/logo.dart';
import 'home_shell.dart';
import 'onboarding_screen.dart';

/// 01 Login
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: AppTheme.lightStatusIcons,
      child: Scaffold(
        body: FillScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: AppColors.forest,
                padding: EdgeInsets.fromLTRB(28, topInset(context, 88), 28, 44),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const WhoPlayLogo(),
                    const SizedBox(height: 14),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 250),
                      child: Text(
                        'Encontra pessoas. Marca o jogo. Vai jogar.',
                        style: AppText.body(19, color: AppColors.white, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(28, 32, 28, 28 + bottomInset(context)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Entrar', style: AppText.display(28, letterSpacing: -0.5)),
                      const SizedBox(height: 18),
                      const AppTextField(
                        label: 'Email',
                        initialValue: 'sebastiao@email.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 18),
                      const AppTextField(
                        label: 'Palavra-passe',
                        initialValue: '12345678',
                        obscureText: true,
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: () => showInfo(context, 'Recuperação de palavra-passe em breve.'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              'Esqueci-me da palavra-passe',
                              style: AppText.body(14, weight: FontWeight.w600, color: AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      AppButton(
                        label: 'Entrar',
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const HomeShell()),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Spacer(),
                      Text(
                        'Ainda não tens conta?',
                        textAlign: TextAlign.center,
                        style: AppText.body(14, color: AppColors.muted),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: 'Criar conta',
                        outlined: true,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

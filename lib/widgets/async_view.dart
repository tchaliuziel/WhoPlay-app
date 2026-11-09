import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'buttons.dart';

/// Mostra um indicador enquanto os dados chegam da API, uma mensagem se
/// falhar (com "Tentar outra vez") e o conteúdo quando estiverem prontos.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.future, required this.builder, this.onRetry});

  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: AppText.body(15, color: AppColors.muted),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 200,
                    child: AppButton.small(label: 'Tentar outra vez', outlined: true, onPressed: onRetry),
                  ),
                ],
              ],
            ),
          );
        }
        return builder(context, snapshot.data as T);
      },
    );
  }
}

/// Texto cinzento para listas vazias.
class EmptyText extends StatelessWidget {
  const EmptyText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: AppText.body(15, color: AppColors.muted)),
      );
}

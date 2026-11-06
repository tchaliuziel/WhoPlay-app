import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(AppTheme.darkStatusIcons);
  runApp(const WhoPlayApp());
}

class WhoPlayApp extends StatelessWidget {
  const WhoPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhoPlay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('pt', 'PT'),
      supportedLocales: const [Locale('pt', 'PT')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const LoginScreen(),
    );
  }
}

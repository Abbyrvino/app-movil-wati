import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/presentation/splash_page.dart';

class WatiApp extends StatelessWidget {
  const WatiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WATI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const SplashPage(),
    );
  }
}
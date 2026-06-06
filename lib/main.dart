import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/session/services/qa_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.init();
  QAService.checkConnectivity();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const JPrimeApp());
}

class JPrimeApp extends StatefulWidget {
  const JPrimeApp({super.key});

  @override
  State<JPrimeApp> createState() => _JPrimeAppState();
}

class _JPrimeAppState extends State<JPrimeApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'jPrime Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: AppShell(onThemeToggle: _toggleTheme),
    );
  }
}

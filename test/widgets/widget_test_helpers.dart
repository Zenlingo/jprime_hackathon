import 'package:flutter/material.dart';
import 'package:mobile_app/core/theme/app_theme.dart';

/// Wraps a widget in a MaterialApp with the jPrime theme so that
/// `context.jp` (the JPThemeColors extension) is available.
Widget wrapWithTheme(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );
}

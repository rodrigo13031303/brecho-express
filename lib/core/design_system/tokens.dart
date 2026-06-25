import 'package:flutter/material.dart';

/// Design tokens centrais para o aplicativo Brechó Express.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF64B5F6); // azul claro
  static const Color primary700 = Color(0xFF2E88F0);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFF00695C); // verde esmeralda
  static const Color accent = Color(0xFF00B8D4);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF6F9FB);

  static const Color gray700 = Color(0xFF1F2933);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray300 = Color(0xFFE6EDF2);

  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF57C00);
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  AppRadius._();

  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
}

class AppSizes {
  AppSizes._();

  static const double buttonHeight = 48.0;
  static const double icon = 24.0;
  static const double touchTarget = 44.0;
}

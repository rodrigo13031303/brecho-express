import 'package:flutter/material.dart';

enum AppPalette {
  terracotta(
    label: 'Terracota',
    seedColor: Color(0xFF9C4F2C),
    backgroundColor: Color(0xFFFFF8F4),
  ),
  sage(
    label: 'Verde sálvia',
    seedColor: Color(0xFF557A60),
    backgroundColor: Color(0xFFF4F8F3),
  ),
  petroleum(
    label: 'Azul petróleo',
    seedColor: Color(0xFF176B70),
    backgroundColor: Color(0xFFF1F8F8),
  ),
  antiqueRose(
    label: 'Rosa antigo',
    seedColor: Color(0xFFA85D72),
    backgroundColor: Color(0xFFFFF5F7),
  ),
  plum(
    label: 'Ameixa',
    seedColor: Color(0xFF704264),
    backgroundColor: Color(0xFFFAF5F9),
  ),
  sand(
    label: 'Areia',
    seedColor: Color(0xFF8A6846),
    backgroundColor: Color(0xFFFAF6EE),
  );

  const AppPalette({
    required this.label,
    required this.seedColor,
    required this.backgroundColor,
  });
  final String label;
  final Color seedColor;
  final Color backgroundColor;
}

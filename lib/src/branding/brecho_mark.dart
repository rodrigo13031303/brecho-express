import 'package:flutter/material.dart';

class BrechoMark extends StatelessWidget {
  const BrechoMark({super.key, this.size = 72});

  static const assetPath =
      'assets/branding/brecho-express-logo-transparent.png';
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Símbolo do Brechó Express',
      image: true,
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

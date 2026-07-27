import 'package:flutter/material.dart';

import 'src/appearance/app_palette.dart';
import 'src/appearance/appearance_store.dart';
import 'src/auth/google_login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appearanceStore = AppearanceStore();
  final initialPalette = await appearanceStore.restore();
  runApp(
    BrechoExpressApp(
      appearanceStore: appearanceStore,
      initialPalette: initialPalette,
    ),
  );
}

class BrechoExpressApp extends StatefulWidget {
  BrechoExpressApp({
    super.key,
    AppearanceStore? appearanceStore,
    this.initialPalette = AppPalette.petroleum,
  }) : appearanceStore = appearanceStore ?? AppearanceStore();

  final AppearanceStore appearanceStore;
  final AppPalette initialPalette;

  @override
  State<BrechoExpressApp> createState() => _BrechoExpressAppState();
}

class _BrechoExpressAppState extends State<BrechoExpressApp> {
  late AppPalette _palette = widget.initialPalette;

  Future<void> _changePalette(AppPalette palette) async {
    setState(() => _palette = palette);
    await widget.appearanceStore.save(palette);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: _palette.seedColor);
    return MaterialApp(
      title: 'Brechó Express',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: _palette.backgroundColor,
        useMaterial3: true,
      ),
      home: GoogleLoginPage(
        palette: _palette,
        onPaletteChanged: _changePalette,
      ),
    );
  }
}

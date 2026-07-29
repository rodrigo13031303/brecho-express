import 'package:brecho_express_app/src/app/main_shell.dart';
import 'package:brecho_express_app/src/appearance/app_palette.dart';
import 'package:brecho_express_app/src/auth/brecho_session.dart';
import 'package:brecho_express_app/src/catalog/catalog_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exibe as cinco áreas e abre o perfil', (tester) async {
    final session = BrechoSession(
      accessToken: 'token',
      sessionPublicId: 'session',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      accountPublicId: 'account',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MainShell(
          session: session,
          palette: AppPalette.petroleum,
          onPaletteChanged: (_) {},
          onLogout: () async {},
          loggingOut: false,
          initialCatalog: Future.value(
            const CatalogSnapshot(categories: [], products: []),
          ),
        ),
      ),
    );

    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Comprar'), findsOneWidget);
    expect(find.text('Vender'), findsOneWidget);
    expect(find.text('Carrinho'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Minha conta'), findsOneWidget);
    expect(find.text('Aparência'), findsOneWidget);
    expect(find.text('Sair da conta'), findsOneWidget);
  });
}

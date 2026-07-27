import 'package:brecho_express_app/src/appearance/app_palette.dart';
import 'package:brecho_express_app/src/appearance/appearance_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('usa azul petróleo quando ainda não há preferência', () async {
    final store = AppearanceStore(storage: MemoryAppearanceStorage());
    expect(await store.restore(), AppPalette.petroleum);
  });

  test('persiste e restaura a paleta escolhida', () async {
    final storage = MemoryAppearanceStorage();
    final store = AppearanceStore(storage: storage);
    await store.save(AppPalette.petroleum);
    expect(await store.restore(), AppPalette.petroleum);
  });

  test('ignora uma preferência desconhecida', () async {
    final storage = MemoryAppearanceStorage()..value = 'unknown';
    final store = AppearanceStore(storage: storage);
    expect(await store.restore(), AppPalette.petroleum);
  });
}

class MemoryAppearanceStorage implements AppearanceStorage {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async => this.value = value;
}

import 'package:brecho_express_app/src/auth/brecho_session.dart';
import 'package:brecho_express_app/src/auth/session_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 7, 27, 12);

  test('persiste e restaura uma sessão válida', () async {
    final storage = MemorySessionStorage();
    final store = SessionStore(storage: storage, now: () => now);
    final session = BrechoSession(
      accessToken: 'token',
      sessionPublicId: 'session-id',
      expiresAt: now.add(const Duration(hours: 1)),
      accountPublicId: 'account-id',
    );

    await store.save(session);
    final restored = await store.restore();

    expect(restored?.accessToken, session.accessToken);
    expect(restored?.sessionPublicId, session.sessionPublicId);
    expect(restored?.expiresAt, session.expiresAt);
    expect(restored?.accountPublicId, session.accountPublicId);
  });

  test('remove e ignora uma sessão expirada', () async {
    final storage = MemorySessionStorage();
    final store = SessionStore(storage: storage, now: () => now);
    storage.value =
        '{"accessToken":"token","sessionPublicId":"session-id",'
        '"expiresAt":"2026-07-27T11:59:59.000Z",'
        '"accountPublicId":"account-id"}';

    expect(await store.restore(), isNull);
    expect(storage.value, isNull);
  });

  test('remove e ignora conteúdo inválido', () async {
    final storage = MemorySessionStorage()..value = 'invalid';
    final store = SessionStore(storage: storage, now: () => now);

    expect(await store.restore(), isNull);
    expect(storage.value, isNull);
  });
}

class MemorySessionStorage implements SessionStorage {
  String? value;

  @override
  Future<void> delete() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

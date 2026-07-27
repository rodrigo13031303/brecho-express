import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'brecho_session.dart';

abstract interface class SessionStorage {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> delete();
}

class SecureSessionStorage implements SessionStorage {
  SecureSessionStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'brecho_express.session.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);

  @override
  Future<void> delete() => _storage.delete(key: _key);
}

class SessionStore {
  SessionStore({SessionStorage? storage, DateTime Function()? now})
    : _storage = storage ?? SecureSessionStorage(),
      _now = now ?? DateTime.now;

  final SessionStorage _storage;
  final DateTime Function() _now;

  Future<void> save(BrechoSession session) async {
    if (session.isExpiredAt(_now())) {
      await clear();
      throw const SessionExpiredException();
    }
    await _storage.write(jsonEncode(session.toJson()));
  }

  Future<BrechoSession?> restore() async {
    final encoded = await _storage.read();
    if (encoded == null) return null;

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid session payload');
      }
      final session = BrechoSession.fromJson(decoded);
      if (session.isExpiredAt(_now())) {
        await clear();
        return null;
      }
      return session;
    } on Object {
      await clear();
      return null;
    }
  }

  Future<void> clear() => _storage.delete();
}

class SessionExpiredException implements Exception {
  const SessionExpiredException();
}

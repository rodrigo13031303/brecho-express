import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_palette.dart';

abstract interface class AppearanceStorage {
  Future<String?> read();
  Future<void> write(String value);
}

class SecureAppearanceStorage implements AppearanceStorage {
  SecureAppearanceStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();
  static const _key = 'brecho_express.appearance.palette.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);
}

class AppearanceStore {
  AppearanceStore({AppearanceStorage? storage})
    : _storage = storage ?? SecureAppearanceStorage();
  final AppearanceStorage _storage;

  Future<AppPalette> restore() async {
    try {
      final value = await _storage.read();
      return AppPalette.values.firstWhere(
        (palette) => palette.name == value,
        orElse: () => AppPalette.petroleum,
      );
    } on Object {
      return AppPalette.petroleum;
    }
  }

  Future<void> save(AppPalette palette) => _storage.write(palette.name);
}

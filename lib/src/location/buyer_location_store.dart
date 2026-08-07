import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'store_location_service.dart';

class BuyerLocationStore {
  BuyerLocationStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'buyer_catalog_location_v1';
  final FlutterSecureStorage _storage;

  Future<BuyerCatalogLocation?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return BuyerCatalogLocation(
        point: GeoPoint(
          (json['latitude'] as num).toDouble(),
          (json['longitude'] as num).toDouble(),
        ),
        label: json['label'] as String,
        isDeviceLocation: json['isDeviceLocation'] as bool? ?? false,
      );
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> write(BuyerCatalogLocation location) => _storage.write(
    key: _key,
    value: jsonEncode({
      'latitude': location.point.latitude,
      'longitude': location.point.longitude,
      'label': location.label,
      'isDeviceLocation': location.isDeviceLocation,
    }),
  );

  Future<void> clear() => _storage.delete(key: _key);
}

class BuyerCatalogLocation {
  const BuyerCatalogLocation({
    required this.point,
    required this.label,
    this.isDeviceLocation = false,
  });

  final GeoPoint point;
  final String label;
  final bool isDeviceLocation;
}

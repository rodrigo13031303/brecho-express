import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class StoreLocationService {
  StoreLocationService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<StoreLocationDraft> lookupPostalCode(String value) async {
    final postalCode = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (postalCode.length != 8) {
      throw const StoreLocationException('Digite um CEP com 8 números.');
    }
    final response = await _client
        .get(Uri.parse('https://brasilapi.com.br/api/cep/v2/$postalCode'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw const StoreLocationException('CEP não encontrado.');
    }
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final location = json['location'] as Map<String, dynamic>?;
      final coordinates = location?['coordinates'] as Map<String, dynamic>?;
      final latitude = _number(coordinates?['latitude']);
      final longitude = _number(coordinates?['longitude']);
      final district = (json['neighborhood'] as String?)?.trim() ?? '';
      final city = (json['city'] as String?)?.trim() ?? '';
      final state = (json['state'] as String?)?.trim().toUpperCase() ?? '';
      if (district.isEmpty ||
          city.isEmpty ||
          state.length != 2 ||
          latitude == null ||
          longitude == null) {
        throw const StoreLocationException(
          'O CEP não possui localização completa. Use sua localização atual.',
        );
      }
      return StoreLocationDraft(
        postalCode: postalCode,
        district: district,
        city: city,
        state: state,
        latitude: latitude,
        longitude: longitude,
      );
    } on FormatException {
      throw const StoreLocationException('A consulta do CEP veio inválida.');
    }
  }

  Future<GeoPoint> currentCoordinates() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const StoreLocationException(
        'Ative a localização do celular para continuar.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const StoreLocationException(
        'Permita o acesso à localização nas configurações do celular.',
      );
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return GeoPoint(position.latitude, position.longitude);
  }

  Future<StoreLocationDraft> useCurrentLocation() async {
    final position = await currentCoordinates();
    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (placemarks.isEmpty) {
      throw const StoreLocationException(
        'Não foi possível identificar o bairro atual.',
      );
    }
    final place = placemarks.first;
    final postalCode = (place.postalCode ?? '').replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final district = [place.subLocality, place.subAdministrativeArea]
        .whereType<String>()
        .map((item) => item.trim())
        .firstWhere((item) => item.isNotEmpty, orElse: () => '');
    final city = (place.locality ?? place.administrativeArea ?? '').trim();
    final state = (place.administrativeArea ?? '').trim().toUpperCase();
    if (postalCode.length != 8 ||
        district.isEmpty ||
        city.isEmpty ||
        state.length != 2) {
      throw const StoreLocationException(
        'Não encontramos o endereço completo. Tente informar o CEP.',
      );
    }
    return StoreLocationDraft(
      postalCode: postalCode,
      district: district,
      city: city,
      state: state,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  static double? _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  void close() => _client.close();
}

class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

class StoreLocationDraft {
  const StoreLocationDraft({
    required this.postalCode,
    required this.district,
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
  });

  final String postalCode;
  final String district;
  final String city;
  final String state;
  final double latitude;
  final double longitude;

  String get publicLabel => '$district • $city/$state';
}

class StoreLocationException implements Exception {
  const StoreLocationException(this.message);
  final String message;
}

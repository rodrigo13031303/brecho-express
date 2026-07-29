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
    try {
      final json = response.statusCode == 200
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};
      final location = json['location'] as Map<String, dynamic>?;
      final coordinates = location?['coordinates'] as Map<String, dynamic>?;
      final fallback = await _lookupViaCep(postalCode);
      final draft = StoreLocationDraft(
        postalCode: postalCode,
        street: _firstText(json['street'], fallback['logradouro']),
        number: '',
        complement: '',
        district: _firstText(json['neighborhood'], fallback['bairro']),
        city: _firstText(json['city'], fallback['localidade']),
        state: _stateCode(_firstText(json['state'], fallback['uf'])),
        latitude: _number(coordinates?['latitude']),
        longitude: _number(coordinates?['longitude']),
      );
      if (draft.city.isEmpty || draft.state.length != 2) {
        throw const StoreLocationException(
          'O CEP retornou poucos dados. Complete o endereço manualmente.',
        );
      }
      return draft;
    } on FormatException {
      throw const StoreLocationException('A consulta do CEP veio inválida.');
    }
  }

  Future<Map<String, dynamic>> _lookupViaCep(String postalCode) async {
    try {
      final response = await _client
          .get(Uri.parse('https://viacep.com.br/ws/$postalCode/json/'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return const {};
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['erro'] == true ? const {} : json;
    } catch (_) {
      return const {};
    }
  }

  static String _firstText(dynamic preferred, dynamic fallback) {
    return _prefer(preferred?.toString() ?? '', fallback?.toString() ?? '');
  }

  static String _prefer(String preferred, String fallback) {
    final first = preferred.trim();
    return first.isNotEmpty ? first : fallback.trim();
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
    final place = placemarks.isEmpty ? null : placemarks.first;
    final district = [place?.subLocality, place?.subAdministrativeArea]
        .whereType<String>()
        .map((item) => item.trim())
        .firstWhere((item) => item.isNotEmpty, orElse: () => '');
    final gpsDraft = StoreLocationDraft(
      postalCode: (place?.postalCode ?? '').replaceAll(RegExp(r'[^0-9]'), ''),
      street: (place?.street ?? place?.thoroughfare ?? '').trim(),
      number: (place?.subThoroughfare ?? '').trim(),
      complement: '',
      district: district,
      city: (place?.locality ?? place?.subAdministrativeArea ?? '').trim(),
      state: _stateCode(place?.administrativeArea ?? ''),
      latitude: position.latitude,
      longitude: position.longitude,
    );
    if (gpsDraft.postalCode.length != 8) return gpsDraft;
    try {
      final postalDraft = await lookupPostalCode(gpsDraft.postalCode);
      return StoreLocationDraft(
        postalCode: gpsDraft.postalCode,
        street: _prefer(gpsDraft.street, postalDraft.street),
        number: gpsDraft.number,
        complement: '',
        district: _prefer(gpsDraft.district, postalDraft.district),
        city: _prefer(gpsDraft.city, postalDraft.city),
        state: _prefer(gpsDraft.state, postalDraft.state),
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return gpsDraft;
    }
  }

  Future<GeoPoint> coordinatesForBuyerReference(
    StoreLocationDraft draft,
  ) async {
    if (draft.latitude != null && draft.longitude != null) {
      return GeoPoint(draft.latitude!, draft.longitude!);
    }
    final query = [
      draft.postalCode,
      draft.district,
      draft.city,
      draft.state,
      'Brasil',
    ].where((part) => part.trim().isNotEmpty).join(', ');
    try {
      final matches = await locationFromAddress(query);
      if (matches.isNotEmpty) {
        return GeoPoint(matches.first.latitude, matches.first.longitude);
      }
    } catch (_) {
      // A mensagem abaixo orienta a tentar GPS ou outro CEP.
    }
    throw const StoreLocationException(
      'Não conseguimos localizar esse CEP. Tente outro ou use o GPS.',
    );
  }

  Future<StoreLocationDraft> ensureCoordinates(StoreLocationDraft draft) async {
    draft.validate();
    final query = [
      draft.street,
      draft.number,
      draft.district,
      draft.city,
      draft.state,
      draft.postalCode,
      'Brasil',
    ].where((part) => part.trim().isNotEmpty).join(', ');
    try {
      final matches = await locationFromAddress(query);
      if (matches.isNotEmpty) {
        return draft.withCoordinates(
          matches.first.latitude,
          matches.first.longitude,
        );
      }
    } catch (_) {
      // Coordinates already obtained from CEP/GPS remain the fallback.
    }
    if (draft.latitude != null && draft.longitude != null) return draft;
    throw const StoreLocationException(
      'Não conseguimos localizar esse endereço. Confira os campos.',
    );
  }

  static double? _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static String _stateCode(String value) {
    final normalized = value.trim().toUpperCase();
    if (normalized.length == 2) return normalized;
    const states = {
      'ACRE': 'AC',
      'ALAGOAS': 'AL',
      'AMAPA': 'AP',
      'AMAZONAS': 'AM',
      'BAHIA': 'BA',
      'CEARA': 'CE',
      'DISTRITO FEDERAL': 'DF',
      'ESPIRITO SANTO': 'ES',
      'GOIAS': 'GO',
      'MARANHAO': 'MA',
      'MATO GROSSO': 'MT',
      'MATO GROSSO DO SUL': 'MS',
      'MINAS GERAIS': 'MG',
      'PARA': 'PA',
      'PARAIBA': 'PB',
      'PARANA': 'PR',
      'PERNAMBUCO': 'PE',
      'PIAUI': 'PI',
      'RIO DE JANEIRO': 'RJ',
      'RIO GRANDE DO NORTE': 'RN',
      'RIO GRANDE DO SUL': 'RS',
      'RONDONIA': 'RO',
      'RORAIMA': 'RR',
      'SANTA CATARINA': 'SC',
      'SAO PAULO': 'SP',
      'SERGIPE': 'SE',
      'TOCANTINS': 'TO',
    };
    const accents = 'ÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇ';
    const plain = 'AAAAEEEIIIOOOOUUUC';
    var key = normalized;
    for (var index = 0; index < accents.length; index++) {
      key = key.replaceAll(accents[index], plain[index]);
    }
    return states[key] ?? '';
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
    required this.street,
    required this.number,
    required this.complement,
    required this.district,
    required this.city,
    required this.state,
    this.latitude,
    this.longitude,
  });

  final String postalCode;
  final String street;
  final String number;
  final String complement;
  final String district;
  final String city;
  final String state;
  final double? latitude;
  final double? longitude;

  String get publicLabel => '$district • $city/$state';

  StoreLocationDraft withCoordinates(double latitude, double longitude) =>
      StoreLocationDraft(
        postalCode: postalCode,
        street: street,
        number: number,
        complement: complement,
        district: district,
        city: city,
        state: state,
        latitude: latitude,
        longitude: longitude,
      );

  StoreLocationDraft copyWith({String? number}) => StoreLocationDraft(
    postalCode: postalCode,
    street: street,
    number: number ?? this.number,
    complement: complement,
    district: district,
    city: city,
    state: state,
    latitude: latitude,
    longitude: longitude,
  );

  void validate() {
    if (postalCode.replaceAll(RegExp(r'[^0-9]'), '').length != 8 ||
        street.trim().isEmpty ||
        number.trim().isEmpty ||
        district.trim().isEmpty ||
        city.trim().isEmpty ||
        state.trim().length != 2) {
      throw const StoreLocationException(
        'Complete CEP, rua, número, bairro, cidade e UF.',
      );
    }
  }
}

class StoreLocationException implements Exception {
  const StoreLocationException(this.message);
  final String message;
}

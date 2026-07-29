import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/brecho_session.dart';

class DeliveryService {
  DeliveryService({http.Client? client}) : _client = client ?? http.Client();

  static final _baseUri = Uri.parse(
    'https://app.rodrigosburguer.com.br/ords/brechoexpress/api/v1/',
  );
  final http.Client _client;

  Future<List<SavedAddress>> listAddresses(BrechoSession session) async {
    final response = await _send('GET', _baseUri.resolve('addresses'), session);
    final data = _decodeData(response);
    if (data is! List) {
      throw const DeliveryException('A lista de endereços veio inválida.');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(SavedAddress.fromJson)
        .where((address) => address.status == 'ACTIVE')
        .toList(growable: false);
  }

  Future<SavedAddress> createAddress({
    required BrechoSession session,
    required AddressDraft draft,
  }) async {
    final response = await _send(
      'POST',
      _baseUri.resolve('addresses'),
      session,
      body: draft.toJson(),
    );
    return SavedAddress.fromJson(_decodeObject(response));
  }

  Future<PurchaseDelivery?> getDelivery({
    required BrechoSession session,
    required String requestPublicId,
  }) async {
    final request = Uri.encodeComponent(requestPublicId);
    final response = await _send(
      'GET',
      _baseUri.resolve('purchase-requests/$request/delivery-address'),
      session,
    );
    if (response.statusCode == 404) return null;
    return PurchaseDelivery.fromJson(_decodeObject(response));
  }

  Future<PurchaseDelivery> selectAddress({
    required BrechoSession session,
    required String requestPublicId,
    required String addressPublicId,
  }) async {
    final request = Uri.encodeComponent(requestPublicId);
    final response = await _send(
      'PUT',
      _baseUri.resolve('purchase-requests/$request/delivery-address'),
      session,
      body: {'addressPublicId': addressPublicId},
    );
    return PurchaseDelivery.fromJson(_decodeObject(response));
  }

  Future<http.Response> _send(
    String method,
    Uri uri,
    BrechoSession session, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final request = http.Request(method, uri)
        ..headers.addAll({
          'Authorization': 'Bearer ${session.accessToken}',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        });
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 45));
      return http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const DeliveryException('A consulta demorou. Tente novamente.');
    } on http.ClientException {
      throw const DeliveryException(
        'Não foi possível acessar os endereços agora.',
      );
    }
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    final data = _decodeData(response);
    if (data is! Map<String, dynamic>) {
      throw const DeliveryException('A resposta do endereço veio inválida.');
    }
    return data;
  }

  dynamic _decodeData(http.Response response) {
    try {
      final envelope = jsonDecode(response.body);
      if (envelope is! Map<String, dynamic>) {
        throw const DeliveryException('A resposta recebida veio inválida.');
      }
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          envelope['success'] == false) {
        final error = envelope['error'];
        final message = error is Map<String, dynamic>
            ? error['message'] as String?
            : null;
        throw DeliveryException(
          message ?? 'Não foi possível confirmar o endereço.',
        );
      }
      return envelope['data'];
    } on FormatException {
      throw const DeliveryException('A resposta recebida veio inválida.');
    }
  }

  void close() => _client.close();
}

class AddressDraft {
  const AddressDraft({
    required this.label,
    required this.zipCode,
    required this.street,
    required this.number,
    required this.complement,
    required this.district,
    required this.city,
    required this.state,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  final String label;
  final String zipCode;
  final String street;
  final String number;
  final String complement;
  final String district;
  final String city;
  final String state;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  Map<String, dynamic> toJson() => {
    if (label.trim().isNotEmpty) 'label': label.trim(),
    'zipCode': zipCode.replaceAll(RegExp(r'[^0-9]'), ''),
    'street': street.trim(),
    'number': number.trim(),
    if (complement.trim().isNotEmpty) 'complement': complement.trim(),
    'district': district.trim(),
    'city': city.trim(),
    'state': state.trim().toUpperCase(),
    'country': 'BR',
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    'isDefault': isDefault,
  };
}

class SavedAddress {
  const SavedAddress({
    required this.publicId,
    required this.label,
    required this.zipCode,
    required this.street,
    required this.number,
    required this.complement,
    required this.district,
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
    required this.status,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
    publicId: json['addressPublicId'] as String,
    label: json['label'] as String?,
    zipCode: json['zipCode'] as String,
    street: json['street'] as String,
    number: json['number'] as String,
    complement: json['complement'] as String?,
    district: json['district'] as String,
    city: json['city'] as String,
    state: json['state'] as String,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    isDefault: json['isDefault'] as bool? ?? false,
    status: json['status'] as String,
  );

  final String publicId;
  final String? label;
  final String zipCode;
  final String street;
  final String number;
  final String? complement;
  final String district;
  final String city;
  final String state;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final String status;

  String get title => label?.trim().isNotEmpty == true ? label! : 'Endereço';
  String get line1 => '$street, $number';
  String get line2 => '$district • $city/$state';
}

class PurchaseDelivery {
  const PurchaseDelivery({
    required this.publicId,
    required this.addressPublicId,
    required this.street,
    required this.number,
    required this.complement,
    required this.district,
    required this.city,
    required this.state,
    required this.status,
  });

  factory PurchaseDelivery.fromJson(Map<String, dynamic> json) =>
      PurchaseDelivery(
        publicId: json['deliveryPublicId'] as String,
        addressPublicId: json['addressPublicId'] as String,
        street: json['street'] as String,
        number: json['number'] as String,
        complement: json['complement'] as String?,
        district: json['district'] as String,
        city: json['city'] as String,
        state: json['state'] as String,
        status: json['status'] as String,
      );

  final String publicId;
  final String addressPublicId;
  final String street;
  final String number;
  final String? complement;
  final String district;
  final String city;
  final String state;
  final String status;

  String get line1 => '$street, $number';
  String get line2 => '$district • $city/$state';
}

class DeliveryException implements Exception {
  const DeliveryException(this.message);
  final String message;

  @override
  String toString() => message;
}

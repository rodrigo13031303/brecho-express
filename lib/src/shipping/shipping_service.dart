import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/brecho_session.dart';

class ShippingService {
  ShippingService({http.Client? client}) : _client = client ?? http.Client();

  static final _baseUri = Uri.parse(
    'https://app.rodrigosburguer.com.br/ords/brechoexpress/api/v1/',
  );
  final http.Client _client;

  Future<List<ShippingOption>> quote({
    required BrechoSession session,
    required String requestPublicId,
  }) async {
    final request = Uri.encodeComponent(requestPublicId);
    final response = await _send(
      'GET',
      _baseUri.resolve('purchase-requests/$request/shipping-options'),
      session,
    );
    return _decodeOptions(response);
  }

  Future<List<ShippingOption>> select({
    required BrechoSession session,
    required String requestPublicId,
    required String optionPublicId,
  }) async {
    final request = Uri.encodeComponent(requestPublicId);
    final response = await _send(
      'PUT',
      _baseUri.resolve('purchase-requests/$request/shipping-options'),
      session,
      body: {'optionPublicId': optionPublicId},
    );
    return _decodeOptions(response);
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
      return http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 45)),
      );
    } on TimeoutException {
      throw const ShippingException('O cálculo demorou. Tente novamente.');
    } on http.ClientException {
      throw const ShippingException('Não foi possível calcular o frete agora.');
    }
  }

  List<ShippingOption> _decodeOptions(http.Response response) {
    try {
      final envelope = jsonDecode(response.body);
      if (envelope is! Map<String, dynamic>) {
        throw const ShippingException('A cotação recebida veio inválida.');
      }
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          envelope['success'] == false) {
        final error = envelope['error'];
        final message = error is Map<String, dynamic>
            ? error['message'] as String?
            : null;
        throw ShippingException(
          message ?? 'Não foi possível calcular o frete.',
        );
      }
      final data = envelope['data'];
      if (data is! List) {
        throw const ShippingException('A cotação recebida veio inválida.');
      }
      return data
          .whereType<Map<String, dynamic>>()
          .map(ShippingOption.fromJson)
          .toList(growable: false);
    } on FormatException {
      throw const ShippingException('A cotação recebida veio inválida.');
    }
  }

  void close() => _client.close();
}

class ShippingOption {
  const ShippingOption({
    required this.publicId,
    required this.storePublicId,
    required this.storeName,
    required this.method,
    required this.price,
    required this.distanceKm,
    required this.minDays,
    required this.maxDays,
    required this.expiresAt,
    required this.isSelected,
  });

  factory ShippingOption.fromJson(Map<String, dynamic> json) => ShippingOption(
    publicId: json['optionPublicId'] as String,
    storePublicId: json['storePublicId'] as String,
    storeName: json['storeName'] as String,
    method: json['method'] as String,
    price: (json['price'] as num).toDouble(),
    distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    minDays: (json['estimatedMinDays'] as num).toInt(),
    maxDays: (json['estimatedMaxDays'] as num).toInt(),
    expiresAt: DateTime.parse(json['expiresAt'] as String),
    isSelected: json['isSelected'] as bool? ?? false,
  );

  final String publicId;
  final String storePublicId;
  final String storeName;
  final String method;
  final double price;
  final double? distanceKm;
  final int minDays;
  final int maxDays;
  final DateTime expiresAt;
  final bool isSelected;

  String get methodLabel =>
      method == 'PICKUP' ? 'Retirar no brechó' : 'Entrega local';
}

class ShippingException implements Exception {
  const ShippingException(this.message);
  final String message;

  @override
  String toString() => message;
}

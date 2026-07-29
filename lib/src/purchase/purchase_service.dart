import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/brecho_session.dart';
import '../cart/cart_service.dart';

class PurchaseService {
  PurchaseService({http.Client? client}) : _client = client ?? http.Client();

  static final _baseUri = Uri.parse(
    'https://app.rodrigosburguer.com.br/ords/brechoexpress/api/v1/',
  );
  final http.Client _client;

  Future<List<PurchaseRequest>> listBuyer(BrechoSession session) async {
    final response = await _get(_baseUri.resolve('purchase-requests'), session);
    return _decodeList(response);
  }

  Future<List<PurchaseRequest>> listStore({
    required BrechoSession session,
    required String storePublicId,
  }) async {
    final store = Uri.encodeComponent(storePublicId);
    final response = await _get(
      _baseUri.resolve('stores/$store/purchase-requests'),
      session,
    );
    return _decodeList(response);
  }

  Future<PurchaseRequest> respond({
    required BrechoSession session,
    required String storePublicId,
    required String requestPublicId,
    required String itemPublicId,
    required int confirmedQuantity,
    String? rejectReason,
  }) async {
    final store = Uri.encodeComponent(storePublicId);
    final request = Uri.encodeComponent(requestPublicId);
    final item = Uri.encodeComponent(itemPublicId);
    final response = await _post(
      _baseUri.resolve(
        'stores/$store/purchase-requests/$request/items/$item/respond',
      ),
      session,
      {
        'confirmedQuantity': confirmedQuantity,
        if (rejectReason?.trim().isNotEmpty ?? false)
          'rejectReason': rejectReason!.trim(),
      },
    );
    return PurchaseRequest.fromJson(_decodeObject(response));
  }

  Future<http.Response> _get(Uri uri, BrechoSession session) async {
    try {
      return await _client
          .get(uri, headers: _headers(session))
          .timeout(const Duration(seconds: 45));
    } on TimeoutException {
      throw const PurchaseException('A consulta demorou. Tente novamente.');
    } on http.ClientException {
      throw const PurchaseException(
        'Não foi possível consultar as solicitações.',
      );
    }
  }

  Future<http.Response> _post(
    Uri uri,
    BrechoSession session,
    Map<String, dynamic> body,
  ) async {
    try {
      return await _client
          .post(uri, headers: _headers(session), body: jsonEncode(body))
          .timeout(const Duration(seconds: 45));
    } on TimeoutException {
      throw const PurchaseException('A resposta demorou. Tente novamente.');
    } on http.ClientException {
      throw const PurchaseException('Não foi possível enviar a resposta.');
    }
  }

  Map<String, String> _headers(BrechoSession session) => {
    'Authorization': 'Bearer ${session.accessToken}',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  List<PurchaseRequest> _decodeList(http.Response response) {
    final data = _decodeData(response);
    if (data is! List) {
      throw const PurchaseException('A lista recebida veio inválida.');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(PurchaseRequest.fromJson)
        .toList(growable: false);
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    final data = _decodeData(response);
    if (data is! Map<String, dynamic>) {
      throw const PurchaseException('A resposta recebida veio inválida.');
    }
    return data;
  }

  dynamic _decodeData(http.Response response) {
    try {
      final envelope = jsonDecode(response.body);
      if (envelope is! Map<String, dynamic>) {
        throw const PurchaseException('A resposta recebida veio inválida.');
      }
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          envelope['success'] == false) {
        final error = envelope['error'];
        final message = error is Map<String, dynamic>
            ? error['message'] as String?
            : null;
        throw PurchaseException(
          message ?? 'Não foi possível concluir a solicitação.',
        );
      }
      return envelope['data'];
    } on FormatException {
      throw const PurchaseException('A resposta recebida veio inválida.');
    }
  }

  void close() => _client.close();
}

class PurchaseException implements Exception {
  const PurchaseException(this.message);
  final String message;

  @override
  String toString() => message;
}

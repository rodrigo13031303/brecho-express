import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/brecho_session.dart';

class CartService {
  CartService({http.Client? client}) : _client = client ?? http.Client();

  static final _baseUri = Uri.parse(
    'https://app.rodrigosburguer.com.br/ords/brechoexpress/api/v1/',
  );
  final http.Client _client;

  Future<CartSnapshot> load(BrechoSession session) async {
    final response = await _request(
      () => _client.get(_baseUri.resolve('cart'), headers: _headers(session)),
    );
    return CartSnapshot.fromJson(_decodeObject(response));
  }

  Future<CartSnapshot> add({
    required BrechoSession session,
    required String cartPublicId,
    required String productPublicId,
    int quantity = 1,
  }) async {
    final cart = Uri.encodeComponent(cartPublicId);
    final response = await _request(
      () => _client.post(
        _baseUri.resolve('cart/$cart/items'),
        headers: _headers(session),
        body: jsonEncode({
          'productPublicId': productPublicId,
          'quantity': quantity,
        }),
      ),
    );
    return CartSnapshot.fromJson(_decodeObject(response));
  }

  Future<CartSnapshot> update({
    required BrechoSession session,
    required String cartPublicId,
    required String itemPublicId,
    required int quantity,
  }) async {
    final cart = Uri.encodeComponent(cartPublicId);
    final item = Uri.encodeComponent(itemPublicId);
    final response = await _request(
      () => _client.put(
        _baseUri.resolve('cart/$cart/items/$item'),
        headers: _headers(session),
        body: jsonEncode({'quantity': quantity}),
      ),
    );
    return CartSnapshot.fromJson(_decodeObject(response));
  }

  Future<PurchaseRequest> checkout({
    required BrechoSession session,
    required String cartPublicId,
  }) async {
    final cart = Uri.encodeComponent(cartPublicId);
    final response = await _request(
      () => _client.post(
        _baseUri.resolve('cart/$cart/checkout'),
        headers: _headers(session),
        body: '{}',
      ),
    );
    return PurchaseRequest.fromJson(_decodeObject(response));
  }

  Future<CartSnapshot> remove({
    required BrechoSession session,
    required String cartPublicId,
    required String itemPublicId,
  }) async {
    final cart = Uri.encodeComponent(cartPublicId);
    final item = Uri.encodeComponent(itemPublicId);
    final response = await _request(
      () => _client.delete(
        _baseUri.resolve('cart/$cart/items/$item'),
        headers: _headers(session),
      ),
    );
    return CartSnapshot.fromJson(_decodeObject(response));
  }

  Future<http.Response> _request(
    Future<http.Response> Function() callback,
  ) async {
    try {
      return await callback().timeout(const Duration(seconds: 45));
    } on TimeoutException {
      throw const CartException(
        'O carrinho demorou para responder. Tente novamente.',
      );
    } on http.ClientException {
      throw const CartException(
        'Não foi possível acessar o carrinho. Confira sua conexão.',
      );
    }
  }

  Map<String, String> _headers(BrechoSession session) => {
    'Authorization': 'Bearer ${session.accessToken}',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Map<String, dynamic> _decodeObject(http.Response response) {
    try {
      final envelope = jsonDecode(response.body);
      if (envelope is! Map<String, dynamic>) {
        throw const CartException('A resposta do carrinho veio inválida.');
      }
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          envelope['success'] == false) {
        final error = envelope['error'];
        final message = error is Map<String, dynamic>
            ? error['message'] as String?
            : null;
        final code = error is Map<String, dynamic>
            ? error['code'] as String?
            : null;
        throw CartException(
          message ?? 'Não foi possível atualizar o carrinho.',
          code: code,
        );
      }
      final data = envelope['data'];
      if (data is! Map<String, dynamic>) {
        throw const CartException('A resposta do carrinho veio inválida.');
      }
      return data;
    } on FormatException {
      throw const CartException('A resposta do carrinho veio inválida.');
    }
  }

  void close() => _client.close();
}

class CartSnapshot {
  const CartSnapshot({
    required this.publicId,
    required this.status,
    required this.items,
  });

  factory CartSnapshot.fromJson(Map<String, dynamic> json) => CartSnapshot(
    publicId: json['cartPublicId'] as String,
    status: json['status'] as String,
    items: (json['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CartItem.fromJson)
        .toList(growable: false),
  );

  final String publicId;
  final String status;
  final List<CartItem> items;

  int get itemCount => items.fold(0, (total, item) => total + item.quantity);
  double get total =>
      items.fold(0, (total, item) => total + item.unitPrice * item.quantity);
}

class CartItem {
  const CartItem({
    required this.publicId,
    required this.productPublicId,
    required this.storePublicId,
    required this.quantity,
    required this.unitPrice,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    publicId: json['itemPublicId'] as String,
    productPublicId: json['productPublicId'] as String,
    storePublicId: json['storePublicId'] as String,
    quantity: (json['quantity'] as num).toInt(),
    unitPrice: (json['unitPrice'] as num).toDouble(),
  );

  final String publicId;
  final String productPublicId;
  final String storePublicId;
  final int quantity;
  final double unitPrice;
}

class PurchaseRequest {
  const PurchaseRequest({
    required this.publicId,
    required this.status,
    required this.requestedAt,
    required this.expiresAt,
    required this.items,
  });

  factory PurchaseRequest.fromJson(Map<String, dynamic> json) =>
      PurchaseRequest(
        publicId: json['requestPublicId'] as String,
        status: json['status'] as String,
        requestedAt: DateTime.parse(json['requestedAt'] as String),
        expiresAt: json['expiresAt'] == null
            ? null
            : DateTime.parse(json['expiresAt'] as String),
        items: (json['items'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(PurchaseRequestItem.fromJson)
            .toList(growable: false),
      );

  final String publicId;
  final String status;
  final DateTime requestedAt;
  final DateTime? expiresAt;
  final List<PurchaseRequestItem> items;
}

class PurchaseRequestItem {
  const PurchaseRequestItem({
    required this.itemPublicId,
    required this.productPublicId,
    required this.storePublicId,
    required this.quantity,
    required this.unitPrice,
    required this.confirmedQuantity,
    required this.rejectReason,
    required this.status,
  });

  factory PurchaseRequestItem.fromJson(Map<String, dynamic> json) =>
      PurchaseRequestItem(
        itemPublicId: json['itemPublicId'] as String,
        productPublicId: json['productPublicId'] as String,
        storePublicId: json['storePublicId'] as String,
        quantity: (json['requestedQuantity'] as num).toInt(),
        unitPrice: (json['unitPrice'] as num).toDouble(),
        confirmedQuantity: (json['confirmedQuantity'] as num?)?.toInt(),
        rejectReason: json['rejectReason'] as String?,
        status: json['status'] as String,
      );

  final String itemPublicId;
  final String productPublicId;
  final String storePublicId;
  final int quantity;
  final double unitPrice;
  final int? confirmedQuantity;
  final String? rejectReason;
  final String status;
}

class CartException implements Exception {
  const CartException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => message;
}

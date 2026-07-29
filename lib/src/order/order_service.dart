import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/brecho_session.dart';

class OrderService {
  OrderService({http.Client? client}) : _client = client ?? http.Client();

  static final _baseUri = Uri.parse(
    'https://app.rodrigosburguer.com.br/ords/brechoexpress/api/v1/',
  );
  final http.Client _client;

  Future<OrderSnapshot> create({
    required BrechoSession session,
    required String requestPublicId,
  }) async {
    final request = Uri.encodeComponent(requestPublicId);
    final response = await _send(
      'POST',
      _baseUri.resolve('purchase-requests/$request/order'),
      session,
    );
    return OrderSnapshot.fromJson(_decodeObject(response));
  }

  Future<OrderSnapshot> get({
    required BrechoSession session,
    required String orderPublicId,
  }) async {
    final order = Uri.encodeComponent(orderPublicId);
    final response = await _send(
      'GET',
      _baseUri.resolve('orders/$order'),
      session,
    );
    return OrderSnapshot.fromJson(_decodeObject(response));
  }

  Future<http.Response> _send(
    String method,
    Uri uri,
    BrechoSession session,
  ) async {
    try {
      final request = http.Request(method, uri)
        ..headers.addAll({
          'Authorization': 'Bearer ${session.accessToken}',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        });
      if (method == 'POST') request.body = '{}';
      return http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 45)),
      );
    } on TimeoutException {
      throw const OrderException(
        'A criação do pedido demorou. Tente novamente.',
      );
    } on http.ClientException {
      throw const OrderException('Não foi possível criar o pedido agora.');
    }
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    try {
      final envelope = jsonDecode(response.body);
      if (envelope is! Map<String, dynamic>) {
        throw const OrderException('A resposta do pedido veio inválida.');
      }
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          envelope['success'] == false) {
        final error = envelope['error'];
        final message = error is Map<String, dynamic>
            ? error['message'] as String?
            : null;
        throw OrderException(message ?? 'Não foi possível fechar o pedido.');
      }
      final data = envelope['data'];
      if (data is! Map<String, dynamic>) {
        throw const OrderException('A resposta do pedido veio inválida.');
      }
      return data;
    } on FormatException {
      throw const OrderException('A resposta do pedido veio inválida.');
    }
  }

  void close() => _client.close();
}

class OrderSnapshot {
  const OrderSnapshot({
    required this.publicId,
    required this.number,
    required this.status,
    required this.subtotal,
    required this.shipping,
    required this.total,
    required this.createdAt,
    required this.items,
    required this.shipments,
  });

  factory OrderSnapshot.fromJson(Map<String, dynamic> json) => OrderSnapshot(
    publicId: json['orderPublicId'] as String,
    number: json['orderNumber'] as String,
    status: json['status'] as String,
    subtotal: (json['subtotalAmount'] as num).toDouble(),
    shipping: (json['shippingAmount'] as num).toDouble(),
    total: (json['totalAmount'] as num).toDouble(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    items: (json['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(OrderItem.fromJson)
        .toList(growable: false),
    shipments: (json['shipping'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(OrderShipping.fromJson)
        .toList(growable: false),
  );

  final String publicId;
  final String number;
  final String status;
  final double subtotal;
  final double shipping;
  final double total;
  final DateTime createdAt;
  final List<OrderItem> items;
  final List<OrderShipping> shipments;
}

class OrderItem {
  const OrderItem({
    required this.publicId,
    required this.productPublicId,
    required this.storePublicId,
    required this.title,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    publicId: json['itemPublicId'] as String,
    productPublicId: json['productPublicId'] as String,
    storePublicId: json['storePublicId'] as String,
    title: json['title'] as String,
    quantity: (json['quantity'] as num).toInt(),
    unitPrice: (json['unitPrice'] as num).toDouble(),
    totalPrice: (json['totalPrice'] as num).toDouble(),
  );

  final String publicId;
  final String productPublicId;
  final String storePublicId;
  final String title;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
}

class OrderShipping {
  const OrderShipping({
    required this.publicId,
    required this.storePublicId,
    required this.storeName,
    required this.method,
    required this.price,
    required this.distanceKm,
    required this.minDays,
    required this.maxDays,
  });

  factory OrderShipping.fromJson(Map<String, dynamic> json) => OrderShipping(
    publicId: json['shippingPublicId'] as String,
    storePublicId: json['storePublicId'] as String,
    storeName: json['storeName'] as String,
    method: json['method'] as String,
    price: (json['price'] as num).toDouble(),
    distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    minDays: (json['estimatedMinDays'] as num).toInt(),
    maxDays: (json['estimatedMaxDays'] as num).toInt(),
  );

  final String publicId;
  final String storePublicId;
  final String storeName;
  final String method;
  final double price;
  final double? distanceKm;
  final int minDays;
  final int maxDays;

  String get methodLabel =>
      method == 'PICKUP' ? 'Retirada no brechó' : 'Entrega local';
}

class OrderException implements Exception {
  const OrderException(this.message);
  final String message;

  @override
  String toString() => message;
}

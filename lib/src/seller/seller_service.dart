import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../auth/brecho_session.dart';

class SellerService {
  SellerService({http.Client? client}) : _client = client ?? http.Client();

  static final _baseUri = Uri.parse(
    'https://app.rodrigosburguer.com.br/ords/brechoexpress/api/v1/',
  );
  final http.Client _client;

  Future<List<SellerStore>> listStores(BrechoSession session) async {
    final account = Uri.encodeComponent(session.accountPublicId);
    final response = await _get(
      _baseUri.resolve('accounts/$account/stores'),
      session,
    );
    final data = _decodeData(response);
    if (data is! List) {
      throw const SellerException('A lista de brechós veio inválida.');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(SellerStore.fromJson)
        .toList(growable: false);
  }

  Future<SellerStore> createStore({
    required BrechoSession session,
    required String name,
    required String slug,
    String? description,
  }) async {
    final account = Uri.encodeComponent(session.accountPublicId);
    final response = await _post(
      _baseUri.resolve('accounts/$account/stores'),
      session,
      body: {
        'storeName': name,
        'storeSlug': slug,
        if (description?.trim().isNotEmpty ?? false)
          'description': description!.trim(),
        'localeCode': 'pt-BR',
        'timezoneName': 'America/Sao_Paulo',
      },
    );
    return SellerStore.fromJson(_decodeObject(response));
  }

  Future<SellerStore> activateStore(
    BrechoSession session,
    String storePublicId,
  ) async {
    final store = Uri.encodeComponent(storePublicId);
    final response = await _post(
      _baseUri.resolve('stores/$store/actions/activate'),
      session,
    );
    return SellerStore.fromJson(_decodeObject(response));
  }

  Future<String> uploadLogo({
    required BrechoSession session,
    required String storePublicId,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final store = Uri.encodeComponent(storePublicId);
    final response = await _client
        .post(
          _baseUri.resolve('stores/$store/logo'),
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
            'Accept': 'application/json',
            'Content-Type': mimeType,
          },
          body: bytes,
        )
        .timeout(const Duration(seconds: 30));
    final data = _decodeObject(response);
    final logoUrl = data['logoUrl'] as String?;
    if (logoUrl == null || logoUrl.isEmpty) {
      throw const SellerException('O endereço do logo veio inválido.');
    }
    return '$logoUrl?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<SellerProduct> publishProduct({
    required BrechoSession session,
    required String storePublicId,
    required String categoryPublicId,
    required String title,
    required String slug,
    required String description,
    required double price,
    required int quantity,
    required String condition,
  }) async {
    final store = Uri.encodeComponent(storePublicId);
    final created = await _post(
      _baseUri.resolve('stores/$store/products'),
      session,
      body: {
        'categoryPublicId': categoryPublicId,
        'title': title,
        'slug': slug,
        if (description.trim().isNotEmpty) 'description': description.trim(),
        'price': price,
        'quantity': quantity,
        'condition': condition,
      },
    );
    final draft = SellerProduct.fromJson(_decodeObject(created));
    final product = Uri.encodeComponent(draft.publicId);
    final activated = await _post(
      _baseUri.resolve('stores/$store/products/$product/actions/activate'),
      session,
    );
    return SellerProduct.fromJson(_decodeObject(activated));
  }

  Future<http.Response> _get(Uri uri, BrechoSession session) => _client
      .get(uri, headers: _headers(session))
      .timeout(const Duration(seconds: 20));

  Future<http.Response> _post(
    Uri uri,
    BrechoSession session, {
    Map<String, dynamic>? body,
  }) => _client
      .post(
        uri,
        headers: _headers(session),
        body: body == null ? null : jsonEncode(body),
      )
      .timeout(const Duration(seconds: 20));

  Map<String, String> _headers(BrechoSession session) => {
    'Authorization': 'Bearer ${session.accessToken}',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Map<String, dynamic> _decodeObject(http.Response response) {
    final data = _decodeData(response);
    if (data is! Map<String, dynamic>) {
      throw const SellerException('A resposta do servidor veio inválida.');
    }
    return data;
  }

  dynamic _decodeData(http.Response response) {
    try {
      final envelope = jsonDecode(response.body);
      if (envelope is! Map<String, dynamic>) {
        throw const SellerException('A resposta do servidor veio inválida.');
      }
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          envelope['success'] != true) {
        final error = envelope['error'];
        final message = error is Map<String, dynamic>
            ? error['message'] as String?
            : null;
        throw SellerException(
          message ?? 'Não foi possível concluir (${response.statusCode}).',
        );
      }
      return envelope['data'];
    } on FormatException {
      throw const SellerException('A resposta do servidor veio inválida.');
    }
  }

  void close() => _client.close();
}

class SellerStore {
  const SellerStore({
    required this.publicId,
    required this.name,
    required this.slug,
    required this.status,
    this.logoUrl,
  });

  factory SellerStore.fromJson(Map<String, dynamic> json) => SellerStore(
    publicId: json['storePublicId'] as String,
    name: json['storeName'] as String,
    slug: json['storeSlug'] as String,
    status: json['status'] as String,
    logoUrl: json['logoUrl'] as String?,
  );

  final String publicId;
  final String name;
  final String slug;
  final String status;
  final String? logoUrl;

  SellerStore withLogo(String value) => SellerStore(
    publicId: publicId,
    name: name,
    slug: slug,
    status: status,
    logoUrl: value,
  );
}

class SellerProduct {
  const SellerProduct({
    required this.publicId,
    required this.title,
    required this.status,
  });

  factory SellerProduct.fromJson(Map<String, dynamic> json) => SellerProduct(
    publicId: json['productPublicId'] as String,
    title: json['title'] as String,
    status: json['status'] as String,
  );

  final String publicId;
  final String title;
  final String status;
}

class SellerException implements Exception {
  const SellerException(this.message);
  final String message;
}

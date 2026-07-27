import 'dart:convert';

import 'package:http/http.dart' as http;

class CatalogService {
  CatalogService({http.Client? client}) : _client = client ?? http.Client();

  static final _baseUri = Uri.parse(
    'https://app.rodrigosburguer.com.br/ords/brechoexpress/api/v1/',
  );
  final http.Client _client;

  Future<CatalogSnapshot> load() async {
    final responses = await Future.wait([
      _client.get(_baseUri.resolve('categories')),
      _client.get(_baseUri.resolve('products')),
    ]).timeout(const Duration(seconds: 20));
    return CatalogSnapshot(
      categories: _decodeList(responses[0], CatalogCategory.fromJson),
      products: _decodeList(responses[1], CatalogProduct.fromJson),
    );
  }

  Future<CatalogProductDetail> loadProductDetail(String publicId) async {
    final encoded = Uri.encodeComponent(publicId);
    final responses = await Future.wait([
      _client.get(_baseUri.resolve('products/$encoded')),
      _client.get(_baseUri.resolve('products/$encoded/images')),
    ]).timeout(const Duration(seconds: 20));
    return CatalogProductDetail(
      product: _decodeObject(responses[0], CatalogProduct.fromJson),
      images: _decodeList(responses[1], CatalogImage.fromJson),
    );
  }

  T _decodeObject<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (response.statusCode != 200) {
      throw CatalogException('Detalhe indisponível (${response.statusCode}).');
    }
    try {
      final envelope = jsonDecode(response.body);
      if (envelope is! Map<String, dynamic> ||
          envelope['success'] != true ||
          envelope['data'] is! Map<String, dynamic>) {
        throw const CatalogException('Resposta inválida do catálogo.');
      }
      return fromJson(envelope['data'] as Map<String, dynamic>);
    } on FormatException {
      throw const CatalogException('Resposta inválida do catálogo.');
    }
  }

  List<T> _decodeList<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (response.statusCode != 200) {
      throw CatalogException('Catálogo indisponível (${response.statusCode}).');
    }
    try {
      final envelope = jsonDecode(response.body);
      if (envelope is! Map<String, dynamic> || envelope['success'] != true) {
        throw const CatalogException('Resposta inválida do catálogo.');
      }
      final data = envelope['data'];
      if (data is! List) {
        throw const CatalogException('Lista inválida do catálogo.');
      }
      return data
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList(growable: false);
    } on FormatException {
      throw const CatalogException('Resposta inválida do catálogo.');
    }
  }

  void close() => _client.close();
}

class CatalogSnapshot {
  const CatalogSnapshot({required this.categories, required this.products});
  final List<CatalogCategory> categories;
  final List<CatalogProduct> products;
}

class CatalogCategory {
  const CatalogCategory({
    required this.publicId,
    required this.name,
    required this.slug,
  });
  factory CatalogCategory.fromJson(Map<String, dynamic> json) =>
      CatalogCategory(
        publicId: json['categoryPublicId'] as String,
        name: json['categoryName'] as String,
        slug: json['categorySlug'] as String,
      );
  final String publicId;
  final String name;
  final String slug;
}

class CatalogProduct {
  const CatalogProduct({
    required this.publicId,
    required this.title,
    required this.price,
    required this.condition,
    this.description,
  });
  factory CatalogProduct.fromJson(Map<String, dynamic> json) => CatalogProduct(
    publicId: json['productPublicId'] as String,
    title: json['title'] as String,
    price: (json['price'] as num).toDouble(),
    condition: json['condition'] as String,
    description: json['description'] as String?,
  );
  final String publicId;
  final String title;
  final double price;
  final String condition;
  final String? description;

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    return normalized.isEmpty ||
        title.toLowerCase().contains(normalized) ||
        (description?.toLowerCase().contains(normalized) ?? false);
  }
}

class CatalogProductDetail {
  const CatalogProductDetail({required this.product, required this.images});
  final CatalogProduct product;
  final List<CatalogImage> images;
}

class CatalogImage {
  const CatalogImage({
    required this.publicId,
    required this.url,
    required this.sortOrder,
    required this.isPrimary,
    this.altText,
  });
  factory CatalogImage.fromJson(Map<String, dynamic> json) => CatalogImage(
    publicId: json['imagePublicId'] as String,
    url: json['imageUrl'] as String,
    sortOrder: (json['sortOrder'] as num).toInt(),
    isPrimary: json['isPrimary'] as bool,
    altText: json['altText'] as String?,
  );
  final String publicId;
  final String url;
  final int sortOrder;
  final bool isPrimary;
  final String? altText;
}

class CatalogException implements Exception {
  const CatalogException(this.message);
  final String message;
}

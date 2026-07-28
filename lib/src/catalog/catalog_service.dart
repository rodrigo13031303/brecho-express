import 'dart:convert';

import 'package:http/http.dart' as http;

class CatalogService {
  CatalogService({http.Client? client}) : _client = client ?? http.Client();

  static final _baseUri = Uri.parse(
    'https://app.rodrigosburguer.com.br/ords/brechoexpress/api/v1/',
  );
  final http.Client _client;

  Future<CatalogSnapshot> load({
    double? requesterLatitude,
    double? requesterLongitude,
  }) async {
    final responses = await Future.wait([
      _client.get(_baseUri.resolve('categories')),
      _client.get(_baseUri.resolve('products')),
    ]).timeout(const Duration(seconds: 20));
    final categories = _decodeList(responses[0], CatalogCategory.fromJson);
    final products = _decodeList(responses[1], CatalogProduct.fromJson);
    final storeIds = products
        .map((product) => product.storePublicId)
        .whereType<String>()
        .toSet();
    final locations = <String, CatalogPublicLocation>{};
    await Future.wait(
      storeIds.map((storeId) async {
        final location = await _loadStoreLocation(
          storeId,
          requesterLatitude: requesterLatitude,
          requesterLongitude: requesterLongitude,
        );
        if (location != null) locations[storeId] = location;
      }),
    ).timeout(const Duration(seconds: 20));
    return CatalogSnapshot(
      categories: categories,
      products: products
          .map(
            (product) => product.withLocation(
              product.storePublicId == null
                  ? null
                  : locations[product.storePublicId],
            ),
          )
          .toList(growable: false),
    );
  }

  Future<CatalogPublicLocation?> _loadStoreLocation(
    String storePublicId, {
    double? requesterLatitude,
    double? requesterLongitude,
  }) async {
    var uri = _baseUri.resolve(
      'stores/${Uri.encodeComponent(storePublicId)}/location',
    );
    if (requesterLatitude != null && requesterLongitude != null) {
      uri = uri.replace(
        queryParameters: {
          'requesterLatitude': requesterLatitude.toString(),
          'requesterLongitude': requesterLongitude.toString(),
        },
      );
    }
    late final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 10));
    } catch (_) {
      return null;
    }
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) return null;
    try {
      final envelope = jsonDecode(response.body) as Map<String, dynamic>;
      final data = envelope['data'];
      return data is Map<String, dynamic>
          ? CatalogPublicLocation.fromJson(data)
          : null;
    } on FormatException {
      return null;
    }
  }

  Future<CatalogProductDetail> loadProductDetail(
    String publicId, {
    CatalogPublicLocation? location,
  }) async {
    final encoded = Uri.encodeComponent(publicId);
    final responses = await Future.wait([
      _client.get(_baseUri.resolve('products/$encoded')),
      _client.get(_baseUri.resolve('products/$encoded/images')),
    ]).timeout(const Duration(seconds: 20));
    return CatalogProductDetail(
      product: _decodeObject(
        responses[0],
        CatalogProduct.fromJson,
      ).withLocation(location),
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
    this.storePublicId,
    this.storeName,
    this.storeLogoUrl,
    this.primaryImageUrl,
    this.imageCount = 0,
    this.weight,
    this.width,
    this.height,
    this.length,
    this.location,
  });
  factory CatalogProduct.fromJson(Map<String, dynamic> json) => CatalogProduct(
    publicId: json['productPublicId'] as String,
    title: json['title'] as String,
    price: (json['price'] as num).toDouble(),
    condition: json['condition'] as String,
    description: json['description'] as String?,
    storePublicId: json['storePublicId'] as String?,
    storeName: json['storeName'] as String?,
    storeLogoUrl: json['storeLogoUrl'] as String?,
    primaryImageUrl: json['primaryImageUrl'] as String?,
    imageCount: (json['imageCount'] as num?)?.toInt() ?? 0,
    weight: (json['weight'] as num?)?.toDouble(),
    width: (json['width'] as num?)?.toDouble(),
    height: (json['height'] as num?)?.toDouble(),
    length: (json['length'] as num?)?.toDouble(),
  );
  final String publicId;
  final String title;
  final double price;
  final String condition;
  final String? description;
  final String? storePublicId;
  final String? storeName;
  final String? storeLogoUrl;
  final String? primaryImageUrl;
  final int imageCount;
  final double? weight;
  final double? width;
  final double? height;
  final double? length;
  final CatalogPublicLocation? location;

  CatalogProduct withLocation(CatalogPublicLocation? value) => CatalogProduct(
    publicId: publicId,
    title: title,
    price: price,
    condition: condition,
    description: description,
    storePublicId: storePublicId,
    storeName: storeName,
    storeLogoUrl: storeLogoUrl,
    primaryImageUrl: primaryImageUrl,
    imageCount: imageCount,
    weight: weight,
    width: width,
    height: height,
    length: length,
    location: value,
  );

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    return normalized.isEmpty ||
        title.toLowerCase().contains(normalized) ||
        (description?.toLowerCase().contains(normalized) ?? false);
  }
}

class CatalogPublicLocation {
  const CatalogPublicLocation({
    required this.district,
    required this.city,
    required this.state,
    this.distanceKm,
  });

  factory CatalogPublicLocation.fromJson(Map<String, dynamic> json) =>
      CatalogPublicLocation(
        district: json['district'] as String,
        city: json['city'] as String,
        state: json['state'] as String,
        distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      );

  final String district;
  final String city;
  final String state;
  final double? distanceKm;

  String get label {
    final distance = distanceKm;
    if (distance == null) return '$district • $city/$state';
    if (distance < 1) return '$district • a menos de 1 km';
    final formatted = distance < 10
        ? distance.toStringAsFixed(1).replaceAll('.', ',')
        : distance.round().toString();
    return '$district • a $formatted km';
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

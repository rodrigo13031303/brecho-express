import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../auth/brecho_session.dart';
import '../location/store_location_service.dart';

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

  Future<SellerStore> createCompleteStore({
    required BrechoSession session,
    required String name,
    required String slug,
    required StoreLocationDraft location,
    Uint8List? logoBytes,
    String? logoMimeType,
    String? description,
  }) async {
    final account = Uri.encodeComponent(session.accountPublicId);
    final response = await _post(
      _baseUri.resolve('accounts/$account/stores/onboarding'),
      session,
      body: {
        'storeName': name,
        'storeSlug': slug,
        if (description?.trim().isNotEmpty ?? false)
          'description': description!.trim(),
        if (logoBytes != null && logoMimeType != null)
          'logo': {
            'mimeType': logoMimeType,
            'contentBase64': base64Encode(logoBytes),
          },
        'location': {
          'postalCode': location.postalCode,
          'street': location.street,
          'number': location.number,
          if (location.complement.trim().isNotEmpty)
            'complement': location.complement,
          'district': location.district,
          'city': location.city,
          'state': location.state,
          'latitude': location.latitude!,
          'longitude': location.longitude!,
        },
      },
    );
    try {
      return SellerStore.fromJson(_decodeObject(response));
    } on SellerException {
      final successfulStatus =
          response.statusCode >= 200 && response.statusCode < 300;
      if (!successfulStatus) rethrow;

      final stores = await listStores(session);
      final normalizedSlug = slug.trim().toLowerCase();
      for (final store in stores) {
        if (store.slug.trim().toLowerCase() == normalizedSlug) {
          return store;
        }
      }
      throw const SellerException(
        'O servidor confirmou a criação, mas não foi possível carregar o brechó.',
      );
    }
  }

  Future<SellerStore> activateStore(
    BrechoSession session,
    String storePublicId,
  ) async {
    final store = Uri.encodeComponent(storePublicId);
    final response = await _post(
      _baseUri.resolve('stores/$store/actions/activate'),
      session,
      body: const {},
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

  Future<StoreLocationDraft> loadLocation({
    required BrechoSession session,
    required String storePublicId,
  }) async {
    final store = Uri.encodeComponent(storePublicId);
    final response = await _get(
      _baseUri.resolve('stores/$store/location/owner'),
      session,
    );
    final data = _decodeObject(response);
    return StoreLocationDraft(
      postalCode: data['postalCode'] as String,
      street: data['street'] as String,
      number: data['number'] as String,
      complement: data['complement'] as String? ?? '',
      district: data['district'] as String,
      city: data['city'] as String,
      state: data['state'] as String,
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
    );
  }

  Future<void> saveLocation({
    required BrechoSession session,
    required String storePublicId,
    required StoreLocationDraft location,
  }) async {
    final store = Uri.encodeComponent(storePublicId);
    final response = await _client
        .put(
          _baseUri.resolve('stores/$store/location'),
          headers: _headers(session),
          body: jsonEncode({
            'postalCode': location.postalCode,
            'street': location.street,
            'number': location.number,
            if (location.complement.trim().isNotEmpty)
              'complement': location.complement,
            'district': location.district,
            'city': location.city,
            'state': location.state,
            'latitude': location.latitude!,
            'longitude': location.longitude!,
          }),
        )
        .timeout(const Duration(seconds: 20));
    _decodeObject(response);
  }

  Future<StoreShippingConfig> loadShippingConfig({
    required BrechoSession session,
    required String storePublicId,
  }) async {
    final store = Uri.encodeComponent(storePublicId);
    final response = await _get(
      _baseUri.resolve('stores/$store/shipping-config'),
      session,
    );
    return StoreShippingConfig.fromJson(_decodeObject(response));
  }

  Future<StoreShippingConfig> saveShippingConfig({
    required BrechoSession session,
    required String storePublicId,
    required StoreShippingConfig config,
  }) async {
    final store = Uri.encodeComponent(storePublicId);
    final response = await _client
        .put(
          _baseUri.resolve('stores/$store/shipping-config'),
          headers: _headers(session),
          body: jsonEncode(config.toJson()),
        )
        .timeout(const Duration(seconds: 30));
    return StoreShippingConfig.fromJson(_decodeObject(response));
  }

  Future<List<SellerProduct>> listProducts({
    required BrechoSession session,
    required String storePublicId,
  }) async {
    final store = Uri.encodeComponent(storePublicId);
    final response = await _get(
      _baseUri.resolve('stores/$store/products'),
      session,
    );
    final data = _decodeData(response);
    if (data is! List) {
      throw const SellerException('A lista de produtos veio inválida.');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(SellerProduct.fromJson)
        .toList(growable: false);
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
    required double weight,
    required double width,
    required double height,
    required double length,
    required List<SellerProductImageUpload> images,
  }) async {
    final store = Uri.encodeComponent(storePublicId);
    final productBody = <String, dynamic>{
      'categoryPublicId': categoryPublicId,
      'title': title,
      'slug': slug,
      if (description.trim().isNotEmpty) 'description': description.trim(),
      'price': price,
      'quantity': quantity,
      'condition': condition,
      'weight': weight,
      'width': width,
      'height': height,
      'length': length,
    };
    http.Response created;
    try {
      created = await _post(
        _baseUri.resolve('stores/$store/products'),
        session,
        body: productBody,
      );
      _decodeObject(created);
    } on SellerException catch (error) {
      if (error.code != 'BEX-PRD-004') rethrow;
      productBody['slug'] =
          '$slug-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
      created = await _post(
        _baseUri.resolve('stores/$store/products'),
        session,
        body: productBody,
      );
    }
    final draft = SellerProduct.fromJson(_decodeObject(created));
    for (var index = 0; index < images.length; index++) {
      await uploadProductImage(
        session: session,
        productPublicId: draft.publicId,
        image: images[index],
        sortOrder: index,
        isPrimary: index == 0,
      );
    }
    final product = Uri.encodeComponent(draft.publicId);
    final activated = await _post(
      _baseUri.resolve('stores/$store/products/$product/actions/activate'),
      session,
      body: const {},
    );
    return SellerProduct.fromJson(_decodeObject(activated));
  }

  Future<SellerProduct> updateProduct({
    required BrechoSession session,
    required String storePublicId,
    required SellerProduct product,
    required Map<String, dynamic> changes,
  }) async {
    final store = Uri.encodeComponent(storePublicId);
    final encodedProduct = Uri.encodeComponent(product.publicId);
    final response = await _client
        .put(
          _baseUri.resolve('stores/$store/products/$encodedProduct'),
          headers: _headers(session),
          body: jsonEncode(changes),
        )
        .timeout(const Duration(seconds: 30));
    return SellerProduct.fromJson(_decodeObject(response));
  }

  Future<SellerProduct> changeProductStatus({
    required BrechoSession session,
    required String storePublicId,
    required String productPublicId,
    required String status,
  }) async {
    final store = Uri.encodeComponent(storePublicId);
    final product = Uri.encodeComponent(productPublicId);
    final response = await _client
        .put(
          _baseUri.resolve('stores/$store/products/$product/status'),
          headers: _headers(session),
          body: jsonEncode({'status': status}),
        )
        .timeout(const Duration(seconds: 30));
    return SellerProduct.fromJson(_decodeObject(response));
  }

  Future<void> uploadProductImage({
    required BrechoSession session,
    required String productPublicId,
    required SellerProductImageUpload image,
    required int sortOrder,
    required bool isPrimary,
  }) async {
    final product = Uri.encodeComponent(productPublicId);
    final response = await _client
        .post(
          _baseUri.resolve('products/$product/images/media'),
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
            'Accept': 'application/json',
            'Content-Type': image.mimeType,
            'X-Image-Sort-Order': '$sortOrder',
            'X-Image-Primary': isPrimary ? '1' : '0',
          },
          body: image.bytes,
        )
        .timeout(
          const Duration(seconds: 90),
          onTimeout: () {
            throw const SellerException(
              'A foto demorou para enviar. Tente novamente com uma conexão estável.',
            );
          },
        );
    _decodeObject(response);
  }

  Future<http.Response> _get(Uri uri, BrechoSession session) async {
    try {
      return await _client
          .get(uri, headers: _headers(session))
          .timeout(const Duration(seconds: 45));
    } on http.ClientException {
      throw const SellerException(
        'A conexão oscilou. Confira sua internet e tente novamente.',
      );
    } on TimeoutException {
      throw const SellerException(
        'O servidor demorou para responder. Tente novamente em instantes.',
      );
    }
  }

  Future<http.Response> _post(
    Uri uri,
    BrechoSession session, {
    Map<String, dynamic>? body,
  }) async {
    try {
      return await _client
          .post(
            uri,
            headers: _headers(session),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));
    } on http.ClientException {
      throw const SellerException(
        'A conexão oscilou. Confira sua internet e tente novamente.',
      );
    } on TimeoutException {
      throw const SellerException(
        'O servidor demorou para responder. Tente novamente em instantes.',
      );
    }
  }

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
      final successfulStatus =
          response.statusCode >= 200 && response.statusCode < 300;
      final successfulEnvelope = envelope['success'] == true;
      final hasSuccessfulData =
          successfulStatus &&
          envelope.containsKey('data') &&
          envelope['success'] != false;
      if (!successfulStatus || (!successfulEnvelope && !hasSuccessfulData)) {
        final error = envelope['error'];
        final message = error is Map<String, dynamic>
            ? error['message'] as String?
            : null;
        final code = error is Map<String, dynamic>
            ? error['code'] as String?
            : null;
        final traceId = envelope['traceId'] as String?;
        final baseMessage =
            message ?? 'Não foi possível concluir (${response.statusCode}).';
        throw SellerException(
          traceId == null ? baseMessage : '$baseMessage Protocolo: $traceId.',
          code: code,
          traceId: traceId,
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

class StoreShippingConfig {
  const StoreShippingConfig({
    required this.pickupEnabled,
    required this.localDeliveryEnabled,
    required this.localBasePrice,
    required this.localPricePerKm,
    required this.localMaxDistanceKm,
    required this.preparationDays,
  });

  factory StoreShippingConfig.fromJson(Map<String, dynamic> json) =>
      StoreShippingConfig(
        pickupEnabled: json['pickupEnabled'] as bool? ?? true,
        localDeliveryEnabled: json['localDeliveryEnabled'] as bool? ?? true,
        localBasePrice: (json['localBasePrice'] as num).toDouble(),
        localPricePerKm: (json['localPricePerKm'] as num).toDouble(),
        localMaxDistanceKm: (json['localMaxDistanceKm'] as num).toDouble(),
        preparationDays: (json['preparationDays'] as num).toInt(),
      );

  final bool pickupEnabled;
  final bool localDeliveryEnabled;
  final double localBasePrice;
  final double localPricePerKm;
  final double localMaxDistanceKm;
  final int preparationDays;

  Map<String, dynamic> toJson() => {
    'pickupEnabled': pickupEnabled,
    'localDeliveryEnabled': localDeliveryEnabled,
    'localBasePrice': localBasePrice,
    'localPricePerKm': localPricePerKm,
    'localMaxDistanceKm': localMaxDistanceKm,
    'preparationDays': preparationDays,
  };
}

class SellerProduct {
  const SellerProduct({
    required this.publicId,
    required this.title,
    required this.status,
    this.slug = '',
    this.quantity = 0,
    this.condition = 'GOOD',
    this.categoryPublicId,
    this.description,
    this.price,
    this.primaryImageUrl,
    this.imageCount = 0,
    this.weight,
    this.width,
    this.height,
    this.length,
  });

  factory SellerProduct.fromJson(Map<String, dynamic> json) => SellerProduct(
    publicId: json['productPublicId'] as String,
    title: json['title'] as String,
    status: json['status'] as String,
    slug: json['slug'] as String? ?? '',
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    condition: json['condition'] as String? ?? 'GOOD',
    categoryPublicId: json['categoryPublicId'] as String?,
    description: json['description'] as String?,
    price: (json['price'] as num?)?.toDouble(),
    primaryImageUrl: json['primaryImageUrl'] as String?,
    imageCount: (json['imageCount'] as num?)?.toInt() ?? 0,
    weight: (json['weight'] as num?)?.toDouble(),
    width: (json['width'] as num?)?.toDouble(),
    height: (json['height'] as num?)?.toDouble(),
    length: (json['length'] as num?)?.toDouble(),
  );

  final String publicId;
  final String title;
  final String status;
  final String slug;
  final int quantity;
  final String condition;
  final String? categoryPublicId;
  final String? description;
  final double? price;
  final String? primaryImageUrl;
  final int imageCount;
  final double? weight;
  final double? width;
  final double? height;
  final double? length;
}

class SellerException implements Exception {
  const SellerException(this.message, {this.code, this.traceId});
  final String message;
  final String? code;
  final String? traceId;
}

class SellerProductImageUpload {
  const SellerProductImageUpload({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;
}

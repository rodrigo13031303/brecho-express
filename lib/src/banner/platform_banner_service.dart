import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../auth/brecho_session.dart';

class PlatformBannerService {
  PlatformBannerService({http.Client? client})
    : _client = client ?? http.Client();

  static final _baseUri = Uri.parse(
    'https://app.rodrigosburguer.com.br/ords/brechoexpress/api/v1/',
  );
  final http.Client _client;

  Future<List<PlatformBanner>> listPublic() async {
    final response = await _client
        .get(_baseUri.resolve('platform-banners'))
        .timeout(const Duration(seconds: 12));
    return _decodeList(response);
  }

  Future<Set<String>> myRoles(BrechoSession session) async {
    final response = await _client
        .get(_baseUri.resolve('me/roles'), headers: _headers(session))
        .timeout(const Duration(seconds: 15));
    final data = _decodeData(response);
    return (data as List? ?? const [])
        .whereType<String>()
        .map((item) => item.toUpperCase())
        .toSet();
  }

  Future<List<PlatformBanner>> listAdmin(BrechoSession session) async {
    final response = await _client
        .get(
          _baseUri.resolve('admin/platform-banners'),
          headers: _headers(session),
        )
        .timeout(const Duration(seconds: 20));
    return _decodeList(response);
  }

  Future<PlatformBanner> save({
    required BrechoSession session,
    required PlatformBannerDraft draft,
    PlatformBanner? current,
  }) async {
    final body = jsonEncode(draft.toJson());
    final response = current == null
        ? await _client.post(
            _baseUri.resolve('admin/platform-banners'),
            headers: {..._headers(session), 'Content-Type': 'application/json'},
            body: body,
          )
        : await _client.put(
            _baseUri.resolve(
              'admin/platform-banners/'
              '${Uri.encodeComponent(current.publicId)}',
            ),
            headers: {..._headers(session), 'Content-Type': 'application/json'},
            body: body,
          );
    return PlatformBanner.fromJson(_decodeObject(response));
  }

  Future<PlatformBanner> uploadImage({
    required BrechoSession session,
    required String bannerPublicId,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final response = await _client
        .post(
          _baseUri.resolve(
            'admin/platform-banners/'
            '${Uri.encodeComponent(bannerPublicId)}/image',
          ),
          headers: {..._headers(session), 'Content-Type': mimeType},
          body: bytes,
        )
        .timeout(const Duration(seconds: 90));
    return PlatformBanner.fromJson(_decodeObject(response));
  }

  Map<String, String> _headers(BrechoSession session) => {
    'Authorization': 'Bearer ${session.accessToken}',
    'Accept': 'application/json',
  };

  List<PlatformBanner> _decodeList(http.Response response) {
    final data = _decodeData(response);
    if (data is! List) {
      throw const PlatformBannerException('A lista de banners veio inválida.');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(PlatformBanner.fromJson)
        .toList(growable: false);
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    final data = _decodeData(response);
    if (data is! Map<String, dynamic>) {
      throw const PlatformBannerException('O banner recebido veio inválido.');
    }
    return data;
  }

  dynamic _decodeData(http.Response response) {
    try {
      final envelope = jsonDecode(response.body);
      if (envelope is! Map<String, dynamic>) {
        throw const PlatformBannerException('A resposta veio inválida.');
      }
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          envelope['success'] != true) {
        final error = envelope['error'];
        final message = error is Map<String, dynamic>
            ? error['message'] as String?
            : null;
        throw PlatformBannerException(
          message ?? 'Não foi possível concluir a operação.',
        );
      }
      return envelope['data'];
    } on FormatException {
      throw const PlatformBannerException('A resposta veio inválida.');
    }
  }

  void close() => _client.close();
}

class PlatformBanner {
  const PlatformBanner({
    required this.publicId,
    required this.title,
    required this.altText,
    required this.targetType,
    required this.startAt,
    required this.endAt,
    required this.displayOrder,
    required this.status,
    this.imageUrl,
    this.targetPublicId,
    this.targetValue,
  });

  factory PlatformBanner.fromJson(Map<String, dynamic> json) => PlatformBanner(
    publicId: json['bannerPublicId'] as String,
    title: json['title'] as String,
    altText: json['altText'] as String,
    imageUrl: json['imageUrl'] as String?,
    targetType: json['targetType'] as String,
    targetPublicId: json['targetPublicId'] as String?,
    targetValue: json['targetValue'] as String?,
    startAt: DateTime.parse(json['startAt'] as String),
    endAt: DateTime.parse(json['endAt'] as String),
    displayOrder: (json['displayOrder'] as num).toInt(),
    status: json['status'] as String,
  );

  final String publicId;
  final String title;
  final String altText;
  final String? imageUrl;
  final String targetType;
  final String? targetPublicId;
  final String? targetValue;
  final DateTime startAt;
  final DateTime endAt;
  final int displayOrder;
  final String status;
}

class PlatformBannerDraft {
  const PlatformBannerDraft({
    required this.title,
    required this.altText,
    required this.targetType,
    required this.startAt,
    required this.endAt,
    required this.displayOrder,
    required this.status,
    this.targetPublicId,
    this.targetValue,
  });

  final String title;
  final String altText;
  final String targetType;
  final String? targetPublicId;
  final String? targetValue;
  final DateTime startAt;
  final DateTime endAt;
  final int displayOrder;
  final String status;

  Map<String, dynamic> toJson() => {
    'title': title,
    'altText': altText,
    'targetType': targetType,
    'targetPublicId': targetPublicId,
    'targetValue': targetValue,
    'startAt': startAt.toUtc().toIso8601String(),
    'endAt': endAt.toUtc().toIso8601String(),
    'displayOrder': displayOrder,
    'status': status,
  };
}

class PlatformBannerException implements Exception {
  const PlatformBannerException(this.message);
  final String message;
  @override
  String toString() => message;
}

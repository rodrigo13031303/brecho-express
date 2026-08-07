import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/brecho_session.dart';

class CategoryAdminService {
  CategoryAdminService({http.Client? client})
    : _client = client ?? http.Client();

  static final _baseUri = Uri.parse(
    'https://app.rodrigosburguer.com.br/ords/brechoexpress/api/v1/',
  );
  final http.Client _client;

  Future<List<AdminCategory>> list(BrechoSession session) async {
    final response = await _client
        .get(_baseUri.resolve('admin/categories'), headers: _headers(session))
        .timeout(const Duration(seconds: 20));
    final data = _decode(response);
    if (data is! List)
      throw const CategoryAdminException('Lista de categorias inválida.');
    return data
        .whereType<Map<String, dynamic>>()
        .map(AdminCategory.fromJson)
        .toList();
  }

  Future<AdminCategory> save(
    BrechoSession session,
    CategoryDraft draft, {
    AdminCategory? current,
  }) async {
    final uri = current == null
        ? _baseUri.resolve('admin/categories')
        : _baseUri.resolve(
            'admin/categories/${Uri.encodeComponent(current.publicId)}',
          );
    final response = current == null
        ? await _client.post(
            uri,
            headers: _jsonHeaders(session),
            body: jsonEncode(draft.toJson()),
          )
        : await _client.put(
            uri,
            headers: _jsonHeaders(session),
            body: jsonEncode(draft.toJson()),
          );
    final data = _decode(response);
    if (data is! Map<String, dynamic>)
      throw const CategoryAdminException('Categoria recebida inválida.');
    return AdminCategory.fromJson(data);
  }

  Future<void> changeStatus(
    BrechoSession session,
    AdminCategory category,
    bool activate,
  ) async {
    final action = activate ? 'activate' : 'inactivate';
    final response = await _client.post(
      _baseUri.resolve(
        'admin/categories/${Uri.encodeComponent(category.publicId)}/actions/$action',
      ),
      headers: _headers(session),
    );
    _decode(response);
  }

  Future<void> delete(BrechoSession session, AdminCategory category) async {
    final response = await _client.delete(
      _baseUri.resolve(
        'admin/categories/${Uri.encodeComponent(category.publicId)}',
      ),
      headers: _headers(session),
    );
    _decode(response);
  }

  Map<String, String> _headers(BrechoSession session) => {
    'Authorization': 'Bearer ${session.accessToken}',
    'Accept': 'application/json',
  };
  Map<String, String> _jsonHeaders(BrechoSession session) => {
    ..._headers(session),
    'Content-Type': 'application/json',
  };

  dynamic _decode(http.Response response) {
    try {
      final envelope = jsonDecode(response.body);
      if (envelope is! Map<String, dynamic>)
        throw const CategoryAdminException('Resposta inválida.');
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          envelope['success'] != true) {
        final error = envelope['error'];
        throw CategoryAdminException(
          error is Map<String, dynamic>
              ? error['message'] as String? ??
                    'Não foi possível concluir a operação.'
              : 'Não foi possível concluir a operação.',
        );
      }
      return envelope['data'];
    } on FormatException {
      throw const CategoryAdminException('Resposta inválida.');
    }
  }

  void close() => _client.close();
}

class AdminCategory {
  const AdminCategory({
    required this.publicId,
    required this.name,
    required this.slug,
    required this.sortOrder,
    required this.acceptsProducts,
    required this.status,
    required this.productCount,
    required this.childCount,
    required this.canDelete,
    required this.canInactivate,
    this.description,
    this.parentPublicId,
  });
  factory AdminCategory.fromJson(Map<String, dynamic> json) => AdminCategory(
    publicId: json['categoryPublicId'] as String,
    name: json['categoryName'] as String,
    slug: json['categorySlug'] as String,
    description: json['description'] as String?,
    parentPublicId: json['parentCategoryPublicId'] as String?,
    sortOrder: (json['sortOrder'] as num).toInt(),
    acceptsProducts: json['acceptsProducts'] as bool,
    status: json['status'] as String,
    productCount: (json['productCount'] as num).toInt(),
    childCount: (json['childCount'] as num).toInt(),
    canDelete: json['canDelete'] as bool,
    canInactivate: json['canInactivate'] as bool,
  );
  final String publicId, name, slug, status;
  final String? description, parentPublicId;
  final int sortOrder, productCount, childCount;
  final bool acceptsProducts, canDelete, canInactivate;
}

class CategoryDraft {
  const CategoryDraft({
    required this.name,
    required this.slug,
    required this.sortOrder,
    required this.acceptsProducts,
    this.description,
    this.parentPublicId,
  });
  final String name, slug;
  final String? description, parentPublicId;
  final int sortOrder;
  final bool acceptsProducts;
  Map<String, dynamic> toJson() => {
    'categoryName': name,
    'categorySlug': slug,
    'description': description,
    'parentCategoryPublicId': parentPublicId,
    'sortOrder': sortOrder,
    'acceptsProducts': acceptsProducts,
  };
}

class CategoryAdminException implements Exception {
  const CategoryAdminException(this.message);
  final String message;
  @override
  String toString() => message;
}

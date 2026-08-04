import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/brecho_session.dart';

class UserProfileService {
  UserProfileService({http.Client? client}) : _client = client ?? http.Client();

  static final _baseUri = Uri.parse(
    'https://app.rodrigosburguer.com.br/ords/brechoexpress/api/v1/',
  );
  final http.Client _client;

  Future<UserProfileSummary> getMe(BrechoSession session) async {
    final response = await _client
        .get(
          _baseUri.resolve('me/profile'),
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 15));
    try {
      final envelope = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          envelope['success'] != true ||
          envelope['data'] is! Map<String, dynamic>) {
        throw const UserProfileException('Não foi possível carregar o perfil.');
      }
      return UserProfileSummary.fromJson(
        envelope['data'] as Map<String, dynamic>,
      );
    } on FormatException {
      throw const UserProfileException('O perfil recebido veio inválido.');
    } on TypeError {
      throw const UserProfileException('O perfil recebido veio inválido.');
    }
  }

  void close() => _client.close();
}

class UserProfileSummary {
  const UserProfileSummary({required this.displayName});

  factory UserProfileSummary.fromJson(Map<String, dynamic> json) =>
      UserProfileSummary(displayName: json['displayName'] as String);

  final String displayName;

  String get firstName {
    final normalized = displayName.trim();
    if (normalized.isEmpty) return '';
    final token = normalized
        .split(RegExp(r'\s+'))
        .first
        .replaceFirst(RegExp(r'\d+$'), '');
    if (token.isEmpty) return normalized;
    return '${token[0].toUpperCase()}${token.substring(1)}';
  }
}

class UserProfileException implements Exception {
  const UserProfileException(this.message);
  final String message;
}

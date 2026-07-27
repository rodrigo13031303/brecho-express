import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'brecho_session.dart';

class GoogleAuthService {
  GoogleAuthService({http.Client? client}) : _client = client ?? http.Client();

  static const _iosClientId =
      '77055318166-815viv1t22035m50v00htkvklqhqvg18'
      '.apps.googleusercontent.com';
  static const _backendClientId =
      '77055318166-jr5lsmj17trmgt651ne3ismc7r7t1tli'
      '.apps.googleusercontent.com';
  static final _loginUri = Uri.parse(
    'https://app.rodrigosburguer.com.br'
    '/ords/brechoexpress/api/v1/auth/social/google',
  );
  static final _logoutUri = Uri.parse(
    'https://app.rodrigosburguer.com.br'
    '/ords/brechoexpress/api/v1/auth/logout',
  );

  final http.Client _client;
  final GoogleSignIn _google = GoogleSignIn.instance;
  bool _initialized = false;

  Future<BrechoSession> signIn() async {
    await _initialize();
    final account = await _google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const GoogleLoginException(
        'O Google não retornou uma credencial de identidade.',
      );
    }

    final response = await _client
        .post(
          _loginUri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'idToken': idToken}),
        )
        .timeout(const Duration(seconds: 20));

    final payload = _decodeObject(response.body);
    if (response.statusCode != 200 || payload['success'] != true) {
      final error = payload['error'];
      final message = error is Map<String, dynamic>
          ? error['message'] as String?
          : null;
      throw GoogleLoginException(
        message ?? 'Não foi possível entrar com o Google.',
      );
    }

    final data = payload['data'];
    if (data is! Map<String, dynamic>) {
      throw const GoogleLoginException(
        'O servidor retornou uma resposta inesperada.',
      );
    }
    return BrechoSession.fromJson(data);
  }

  Future<void> logout(String accessToken) async {
    final response = await _client
        .post(_logoutUri, headers: {'Authorization': 'Bearer $accessToken'})
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 204) {
      throw const GoogleLoginException(
        'Não foi possível encerrar a sessão no servidor.',
      );
    }
    if (_initialized) await _google.signOut();
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    await _google.initialize(
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? _iosClientId
          : null,
      serverClientId: _backendClientId,
    );
    _initialized = true;
  }

  Map<String, dynamic> _decodeObject(String body) {
    try {
      final value = jsonDecode(body);
      if (value is Map<String, dynamic>) return value;
    } on FormatException {
      // Converted below into a stable application error.
    }
    throw const GoogleLoginException(
      'O servidor retornou uma resposta inválida.',
    );
  }

  void close() => _client.close();
}

class GoogleLoginException implements Exception {
  const GoogleLoginException(this.message);
  final String message;
}

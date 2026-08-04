import 'package:brecho_express_app/src/auth/brecho_session.dart';
import 'package:brecho_express_app/src/profile/user_profile_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final session = BrechoSession(
    accessToken: 'token',
    sessionPublicId: 'session',
    expiresAt: DateTime.utc(2030),
    accountPublicId: 'account',
  );

  test('carrega o nome do perfil da conta autenticada', () async {
    final service = UserProfileService(
      client: MockClient((request) async {
        expect(request.url.path, endsWith('/me/profile'));
        expect(request.headers['Authorization'], 'Bearer token');
        return http.Response(
          '{"success":true,"traceId":"trace","data":{'
          '"profilePublicId":"profile","displayName":"Rodrigo Paes",'
          '"fullName":null,"birthDate":null,"bio":null,"avatarUrl":null,'
          '"localeCode":"pt-BR","timezoneName":"America/Sao_Paulo",'
          '"createdAt":"2026-01-01T00:00:00Z",'
          '"updatedAt":"2026-01-01T00:00:00Z"}}',
          200,
        );
      }),
    );

    final profile = await service.getMe(session);

    expect(profile.displayName, 'Rodrigo Paes');
    expect(profile.firstName, 'Rodrigo');
    service.close();
  });

  test('transforma identificador legado em saudação legível', () {
    const profile = UserProfileSummary(displayName: 'rodrigo13031303');

    expect(profile.firstName, 'Rodrigo');
  });
}

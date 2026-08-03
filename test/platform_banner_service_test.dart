import 'package:brecho_express_app/src/auth/brecho_session.dart';
import 'package:brecho_express_app/src/banner/platform_banner_service.dart';
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

  test('carrega somente o contrato público de banners', () async {
    final service = PlatformBannerService(
      client: MockClient(
        (_) async => http.Response(
          '{"success":true,"data":[{'
          '"bannerPublicId":"banner","title":"Festival",'
          '"altText":"Festival circular","imageUrl":"https://img/banner.webp",'
          '"targetType":"APP_SCREEN","targetPublicId":null,'
          '"targetValue":"comprar","startAt":"2026-08-01T00:00:00Z",'
          '"endAt":"2026-08-31T23:59:59Z","displayOrder":1,'
          '"status":"ACTIVE"}]}',
          200,
        ),
      ),
    );

    final banners = await service.listPublic();

    expect(banners.single.title, 'Festival');
    expect(banners.single.targetValue, 'comprar');
    service.close();
  });

  test('consulta os papéis globais da própria sessão', () async {
    final service = PlatformBannerService(
      client: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer token');
        return http.Response(
          '{"success":true,"data":["ADMIN","CUSTOMER"]}',
          200,
        );
      }),
    );

    final roles = await service.myRoles(session);

    expect(roles, contains('ADMIN'));
    service.close();
  });

  test('cria banner administrativo inicialmente como rascunho', () async {
    final service = PlatformBannerService(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, endsWith('/admin/platform-banners'));
        return http.Response(
          '{"success":true,"data":{'
          '"bannerPublicId":"banner","title":"Festival",'
          '"altText":"Festival circular","imageUrl":null,'
          '"targetType":"APP_SCREEN","targetPublicId":null,'
          '"targetValue":"comprar","startAt":"2026-08-01T00:00:00Z",'
          '"endAt":"2026-08-31T23:59:59Z","displayOrder":1,'
          '"status":"DRAFT"}}',
          201,
        );
      }),
    );

    final banner = await service.save(
      session: session,
      draft: PlatformBannerDraft(
        title: 'Festival',
        altText: 'Festival circular',
        targetType: 'APP_SCREEN',
        targetValue: 'comprar',
        startAt: DateTime.utc(2026, 8),
        endAt: DateTime.utc(2026, 9),
        displayOrder: 1,
        status: 'DRAFT',
      ),
    );

    expect(banner.status, 'DRAFT');
    service.close();
  });
}

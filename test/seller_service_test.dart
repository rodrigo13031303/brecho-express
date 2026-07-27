import 'dart:convert';
import 'dart:typed_data';

import 'package:brecho_express_app/src/auth/brecho_session.dart';
import 'package:brecho_express_app/src/location/store_location_service.dart';
import 'package:brecho_express_app/src/seller/seller_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final session = BrechoSession(
    accessToken: 'secret-token',
    sessionPublicId: 'session',
    expiresAt: DateTime.utc(2030),
    accountPublicId: 'account-1',
  );

  test('lista lojas usando a sessão autenticada', () async {
    final service = SellerService(
      client: MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer secret-token');
        expect(request.url.path, endsWith('/accounts/account-1/stores'));
        return http.Response(
          '{"success":true,"data":[{"storePublicId":"store-1",'
          '"storeName":"Meu Brechó","storeSlug":"meu-brecho",'
          '"status":"ACTIVE"}]}',
          200,
        );
      }),
    );

    final stores = await service.listStores(session);

    expect(stores.single.name, 'Meu Brechó');
    expect(stores.single.status, 'ACTIVE');
    service.close();
  });

  test('cria uma peça e em seguida ativa a publicação', () async {
    var calls = 0;
    final service = SellerService(
      client: MockClient((request) async {
        calls++;
        expect(request.headers['authorization'], 'Bearer secret-token');
        if (calls == 1) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['title'], 'Vestido azul');
          expect(body['condition'], 'GOOD');
          return http.Response(
            '{"success":true,"data":{"productPublicId":"product-1",'
            '"title":"Vestido azul","status":"DRAFT"}}',
            201,
          );
        }
        expect(
          request.url.path,
          endsWith('/products/product-1/actions/activate'),
        );
        expect(request.body, '{}');
        return http.Response(
          '{"success":true,"data":{"productPublicId":"product-1",'
          '"title":"Vestido azul","status":"ACTIVE"}}',
          200,
        );
      }),
    );

    final product = await service.publishProduct(
      session: session,
      storePublicId: 'store-1',
      categoryPublicId: 'category-1',
      title: 'Vestido azul',
      slug: 'vestido-azul',
      description: 'Como novo',
      price: 59.9,
      quantity: 1,
      condition: 'GOOD',
    );

    expect(calls, 2);
    expect(product.status, 'ACTIVE');
    service.close();
  });

  test('envia o logo como mídia autenticada', () async {
    final service = SellerService(
      client: MockClient((request) async {
        expect(request.url.path, endsWith('/stores/store-1/logo'));
        expect(request.headers['authorization'], 'Bearer secret-token');
        expect(request.headers['content-type'], 'image/jpeg');
        expect(request.bodyBytes, [1, 2, 3]);
        return http.Response(
          '{"success":true,"data":{"logoUrl":"https://example/logo"}}',
          200,
        );
      }),
    );

    final url = await service.uploadLogo(
      session: session,
      storePublicId: 'store-1',
      bytes: Uint8List.fromList([1, 2, 3]),
      mimeType: 'image/jpeg',
    );

    expect(url, startsWith('https://example/logo?v='));
    service.close();
  });
  test('preserva a mensagem pública de erro da API', () async {
    final service = SellerService(
      client: MockClient(
        (_) async => http.Response(
          '{"success":false,"error":{"code":"BEX-STORE-018",'
          '"message":"O endereço já está em uso."}}',
          409,
        ),
      ),
    );

    expect(
      service.listStores(session),
      throwsA(
        isA<SellerException>().having(
          (error) => error.message,
          'message',
          'O endereço já está em uso.',
        ),
      ),
    );
    service.close();
  });

  test('ativa brechó enviando um objeto JSON vazio', () async {
    final service = SellerService(
      client: MockClient((request) async {
        expect(request.url.path, endsWith('/stores/store-1/actions/activate'));
        expect(request.headers['content-type'], 'application/json');
        expect(request.body, '{}');
        return http.Response(
          '{"success":true,"data":{"storePublicId":"store-1",'
          '"storeName":"Meu Brechó","storeSlug":"meu-brecho",'
          '"status":"ACTIVE"}}',
          200,
        );
      }),
    );

    final store = await service.activateStore(session, 'store-1');

    expect(store.status, 'ACTIVE');
    service.close();
  });

  test('cria brechó completo em uma única chamada de onboarding', () async {
    final service = SellerService(
      client: MockClient((request) async {
        expect(
          request.url.path,
          endsWith('/accounts/account-1/stores/onboarding'),
        );
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final location = body['location'] as Map<String, dynamic>;
        expect(body['storeSlug'], 'meu-brecho');
        expect(location['city'], 'Campinas');
        expect(location['number'], '100');
        return http.Response(
          '{"success":true,"data":{"storePublicId":"store-1",'
          '"storeName":"Meu Brechó","storeSlug":"meu-brecho",'
          '"status":"ACTIVE","logoUrl":null}}',
          201,
        );
      }),
    );
    const location = StoreLocationDraft(
      postalCode: '13010111',
      street: 'Rua Barão de Jaguara',
      number: '100',
      complement: '',
      district: 'Centro',
      city: 'Campinas',
      state: 'SP',
      latitude: -22.905,
      longitude: -47.06,
    );

    final store = await service.createCompleteStore(
      session: session,
      name: 'Meu Brechó',
      slug: 'meu-brecho',
      location: location,
    );

    expect(store.status, 'ACTIVE');
    service.close();
  });

  test('carrega endereço privado para edição do brechó', () async {
    final service = SellerService(
      client: MockClient((request) async {
        expect(request.url.path, endsWith('/stores/store-1/location/owner'));
        expect(request.headers['authorization'], 'Bearer secret-token');
        return http.Response(
          '{"success":true,"data":{"postalCode":"13010111",'
          '"street":"Rua Barão de Jaguara","number":"100",'
          '"complement":null,"district":"Centro","city":"Campinas",'
          '"state":"SP","latitude":-22.905,"longitude":-47.06}}',
          200,
        );
      }),
    );

    final location = await service.loadLocation(
      session: session,
      storePublicId: 'store-1',
    );

    expect(location.city, 'Campinas');
    expect(location.number, '100');
    service.close();
  });
}

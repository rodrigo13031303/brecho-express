import 'dart:convert';

import 'package:brecho_express_app/src/auth/brecho_session.dart';
import 'package:brecho_express_app/src/cart/cart_service.dart';
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

  test('carrega o carrinho persistente autenticado', () async {
    final service = CartService(
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/cart'));
        expect(request.headers['authorization'], 'Bearer secret-token');
        return http.Response(
          '{"success":true,"data":{"cartPublicId":"cart-1",'
          '"status":"ACTIVE","items":[{"itemPublicId":"item-1",'
          '"productPublicId":"product-1","storePublicId":"store-1",'
          '"quantity":2,"unitPrice":49.9,"status":"ACTIVE"}]}}',
          200,
        );
      }),
    );

    final cart = await service.load(session);

    expect(cart.itemCount, 2);
    expect(cart.total, 99.8);
    service.close();
  });

  test('adiciona produto ao carrinho', () async {
    final service = CartService(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, endsWith('/cart/cart-1/items'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['productPublicId'], 'product-1');
        expect(body['quantity'], 1);
        return http.Response(
          '{"success":true,"data":{"cartPublicId":"cart-1",'
          '"status":"ACTIVE","items":[]}}',
          201,
        );
      }),
    );

    final cart = await service.add(
      session: session,
      cartPublicId: 'cart-1',
      productPublicId: 'product-1',
    );

    expect(cart.publicId, 'cart-1');
    service.close();
  });

  test('preserva o erro conhecido de estoque', () async {
    final service = CartService(
      client: MockClient(
        (_) async => http.Response(
          '{"success":false,"error":{"code":"BEX-CRT-004",'
          '"message":"Quantidade indisponível."}}',
          422,
        ),
      ),
    );

    expect(
      service.update(
        session: session,
        cartPublicId: 'cart-1',
        itemPublicId: 'item-1',
        quantity: 99,
      ),
      throwsA(
        isA<CartException>()
            .having((error) => error.code, 'code', 'BEX-CRT-004')
            .having(
              (error) => error.message,
              'message',
              'Quantidade indisponível.',
            ),
      ),
    );
    service.close();
  });
}

import 'dart:convert';

import 'package:brecho_express_app/src/auth/brecho_session.dart';
import 'package:brecho_express_app/src/purchase/purchase_service.dart';
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

  const requestJson =
      '{"requestPublicId":"request-1","profilePublicId":"profile-1",'
      '"status":"PENDING","requestedAt":"2026-07-29T12:00:00Z",'
      '"confirmedAt":null,"responseAt":null,'
      '"expiresAt":"2026-07-31T12:00:00Z","items":['
      '{"itemPublicId":"item-1","productPublicId":"product-1",'
      '"storePublicId":"store-1","requestedQuantity":2,'
      '"confirmedQuantity":null,"unitPrice":49.9,'
      '"rejectReason":null,"status":"PENDING"}]}';

  test('lista solicitações do comprador', () async {
    final service = PurchaseService(
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/purchase-requests'));
        expect(request.headers['authorization'], 'Bearer secret-token');
        return http.Response('{"success":true,"data":[$requestJson]}', 200);
      }),
    );

    final requests = await service.listBuyer(session);

    expect(requests.single.publicId, 'request-1');
    expect(requests.single.items.single.quantity, 2);
    service.close();
  });

  test('vendedor responde uma peça solicitada', () async {
    final service = PurchaseService(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.path,
          endsWith(
            '/stores/store-1/purchase-requests/request-1/items/item-1/respond',
          ),
        );
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['confirmedQuantity'], 1);
        return http.Response('{"success":true,"data":$requestJson}', 200);
      }),
    );

    final request = await service.respond(
      session: session,
      storePublicId: 'store-1',
      requestPublicId: 'request-1',
      itemPublicId: 'item-1',
      confirmedQuantity: 1,
    );

    expect(request.publicId, 'request-1');
    service.close();
  });
}

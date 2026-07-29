import 'package:brecho_express_app/src/auth/brecho_session.dart';
import 'package:brecho_express_app/src/order/order_service.dart';
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
  const orderJson =
      '{"orderPublicId":"order-1","orderNumber":"BEX-20260729-ABC123",'
      '"status":"PAYMENT_PENDING","subtotalAmount":100,'
      '"shippingAmount":16,"totalAmount":116,'
      '"createdAt":"2026-07-29T12:00:00Z","items":['
      '{"itemPublicId":"item-1","productPublicId":"product-1",'
      '"storePublicId":"store-1","title":"Vestido","quantity":1,'
      '"unitPrice":100,"totalPrice":100}],"shipping":['
      '{"shippingPublicId":"shipping-1","storePublicId":"store-1",'
      '"storeName":"Brechó da Ana","method":"LOCAL","price":16,'
      '"distanceKm":5,"estimatedMinDays":2,"estimatedMaxDays":4}]}';

  test('cria pedido aguardando pagamento', () async {
    final service = OrderService(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.path,
          endsWith('/purchase-requests/request-1/order'),
        );
        expect(request.headers['authorization'], 'Bearer secret-token');
        return http.Response('{"success":true,"data":$orderJson}', 201);
      }),
    );

    final order = await service.create(
      session: session,
      requestPublicId: 'request-1',
    );

    expect(order.status, 'PAYMENT_PENDING');
    expect(order.total, 116);
    expect(order.shipments.single.storeName, 'Brechó da Ana');
    service.close();
  });

  test('recupera o mesmo pedido pelo identificador público', () async {
    final service = OrderService(
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/orders/order-1'));
        return http.Response('{"success":true,"data":$orderJson}', 200);
      }),
    );

    final order = await service.get(session: session, orderPublicId: 'order-1');

    expect(order.items.single.title, 'Vestido');
    expect(order.shipping, 16);
    service.close();
  });
}

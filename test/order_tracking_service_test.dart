import 'package:brecho_express_app/src/auth/brecho_session.dart';
import 'package:brecho_express_app/src/order/order_service.dart';
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
  const summary =
      '{"orderPublicId":"order-1","orderNumber":"BEX-1",'
      '"status":"PAYMENT_PENDING","subtotalAmount":50,'
      '"shippingAmount":0,"totalAmount":50,'
      '"createdAt":"2026-07-29T12:00:00Z",'
      '"paymentExpiresAt":"2026-07-29T12:30:00Z",'
      '"items":[],"shipping":[]}';

  test('lista os pedidos do comprador', () async {
    final service = OrderService(
      client: MockClient((request) async {
        expect(request.url.path, endsWith('/orders'));
        return http.Response('{"success":true,"data":[$summary]}', 200);
      }),
    );
    final orders = await service.listBuyer(session);
    expect(orders.single.paymentExpiresAt, isNotNull);
    service.close();
  });

  test('lista somente os pedidos do brechó', () async {
    final service = OrderService(
      client: MockClient((request) async {
        expect(request.url.path, endsWith('/stores/store-1/orders'));
        return http.Response('{"success":true,"data":[$summary]}', 200);
      }),
    );
    final orders = await service.listStore(
      session: session,
      storePublicId: 'store-1',
    );
    expect(orders.single.total, 50);
    service.close();
  });

  test('cancela pedido aguardando pagamento', () async {
    final service = OrderService(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, endsWith('/orders/order-1/actions/cancel'));
        return http.Response(
          '{"success":true,"data":${summary.replaceFirst('PAYMENT_PENDING', 'CANCELLED')}}',
          200,
        );
      }),
    );
    final order = await service.cancel(
      session: session,
      orderPublicId: 'order-1',
    );
    expect(order.status, 'CANCELLED');
    service.close();
  });
}

import 'dart:convert';

import 'package:brecho_express_app/src/auth/brecho_session.dart';
import 'package:brecho_express_app/src/shipping/shipping_service.dart';
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
  const optionsJson =
      '[{"optionPublicId":"pickup-1","storePublicId":"store-1",'
      '"storeName":"Brechó da Ana","method":"PICKUP","price":0,'
      '"distanceKm":null,"estimatedMinDays":1,"estimatedMaxDays":3,'
      '"expiresAt":"2030-01-01T12:30:00Z","isSelected":false},'
      '{"optionPublicId":"local-1","storePublicId":"store-1",'
      '"storeName":"Brechó da Ana","method":"LOCAL","price":16,'
      '"distanceKm":5,"estimatedMinDays":2,"estimatedMaxDays":4,'
      '"expiresAt":"2030-01-01T12:30:00Z","isSelected":true}]';

  test('calcula retirada e entrega local por brechó', () async {
    final service = ShippingService(
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.path,
          endsWith('/purchase-requests/request-1/shipping-options'),
        );
        expect(request.headers['authorization'], 'Bearer secret-token');
        return http.Response('{"success":true,"data":$optionsJson}', 200);
      }),
    );

    final options = await service.quote(
      session: session,
      requestPublicId: 'request-1',
    );

    expect(options, hasLength(2));
    expect(options.first.methodLabel, 'Retirar no brechó');
    expect(options.last.distanceKm, 5);
    expect(options.last.isSelected, isTrue);
    service.close();
  });

  test('persiste a modalidade escolhida', () async {
    final service = ShippingService(
      client: MockClient((request) async {
        expect(request.method, 'PUT');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['optionPublicId'], 'pickup-1');
        return http.Response('{"success":true,"data":$optionsJson}', 200);
      }),
    );

    final options = await service.select(
      session: session,
      requestPublicId: 'request-1',
      optionPublicId: 'pickup-1',
    );

    expect(options.last.price, 16);
    service.close();
  });
}

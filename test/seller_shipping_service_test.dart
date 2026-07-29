import 'dart:convert';

import 'package:brecho_express_app/src/auth/brecho_session.dart';
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
  const configJson =
      '{"pickupEnabled":true,"localDeliveryEnabled":true,'
      '"localBasePrice":7,"localPricePerKm":1.8,'
      '"localMaxDistanceKm":20,"preparationDays":1}';

  test('carrega os padrões de entrega do brechó', () async {
    final service = SellerService(
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/stores/store-1/shipping-config'));
        expect(request.headers['authorization'], 'Bearer secret-token');
        return http.Response('{"success":true,"data":$configJson}', 200);
      }),
    );

    final config = await service.loadShippingConfig(
      session: session,
      storePublicId: 'store-1',
    );

    expect(config.pickupEnabled, isTrue);
    expect(config.localPricePerKm, 1.8);
    service.close();
  });

  test('salva preços, alcance e prazo do brechó', () async {
    final service = SellerService(
      client: MockClient((request) async {
        expect(request.method, 'PUT');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['localBasePrice'], 9);
        expect(body['localMaxDistanceKm'], 15);
        expect(body['preparationDays'], 2);
        return http.Response('{"success":true,"data":$configJson}', 200);
      }),
    );

    final result = await service.saveShippingConfig(
      session: session,
      storePublicId: 'store-1',
      config: const StoreShippingConfig(
        pickupEnabled: true,
        localDeliveryEnabled: true,
        localBasePrice: 9,
        localPricePerKm: 2,
        localMaxDistanceKm: 15,
        preparationDays: 2,
      ),
    );

    expect(result.preparationDays, 1);
    service.close();
  });
}

import 'dart:convert';

import 'package:brecho_express_app/src/auth/brecho_session.dart';
import 'package:brecho_express_app/src/delivery/delivery_service.dart';
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

  const addressJson =
      '{"addressPublicId":"address-1","label":"Minha casa",'
      '"zipCode":"01001000","street":"Praça da Sé","number":"100",'
      '"complement":"apto 1","district":"Sé","city":"São Paulo",'
      '"state":"SP","country":"BR","isDefault":true,"status":"ACTIVE"}';

  test('lista os endereços ativos do comprador', () async {
    final service = DeliveryService(
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/addresses'));
        expect(request.headers['authorization'], 'Bearer secret-token');
        return http.Response(
          '{"success":true,"data":[$addressJson]}',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final addresses = await service.listAddresses(session);

    expect(addresses.single.city, 'São Paulo');
    expect(addresses.single.complement, 'apto 1');
    service.close();
  });

  test('cria e seleciona um endereço para a solicitação', () async {
    var calls = 0;
    final service = DeliveryService(
      client: MockClient((request) async {
        calls++;
        if (calls == 1) {
          expect(request.method, 'POST');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['city'], 'São Paulo');
          expect(body['country'], 'BR');
          return http.Response('{"success":true,"data":$addressJson}', 201);
        }
        expect(request.method, 'PUT');
        expect(
          request.url.path,
          endsWith('/purchase-requests/request-1/delivery-address'),
        );
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['addressPublicId'], 'address-1');
        return http.Response(
          '{"success":true,"data":{"deliveryPublicId":"delivery-1",'
          '"requestPublicId":"request-1","addressPublicId":"address-1",'
          '"label":"Minha casa","zipCode":"01001000",'
          '"street":"Praça da Sé","number":"100","complement":"apto 1",'
          '"district":"Sé","city":"São Paulo","state":"SP","country":"BR",'
          '"status":"ADDRESS_SELECTED"}}',
          200,
        );
      }),
    );

    final address = await service.createAddress(
      session: session,
      draft: const AddressDraft(
        label: 'Minha casa',
        zipCode: '01001-000',
        street: 'Praça da Sé',
        number: '100',
        complement: 'apto 1',
        district: 'Sé',
        city: 'São Paulo',
        state: 'sp',
      ),
    );
    final delivery = await service.selectAddress(
      session: session,
      requestPublicId: 'request-1',
      addressPublicId: address.publicId,
    );

    expect(delivery.status, 'ADDRESS_SELECTED');
    expect(delivery.line2, 'Sé • São Paulo/SP');
    service.close();
  });

  test('entrega ainda não informada retorna nulo', () async {
    final service = DeliveryService(
      client: MockClient(
        (_) async => http.Response(
          '{"success":false,"error":{"code":"BEX-PDL-001",'
          '"message":"Entrega ainda não informada."}}',
          404,
        ),
      ),
    );

    final delivery = await service.getDelivery(
      session: session,
      requestPublicId: 'request-1',
    );

    expect(delivery, isNull);
    service.close();
  });
}

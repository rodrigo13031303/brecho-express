import 'package:brecho_express_app/src/location/store_location_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('consulta CEP V2 com bairro e coordenadas', () async {
    final service = StoreLocationService(
      client: MockClient((request) async {
        if (request.url.host == 'viacep.com.br') {
          return http.Response('{}', 200);
        }
        expect(request.url.path, endsWith('/cep/v2/01310930'));
        return http.Response(
          '{"cep":"01310930","state":"SP","city":"São Paulo",'
          '"neighborhood":"Bela Vista","street":"Avenida Paulista",'
          '"location":{"type":"Point","coordinates":{'
          '"longitude":"-46.6544","latitude":"-23.5614"}}}',
          200,
        );
      }),
    );

    final location = await service.lookupPostalCode('01310-930');

    expect(location.district, 'Bela Vista');
    expect(location.city, 'São Paulo');
    expect(location.latitude, closeTo(-23.5614, 0.00001));
    expect(location.publicLabel, 'Bela Vista • São Paulo/SP');
    service.close();
  });

  test('rejeita CEP sem oito números', () async {
    final service = StoreLocationService(
      client: MockClient((_) async => http.Response('{}', 200)),
    );

    expect(
      service.lookupPostalCode('123'),
      throwsA(isA<StoreLocationException>()),
    );
    service.close();
  });

  test('aceita endereço de CEP mesmo sem coordenadas', () async {
    final service = StoreLocationService(
      client: MockClient(
        (request) async => request.url.host == 'viacep.com.br'
            ? http.Response('{}', 200)
            : http.Response(
                '{"cep":"13000000","state":"SP","city":"Campinas",'
                '"neighborhood":"Centro","street":"Rua Exemplo",'
                '"location":{"type":"Point","coordinates":{}}}',
                200,
              ),
      ),
    );

    final location = await service.lookupPostalCode('13000000');

    expect(location.street, 'Rua Exemplo');
    expect(location.district, 'Centro');
    expect(location.latitude, isNull);
    expect(location.longitude, isNull);
    service.close();
  });

  test('completa cidade ausente usando ViaCEP', () async {
    final service = StoreLocationService(
      client: MockClient((request) async {
        if (request.url.host == 'viacep.com.br') {
          return http.Response(
            '{"cep":"13010-111","logradouro":"Rua Barão de Jaguara",'
            '"bairro":"Centro","localidade":"Campinas","uf":"SP"}',
            200,
          );
        }
        return http.Response(
          '{"cep":"13010111","state":"SP","city":"",'
          '"neighborhood":"","street":"","location":{"coordinates":{}}}',
          200,
        );
      }),
    );

    final location = await service.lookupPostalCode('13010-111');

    expect(location.street, 'Rua Barão de Jaguara');
    expect(location.district, 'Centro');
    expect(location.city, 'Campinas');
    expect(location.state, 'SP');
    service.close();
  });
}

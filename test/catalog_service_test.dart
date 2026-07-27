import 'package:brecho_express_app/src/catalog/catalog_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('carrega categorias e produtos do envelope público', () async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/categories')) {
        return http.Response(
          '{"success":true,"data":[{"categoryPublicId":"cat","categoryName":"Roupas","categorySlug":"roupas"}]}',
          200,
        );
      }
      return http.Response(
        '{"success":true,"data":[{"productPublicId":"prd","title":"Vestido","price":59.9,"condition":"GOOD","description":null}]}',
        200,
      );
    });
    final service = CatalogService(client: client);

    final catalog = await service.load();

    expect(catalog.categories.single.name, 'Roupas');
    expect(catalog.products.single.title, 'Vestido');
    expect(catalog.products.single.price, 59.9);
    service.close();
  });

  test('carrega detalhe e imagens de uma peça', () async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/images')) {
        return http.Response(
          '{"success":true,"data":[{"imagePublicId":"img","imageUrl":"https://example.invalid/a.jpg","sortOrder":0,"isPrimary":true,"altText":"Frente"}]}',
          200,
        );
      }
      return http.Response(
        '{"success":true,"data":{"productPublicId":"prd","title":"Vestido","price":59.9,"condition":"GOOD","description":"Azul"}}',
        200,
      );
    });
    final service = CatalogService(client: client);

    final detail = await service.loadProductDetail('prd');

    expect(detail.product.title, 'Vestido');
    expect(detail.images.single.isPrimary, isTrue);
    expect(detail.images.single.altText, 'Frente');
    service.close();
  });
  test('converte resposta HTTP indisponível em erro de catálogo', () async {
    final service = CatalogService(
      client: MockClient((_) async => http.Response('', 404)),
    );

    expect(service.load(), throwsA(isA<CatalogException>()));
    service.close();
  });
}

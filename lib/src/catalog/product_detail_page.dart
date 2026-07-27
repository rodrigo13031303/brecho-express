import 'package:flutter/material.dart';

import 'catalog_service.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({required this.productPublicId, super.key});
  final String productPublicId;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late final CatalogService _service;
  late Future<CatalogProductDetail> _detail;

  @override
  void initState() {
    super.initState();
    _service = CatalogService();
    _detail = _service.loadProductDetail(widget.productPublicId);
  }

  @override
  void dispose() {
    _service.close();
    super.dispose();
  }

  void _retry() => setState(
    () => _detail = _service.loadProductDetail(widget.productPublicId),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da peça')),
      body: FutureBuilder<CatalogProductDetail>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 56),
                  const SizedBox(height: 12),
                  const Text('Não foi possível carregar esta peça.'),
                  TextButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }
          final detail = snapshot.data!;
          final product = detail.product;
          final price = product.price.toStringAsFixed(2).replaceAll('.', ',');
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              _ProductGallery(images: detail.images),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'R\$ $price',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 18),
                    Chip(
                      avatar: const Icon(Icons.checkroom_outlined, size: 18),
                      label: Text(_conditionLabel(product.condition)),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Sobre a peça',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description ??
                          'O vendedor ainda não adicionou uma descrição.',
                    ),
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: const Text('Comprar — em breve'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _conditionLabel(String value) => switch (value) {
    'NEW' => 'Novo',
    'LIKE_NEW' => 'Como novo',
    'GOOD' => 'Bom estado',
    'FAIR' => 'Usado',
    _ => value,
  };
}

class _ProductGallery extends StatelessWidget {
  const _ProductGallery({required this.images});
  final List<CatalogImage> images;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        height: 320,
        color: Theme.of(context).colorScheme.primaryContainer,
        child: const Center(child: Icon(Icons.checkroom_outlined, size: 88)),
      );
    }
    return SizedBox(
      height: 360,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) => Image.network(
          images[index].url,
          fit: BoxFit.cover,
          semanticLabel: images[index].altText ?? 'Foto da peça',
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const Center(child: CircularProgressIndicator()),
          errorBuilder: (context, error, stackTrace) => Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: const Center(
              child: Icon(Icons.broken_image_outlined, size: 72),
            ),
          ),
        ),
      ),
    );
  }
}

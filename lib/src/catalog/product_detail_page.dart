import 'package:flutter/material.dart';

import 'catalog_service.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({required this.product, super.key});
  final CatalogProduct product;

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
    _detail = _service.loadProductDetail(
      widget.product.publicId,
      location: widget.product.location,
    );
  }

  @override
  void dispose() {
    _service.close();
    super.dispose();
  }

  void _retry() => setState(
    () => _detail = _service.loadProductDetail(
      widget.product.publicId,
      location: widget.product.location,
    ),
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
                    Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: _StoreAvatar(
                          name: product.storeName ?? 'Brechó Express',
                          logoUrl: product.storeLogoUrl,
                        ),
                        title: Text(product.storeName ?? 'Brechó Express'),
                        subtitle: product.location == null
                            ? const Text('Localização não informada')
                            : Text(product.location!.label),
                      ),
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
                    if (product.weight != null &&
                        product.width != null &&
                        product.height != null &&
                        product.length != null) ...[
                      const SizedBox(height: 22),
                      Text(
                        'Peso e dimensões',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_number(product.weight!)} kg • '
                        '${_number(product.width!)} × ${_number(product.height!)} × '
                        '${_number(product.length!)} cm',
                      ),
                    ],
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

  String _number(double value) {
    final text = value
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
    return text.replaceAll('.', ',');
  }

  String _conditionLabel(String value) => switch (value) {
    'NEW' => 'Novo',
    'LIKE_NEW' => 'Como novo',
    'GOOD' => 'Bom estado',
    'FAIR' => 'Usado',
    _ => value,
  };
}

class _ProductGallery extends StatefulWidget {
  const _ProductGallery({required this.images});
  final List<CatalogImage> images;

  @override
  State<_ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<_ProductGallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    if (images.isEmpty) {
      return Container(
        height: 320,
        color: Theme.of(context).colorScheme.primaryContainer,
        child: const Center(child: Icon(Icons.checkroom_outlined, size: 88)),
      );
    }
    return SizedBox(
      height: 390,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              itemCount: images.length,
              onPageChanged: (value) => setState(() => _page = value),
              itemBuilder: (context, index) => Image.network(
                images[index].url,
                width: double.infinity,
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
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              images.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: index == _page ? 18 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: index == _page
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_page + 1} de ${images.length} fotos',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _StoreAvatar extends StatelessWidget {
  const _StoreAvatar({required this.name, this.logoUrl});

  final String name;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'B' : name.trim()[0].toUpperCase();
    final image = logoUrl?.trim().isNotEmpty == true
        ? NetworkImage(logoUrl!)
        : null;
    return CircleAvatar(
      foregroundImage: image,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      onForegroundImageError: image == null ? null : (_, _) {},
      child: image == null
          ? Text(initial, style: const TextStyle(fontWeight: FontWeight.w800))
          : null,
    );
  }
}

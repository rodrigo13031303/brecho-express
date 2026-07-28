import 'package:flutter/material.dart';

import '../branding/brecho_mark.dart';
import '../catalog/catalog_service.dart';
import 'cart_service.dart';

class CartPage extends StatelessWidget {
  const CartPage({
    required this.cart,
    required this.catalog,
    required this.busyItemId,
    required this.onRetry,
    required this.onQuantityChanged,
    required this.onRemove,
    super.key,
  });

  final Future<CartSnapshot> cart;
  final Future<CatalogSnapshot> catalog;
  final String? busyItemId;
  final VoidCallback onRetry;
  final Future<void> Function(CartItem item, int quantity) onQuantityChanged;
  final Future<void> Function(CartItem item) onRemove;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: FutureBuilder<CartSnapshot>(
      future: cart,
      builder: (context, cartSnapshot) {
        if (cartSnapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (cartSnapshot.hasError) {
          return _CartMessage(
            icon: Icons.cloud_off_outlined,
            title: 'Não foi possível abrir seu carrinho',
            message: 'Sua seleção continua segura. Vamos tentar novamente?',
            action: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          );
        }
        final value = cartSnapshot.data!;
        if (value.items.isEmpty) {
          return const _CartMessage(
            icon: Icons.shopping_cart_outlined,
            title: 'Seu carrinho está vazio 🛒',
            message: 'Quando uma peça conquistar você, ela aparecerá aqui.',
          );
        }
        return FutureBuilder<CatalogSnapshot>(
          future: catalog,
          builder: (context, catalogSnapshot) {
            final products = {
              for (final product
                  in catalogSnapshot.data?.products ??
                      const <CatalogProduct>[])
                product.publicId: product,
            };
            final groups = <String, List<CartItem>>{};
            for (final item in value.items) {
              groups.putIfAbsent(item.storePublicId, () => []).add(item);
            }
            final currency = value.total
                .toStringAsFixed(2)
                .replaceAll('.', ',');
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              children: [
                const _CartHeader(),
                const SizedBox(height: 8),
                Text(
                  '${value.itemCount} item${value.itemCount == 1 ? '' : 's'} esperando por você ✨',
                ),
                const SizedBox(height: 22),
                ...groups.entries.map((entry) {
                  final firstProduct = products[entry.value.first.productPublicId];
                  return _StoreGroup(
                    storeName: firstProduct?.storeName ?? 'Brechó',
                    items: entry.value,
                    products: products,
                    busyItemId: busyItemId,
                    onQuantityChanged: onQuantityChanged,
                    onRemove: onRemove,
                  );
                }),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Subtotal',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'R\$ $currency',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Frete e pagamento serão calculados no checkout.',
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.lock_outline),
                          label: const Text('Checkout em breve'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ),
  );
}

class _StoreGroup extends StatelessWidget {
  const _StoreGroup({
    required this.storeName,
    required this.items,
    required this.products,
    required this.busyItemId,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  final String storeName;
  final List<CartItem> items;
  final Map<String, CatalogProduct> products;
  final String? busyItemId;
  final Future<void> Function(CartItem item, int quantity) onQuantityChanged;
  final Future<void> Function(CartItem item) onRemove;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  storeName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const Divider(height: 22),
          ...items.map((item) {
            final product = products[item.productPublicId];
            final busy = busyItemId == item.publicId;
            final price = item.unitPrice
                .toStringAsFixed(2)
                .replaceAll('.', ',');
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox.square(
                      dimension: 72,
                      child: product?.primaryImageUrl == null
                          ? ColoredBox(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              child: const Icon(Icons.checkroom_outlined),
                            )
                          : Image.network(
                              product!.primaryImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.broken_image_outlined),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product?.title ?? 'Peça indisponível',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text('R\$ $price'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton.outlined(
                              onPressed: busy || item.quantity <= 1
                                  ? null
                                  : () => onQuantityChanged(
                                      item,
                                      item.quantity - 1,
                                    ),
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.remove, size: 18),
                              tooltip: 'Diminuir',
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: busy
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      '${item.quantity}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                            IconButton.outlined(
                              onPressed: busy
                                  ? null
                                  : () => onQuantityChanged(
                                      item,
                                      item.quantity + 1,
                                    ),
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.add, size: 18),
                              tooltip: 'Aumentar',
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: busy ? null : () => onRemove(item),
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Remover',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ),
  );
}

class _CartHeader extends StatelessWidget {
  const _CartHeader();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const BrechoMark(size: 36),
      const SizedBox(width: 10),
      Text(
        'Meu carrinho 🛒',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ],
  );
}

class _CartMessage extends StatelessWidget {
  const _CartMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 72, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    ),
  );
}

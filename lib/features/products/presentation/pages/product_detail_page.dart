import 'package:flutter/material.dart';
import 'package:brecho_express_app/core/design_system/tokens.dart';

class Product {
  final String title;
  final String subtitle;
  final String price;
  final String shopName;
  final String condition;
  final String description;
  final String deliveryEstimate;

  const Product({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.shopName,
    required this.condition,
    required this.description,
    required this.deliveryEstimate,
  });
}

class ProductDetailPage extends StatelessWidget {
  final Product? product;

  const ProductDetailPage({this.product, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = product ?? const Product(
      title: 'Achado sem título',
      subtitle: 'Vintage, ótimo estado',
      price: 'R\$ 0,00',
      shopName: 'Brechó Express',
      condition: 'Bom estado',
      description: 'Descrição do produto não disponível.',
      deliveryEstimate: 'Entrega em até 45 min',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe do produto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 260,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(AppRadius.large),
              ),
              child: Center(
                child: Icon(
                  Icons.photo_camera,
                  size: 56,
                  color: AppColors.gray500,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(item.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
            Text(item.subtitle, style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.gray500)),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.price, style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(31),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  child: Text(item.deliveryEstimate, style: theme.textTheme.bodySmall),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(color: AppColors.gray300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Brechó', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(item.shopName, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: AppSpacing.md),
                  Text('Condição', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(item.condition, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Descrição', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
            Text(item.description, style: theme.textTheme.bodyMedium, textAlign: TextAlign.justify),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Comprar agora'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Adicionar ao carrinho'),
            ),
          ],
        ),
      ),
    );
  }
}

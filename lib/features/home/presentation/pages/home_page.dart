import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:brecho_express_app/core/design_system/tokens.dart';
import 'package:brecho_express_app/features/products/presentation/pages/product_detail_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static final List<Product> mockProducts = List.generate(
    6,
    (i) => Product(
      title: 'Peça única ${i + 1}',
      subtitle: 'Vintage, ótimo estado',
      price: 'R\$ ${(29 + i * 10).toStringAsFixed(2)}',
      shopName: 'Brechó Express',
      condition: 'Bom estado',
      description:
          'Peça única escolhida à mão com acabamento preservado e estilo urbano para combinações versáteis.',
      deliveryEstimate: 'Entrega em até 45 min',
    ),
  );

  static final List<String> categories = [
    'Vestidos',
    'Camisas',
    'Sapatos',
    'Acessórios',
    'Casacos',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: Text('Olá, bem vindo!', style: theme.textTheme.titleLarge),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Icon(Icons.location_on, color: AppColors.gray700),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              // delivery indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(31),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_shipping,
                      size: 18,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Entrega em até 45 min',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // search field
              TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar achados, marcas ou categorias',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    borderSide: BorderSide(color: AppColors.gray300),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // categories
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final label = categories[index];
                    return ActionChip(
                      label: Text(label),
                      onPressed: () {},
                      backgroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Achados de hoje header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Achados de hoje',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(onPressed: () {}, child: const Text('Ver tudo')),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // product grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.7,
                ),
                itemCount: mockProducts.length,
                itemBuilder: (context, index) {
                  final p = mockProducts[index];
                  return _ProductCard(
                    product: p,
                    onTap: () => context.push('/product-detail', extra: p),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // image placeholder
            Container(
              height: 120,
              color: AppColors.gray300,
              child: Center(
                child: Icon(Icons.photo, size: 40, color: AppColors.gray500),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.price,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(31),
                          borderRadius: BorderRadius.circular(AppRadius.small),
                        ),
                        child: const Text(
                          'Entrega em até 45 min',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

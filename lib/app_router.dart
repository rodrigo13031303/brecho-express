import 'package:go_router/go_router.dart';

import 'features/auth/presentation/pages/login_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/products/presentation/pages/product_detail_page.dart';

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/product-detail',
        builder: (context, state) {
          final product = state.extra as Product?;
          return ProductDetailPage(product: product);
        },
      ),
    ],
  );
}

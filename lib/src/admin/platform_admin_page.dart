import 'package:flutter/material.dart';

import '../auth/brecho_session.dart';
import '../banner/platform_banner_admin_page.dart';
import '../banner/platform_banner_service.dart';
import '../catalog/category_admin_page.dart';

class PlatformAdminPage extends StatelessWidget {
  const PlatformAdminPage({
    super.key,
    required this.session,
    required this.bannerService,
  });
  final BrechoSession session;
  final PlatformBannerService bannerService;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Administração 🛠️')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.view_carousel_outlined),
            title: const Text('Banners'),
            subtitle: const Text('Conteúdo rotativo da página inicial'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PlatformBannerAdminPage(
                  session: session,
                  service: bannerService,
                ),
              ),
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.account_tree_outlined),
            title: const Text('Categorias'),
            subtitle: const Text('Categorias, subcategorias e disponibilidade'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CategoryAdminPage(session: session),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';

import '../appearance/app_palette.dart';
import '../auth/brecho_session.dart';
import '../branding/brecho_mark.dart';
import '../cart/cart_page.dart';
import '../cart/cart_service.dart';
import '../catalog/catalog_service.dart';
import '../catalog/product_detail_page.dart';
import '../location/store_location_service.dart';
import '../purchase/purchases_hub_page.dart';
import '../seller/seller_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    required this.session,
    required this.palette,
    required this.onPaletteChanged,
    required this.onLogout,
    required this.loggingOut,
    this.initialCatalog,
    super.key,
  });

  final BrechoSession session;
  final AppPalette palette;
  final ValueChanged<AppPalette> onPaletteChanged;
  final Future<void> Function() onLogout;
  final bool loggingOut;
  final Future<CatalogSnapshot>? initialCatalog;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late final CatalogService _catalogService;
  late final CartService _cartService;
  late final StoreLocationService _locationService;
  late Future<CatalogSnapshot> _catalog;
  late Future<CartSnapshot> _cart;
  CartSnapshot? _cartValue;
  String? _busyCartItemId;
  bool _checkingOut = false;
  int _purchaseRefresh = 0;
  bool _distanceEnabled = false;
  bool _enablingDistance = false;
  GeoPoint? _viewerLocation;

  @override
  void initState() {
    super.initState();
    _catalogService = CatalogService();
    _cartService = CartService();
    _locationService = StoreLocationService();
    _catalog = widget.initialCatalog ?? _catalogService.load();
    _cart = _loadCart();
  }

  @override
  void dispose() {
    _catalogService.close();
    _cartService.close();
    _locationService.close();
    super.dispose();
  }

  Future<CartSnapshot> _loadCart() async {
    final value = await _cartService.load(widget.session);
    if (mounted) setState(() => _cartValue = value);
    return value;
  }

  void _retryCart() => setState(() => _cart = _loadCart());

  Future<void> _addToCart(CatalogProduct product) async {
    final current = await _cart;
    final existing = current.items
        .where((item) => item.productPublicId == product.publicId)
        .firstOrNull;
    final updated = existing == null
        ? await _cartService.add(
            session: widget.session,
            cartPublicId: current.publicId,
            productPublicId: product.publicId,
          )
        : await _cartService.update(
            session: widget.session,
            cartPublicId: current.publicId,
            itemPublicId: existing.publicId,
            quantity: existing.quantity + 1,
          );
    if (!mounted) return;
    setState(() {
      _cartValue = updated;
      _cart = Future.value(updated);
    });
  }

  Future<PurchaseRequest> _checkout() async {
    final current = await _cart;
    setState(() => _checkingOut = true);
    try {
      final request = await _cartService.checkout(
        session: widget.session,
        cartPublicId: current.publicId,
      );
      if (mounted) {
        setState(() {
          _cartValue = null;
          _purchaseRefresh++;
          _cart = _loadCart();
        });
      }
      return request;
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  Future<void> _changeCartQuantity(CartItem item, int quantity) async {
    final current = await _cart;
    setState(() => _busyCartItemId = item.publicId);
    try {
      final updated = await _cartService.update(
        session: widget.session,
        cartPublicId: current.publicId,
        itemPublicId: item.publicId,
        quantity: quantity,
      );
      if (!mounted) return;
      setState(() {
        _cartValue = updated;
        _cart = Future.value(updated);
      });
    } on CartException catch (error) {
      if (mounted) _showCartError(error.message);
    } finally {
      if (mounted) setState(() => _busyCartItemId = null);
    }
  }

  Future<void> _removeCartItem(CartItem item) async {
    final current = await _cart;
    setState(() => _busyCartItemId = item.publicId);
    try {
      final updated = await _cartService.remove(
        session: widget.session,
        cartPublicId: current.publicId,
        itemPublicId: item.publicId,
      );
      if (!mounted) return;
      setState(() {
        _cartValue = updated;
        _cart = Future.value(updated);
      });
    } on CartException catch (error) {
      if (mounted) _showCartError(error.message);
    } finally {
      if (mounted) setState(() => _busyCartItemId = null);
    }
  }

  void _showCartError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _retryCatalog() {
    final point = _viewerLocation;
    setState(
      () => _catalog = _catalogService.load(
        requesterLatitude: point?.latitude,
        requesterLongitude: point?.longitude,
      ),
    );
  }

  Future<void> _enableDistance() async {
    if (_enablingDistance) return;
    setState(() => _enablingDistance = true);
    try {
      final point = await _locationService.currentCoordinates();
      if (!mounted) return;
      setState(() {
        _distanceEnabled = true;
        _viewerLocation = point;
        _catalog = _catalogService.load(
          requesterLatitude: point.latitude,
          requesterLongitude: point.longitude,
        );
      });
    } on StoreLocationException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _enablingDistance = false);
    }
  }

  void _selectTab(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        catalog: _catalog,
        onRetry: _retryCatalog,
        onExplore: () => _selectTab(1),
        onSell: () => _selectTab(2),
        onAddToCart: _addToCart,
      ),
      ExplorePage(
        catalog: _catalog,
        onRetry: _retryCatalog,
        distanceEnabled: _distanceEnabled,
        enablingDistance: _enablingDistance,
        onEnableDistance: _enableDistance,
        onAddToCart: _addToCart,
      ),
      SellerPage(
        session: widget.session,
        catalog: _catalog,
        onPublished: _retryCatalog,
      ),
      PurchasesHubPage(
        session: widget.session,
        catalog: _catalog,
        refreshToken: _purchaseRefresh,
        cartPage: CartPage(
          cart: _cart,
          catalog: _catalog,
          busyItemId: _busyCartItemId,
          onRetry: _retryCart,
          onQuantityChanged: _changeCartQuantity,
          onRemove: _removeCartItem,
          onCheckout: _checkout,
          checkoutBusy: _checkingOut,
        ),
      ),
      ProfilePage(
        session: widget.session,
        palette: widget.palette,
        onPaletteChanged: widget.onPaletteChanged,
        onLogout: widget.onLogout,
        loggingOut: widget.loggingOut,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _selectTab,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.manage_search),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Vender',
          ),
          NavigationDestination(
            icon: _CartNavigationIcon(count: _cartValue?.itemCount ?? 0),
            selectedIcon: _CartNavigationIcon(
              count: _cartValue?.itemCount ?? 0,
              selected: true,
            ),
            label: 'Compras',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class _CartNavigationIcon extends StatelessWidget {
  const _CartNavigationIcon({required this.count, this.selected = false});

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) => Badge(
    isLabelVisible: count > 0,
    label: Text(count > 99 ? '99+' : '$count'),
    child: Icon(selected ? Icons.shopping_cart : Icons.shopping_cart_outlined),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({
    required this.catalog,
    required this.onRetry,
    required this.onExplore,
    required this.onSell,
    required this.onAddToCart,
    super.key,
  });
  final Future<CatalogSnapshot> catalog;
  final VoidCallback onRetry;
  final VoidCallback onExplore;
  final VoidCallback onSell;
  final Future<void> Function(CatalogProduct product) onAddToCart;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            sliver: SliverList.list(
              children: [
                const _BrandHeader(title: 'Brechó Express'),
                const SizedBox(height: 24),
                Text(
                  'Olá! 👋',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Que história sua próxima peça vai contar?',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 22),
                SearchBar(
                  onTap: onExplore,
                  readOnly: true,
                  leading: const Icon(Icons.search),
                  hintText: 'Buscar peças, marcas ou estilos',
                ),
                const SizedBox(height: 28),
                Text(
                  'Explore por categoria',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _CategoryChip(
                      icon: Icons.checkroom_outlined,
                      label: 'Roupas',
                      onTap: onExplore,
                    ),
                    _CategoryChip(
                      icon: Icons.shopping_bag_outlined,
                      label: 'Bolsas',
                      onTap: onExplore,
                    ),
                    _CategoryChip(
                      icon: Icons.diamond_outlined,
                      label: 'Acessórios',
                      onTap: onExplore,
                    ),
                    _CategoryChip(
                      icon: Icons.directions_run_outlined,
                      label: 'Calçados',
                      onTap: onExplore,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: colors.onPrimaryContainer,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Desapegue. Renove. Recomece.',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Dê uma nova história às peças que você não usa mais.',
                        style: TextStyle(color: colors.onPrimaryContainer),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: onSell,
                        icon: const Icon(Icons.add),
                        label: const Text('Quero vender'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Novidades',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _CatalogContent(
                  catalog: catalog,
                  onRetry: onRetry,
                  preview: true,
                  onAddToCart: onAddToCart,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ExplorePage extends StatefulWidget {
  const ExplorePage({
    required this.catalog,
    required this.onRetry,
    required this.distanceEnabled,
    required this.enablingDistance,
    required this.onEnableDistance,
    required this.onAddToCart,
    super.key,
  });
  final Future<CatalogSnapshot> catalog;
  final VoidCallback onRetry;
  final bool distanceEnabled;
  final bool enablingDistance;
  final VoidCallback onEnableDistance;
  final Future<void> Function(CatalogProduct product) onAddToCart;
  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final _searchController = TextEditingController();
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          const _BrandHeader(title: 'Explorar'),
          const SizedBox(height: 22),
          SearchBar(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            leading: const Icon(Icons.search),
            hintText: 'O que você procura?',
            trailing: [
              IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close),
                tooltip: 'Limpar busca',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              const FilterChip(label: Text('Categoria'), onSelected: null),
              const FilterChip(label: Text('Tamanho'), onSelected: null),
              const FilterChip(label: Text('Preço'), onSelected: null),
              FilterChip(
                selected: widget.distanceEnabled,
                avatar: widget.enablingDistance
                    ? const SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.near_me_outlined, size: 18),
                label: Text(
                  widget.distanceEnabled ? 'Distância ativa' : 'Ver distância',
                ),
                onSelected: widget.enablingDistance
                    ? null
                    : (_) => widget.onEnableDistance(),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _CatalogContent(
            catalog: widget.catalog,
            onRetry: widget.onRetry,
            query: _searchController.text,
            onAddToCart: widget.onAddToCart,
          ),
        ],
      ),
    );
  }
}

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          const _BrandHeader(title: 'Pedidos'),
          const SizedBox(height: 72),
          Icon(
            Icons.receipt_long_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 18),
          Text(
            'Nenhum pedido por aqui',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Suas compras e vendas aparecerão aqui.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    required this.session,
    required this.palette,
    required this.onPaletteChanged,
    required this.onLogout,
    required this.loggingOut,
    this.initialCatalog,
    super.key,
  });
  final BrechoSession session;
  final AppPalette palette;
  final ValueChanged<AppPalette> onPaletteChanged;
  final Future<void> Function() onLogout;
  final bool loggingOut;
  final Future<CatalogSnapshot>? initialCatalog;

  Future<void> _chooseAppearance(BuildContext context) async {
    final selected = await showModalBottomSheet<AppPalette>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Escolha seu estilo',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              const Text('A cor do cabide permanece sempre a mesma.'),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: AppPalette.values
                    .map(
                      (item) => ChoiceChip(
                        selected: item == palette,
                        onSelected: (_) => Navigator.pop(context, item),
                        avatar: CircleAvatar(backgroundColor: item.seedColor),
                        label: Text(item.label),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) onPaletteChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          const _BrandHeader(title: 'Perfil'),
          const SizedBox(height: 28),
          CircleAvatar(
            radius: 42,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.person,
              size: 46,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Minha conta',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            session.accountPublicId,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 28),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Aparência'),
                  subtitle: Text(palette.label),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _chooseAppearance(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Sessão segura'),
                  subtitle: Text(
                    'Ativa até ${_formatDate(session.expiresAt.toLocal())}',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: loggingOut ? null : onLogout,
            icon: loggingOut
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            label: Text(loggingOut ? 'Saindo…' : 'Sair da conta'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} às ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const BrechoMark(size: 36),
      const SizedBox(width: 10),
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ],
  );
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ActionChip(
    avatar: Icon(icon, size: 19),
    label: Text(label),
    onPressed: onTap,
  );
}

class _CatalogContent extends StatelessWidget {
  const _CatalogContent({
    required this.catalog,
    required this.onRetry,
    this.query = '',
    this.preview = false,
    required this.onAddToCart,
  });
  final Future<CatalogSnapshot> catalog;
  final VoidCallback onRetry;
  final String query;
  final bool preview;
  final Future<void> Function(CatalogProduct product) onAddToCart;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CatalogSnapshot>(
      future: catalog,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return _CatalogMessage(
            icon: Icons.cloud_off_outlined,
            title: 'Catálogo temporariamente indisponível',
            message: 'Não foi possível carregar as peças agora.',
            action: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          );
        }
        final products = snapshot.data!.products
            .where((item) => item.matches(query))
            .toList();
        if (products.isEmpty) {
          return _CatalogMessage(
            icon: Icons.inventory_2_outlined,
            title: query.trim().isEmpty
                ? 'Nenhuma peça publicada ainda'
                : 'Nenhuma peça encontrada',
            message: query.trim().isEmpty
                ? 'As primeiras peças aparecerão aqui assim que forem publicadas.'
                : 'Tente buscar por outro nome ou estilo.',
          );
        }
        final visible = preview ? products.take(4) : products;
        return Column(
          children: visible
              .map(
                (product) =>
                    _ProductCard(product: product, onAddToCart: onAddToCart),
              )
              .toList(),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onAddToCart});
  final CatalogProduct product;
  final Future<void> Function(CatalogProduct product) onAddToCart;

  @override
  Widget build(BuildContext context) {
    final price = product.price.toStringAsFixed(2).replaceAll('.', ',');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.antiAlias,
          child: product.primaryImageUrl == null
              ? const Icon(Icons.checkroom_outlined)
              : Image.network(
                  product.primaryImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.broken_image_outlined),
                ),
        ),
        title: Text(
          product.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          [
            if (product.storeName != null) product.storeName!,
            _conditionLabel(product.condition),
            'R\$ $price',
            if (product.location != null) product.location!.label,
          ].join(' • '),
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) =>
                ProductDetailPage(product: product, onAddToCart: onAddToCart),
          ),
        ),
      ),
    );
  }

  static String _conditionLabel(String value) => switch (value) {
    'NEW' => 'Novo',
    'LIKE_NEW' => 'Como novo',
    'GOOD' => 'Bom estado',
    'FAIR' => 'Usado',
    _ => value,
  };
}

class _CatalogMessage extends StatelessWidget {
  const _CatalogMessage({
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
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 8), action!],
        ],
      ),
    ),
  );
}

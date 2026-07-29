import 'package:flutter/material.dart';

import '../appearance/app_palette.dart';
import '../auth/brecho_session.dart';
import '../branding/brecho_mark.dart';
import '../cart/cart_page.dart';
import '../cart/cart_service.dart';
import '../catalog/catalog_service.dart';
import '../catalog/product_detail_page.dart';
import '../location/buyer_location_store.dart';
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
  late final BuyerLocationStore _buyerLocationStore;
  late Future<CatalogSnapshot> _catalog;
  late Future<CartSnapshot> _cart;
  CartSnapshot? _cartValue;
  String? _busyCartItemId;
  bool _checkingOut = false;
  int _purchaseRefresh = 0;
  bool _distanceEnabled = false;
  bool _enablingDistance = false;
  GeoPoint? _viewerLocation;
  String? _viewerLocationLabel;

  @override
  void initState() {
    super.initState();
    _catalogService = CatalogService();
    _cartService = CartService();
    _locationService = StoreLocationService();
    _buyerLocationStore = BuyerLocationStore();
    _catalog = widget.initialCatalog ?? _catalogService.load();
    _cart = _loadCart();
    _restoreBuyerLocation();
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
          _restoreBuyerLocation();
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

  Future<void> _restoreBuyerLocation() async {
    final saved = await _buyerLocationStore.read();
    if (saved == null || !mounted) return;
    _applyBuyerLocation(saved);
  }

  void _applyBuyerLocation(BuyerCatalogLocation location) {
    setState(() {
      _distanceEnabled = true;
      _viewerLocation = location.point;
      _viewerLocationLabel = location.label;
      _catalog = _catalogService.load(
        requesterLatitude: location.point.latitude,
        requesterLongitude: location.point.longitude,
      );
    });
  }

  Future<void> _chooseBuyerLocation() async {
    final postalCode = TextEditingController();
    final result = await showModalBottomSheet<BuyerCatalogLocation>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _BuyerLocationSheet(
        postalCode: postalCode,
        service: _locationService,
      ),
    );
    postalCode.dispose();
    if (result == null || !mounted) return;
    await _buyerLocationStore.write(result);
    if (mounted) _applyBuyerLocation(result);
  }

  Future<void> _enableDistance() async {
    if (_enablingDistance) return;
    setState(() => _enablingDistance = true);
    try {
      final point = await _locationService.currentCoordinates();
      if (!mounted) return;
      final location = BuyerCatalogLocation(
        point: point,
        label: 'Minha localização atual',
      );
      await _buyerLocationStore.write(location);
      if (mounted) _applyBuyerLocation(location);
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
        locationLabel: _viewerLocationLabel,
        onChooseLocation: _chooseBuyerLocation,
      ),
      ExplorePage(
        catalog: _catalog,
        onRetry: _retryCatalog,
        distanceEnabled: _distanceEnabled,
        enablingDistance: _enablingDistance,
        onEnableDistance: _enableDistance,
        locationLabel: _viewerLocationLabel,
        onChooseLocation: _chooseBuyerLocation,
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
            label: 'Comprar',
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
            label: 'Carrinho',
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
    required this.locationLabel,
    required this.onChooseLocation,
    super.key,
  });
  final Future<CatalogSnapshot> catalog;
  final VoidCallback onRetry;
  final VoidCallback onExplore;
  final VoidCallback onSell;
  final Future<void> Function(CatalogProduct product) onAddToCart;
  final String? locationLabel;
  final VoidCallback onChooseLocation;

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
                const SizedBox(height: 14),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(locationLabel ?? 'Escolha onde quer comprar'),
                    subtitle: const Text('Ver distância dos brechós'),
                    trailing: const Icon(Icons.edit_location_alt_outlined),
                    onTap: onChooseLocation,
                  ),
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
    required this.locationLabel,
    required this.onChooseLocation,
    super.key,
  });
  final Future<CatalogSnapshot> catalog;
  final VoidCallback onRetry;
  final bool distanceEnabled;
  final bool enablingDistance;
  final VoidCallback onEnableDistance;
  final Future<void> Function(CatalogProduct product) onAddToCart;
  final String? locationLabel;
  final VoidCallback onChooseLocation;
  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final _searchController = TextEditingController();
  bool _sortNearest = false;
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
          const _BrandHeader(title: 'Comprar'),
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
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(widget.locationLabel ?? 'Escolha sua localização'),
              subtitle: const Text('Referência para calcular as distâncias'),
              trailing: const Icon(Icons.edit_location_alt_outlined),
              onTap: widget.onChooseLocation,
            ),
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 12),
          DropdownButtonFormField<bool>(
            initialValue: _sortNearest,
            decoration: const InputDecoration(
              labelText: 'Ordenar produtos',
              prefixIcon: Icon(Icons.sort),
            ),
            items: const [
              DropdownMenuItem(value: false, child: Text('Mais recentes')),
              DropdownMenuItem(
                value: true,
                child: Text('Brechós mais próximos'),
              ),
            ],
            onChanged: (value) => setState(() => _sortNearest = value ?? false),
          ),
          const SizedBox(height: 24),
          _CatalogContent(
            catalog: widget.catalog,
            onRetry: widget.onRetry,
            query: _searchController.text,
            sortNearest: _sortNearest,
            onAddToCart: widget.onAddToCart,
          ),
        ],
      ),
    );
  }
}

class _BuyerLocationSheet extends StatefulWidget {
  const _BuyerLocationSheet({required this.postalCode, required this.service});
  final TextEditingController postalCode;
  final StoreLocationService service;

  @override
  State<_BuyerLocationSheet> createState() => _BuyerLocationSheetState();
}

class _BuyerLocationSheetState extends State<_BuyerLocationSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _byPostalCode() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final draft = await widget.service.lookupPostalCode(
        widget.postalCode.text,
      );
      final point = await widget.service.coordinatesForBuyerReference(draft);
      if (!mounted) return;
      Navigator.pop(
        context,
        BuyerCatalogLocation(point: point, label: draft.publicLabel),
      );
    } on StoreLocationException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _current() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final point = await widget.service.currentCoordinates();
      if (!mounted) return;
      Navigator.pop(
        context,
        BuyerCatalogLocation(point: point, label: 'Minha localização atual'),
      );
    } on StoreLocationException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      24,
      4,
      24,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Onde você quer comprar? 📍',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text('Escolha qualquer região; não precisa ser onde você está.'),
        const SizedBox(height: 18),
        TextField(
          controller: widget.postalCode,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'CEP de referência',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _busy ? null : _byPostalCode,
          icon: const Icon(Icons.search),
          label: const Text('Usar este CEP'),
        ),
        OutlinedButton.icon(
          onPressed: _busy ? null : _current,
          icon: const Icon(Icons.my_location),
          label: const Text('Usar minha localização atual'),
        ),
      ],
    ),
  );
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
    this.sortNearest = false,
    required this.onAddToCart,
  });
  final Future<CatalogSnapshot> catalog;
  final VoidCallback onRetry;
  final String query;
  final bool preview;
  final bool sortNearest;
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
        if (sortNearest) {
          products.sort((a, b) {
            final left = a.location?.distanceKm ?? double.infinity;
            final right = b.location?.distanceKm ?? double.infinity;
            return left.compareTo(right);
          });
        }
        final visible = (preview ? products.take(4) : products).toList();
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visible.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: .58,
          ),
          itemBuilder: (context, index) =>
              _ProductCard(product: visible[index], onAddToCart: onAddToCart),
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
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) =>
                ProductDetailPage(product: product, onAddToCart: onAddToCart),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ColoredBox(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: product.primaryImageUrl == null
                    ? const Icon(Icons.checkroom_outlined, size: 54)
                    : Image.network(
                        product.primaryImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.broken_image_outlined),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (product.storeLogoUrl != null)
                        CircleAvatar(
                          radius: 9,
                          foregroundImage: NetworkImage(product.storeLogoUrl!),
                        ),
                      if (product.storeLogoUrl != null)
                        const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          product.storeName ?? 'Brechó Express',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'R\$ $price',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  if (product.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            product.location!.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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

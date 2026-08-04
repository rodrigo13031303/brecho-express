import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../appearance/app_palette.dart';
import '../auth/brecho_session.dart';
import '../banner/platform_banner_admin_page.dart';
import '../banner/platform_banner_carousel.dart';
import '../banner/platform_banner_service.dart';
import '../branding/brecho_mark.dart';
import '../cart/cart_page.dart';
import '../cart/cart_service.dart';
import '../catalog/catalog_service.dart';
import '../catalog/product_detail_page.dart';
import '../location/buyer_location_store.dart';
import '../location/store_location_service.dart';
import '../notification/push_notification_service.dart';
import '../purchase/purchases_hub_page.dart';
import '../profile/user_profile_service.dart';
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
  late final PushNotificationService _pushNotificationService;
  late final PlatformBannerService _bannerService;
  late final UserProfileService _profileService;
  late Future<CatalogSnapshot> _catalog;
  late Future<CartSnapshot> _cart;
  late Future<List<PlatformBanner>> _banners;
  late Future<Set<String>> _roles;
  late Future<UserProfileSummary?> _profile;
  CartSnapshot? _cartValue;
  String? _busyCartItemId;
  bool _checkingOut = false;
  int _purchaseRefresh = 0;
  GeoPoint? _viewerLocation;
  String? _viewerLocationLabel;

  @override
  void initState() {
    super.initState();
    _catalogService = CatalogService();
    _cartService = CartService();
    _locationService = StoreLocationService();
    _buyerLocationStore = BuyerLocationStore();
    _pushNotificationService = PushNotificationService();
    _bannerService = PlatformBannerService();
    _profileService = UserProfileService();
    _catalog = widget.initialCatalog ?? _catalogService.load();
    _cart = _loadCart();
    _banners = _bannerService.listPublic();
    _roles = _bannerService.myRoles(widget.session);
    _profile = _loadProfile();
    _restoreBuyerLocation();
    _activatePushNotifications();
  }

  @override
  void dispose() {
    _catalogService.close();
    _cartService.close();
    _pushNotificationService.close();
    _bannerService.close();
    _locationService.close();
    _profileService.close();
    super.dispose();
  }

  Future<void> _activatePushNotifications() async {
    try {
      await _pushNotificationService.activate(widget.session);
    } catch (_) {
      // O app continua funcional e tenta registrar novamente no próximo login.
    }
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
          _banners = _bannerService.listPublic();
          _roles = _bannerService.myRoles(widget.session);
          _banners = _bannerService.listPublic();
          _roles = _bannerService.myRoles(widget.session);
          _restoreBuyerLocation();
          _activatePushNotifications();
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
    if (saved != null && saved.label != 'Minha localização atual') {
      if (mounted) _applyBuyerLocation(saved);
      return;
    }
    try {
      final draft = await _locationService.useCurrentLocation();
      final location = BuyerCatalogLocation(
        point: GeoPoint(draft.latitude!, draft.longitude!),
        label: _buyerLocationLabel(draft),
      );
      await _buyerLocationStore.write(location);
      if (mounted) _applyBuyerLocation(location);
    } catch (_) {
      // A Home continua utilizável e permite escolher CEP ou GPS manualmente.
    }
  }

  Future<UserProfileSummary?> _loadProfile() async {
    try {
      return await _profileService.getMe(widget.session);
    } catch (_) {
      return null;
    }
  }

  static String _buyerLocationLabel(StoreLocationDraft draft) {
    final street = draft.street.trim();
    final number = draft.number.trim();
    if (street.isNotEmpty) {
      return number.isEmpty ? street : '$street, $number';
    }
    return draft.publicLabel;
  }

  void _applyBuyerLocation(BuyerCatalogLocation location) {
    setState(() {
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

  void _selectTab(int index) => setState(() => _currentIndex = index);

  void _reloadBanners() => setState(() {
    _banners = _bannerService.listPublic();
  });

  Future<void> _openBanner(PlatformBanner banner) async {
    if (banner.targetType == 'APP_SCREEN') {
      final index = switch (banner.targetValue?.toLowerCase()) {
        'home' || 'inicio' => 0,
        'buy' || 'comprar' || 'explore' => 1,
        'sell' || 'vender' => 2,
        'cart' || 'carrinho' => 3,
        'profile' || 'perfil' => 4,
        _ => 1,
      };
      _selectTab(index);
      return;
    }
    if (banner.targetType == 'PRODUCT' && banner.targetPublicId != null) {
      final snapshot = await _catalog;
      final product = snapshot.products
          .where((item) => item.publicId == banner.targetPublicId)
          .firstOrNull;
      if (product != null && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                ProductDetailPage(product: product, onAddToCart: _addToCart),
          ),
        );
        return;
      }
    }
    if (mounted) _selectTab(1);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        banners: _banners,
        onOpenBanner: _openBanner,
        profile: _profile,
        catalog: _catalog,
        onRetry: _retryCatalog,
        onAddToCart: _addToCart,
        locationLabel: _viewerLocationLabel,
        onChooseLocation: _chooseBuyerLocation,
      ),
      ExplorePage(
        catalog: _catalog,
        onRetry: _retryCatalog,

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
        roles: _roles,
        bannerService: _bannerService,
        onBannersChanged: _reloadBanners,
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
    required this.banners,
    required this.onOpenBanner,
    required this.profile,
    required this.catalog,
    required this.onRetry,
    required this.onAddToCart,
    required this.locationLabel,
    required this.onChooseLocation,
    super.key,
  });
  final Future<List<PlatformBanner>> banners;
  final ValueChanged<PlatformBanner> onOpenBanner;
  final Future<UserProfileSummary?> profile;
  final Future<CatalogSnapshot> catalog;
  final VoidCallback onRetry;
  final Future<void> Function(CatalogProduct product) onAddToCart;
  final String? locationLabel;
  final VoidCallback onChooseLocation;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            sliver: SliverList.list(
              children: [
                const _BrandHeader(title: 'Brechó Express'),
                const SizedBox(height: 18),
                PlatformBannerCarousel(banners: banners, onOpen: onOpenBanner),
                const SizedBox(height: 18),
                _HomeIdentityHeader(
                  profile: profile,
                  locationLabel: locationLabel,
                  onChooseLocation: onChooseLocation,
                ),
                const SizedBox(height: 24),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeIdentityHeader extends StatelessWidget {
  const _HomeIdentityHeader({
    required this.profile,
    required this.locationLabel,
    required this.onChooseLocation,
  });

  final Future<UserProfileSummary?> profile;
  final String? locationLabel;
  final VoidCallback onChooseLocation;

  @override
  Widget build(BuildContext context) => FutureBuilder<UserProfileSummary?>(
    future: profile,
    builder: (context, snapshot) {
      final firstName = snapshot.data?.firstName ?? '';
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onChooseLocation,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                firstName.isEmpty ? 'Olá! 👋' : 'Olá, $firstName! 👋',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 20),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      locationLabel ?? 'Toque para escolher sua localização',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class ExplorePage extends StatefulWidget {
  const ExplorePage({
    required this.catalog,
    required this.onRetry,

    required this.onAddToCart,
    required this.locationLabel,
    required this.onChooseLocation,
    super.key,
  });
  final Future<CatalogSnapshot> catalog;
  final VoidCallback onRetry;

  final Future<void> Function(CatalogProduct product) onAddToCart;
  final String? locationLabel;
  final VoidCallback onChooseLocation;
  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final _searchController = TextEditingController();
  bool _sortNearest = false;
  String? _categoryPublicId;
  _PriceFilter _priceFilter = _PriceFilter.all;
  _SizeFilter _sizeFilter = _SizeFilter.all;
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
          FutureBuilder<CatalogSnapshot>(
            future: widget.catalog,
            builder: (context, snapshot) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  selected: _categoryPublicId != null,
                  label: Text(_categoryLabel(snapshot.data)),
                  onSelected: snapshot.hasData
                      ? (_) => _chooseCategory(snapshot.data!.categories)
                      : null,
                ),
                FilterChip(
                  selected: _sizeFilter != _SizeFilter.all,
                  label: Text(_sizeFilter.label),
                  onSelected: (_) => _chooseSize(),
                ),
                FilterChip(
                  selected: _priceFilter != _PriceFilter.all,
                  label: Text(_priceFilter.label),
                  onSelected: (_) => _choosePrice(),
                ),
              ],
            ),
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
            categoryPublicId: _categoryPublicId,
            priceFilter: _priceFilter,
            sizeFilter: _sizeFilter,
            onAddToCart: widget.onAddToCart,
          ),
        ],
      ),
    );
  }

  String _categoryLabel(CatalogSnapshot? snapshot) {
    if (_categoryPublicId == null) return 'Categoria';
    for (final category in snapshot?.categories ?? const <CatalogCategory>[]) {
      if (category.publicId == _categoryPublicId) return category.name;
    }
    return 'Categoria';
  }

  Future<void> _chooseCategory(List<CatalogCategory> categories) async {
    final value = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.apps),
              title: const Text('Todas as categorias'),
              onTap: () => Navigator.pop(context, ''),
            ),
            ...categories.map(
              (item) => ListTile(
                leading: const Icon(Icons.checkroom_outlined),
                title: Text(item.name),
                selected: item.publicId == _categoryPublicId,
                onTap: () => Navigator.pop(context, item.publicId),
              ),
            ),
          ],
        ),
      ),
    );
    if (value == null || !mounted) return;
    setState(() => _categoryPublicId = value.isEmpty ? null : value);
  }

  Future<void> _chooseSize() async {
    final value = await _chooseEnum<_SizeFilter>(
      title: 'Comprimento / tamanho',
      values: _SizeFilter.values,
      label: (item) => item.menuLabel,
    );
    if (value != null && mounted) setState(() => _sizeFilter = value);
  }

  Future<void> _choosePrice() async {
    final value = await _chooseEnum<_PriceFilter>(
      title: 'Faixa de preço',
      values: _PriceFilter.values,
      label: (item) => item.menuLabel,
    );
    if (value != null && mounted) setState(() => _priceFilter = value);
  }

  Future<T?> _chooseEnum<T>({
    required String title,
    required List<T> values,
    required String Function(T) label,
  }) => showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          ...values.map(
            (item) => ListTile(
              title: Text(label(item)),
              onTap: () => Navigator.pop(context, item),
            ),
          ),
        ],
      ),
    ),
  );
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
      final draft = await widget.service.useCurrentLocation();
      final point = GeoPoint(draft.latitude!, draft.longitude!);
      if (!mounted) return;
      Navigator.pop(
        context,
        BuyerCatalogLocation(
          point: point,
          label: _MainShellState._buyerLocationLabel(draft),
        ),
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
    required this.roles,
    required this.bannerService,
    required this.onBannersChanged,
    this.initialCatalog,
    super.key,
  });
  final BrechoSession session;
  final AppPalette palette;
  final ValueChanged<AppPalette> onPaletteChanged;
  final Future<void> Function() onLogout;
  final bool loggingOut;
  final Future<Set<String>> roles;
  final PlatformBannerService bannerService;
  final VoidCallback onBannersChanged;
  final Future<CatalogSnapshot>? initialCatalog;

  Future<void> _chooseAppearance(BuildContext context) async {
    final selected = await showModalBottomSheet<AppPalette>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: ListView(
            shrinkWrap: true,
            children: [
              Column(
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
                            avatar: CircleAvatar(
                              backgroundColor: item.seedColor,
                            ),
                            label: Text(item.label),
                          ),
                        )
                        .toList(),
                  ),
                ],
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
                FutureBuilder<Set<String>>(
                  future: roles,
                  builder: (context, snapshot) {
                    if (!(snapshot.data?.contains('ADMIN') ?? false)) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.admin_panel_settings_outlined,
                          ),
                          title: const Text('Administração'),
                          subtitle: const Text('Banners da página inicial'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => PlatformBannerAdminPage(
                                  session: session,
                                  service: bannerService,
                                ),
                              ),
                            );
                            onBannersChanged();
                          },
                        ),
                      ],
                    );
                  },
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

class _CatalogContent extends StatelessWidget {
  const _CatalogContent({
    required this.catalog,
    required this.onRetry,
    this.query = '',
    this.preview = false,
    this.sortNearest = false,
    this.categoryPublicId,
    this.priceFilter = _PriceFilter.all,
    this.sizeFilter = _SizeFilter.all,
    required this.onAddToCart,
  });
  final Future<CatalogSnapshot> catalog;
  final VoidCallback onRetry;
  final String query;
  final bool preview;
  final bool sortNearest;
  final String? categoryPublicId;
  final _PriceFilter priceFilter;
  final _SizeFilter sizeFilter;
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
            .where(
              (item) =>
                  categoryPublicId == null ||
                  item.categoryPublicId == categoryPublicId,
            )
            .where(priceFilter.matches)
            .where(sizeFilter.matches)
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
                    : CachedNetworkImage(
                        imageUrl: product.primaryImageUrl!,
                        fit: BoxFit.contain,
                        memCacheWidth: 720,
                        placeholder: (_, _) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (_, _, _) =>
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
                            product.location!.distanceLabel,
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

enum _PriceFilter {
  all('Preço', 'Todos os preços'),
  upTo50('Até R\$ 50', 'Até R\$ 50'),
  from50To100('R\$ 50–100', 'De R\$ 50 a R\$ 100'),
  above100('Acima de R\$ 100', 'Acima de R\$ 100');

  const _PriceFilter(this.label, this.menuLabel);
  final String label;
  final String menuLabel;

  bool matches(CatalogProduct product) => switch (this) {
    all => true,
    upTo50 => product.price <= 50,
    from50To100 => product.price > 50 && product.price <= 100,
    above100 => product.price > 100,
  };
}

enum _SizeFilter {
  all('Tamanho', 'Todos os tamanhos'),
  small('Até 50 cm', 'Pequeno — até 50 cm'),
  medium('50–100 cm', 'Médio — de 50 a 100 cm'),
  large('Acima de 100 cm', 'Grande — acima de 100 cm');

  const _SizeFilter(this.label, this.menuLabel);
  final String label;
  final String menuLabel;

  bool matches(CatalogProduct product) => switch (this) {
    all => true,
    small => product.length != null && product.length! <= 50,
    medium =>
      product.length != null && product.length! > 50 && product.length! <= 100,
    large => product.length != null && product.length! > 100,
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

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../auth/brecho_session.dart';
import '../branding/brecho_mark.dart';
import '../catalog/catalog_service.dart';
import '../purchase/purchase_service.dart';
import '../location/store_location_service.dart';
import '../order/orders_page.dart';
import 'seller_requests_page.dart';
import 'seller_service.dart';
import 'seller_shipping_page.dart';

enum _SellerSection {
  hub,
  store,
  shipping,
  products,
  requests,
  orders,
  newProduct,
}

class SellerPage extends StatefulWidget {
  const SellerPage({
    required this.session,
    required this.catalog,
    required this.onPublished,
    super.key,
  });

  final BrechoSession session;
  final Future<CatalogSnapshot> catalog;
  final VoidCallback onPublished;

  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage> {
  final _service = SellerService();
  final _imagePicker = ImagePicker();
  final _locationService = StoreLocationService();
  final _purchaseService = PurchaseService();
  final _storeForm = GlobalKey<FormState>();
  final _productForm = GlobalKey<FormState>();
  final _productSearch = TextEditingController();
  final _storeName = TextEditingController();
  final _storeSlug = TextEditingController();
  final _storeDescription = TextEditingController();
  final _postalCode = TextEditingController();
  final _street = TextEditingController();
  final _number = TextEditingController();
  final _complement = TextEditingController();
  final _district = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _title = TextEditingController();
  final _slug = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _weight = TextEditingController();
  final _width = TextEditingController();
  final _height = TextEditingController();
  final _length = TextEditingController();

  late Future<List<SellerStore>> _stores;
  Future<List<SellerProduct>>? _products;
  SellerStore? _store;
  String? _categoryPublicId;
  String _condition = 'GOOD';
  String _productStatus = 'ACTIVE';
  Uint8List? _selectedLogo;
  String? _selectedLogoMime;
  final List<_SelectedProductImage> _productImages = [];
  StoreLocationDraft? _location;
  bool _locating = false;
  bool _locationLoaded = false;
  Timer? _requestPoller;
  int _pendingRequestCount = 0;
  int _knownPendingRequestCount = -1;
  String? _locationMessage;
  bool _locationMessageIsError = false;
  bool _saving = false;
  _SellerSection _section = _SellerSection.hub;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _stores = _service.listStores(widget.session);
  }

  @override
  void dispose() {
    _service.close();
    _requestPoller?.cancel();
    _purchaseService.close();
    _locationService.close();
    for (final controller in [
      _productSearch,
      _storeName,
      _storeSlug,
      _storeDescription,
      _postalCode,
      _street,
      _number,
      _complement,
      _district,
      _city,
      _state,
      _title,
      _slug,
      _description,
      _price,
      _quantity,
      _weight,
      _width,
      _height,
      _length,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String _slugify(String value) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const to = 'aaaaaeeeeiiiiooooouuuucn';
    var normalized = value.trim().toLowerCase();
    for (var index = 0; index < from.length; index++) {
      normalized = normalized.replaceAll(from[index], to[index]);
    }
    return normalized
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  void _startRequestAlerts(SellerStore store) {
    if (_requestPoller != null) return;
    _checkPendingRequests(store);
    _requestPoller = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _checkPendingRequests(store),
    );
  }

  Future<void> _checkPendingRequests(SellerStore store) async {
    try {
      final requests = await _purchaseService.listStore(
        session: widget.session,
        storePublicId: store.publicId,
      );
      final pending = requests
          .where((request) => request.status == 'PENDING')
          .length;
      final shouldAlert =
          _knownPendingRequestCount >= 0 && pending > _knownPendingRequestCount;
      _knownPendingRequestCount = pending;
      if (!mounted) return;
      setState(() => _pendingRequestCount = pending);
      if (shouldAlert) {
        await SystemSound.play(SystemSoundType.alert);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Nova solicitação! Você tem 5 minutos para responder. 🔔',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'ABRIR',
              onPressed: () =>
                  setState(() => _section = _SellerSection.requests),
            ),
          ),
        );
      }
    } catch (_) {
      // A próxima verificação automática tenta novamente.
    }
  }

  Future<void> _chooseLogo() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 640,
      maxHeight: 640,
      imageQuality: 82,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    if (bytes.length > 1048576) {
      setState(() => _error = 'Escolha uma imagem de até 1 MB.');
      return;
    }
    final extension = image.name.toLowerCase();
    final mime = extension.endsWith('.png')
        ? 'image/png'
        : extension.endsWith('.webp')
        ? 'image/webp'
        : 'image/jpeg';
    setState(() {
      _selectedLogo = bytes;
      _selectedLogoMime = mime;
      _error = null;
    });
  }

  Future<void> _chooseProductImages() async {
    final remaining = 8 - _productImages.length;
    if (remaining <= 0) {
      setState(() => _error = 'Você pode adicionar até 8 fotos por produto.');
      return;
    }
    final images = await _imagePicker.pickMultiImage(
      maxWidth: 900,
      maxHeight: 1200,
      imageQuality: 65,
      limit: remaining,
    );
    if (images.isEmpty || !mounted) return;

    final selected = <_SelectedProductImage>[];
    for (final image in images) {
      final bytes = await image.readAsBytes();
      if (bytes.length > 1536 * 1024) {
        if (mounted) {
          setState(() => _error = 'Cada foto deve ter no máximo 1,5 MB.');
        }
        return;
      }
      final name = image.name.toLowerCase();
      final mimeType = name.endsWith('.png')
          ? 'image/png'
          : name.endsWith('.webp')
          ? 'image/webp'
          : 'image/jpeg';
      selected.add(
        _SelectedProductImage(
          bytes: bytes,
          mimeType: mimeType,
          name: image.name,
        ),
      );
    }
    if (!mounted) return;
    setState(() {
      _productImages.addAll(selected);
      _error = null;
    });
  }

  Future<SellerStore> _uploadSelectedLogo(SellerStore store) async {
    if (_selectedLogo == null || _selectedLogoMime == null) return store;
    final url = await _service.uploadLogo(
      session: widget.session,
      storePublicId: store.publicId,
      bytes: _selectedLogo!,
      mimeType: _selectedLogoMime!,
    );
    return store.withLogo(url);
  }

  void _fillLocation(StoreLocationDraft location) {
    _postalCode.text = location.postalCode;
    _street.text = location.street;
    _number.text = location.number;
    _complement.text = location.complement;
    _district.text = location.district;
    _city.text = location.city;
    _state.text = location.state;
    _location = location;
  }

  StoreLocationDraft _draftFromFields() => StoreLocationDraft(
    postalCode: _postalCode.text.trim(),
    street: _street.text.trim(),
    number: _number.text.trim(),
    complement: _complement.text.trim(),
    district: _district.text.trim(),
    city: _city.text.trim(),
    state: _state.text.trim().toUpperCase(),
    latitude: _location?.latitude,
    longitude: _location?.longitude,
  );

  void _showLocationMessage(String message, {required bool error}) {
    setState(() {
      _locationMessage = message;
      _locationMessageIsError = error;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
        ),
      );
  }

  Future<void> _resolveLocation({required bool current}) async {
    setState(() {
      _locating = true;
      _locationMessage = null;
    });
    try {
      final location = current
          ? await _locationService.useCurrentLocation()
          : await _locationService.lookupPostalCode(_postalCode.text);
      if (!mounted) return;
      setState(() => _fillLocation(location));
      _showLocationMessage(
        'Confira os campos e informe o número antes de salvar.',
        error: false,
      );
    } on StoreLocationException catch (error) {
      if (mounted) _showLocationMessage(error.message, error: true);
    } catch (_) {
      if (mounted) {
        _showLocationMessage(
          'Não foi possível obter a localização agora.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<StoreLocationDraft> _prepareLocation() async {
    final location = await _locationService.ensureCoordinates(
      _draftFromFields(),
    );
    if (mounted) setState(() => _location = location);
    return location;
  }

  Future<void> _loadStoreLocation(
    SellerStore store, {
    bool showError = false,
  }) async {
    if (_locationLoaded) return;
    _locationLoaded = true;
    try {
      final location = await _service.loadLocation(
        session: widget.session,
        storePublicId: store.publicId,
      );
      if (mounted) setState(() => _fillLocation(location));
    } on SellerException catch (error) {
      _locationLoaded = false;
      if (mounted && showError) {
        _showLocationMessage(
          'Não foi possível carregar o endereço salvo. ${error.message}',
          error: true,
        );
      }
    }
  }

  Future<void> _saveLocation() async {
    setState(() => _locating = true);
    try {
      final location = await _prepareLocation();
      if (_store != null) {
        await _service.saveLocation(
          session: widget.session,
          storePublicId: _store!.publicId,
          location: location,
        );
      }
      if (mounted) {
        _showLocationMessage(
          _store == null
              ? 'Endereço pronto para criar o brechó.'
              : 'Localização atualizada com sucesso!',
          error: false,
        );
      }
    } on StoreLocationException catch (error) {
      if (mounted) _showLocationMessage(error.message, error: true);
    } on SellerException catch (error) {
      if (mounted) _showLocationMessage(error.message, error: true);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _createStore() async {
    if (!_storeForm.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final preparedLocation = await _prepareLocation();
      final store = await _service.createCompleteStore(
        session: widget.session,
        name: _storeName.text.trim(),
        slug: _storeSlug.text.trim(),
        description: _storeDescription.text,
        location: preparedLocation,
        logoBytes: _selectedLogo,
        logoMimeType: _selectedLogoMime,
      );
      if (!mounted) return;
      setState(() {
        _store = store;
        _products = _service.listProducts(
          session: widget.session,
          storePublicId: store.publicId,
        );
        _success =
            'Seu brechó está pronto! Agora você pode configurar o logo ou cadastrar produtos.';
      });
    } on StoreLocationException catch (error) {
      if (mounted) _showLocationMessage(error.message, error: true);
    } on SellerException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Não foi possível criar o brechó agora. Nenhum dado foi gravado.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _replaceLogo() async {
    await _chooseLogo();
    if (_selectedLogo == null || _store == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final store = await _uploadSelectedLogo(_store!);
      if (mounted) {
        setState(() {
          _store = store;
          _success = 'Logo atualizado com sucesso!';
        });
      }
    } on SellerException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _activateStore(SellerStore store) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final active = await _service.activateStore(
        widget.session,
        store.publicId,
      );
      if (mounted) setState(() => _store = active);
    } on SellerException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _positiveMeasurementValidator(String? value) {
    final number = double.tryParse((value ?? '').replaceAll(',', '.'));
    return number == null || number <= 0 ? 'Informe um valor válido.' : null;
  }

  Future<void> _editProduct(SellerProduct product) async {
    final changes = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          _ProductEditSheet(product: product, catalog: widget.catalog),
    );
    if (changes == null || _store == null || !mounted) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final replacementImages =
          (changes.remove('_replacementImages') as List?)
              ?.whereType<_SelectedProductImage>()
              .toList(growable: false) ??
          const <_SelectedProductImage>[];
      await _service.updateProduct(
        session: widget.session,
        storePublicId: _store!.publicId,
        product: product,
        changes: changes,
      );
      for (var index = 0; index < replacementImages.length; index++) {
        final image = replacementImages[index];
        await _service.uploadProductImage(
          session: widget.session,
          productPublicId: product.publicId,
          image: SellerProductImageUpload(
            bytes: image.bytes,
            mimeType: image.mimeType,
          ),
          sortOrder: index,
          isPrimary: index == 0,
        );
      }
      if (!mounted) return;
      setState(() {
        _products = _service.listProducts(
          session: widget.session,
          storePublicId: _store!.publicId,
        );
        _success = 'Informações da peça atualizadas! ✨';
      });
      widget.onPublished();
    } on SellerException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changeProductStatus(
    SellerProduct product,
    String status,
  ) async {
    if (_store == null || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.changeProductStatus(
        session: widget.session,
        storePublicId: _store!.publicId,
        productPublicId: product.publicId,
        status: status,
      );
      if (!mounted) return;
      setState(() {
        _products = _service.listProducts(
          session: widget.session,
          storePublicId: _store!.publicId,
        );
        _success = status == 'SOLD'
            ? 'Peça marcada como vendida! ✅'
            : 'Peça colocada novamente à venda! 🎉';
      });
      widget.onPublished();
    } on SellerException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _publish() async {
    if (!_productForm.currentState!.validate() || _store == null) return;
    if (_productImages.isEmpty) {
      setState(() => _error = 'Adicione pelo menos uma foto do produto.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });
    try {
      final product = await _service.publishProduct(
        session: widget.session,
        storePublicId: _store!.publicId,
        categoryPublicId: _categoryPublicId!,
        title: _title.text.trim(),
        slug: _slug.text.trim(),
        description: _description.text,
        price: double.parse(_price.text.replaceAll(',', '.')),
        quantity: int.parse(_quantity.text),
        condition: _condition,
        weight: double.parse(_weight.text.replaceAll(',', '.')),
        width: double.parse(_width.text.replaceAll(',', '.')),
        height: double.parse(_height.text.replaceAll(',', '.')),
        length: double.parse(_length.text.replaceAll(',', '.')),
        images: _productImages
            .map(
              (image) => SellerProductImageUpload(
                bytes: image.bytes,
                mimeType: image.mimeType,
              ),
            )
            .toList(growable: false),
      );
      if (!mounted) return;
      _productForm.currentState!.reset();
      _title.clear();
      _slug.clear();
      _description.clear();
      _price.clear();
      _quantity.text = '1';
      _weight.clear();
      _width.clear();
      _height.clear();
      _length.clear();
      setState(() {
        _categoryPublicId = null;
        _condition = 'GOOD';
        _productImages.clear();
        _products = _service.listProducts(
          session: widget.session,
          storePublicId: _store!.publicId,
        );
        _success = '${product.title} foi publicada no catálogo! 🎉';
        _section = _SellerSection.products;
      });
      widget.onPublished();
    } on SellerException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error =
              'Não foi possível publicar a peça. Detalhe: ${error.toString()}',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: FutureBuilder<List<SellerStore>>(
      future: _stores,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError && _store == null) {
          return _LoadError(
            onRetry: () {
              setState(() => _stores = _service.listStores(widget.session));
            },
          );
        }
        if (_store == null && snapshot.data?.firstOrNull != null) {
          _store = snapshot.data!.first;
          _products ??= _service.listProducts(
            session: widget.session,
            storePublicId: _store!.publicId,
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadStoreLocation(_store!);
            _startRequestAlerts(_store!);
          });
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
          children: [
            const _Header(),
            const SizedBox(height: 24),
            if (_error != null) _Message(text: _error!, error: true),
            if (_success != null)
              _Message(
                text: _success!,
                onClose: () => setState(() => _success = null),
              ),
            if (_store == null)
              _buildStoreForm(context)
            else
              _buildSeller(context),
          ],
        );
      },
    ),
  );

  Widget _buildStoreForm(BuildContext context) => Form(
    key: _storeForm,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Abra seu brechó gratuito',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Preencha os dados abaixo. O cadastro só será concluído quando tudo estiver válido.',
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: _StoreLogoAvatar(
              name: _storeName.text,
              radius: 24,
              bytes: _selectedLogo,
            ),
            title: Text(
              _selectedLogo == null ? 'Logo do brechó' : 'Logo selecionado',
            ),
            subtitle: const Text('Opcional • imagem quadrada de até 1 MB'),
            trailing: TextButton(
              onPressed: _saving ? null : _chooseLogo,
              child: Text(_selectedLogo == null ? 'Adicionar' : 'Trocar'),
            ),
          ),
        ),
        const SizedBox(height: 22),
        TextFormField(
          controller: _storeName,
          decoration: const InputDecoration(
            labelText: 'Nome do brechó',
            prefixIcon: Icon(Icons.storefront_outlined),
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) {
            _storeSlug.text = _slugify(_storeName.text);
            setState(() {});
          },
          validator: (value) => (value?.trim().length ?? 0) < 3
              ? 'Digite pelo menos 3 caracteres.'
              : null,
        ),
        const SizedBox(height: 14),
        Semantics(
          label: 'Endereço público do brechó',
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.link, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'brechoexpress.com.br/${_storeSlug.text.isEmpty ? 'seu-brecho' : _storeSlug.text}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _storeDescription,
          decoration: const InputDecoration(
            labelText: 'Descrição (opcional)',
            alignLabelWithHint: true,
          ),
          maxLines: 3,
        ),
        _LocationEditor(
          postalCode: _postalCode,
          street: _street,
          number: _number,
          complement: _complement,
          district: _district,
          city: _city,
          state: _state,
          location: _location,
          busy: _locating,
          onLookup: () => _resolveLocation(current: false),
          onCurrent: () => _resolveLocation(current: true),
          onSave: null,
          message: _locationMessage,
          messageIsError: _locationMessageIsError,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _saving ? null : _createStore,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.rocket_launch_outlined),
          label: const Text('Criar meu brechó'),
        ),
      ],
    ),
  );

  Widget _buildStoreHeader(SellerStore store) => Row(
    children: [
      _StoreLogoAvatar(name: store.name, logoUrl: store.logoUrl, radius: 34),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              store.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Text('Brechó ativo • plano gratuito'),
          ],
        ),
      ),
    ],
  );

  Widget _buildSellerHub(SellerStore store) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _buildStoreHeader(store),
      const SizedBox(height: 24),
      Text(
        'O que você quer fazer hoje? 🚀',
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 14),
      Card(
        child: ListTile(
          leading: const Icon(Icons.storefront_outlined),
          title: const Text('Meu brechó 🏪'),
          subtitle: const Text('Logo, endereço e configurações da loja'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => setState(() {
            _section = _SellerSection.store;
            _success = null;
            _locationLoaded = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadStoreLocation(store, showError: true);
            });
          }),
        ),
      ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.local_shipping_outlined),
          title: const Text('Entregas e retirada 🚚'),
          subtitle: const Text('Preços, alcance e prazo de preparação'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => setState(() {
            _section = _SellerSection.shipping;
            _success = null;
          }),
        ),
      ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.checkroom_outlined),
          title: const Text('Produtos 👗'),
          subtitle: const Text('Cadastre e gerencie suas peças'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => setState(() {
            _section = _SellerSection.products;
            _success = null;
          }),
        ),
      ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.receipt_long_outlined),
          title: const Text('Pedidos recebidos 🛍️'),
          subtitle: const Text('Acompanhe pagamentos e preparação'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => setState(() {
            _section = _SellerSection.orders;
            _success = null;
          }),
        ),
      ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.mark_email_unread_outlined),
          title: Text(
            _pendingRequestCount == 0
                ? 'Solicitações 📦'
                : 'Solicitações 📦  ($_pendingRequestCount)',
          ),
          subtitle: Text(
            _pendingRequestCount == 0
                ? 'Confirme as peças pedidas pelos compradores'
                : 'Aguardando resposta • prazo de 5 minutos 🔔',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => setState(() {
            _section = _SellerSection.requests;
            _success = null;
          }),
        ),
      ),
    ],
  );

  Widget _buildStoreSettings(SellerStore store) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          IconButton(
            onPressed: () => setState(() {
              _section = _SellerSection.hub;
              _success = null;
            }),
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Voltar',
          ),
          const SizedBox(width: 8),
          Text(
            'Meu brechó',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
      const SizedBox(height: 18),
      _buildStoreHeader(store),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: _saving ? null : _replaceLogo,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: Text(store.logoUrl == null ? 'Adicionar logo' : 'Trocar logo'),
      ),
      _LocationEditor(
        postalCode: _postalCode,
        street: _street,
        number: _number,
        complement: _complement,
        district: _district,
        city: _city,
        state: _state,
        location: _location,
        busy: _locating,
        onLookup: () => _resolveLocation(current: false),
        onCurrent: () => _resolveLocation(current: true),
        onSave: _saveLocation,
        message: _locationMessage,
        messageIsError: _locationMessageIsError,
      ),
    ],
  );
  Widget _buildProducts(SellerStore store) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          IconButton(
            onPressed: () => setState(() {
              _section = _SellerSection.hub;
              _success = null;
            }),
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Voltar',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Minhas peças 👗',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      const Text(
        'Encontre rapidamente qualquer item, inclusive os já vendidos.',
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _productSearch,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          labelText: 'Buscar nas minhas peças',
          hintText: 'Ex.: vestido azul',
          prefixIcon: Icon(Icons.search),
        ),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: _productStatus,
        decoration: const InputDecoration(
          labelText: 'Situação',
          prefixIcon: Icon(Icons.filter_alt_outlined),
        ),
        items: const [
          DropdownMenuItem(value: 'ALL', child: Text('Todas as peças')),
          DropdownMenuItem(value: 'ACTIVE', child: Text('Em estoque')),
          DropdownMenuItem(value: 'SOLD', child: Text('Vendidas')),
          DropdownMenuItem(value: 'DRAFT', child: Text('Rascunhos')),
          DropdownMenuItem(value: 'INACTIVE', child: Text('Pausadas')),
          DropdownMenuItem(value: 'ARCHIVED', child: Text('Arquivadas')),
        ],
        onChanged: (value) => setState(() => _productStatus = value ?? 'ALL'),
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: () => setState(() {
          _section = _SellerSection.newProduct;
          _error = null;
          _success = null;
        }),
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Cadastrar novo produto'),
      ),
      const SizedBox(height: 18),
      _SellerProductList(
        products: _products,
        query: _productSearch.text,
        status: _productStatus,
        onStatusChanged: _changeProductStatus,
        onEdit: _editProduct,
      ),
    ],
  );
  Widget _buildSeller(BuildContext context) {
    final store = _store!;
    if (store.status != 'ACTIVE') {
      return Column(
        children: [
          const SizedBox(height: 42),
          const Icon(Icons.storefront_outlined, size: 72),
          const SizedBox(height: 16),
          Text(store.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Ative o brechó para começar a publicar.'),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : () => _activateStore(store),
            child: const Text('Ativar brechó'),
          ),
        ],
      );
    }
    if (_section == _SellerSection.hub) return _buildSellerHub(store);
    if (_section == _SellerSection.store) return _buildStoreSettings(store);
    if (_section == _SellerSection.shipping) {
      return SellerShippingPage(
        session: widget.session,
        store: store,
        onBack: () => setState(() => _section = _SellerSection.hub),
      );
    }
    if (_section == _SellerSection.products) return _buildProducts(store);
    if (_section == _SellerSection.orders) {
      return OrdersPage(
        session: widget.session,
        store: store,
        onBack: () => setState(() => _section = _SellerSection.hub),
      );
    }
    if (_section == _SellerSection.requests) {
      return SellerRequestsPage(
        session: widget.session,
        store: store,
        catalog: widget.catalog,
        onBack: () => setState(() => _section = _SellerSection.hub),
      );
    }

    return FutureBuilder<CatalogSnapshot>(
      future: widget.catalog,
      builder: (context, snapshot) {
        final categories =
            snapshot.data?.categories ?? const <CatalogCategory>[];
        return Form(
          key: _productForm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() {
                      _section = _SellerSection.products;
                      _success = null;
                    }),
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Voltar aos produtos',
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Nova peça ✨',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                'Cadastrar novo produto',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Título'),
                textCapitalization: TextCapitalization.sentences,
                onChanged: (value) => _slug.text = _slugify(value),
                validator: (value) => (value?.trim().length ?? 0) < 3
                    ? 'Conte qual é a peça.'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _slug,
                decoration: const InputDecoration(
                  labelText: 'Endereço do anúncio',
                  helperText: 'Gerado automaticamente a partir do título.',
                ),
                readOnly: true,
                validator: (value) => (value?.trim().length ?? 0) < 3
                    ? 'O endereço é obrigatório.'
                    : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _categoryPublicId,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: categories
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.publicId,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: categories.isEmpty
                    ? null
                    : (value) => setState(() => _categoryPublicId = value),
                validator: (value) =>
                    value == null ? 'Escolha uma categoria.' : null,
              ),
              if (categories.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Cadastre as categorias oficiais no Oracle.'),
                ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _condition,
                decoration: const InputDecoration(labelText: 'Estado da peça'),
                items: const [
                  DropdownMenuItem(value: 'NEW', child: Text('Nova')),
                  DropdownMenuItem(value: 'LIKE_NEW', child: Text('Como nova')),
                  DropdownMenuItem(value: 'GOOD', child: Text('Bom estado')),
                  DropdownMenuItem(value: 'FAIR', child: Text('Usada')),
                ],
                onChanged: (value) => setState(() => _condition = value!),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      decoration: const InputDecoration(
                        labelText: 'Preço',
                        prefixText: 'R\$ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        final price = double.tryParse(
                          (value ?? '').replaceAll(',', '.'),
                        );
                        return price == null || price <= 0
                            ? 'Preço inválido.'
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _quantity,
                      decoration: const InputDecoration(
                        labelText: 'Quantidade',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final quantity = int.tryParse(value ?? '');
                        return quantity == null || quantity < 1
                            ? 'Quantidade inválida.'
                            : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Peso e dimensões',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text('Necessários para calcular embalagem e entrega.'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _weight,
                decoration: const InputDecoration(
                  labelText: 'Peso',
                  suffixText: 'kg',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _positiveMeasurementValidator,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _width,
                      decoration: const InputDecoration(
                        labelText: 'Largura',
                        suffixText: 'cm',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _positiveMeasurementValidator,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _height,
                      decoration: const InputDecoration(
                        labelText: 'Altura',
                        suffixText: 'cm',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _positiveMeasurementValidator,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _length,
                      decoration: const InputDecoration(
                        labelText: 'Comprimento / tamanho',
                        suffixText: 'cm',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _positiveMeasurementValidator,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 14),
              _ProductImagePicker(
                images: _productImages,
                onAdd: _saving ? null : _chooseProductImages,
                onRemove: _saving
                    ? null
                    : (index) => setState(() => _productImages.removeAt(index)),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving || categories.isEmpty ? null : _publish,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.publish_outlined),
                label: const Text('Publicar peça'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LocationEditor extends StatelessWidget {
  const _LocationEditor({
    required this.postalCode,
    required this.street,
    required this.number,
    required this.complement,
    required this.district,
    required this.city,
    required this.state,
    required this.location,
    required this.busy,
    required this.onLookup,
    required this.onCurrent,
    required this.onSave,
    required this.message,
    required this.messageIsError,
  });

  final TextEditingController postalCode;
  final TextEditingController street;
  final TextEditingController number;
  final TextEditingController complement;
  final TextEditingController district;
  final TextEditingController city;
  final TextEditingController state;
  final StoreLocationDraft? location;
  final bool busy;
  final VoidCallback onLookup;
  final VoidCallback onCurrent;
  final VoidCallback? onSave;
  final String? message;
  final bool messageIsError;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: 18),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Localização do brechó',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Rua e número ficam privados. Clientes verão somente bairro, cidade e distância aproximada.',
          ),
          const SizedBox(height: 14),
          TextField(
            controller: postalCode,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ],
            decoration: InputDecoration(
              labelText: 'CEP',
              hintText: '00000000',
              suffixIcon: IconButton(
                onPressed: busy ? null : onLookup,
                tooltip: 'Buscar CEP',
                icon: const Icon(Icons.search),
              ),
            ),
            onSubmitted: (_) {
              if (!busy) onLookup();
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: street,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Rua'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: number,
                  decoration: const InputDecoration(labelText: 'Número'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: complement,
                  decoration: const InputDecoration(
                    labelText: 'Complemento (opcional)',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: district,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Bairro'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: city,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Cidade'),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 82,
                child: TextField(
                  controller: state,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                    LengthLimitingTextInputFormatter(2),
                  ],
                  decoration: const InputDecoration(labelText: 'UF'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: busy ? null : onCurrent,
            icon: const Icon(Icons.my_location),
            label: const Text('Usar minha localização atual'),
          ),
          if (onSave != null)
            FilledButton.icon(
              onPressed: busy ? null : onSave,
              icon: busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Salvar endereço'),
            ),
          if (message != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: messageIsError
                    ? Theme.of(context).colorScheme.errorContainer
                    : Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    messageIsError ? Icons.error_outline : Icons.info_outline,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(message!)),
                ],
              ),
            ),
          ] else if (location != null) ...[
            const SizedBox(height: 10),
            Text(
              location!.publicLabel,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    ),
  );
}

class _SellerProductList extends StatelessWidget {
  const _SellerProductList({
    required this.products,
    required this.query,
    required this.status,
    required this.onStatusChanged,
    required this.onEdit,
  });

  final Future<List<SellerProduct>>? products;
  final String query;
  final String status;
  final Future<void> Function(SellerProduct product, String status)
  onStatusChanged;
  final Future<void> Function(SellerProduct product) onEdit;

  @override
  Widget build(BuildContext context) {
    final future = products;
    if (future == null) return const SizedBox.shrink();
    return FutureBuilder<List<SellerProduct>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snapshot.hasError) {
          return const Card(
            child: ListTile(
              leading: Icon(Icons.cloud_off_outlined),
              title: Text('Não foi possível carregar seus produtos.'),
            ),
          );
        }
        final allItems = snapshot.data ?? const <SellerProduct>[];
        final normalizedQuery = query.trim().toLowerCase();
        final items = allItems
            .where((product) {
              final matchesStatus = status == 'ALL' || product.status == status;
              final matchesQuery =
                  normalizedQuery.isEmpty ||
                  product.title.toLowerCase().contains(normalizedQuery);
              return matchesStatus && matchesQuery;
            })
            .toList(growable: false);
        if (items.isEmpty) {
          return const Card(
            child: ListTile(
              leading: Icon(Icons.inventory_2_outlined),
              title: Text('Nenhuma peça encontrada 🔎'),
              subtitle: Text('Tente outro nome ou mude o filtro.'),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${items.length} peça${items.length == 1 ? '' : 's'} encontrada${items.length == 1 ? '' : 's'}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ...items.map((product) {
              final price = product.price
                  ?.toStringAsFixed(2)
                  .replaceAll('.', ',');
              return Card(
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox.square(
                      dimension: 58,
                      child: product.primaryImageUrl == null
                          ? ColoredBox(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              child: const Icon(Icons.checkroom_outlined),
                            )
                          : CachedNetworkImage(
                              imageUrl: product.primaryImageUrl!,
                              fit: BoxFit.contain,
                              memCacheWidth: 240,
                              placeholder: (_, _) => const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              errorWidget: (_, _, _) =>
                                  const Icon(Icons.broken_image_outlined),
                            ),
                    ),
                  ),
                  title: Text(product.title),
                  subtitle: Text(
                    [
                      _statusLabel(product.status),
                      if (price != null) 'R\$ $price',
                      '${product.imageCount} foto${product.imageCount == 1 ? '' : 's'}',
                    ].join(' • '),
                  ),
                  trailing: PopupMenuButton<String>(
                    tooltip: 'Ações da peça',
                    onSelected: (value) => value == 'EDIT'
                        ? onEdit(product)
                        : onStatusChanged(product, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'EDIT',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Editar informações'),
                        ),
                      ),
                      if (product.status == 'ACTIVE')
                        const PopupMenuItem(
                          value: 'SOLD',
                          child: ListTile(
                            leading: Icon(Icons.sell_outlined),
                            title: Text('Marcar como vendida'),
                          ),
                        )
                      else if (product.status == 'SOLD')
                        const PopupMenuItem(
                          value: 'ACTIVE',
                          child: ListTile(
                            leading: Icon(Icons.inventory_2_outlined),
                            title: Text('Colocar à venda novamente'),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  static String _statusLabel(String value) => switch (value) {
    'ACTIVE' => 'Publicado',
    'DRAFT' => 'Rascunho',
    'INACTIVE' => 'Pausado',
    'SOLD' => 'Vendido',
    'ARCHIVED' => 'Arquivado',
    _ => value,
  };
}

class _ProductEditSheet extends StatefulWidget {
  const _ProductEditSheet({required this.product, required this.catalog});
  final SellerProduct product;
  final Future<CatalogSnapshot> catalog;

  @override
  State<_ProductEditSheet> createState() => _ProductEditSheetState();
}

class _ProductEditSheetState extends State<_ProductEditSheet> {
  late final _title = TextEditingController(text: widget.product.title);
  late final _description = TextEditingController(
    text: widget.product.description,
  );
  late final _price = TextEditingController(
    text: widget.product.price?.toStringAsFixed(2),
  );
  late final _quantity = TextEditingController(
    text: widget.product.quantity.toString(),
  );
  late final _weight = TextEditingController(
    text: widget.product.weight?.toString(),
  );
  late final _width = TextEditingController(
    text: widget.product.width?.toString(),
  );
  late final _height = TextEditingController(
    text: widget.product.height?.toString(),
  );
  late final _length = TextEditingController(
    text: widget.product.length?.toString(),
  );
  late String _condition = widget.product.condition;
  late String? _category = widget.product.categoryPublicId;
  final _replacementImages = <_SelectedProductImage>[];
  final _editImagePicker = ImagePicker();

  @override
  void dispose() {
    for (final controller in [
      _title,
      _description,
      _price,
      _quantity,
      _weight,
      _width,
      _height,
      _length,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  double? _number(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.'));

  void _save() {
    final title = _title.text.trim();
    final price = _number(_price);
    final quantity = int.tryParse(_quantity.text.trim());
    if (title.length < 3 ||
        price == null ||
        price < 0 ||
        quantity == null ||
        quantity < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confira título, preço e quantidade.')),
      );
      return;
    }
    Navigator.pop(context, <String, dynamic>{
      'title': title,
      'description': _description.text.trim(),
      'price': price,
      'quantity': quantity,
      'condition': _condition,
      if (_category != null) 'categoryPublicId': _category,
      'weight': _number(_weight),
      'width': _number(_width),
      'height': _number(_height),
      'length': _number(_length),
      '_replacementImages': _replacementImages,
    });
  }

  Future<void> _chooseReplacementImages() async {
    final remaining = 8 - _replacementImages.length;
    if (remaining <= 0) return;
    final images = await _editImagePicker.pickMultiImage(
      maxWidth: 900,
      maxHeight: 1200,
      imageQuality: 65,
      limit: remaining,
    );
    if (images.isEmpty || !mounted) return;
    final selected = <_SelectedProductImage>[];
    for (final image in images) {
      final bytes = await image.readAsBytes();
      if (bytes.length > 1536 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cada foto deve ter no máximo 1,5 MB.'),
            ),
          );
        }
        return;
      }
      final name = image.name.toLowerCase();
      selected.add(
        _SelectedProductImage(
          bytes: bytes,
          mimeType: name.endsWith('.png')
              ? 'image/png'
              : name.endsWith('.webp')
              ? 'image/webp'
              : 'image/jpeg',
          name: image.name,
        ),
      );
    }
    if (mounted) setState(() => _replacementImages.addAll(selected));
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      4,
      20,
      20 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .78,
      child: ListView(
        children: [
          Text(
            'Editar peça ✏️',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          _ProductImagePicker(
            images: _replacementImages,
            onAdd: _chooseReplacementImages,
            onRemove: (index) =>
                setState(() => _replacementImages.removeAt(index)),
            title: 'Novas fotos do produto',
            description:
                '${widget.product.imageCount} foto(s) já publicada(s). '
                'As novas fotos aparecem abaixo; a primeira será a capa.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Título'),
          ),
          const SizedBox(height: 12),
          FutureBuilder<CatalogSnapshot>(
            future: widget.catalog,
            builder: (context, snapshot) => DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: (snapshot.data?.categories ?? const <CatalogCategory>[])
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.publicId,
                      child: Text(item.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _category = value),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Descrição'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Preço',
                    prefixText: 'R\$ ',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _quantity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantidade'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _condition,
            decoration: const InputDecoration(labelText: 'Estado da peça'),
            items: const [
              DropdownMenuItem(value: 'NEW', child: Text('Novo')),
              DropdownMenuItem(value: 'LIKE_NEW', child: Text('Como novo')),
              DropdownMenuItem(value: 'GOOD', child: Text('Bom estado')),
              DropdownMenuItem(value: 'FAIR', child: Text('Usado')),
            ],
            onChanged: (value) => setState(() => _condition = value ?? 'GOOD'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Peso',
              suffixText: 'kg',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _width,
                  decoration: const InputDecoration(
                    labelText: 'Largura',
                    suffixText: 'cm',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _height,
                  decoration: const InputDecoration(
                    labelText: 'Altura',
                    suffixText: 'cm',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _length,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Comprimento / tamanho',
              hintText: 'Ex.: 80 cm ou referência M na descrição',
              suffixText: 'cm',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Salvar alterações'),
          ),
        ],
      ),
    ),
  );
}

class _SelectedProductImage {
  const _SelectedProductImage({
    required this.bytes,
    required this.mimeType,
    required this.name,
  });

  final Uint8List bytes;
  final String mimeType;
  final String name;
}

class _ProductImagePicker extends StatelessWidget {
  const _ProductImagePicker({
    required this.images,
    required this.onAdd,
    required this.onRemove,
    this.title = 'Fotos do produto',
    this.description =
        'Obrigatório. Adicione até 8 fotos; a primeira será a capa.',
  });

  final List<_SelectedProductImage> images;
  final VoidCallback? onAdd;
  final ValueChanged<int>? onRemove;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_library_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text('${images.length}/8'),
            ],
          ),
          const SizedBox(height: 6),
          Text(description),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 112,
              child: ReorderableListView.builder(
                scrollDirection: Axis.horizontal,
                buildDefaultDragHandles: false,
                itemCount: images.length,
                onReorderItem: (oldIndex, newIndex) {
                  final image = images.removeAt(oldIndex);
                  images.insert(newIndex, image);
                },
                itemBuilder: (context, index) => Padding(
                  key: ObjectKey(images[index]),
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      ReorderableDragStartListener(
                        index: index,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            images[index].bytes,
                            width: 104,
                            height: 104,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (index == 0)
                        const Positioned(
                          left: 5,
                          bottom: 5,
                          child: Chip(
                            label: Text('Capa'),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: IconButton.filled(
                          visualDensity: VisualDensity.compact,
                          onPressed: onRemove == null
                              ? null
                              : () => onRemove!(index),
                          icon: const Icon(Icons.close, size: 18),
                          tooltip: 'Remover foto',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: images.length >= 8 ? null : onAdd,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(images.isEmpty ? 'Adicionar fotos' : 'Adicionar mais'),
          ),
        ],
      ),
    ),
  );
}

class _StoreLogoAvatar extends StatelessWidget {
  const _StoreLogoAvatar({
    required this.name,
    required this.radius,
    this.bytes,
    this.logoUrl,
  });

  final String name;
  final double radius;
  final Uint8List? bytes;
  final String? logoUrl;

  String get _initials {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty);
    final value = words.take(2).map((word) => word[0].toUpperCase()).join();
    return value.isEmpty ? 'BE' : value;
  }

  @override
  Widget build(BuildContext context) {
    final ImageProvider<Object>? image = bytes != null
        ? MemoryImage(bytes!)
        : logoUrl?.isNotEmpty == true
        ? NetworkImage(logoUrl!)
        : null;
    return CircleAvatar(
      radius: radius,
      foregroundImage: image,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: image == null
          ? Text(
              _initials,
              style: TextStyle(
                fontSize: radius * .62,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            )
          : null,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const BrechoMark(size: 36),
      const SizedBox(width: 10),
      Text(
        'Vender',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ],
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.error = false, this.onClose});
  final String text;
  final bool error;
  final VoidCallback? onClose;
  @override
  Widget build(BuildContext context) => Card(
    color: error
        ? Theme.of(context).colorScheme.errorContainer
        : Theme.of(context).colorScheme.primaryContainer,
    child: ListTile(
      leading: Icon(error ? Icons.error_outline : Icons.check_circle_outline),
      title: Text(text),
      trailing: onClose == null
          ? null
          : IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close),
              tooltip: 'Fechar mensagem',
            ),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 56),
            const SizedBox(height: 14),
            const Text('Não foi possível carregar seu brechó.'),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../auth/brecho_session.dart';
import '../branding/brecho_mark.dart';
import '../catalog/catalog_service.dart';
import 'seller_service.dart';

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
  final _storeForm = GlobalKey<FormState>();
  final _productForm = GlobalKey<FormState>();
  final _storeName = TextEditingController();
  final _storeSlug = TextEditingController();
  final _storeDescription = TextEditingController();
  final _title = TextEditingController();
  final _slug = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _quantity = TextEditingController(text: '1');

  late Future<List<SellerStore>> _stores;
  SellerStore? _store;
  String? _categoryPublicId;
  String _condition = 'GOOD';
  Uint8List? _selectedLogo;
  String? _selectedLogoMime;
  bool _saving = false;
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
    for (final controller in [
      _storeName,
      _storeSlug,
      _storeDescription,
      _title,
      _slug,
      _description,
      _price,
      _quantity,
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

  void _syncSlug(TextEditingController source, TextEditingController target) {
    if (target.text.isEmpty) target.text = _slugify(source.text);
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

  Future<void> _createStore() async {
    if (!_storeForm.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      var store = await _service.createStore(
        session: widget.session,
        name: _storeName.text.trim(),
        slug: _storeSlug.text.trim(),
        description: _storeDescription.text,
      );
      if (store.status == 'DRAFT') {
        store = await _service.activateStore(widget.session, store.publicId);
      }
      store = await _uploadSelectedLogo(store);
      if (!mounted) return;
      setState(() {
        _store = store;
        _success = 'Seu brechó gratuito está pronto!';
      });
    } on SellerException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível criar o brechó agora.');
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

  Future<void> _publish() async {
    if (!_productForm.currentState!.validate() || _store == null) return;
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
      );
      if (!mounted) return;
      _productForm.currentState!.reset();
      _title.clear();
      _slug.clear();
      _description.clear();
      _price.clear();
      _quantity.text = '1';
      setState(() {
        _categoryPublicId = null;
        _condition = 'GOOD';
        _success = '${product.title} foi publicada no catálogo!';
      });
      widget.onPublished();
    } on SellerException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível publicar a peça agora.');
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
        _store ??= snapshot.data?.firstOrNull;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
          children: [
            const _Header(),
            const SizedBox(height: 24),
            if (_error != null) _Message(text: _error!, error: true),
            if (_success != null) _Message(text: _success!),
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
        const Text('Você só precisa escolher um nome. Não há mensalidade.'),
        const SizedBox(height: 22),
        _StoreLogoEditor(
          name: _storeName.text,
          bytes: _selectedLogo,
          onTap: _saving ? null : _chooseLogo,
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
            _syncSlug(_storeName, _storeSlug);
            setState(() {});
          },
          validator: (value) => (value?.trim().length ?? 0) < 3
              ? 'Digite pelo menos 3 caracteres.'
              : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _storeSlug,
          decoration: const InputDecoration(
            labelText: 'Endereço do brechó',
            prefixText: 'brechoexpress/ ',
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9-]')),
          ],
          validator: (value) => (value?.trim().length ?? 0) < 3
              ? 'Escolha um endereço válido.'
              : null,
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
                  _StoreLogoAvatar(
                    name: store.name,
                    logoUrl: store.logoUrl,
                    radius: 34,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Text('Brechó ativo • plano gratuito'),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : _replaceLogo,
                    tooltip: 'Trocar logo',
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Nova peça',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Título'),
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => _syncSlug(_title, _slug),
                validator: (value) => (value?.trim().length ?? 0) < 3
                    ? 'Conte qual é a peça.'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _slug,
                decoration: const InputDecoration(
                  labelText: 'Endereço do anúncio',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9-]')),
                ],
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
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 14),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.photo_camera_outlined),
                  title: Text('Fotos chegam na próxima etapa'),
                  subtitle: Text(
                    'O upload será seguro e otimizado, sem usar links improvisados.',
                  ),
                ),
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

class _StoreLogoEditor extends StatelessWidget {
  const _StoreLogoEditor({
    required this.name,
    required this.bytes,
    required this.onTap,
  });

  final String name;
  final Uint8List? bytes;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _StoreLogoAvatar(name: name, bytes: bytes, radius: 52),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: Text(bytes == null ? 'Adicionar logo' : 'Trocar logo'),
      ),
      const SizedBox(height: 4),
      Text(
        'Opcional • imagem quadrada de até 1 MB',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
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
  const _Message({required this.text, this.error = false});
  final String text;
  final bool error;
  @override
  Widget build(BuildContext context) => Card(
    color: error
        ? Theme.of(context).colorScheme.errorContainer
        : Theme.of(context).colorScheme.primaryContainer,
    child: Padding(padding: const EdgeInsets.all(14), child: Text(text)),
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

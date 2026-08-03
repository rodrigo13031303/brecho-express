import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../auth/brecho_session.dart';
import 'platform_banner_service.dart';

class PlatformBannerAdminPage extends StatefulWidget {
  const PlatformBannerAdminPage({
    required this.session,
    required this.service,
    super.key,
  });

  final BrechoSession session;
  final PlatformBannerService service;

  @override
  State<PlatformBannerAdminPage> createState() =>
      _PlatformBannerAdminPageState();
}

class _PlatformBannerAdminPageState extends State<PlatformBannerAdminPage> {
  late Future<List<PlatformBanner>> _banners;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _banners = widget.service.listAdmin(widget.session);

  Future<void> _edit([PlatformBanner? banner]) async {
    final result = await showModalBottomSheet<_BannerFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _BannerForm(banner: banner),
    );
    if (result == null || !mounted) return;
    try {
      var saved = await widget.service.save(
        session: widget.session,
        draft: result.draft,
        current: banner,
      );
      if (result.image != null && result.mimeType != null) {
        saved = await widget.service.uploadImage(
          session: widget.session,
          bannerPublicId: saved.publicId,
          bytes: result.image!,
          mimeType: result.mimeType!,
        );
      }
      if (saved.status != result.draft.status) {
        saved = await widget.service.save(
          session: widget.session,
          draft: result.draft,
          current: saved,
        );
      }
      if (!mounted) return;
      setState(_reload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Banner salvo com sucesso! ✨')),
      );
    } on PlatformBannerException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Banners da Home')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _edit,
      icon: const Icon(Icons.add_photo_alternate_outlined),
      label: const Text('Novo banner'),
    ),
    body: FutureBuilder<List<PlatformBanner>>(
      future: _banners,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: TextButton.icon(
              onPressed: () => setState(_reload),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          );
        }
        final banners = snapshot.data ?? const <PlatformBanner>[];
        if (banners.isEmpty) {
          return const Center(child: Text('Nenhum banner cadastrado.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: banners.length,
          itemBuilder: (context, index) {
            final banner = banners[index];
            return Card(
              child: ListTile(
                leading: banner.imageUrl == null
                    ? const CircleAvatar(child: Icon(Icons.image_outlined))
                    : CircleAvatar(
                        backgroundImage: NetworkImage(banner.imageUrl!),
                      ),
                title: Text(banner.title),
                subtitle: Text(
                  '${banner.status} • ordem ${banner.displayOrder}\n'
                  '${_date(banner.startAt)} até ${_date(banner.endAt)}',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => _edit(banner),
              ),
            );
          },
        );
      },
    ),
  );

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _BannerForm extends StatefulWidget {
  const _BannerForm({this.banner});
  final PlatformBanner? banner;
  @override
  State<_BannerForm> createState() => _BannerFormState();
}

class _BannerFormState extends State<_BannerForm> {
  static const _appScreens = <String, String>{
    'inicio': 'Início',
    'comprar': 'Comprar',
    'vender': 'Vender',
    'carrinho': 'Carrinho',
    'perfil': 'Perfil',
  };

  final _form = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final _title = TextEditingController(text: widget.banner?.title);
  late final _alt = TextEditingController(text: widget.banner?.altText);
  late final _target = TextEditingController(
    text: widget.banner?.targetPublicId ?? widget.banner?.targetValue,
  );
  late final _order = TextEditingController(
    text: '${widget.banner?.displayOrder ?? 0}',
  );
  late String _targetType = widget.banner?.targetType ?? 'APP_SCREEN';
  late String _status = widget.banner?.status ?? 'DRAFT';
  late DateTime _start = widget.banner?.startAt.toLocal() ?? DateTime.now();
  late DateTime _end =
      widget.banner?.endAt.toLocal() ??
      DateTime.now().add(const Duration(days: 7));
  Uint8List? _image;
  String? _mimeType;

  @override
  void initState() {
    super.initState();
    if (_targetType == 'APP_SCREEN' &&
        !_appScreens.containsKey(_target.text.toLowerCase())) {
      _target.text = 'comprar';
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _alt.dispose();
    _target.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _chooseImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 600,
      imageQuality: 75,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.length > 1048576) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A imagem deve ter até 1 MB.')),
        );
      }
      return;
    }
    final name = file.name.toLowerCase();
    setState(() {
      _image = bytes;
      _mimeType = name.endsWith('.png')
          ? 'image/png'
          : name.endsWith('.webp')
          ? 'image/webp'
          : 'image/jpeg';
    });
  }

  Future<void> _date(bool start) async {
    final current = start ? _start : _end;
    final value = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (value != null) {
      setState(() {
        if (start) {
          _start = value;
        } else {
          _end = value.add(const Duration(hours: 23, minutes: 59));
        }
      });
    }
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final resource = const {
      'PRODUCT',
      'STORE',
      'CATEGORY',
      'STORE_EVENT',
    }.contains(_targetType);
    Navigator.pop(
      context,
      _BannerFormResult(
        draft: PlatformBannerDraft(
          title: _title.text.trim(),
          altText: _alt.text.trim(),
          targetType: _targetType,
          targetPublicId: resource ? _target.text.trim() : null,
          targetValue: resource ? null : _target.text.trim(),
          startAt: _start,
          endAt: _end,
          displayOrder: int.parse(_order.text),
          status: _status,
        ),
        image: _image,
        mimeType: _mimeType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      0,
      20,
      20 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .82,
      child: Form(
        key: _form,
        child: ListView(
          children: [
            Text(
              widget.banner == null ? 'Novo banner 🎨' : 'Editar banner ✏️',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _chooseImage,
              icon: const Icon(Icons.image_outlined),
              label: Text(
                _image == null ? 'Escolher imagem 2:1' : 'Imagem selecionada',
              ),
            ),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Título interno'),
              validator: _required,
            ),
            TextFormField(
              controller: _alt,
              decoration: const InputDecoration(
                labelText: 'Descrição acessível da imagem',
              ),
              validator: _required,
            ),
            DropdownButtonFormField<String>(
              initialValue: _targetType,
              decoration: const InputDecoration(labelText: 'Destino do clique'),
              items: const [
                DropdownMenuItem(value: 'PRODUCT', child: Text('Produto')),
                DropdownMenuItem(value: 'STORE', child: Text('Brechó')),
                DropdownMenuItem(value: 'CATEGORY', child: Text('Categoria')),
                DropdownMenuItem(
                  value: 'STORE_EVENT',
                  child: Text('Evento do brechó'),
                ),
                DropdownMenuItem(
                  value: 'APP_SCREEN',
                  child: Text('Tela do aplicativo'),
                ),
                DropdownMenuItem(
                  value: 'EXTERNAL_URL',
                  child: Text('Link externo HTTPS'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _targetType = value ?? 'APP_SCREEN';
                  if (_targetType == 'APP_SCREEN' &&
                      !_appScreens.containsKey(_target.text.toLowerCase())) {
                    _target.text = 'comprar';
                  }
                });
              },
            ),
            if (_targetType == 'APP_SCREEN')
              DropdownButtonFormField<String>(
                initialValue: _target.text.toLowerCase(),
                decoration: const InputDecoration(
                  labelText: 'Tela do aplicativo',
                ),
                items: _appScreens.entries
                    .map(
                      (screen) => DropdownMenuItem(
                        value: screen.key,
                        child: Text(screen.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) => _target.text = value ?? 'comprar',
              )
            else
              TextFormField(
                controller: _target,
                decoration: InputDecoration(
                  labelText: _targetType == 'EXTERNAL_URL'
                      ? 'URL HTTPS'
                      : 'Public ID do destino',
                ),
                validator: _required,
              ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _order,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Ordem'),
                    validator: (value) =>
                        int.tryParse(value ?? '') == null ? 'Inválida' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'DRAFT', child: Text('Rascunho')),
                      DropdownMenuItem(value: 'ACTIVE', child: Text('Ativo')),
                      DropdownMenuItem(
                        value: 'INACTIVE',
                        child: Text('Inativo'),
                      ),
                      DropdownMenuItem(
                        value: 'ARCHIVED',
                        child: Text('Arquivado'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _status = value ?? 'DRAFT'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _date(true),
                    child: Text('Início: ${_short(_start)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _date(false),
                    child: Text('Fim: ${_short(_end)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Salvar banner'),
            ),
          ],
        ),
      ),
    ),
  );

  static String? _required(String? value) =>
      (value?.trim().isEmpty ?? true) ? 'Campo obrigatório.' : null;
  static String _short(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _BannerFormResult {
  const _BannerFormResult({required this.draft, this.image, this.mimeType});
  final PlatformBannerDraft draft;
  final Uint8List? image;
  final String? mimeType;
}

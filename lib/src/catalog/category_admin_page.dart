import 'package:flutter/material.dart';

import '../auth/brecho_session.dart';
import 'category_admin_service.dart';

class CategoryAdminPage extends StatefulWidget {
  const CategoryAdminPage({super.key, required this.session});
  final BrechoSession session;
  @override
  State<CategoryAdminPage> createState() => _CategoryAdminPageState();
}

class _CategoryAdminPageState extends State<CategoryAdminPage> {
  final _service = CategoryAdminService();
  late Future<List<AdminCategory>> _future = _service.list(widget.session);
  @override
  void dispose() {
    _service.close();
    super.dispose();
  }

  void _reload() => setState(() => _future = _service.list(widget.session));
  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _edit(
    List<AdminCategory> categories, [
    AdminCategory? category,
  ]) async {
    final draft = await Navigator.of(context).push<CategoryDraft>(
      MaterialPageRoute(
        builder: (_) =>
            _CategoryForm(categories: categories, category: category),
      ),
    );
    if (draft == null || !mounted) return;
    try {
      await _service.save(widget.session, draft, current: category);
      _reload();
      _message('Categoria salva ✅');
    } on CategoryAdminException catch (e) {
      _message(e.message);
    }
  }

  Future<void> _toggle(AdminCategory category) async {
    try {
      await _service.changeStatus(
        widget.session,
        category,
        category.status != 'ACTIVE',
      );
      _reload();
    } on CategoryAdminException catch (e) {
      _message(e.message);
    }
  }

  Future<void> _delete(AdminCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir categoria?'),
        content: Text(
          '“${category.name}” será excluída definitivamente. Isso só funciona se nunca foi usada e não possui subcategorias.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _service.delete(widget.session, category);
      _reload();
      _message('Categoria excluída.');
    } on CategoryAdminException catch (e) {
      _message(e.message);
    }
  }

  List<({AdminCategory category, int depth})> _tree(List<AdminCategory> all) {
    final result = <({AdminCategory category, int depth})>[];
    void add(String? parent, int depth, Set<String> path) {
      final children = all.where((c) => c.parentPublicId == parent).toList()
        ..sort((a, b) {
          final order = a.sortOrder.compareTo(b.sortOrder);
          return order != 0 ? order : a.name.compareTo(b.name);
        });
      for (final child in children) {
        if (path.contains(child.publicId)) continue;
        result.add((category: child, depth: depth));
        add(child.publicId, depth + 1, {...path, child.publicId});
      }
    }

    add(null, 0, {});
    for (final orphan in all.where(
      (c) => !result.any((r) => r.category.publicId == c.publicId),
    )) {
      result.add((category: orphan, depth: 0));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Categorias 🗂️')),
    floatingActionButton: FutureBuilder<List<AdminCategory>>(
      future: _future,
      builder: (_, snapshot) => FloatingActionButton.extended(
        onPressed: snapshot.hasData ? () => _edit(snapshot.data!) : null,
        icon: const Icon(Icons.add),
        label: const Text('Nova categoria'),
      ),
    ),
    body: FutureBuilder<List<AdminCategory>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$snapshot.error', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _reload,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        final categories = snapshot.data ?? [];
        if (categories.isEmpty)
          return const Center(child: Text('Nenhuma categoria cadastrada.'));
        final rows = _tree(categories);
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final row = rows[index];
              final c = row.category;
              return ListTile(
                contentPadding: EdgeInsets.only(
                  left: 12.0 + row.depth * 22,
                  right: 4,
                ),
                leading: Icon(
                  c.acceptsProducts
                      ? Icons.sell_outlined
                      : Icons.folder_outlined,
                ),
                title: Text(
                  c.name,
                  style: TextStyle(
                    decoration: c.status == 'ACTIVE'
                        ? null
                        : TextDecoration.lineThrough,
                  ),
                ),
                subtitle: Text(
                  '${c.status == 'ACTIVE' ? 'Ativa' : 'Inativa'} • ${c.productCount} produto(s) • ${c.childCount} subcategoria(s)',
                ),
                onTap: () => _edit(categories, c),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit')
                      _edit(categories, c);
                    else if (value == 'status')
                      _toggle(c);
                    else
                      _delete(c);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(
                      value: 'status',
                      enabled: c.status != 'ACTIVE' || c.canInactivate,
                      child: Text(c.status == 'ACTIVE' ? 'Inativar' : 'Ativar'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      enabled: c.canDelete,
                      child: const Text('Excluir'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    ),
  );
}

class _CategoryForm extends StatefulWidget {
  const _CategoryForm({required this.categories, this.category});
  final List<AdminCategory> categories;
  final AdminCategory? category;
  @override
  State<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<_CategoryForm> {
  final _key = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.category?.name);
  late final _slug = TextEditingController(text: widget.category?.slug);
  late final _description = TextEditingController(
    text: widget.category?.description,
  );
  late final _order = TextEditingController(
    text: '${widget.category?.sortOrder ?? 0}',
  );
  late String? _parent = widget.category?.parentPublicId;
  late bool _accepts = widget.category?.acceptsProducts ?? true;
  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    _description.dispose();
    _order.dispose();
    super.dispose();
  }

  String _slugify(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[áàâãä]'), 'a')
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[íìîï]'), 'i')
      .replaceAll(RegExp(r'[óòôõö]'), 'o')
      .replaceAll(RegExp(r'[úùûü]'), 'u')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  @override
  Widget build(BuildContext context) {
    final parents = widget.categories
        .where((c) => c.publicId != widget.category?.publicId)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category == null ? 'Nova categoria ✨' : 'Editar categoria ✏️',
        ),
      ),
      body: Form(
        key: _key,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nome da categoria'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Informe o nome.' : null,
              onChanged: (v) {
                if (widget.category == null) _slug.text = _slugify(v);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _slug,
              decoration: const InputDecoration(
                labelText: 'Slug',
                helperText: 'Ex.: bermudas-jeans',
              ),
              validator: (v) =>
                  RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$').hasMatch(v ?? '')
                  ? null
                  : 'Use letras minúsculas, números e hífens.',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _parent,
              decoration: const InputDecoration(labelText: 'Categoria pai'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Nenhuma — categoria raiz'),
                ),
                ...parents.map(
                  (c) => DropdownMenuItem<String?>(
                    value: c.publicId,
                    child: Text(c.name),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _parent = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _order,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Ordem de exibição'),
              validator: (v) =>
                  int.tryParse(v ?? '') == null ? 'Informe um número.' : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aceita produtos diretamente'),
              subtitle: const Text(
                'Desative para usar somente como agrupador.',
              ),
              value: _accepts,
              onChanged: (v) => setState(() => _accepts = v),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                if (!_key.currentState!.validate()) return;
                Navigator.pop(
                  context,
                  CategoryDraft(
                    name: _name.text.trim(),
                    slug: _slug.text.trim(),
                    description: _description.text.trim().isEmpty
                        ? null
                        : _description.text.trim(),
                    parentPublicId: _parent,
                    sortOrder: int.parse(_order.text),
                    acceptsProducts: _accepts,
                  ),
                );
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Salvar categoria'),
            ),
          ],
        ),
      ),
    );
  }
}

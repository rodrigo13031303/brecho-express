import 'package:flutter/material.dart';

import '../auth/brecho_session.dart';
import '../cart/cart_service.dart';
import '../catalog/catalog_service.dart';
import '../purchase/purchase_service.dart';
import 'seller_service.dart';

class SellerRequestsPage extends StatefulWidget {
  const SellerRequestsPage({
    required this.session,
    required this.store,
    required this.catalog,
    required this.onBack,
    super.key,
  });

  final BrechoSession session;
  final SellerStore store;
  final Future<CatalogSnapshot> catalog;
  final VoidCallback onBack;

  @override
  State<SellerRequestsPage> createState() => _SellerRequestsPageState();
}

class _SellerRequestsPageState extends State<SellerRequestsPage> {
  final _service = PurchaseService();
  late Future<List<PurchaseRequest>> _requests;
  String? _busyItem;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _service.close();
    super.dispose();
  }

  void _reload() {
    _requests = _service.listStore(
      session: widget.session,
      storePublicId: widget.store.publicId,
    );
  }

  Future<void> _respond(
    PurchaseRequest request,
    PurchaseRequestItem item,
  ) async {
    final result = await showModalBottomSheet<_SellerResponse>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _ResponseSheet(item: item),
    );
    if (result == null || !mounted) return;
    setState(() => _busyItem = item.itemPublicId);
    try {
      await _service.respond(
        session: widget.session,
        storePublicId: widget.store.publicId,
        requestPublicId: request.publicId,
        itemPublicId: item.itemPublicId,
        confirmedQuantity: result.quantity,
        rejectReason: result.reason,
      );
      if (!mounted) return;
      setState(_reload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resposta enviada ao comprador! ✅'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on PurchaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyItem = null);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<PurchaseRequest>>(
    future: _requests,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(
          child: TextButton.icon(
            onPressed: () => setState(_reload),
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar carregar solicitações novamente'),
          ),
        );
      }
      final requests = snapshot.data ?? const <PurchaseRequest>[];
      return FutureBuilder<CatalogSnapshot>(
        future: widget.catalog,
        builder: (context, catalogSnapshot) {
          final products = {
            for (final product
                in catalogSnapshot.data?.products ?? const <CatalogProduct>[])
              product.publicId: product,
          };
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Voltar',
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Solicitações recebidas 📦',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Confirme somente o que você realmente consegue separar.',
              ),
              const SizedBox(height: 18),
              if (requests.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.mark_email_unread_outlined),
                    title: Text('Nenhuma solicitação por enquanto'),
                    subtitle: Text(
                      'Quando alguém quiser uma peça, ela aparecerá aqui.',
                    ),
                  ),
                )
              else
                ...requests.map(
                  (request) => _RequestCard(
                    request: request,
                    products: products,
                    busyItem: _busyItem,
                    onRespond: (item) => _respond(request, item),
                  ),
                ),
            ],
          );
        },
      );
    },
  );
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.products,
    required this.busyItem,
    required this.onRespond,
  });

  final PurchaseRequest request;
  final Map<String, CatalogProduct> products;
  final String? busyItem;
  final ValueChanged<PurchaseRequestItem> onRespond;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _requestStatus(request.status),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (request.status == 'PENDING' && request.expiresAt != null)
                Chip(
                  avatar: const Icon(Icons.timer_outlined, size: 18),
                  label: Text(_remaining(request.expiresAt!)),
                ),
            ],
          ),
          const Divider(height: 22),
          ...request.items.map((item) {
            final product = products[item.productPublicId];
            final pending = item.status == 'PENDING';
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: product?.primaryImageUrl == null
                  ? const CircleAvatar(child: Icon(Icons.checkroom_outlined))
                  : CircleAvatar(
                      foregroundImage: NetworkImage(product!.primaryImageUrl!),
                    ),
              title: Text(product?.title ?? 'Peça solicitada'),
              subtitle: Text(
                '${item.quantity} unidade${item.quantity == 1 ? '' : 's'}'
                ' • ${_itemStatus(item)}',
              ),
              trailing: busyItem == item.itemPublicId
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : pending
                  ? FilledButton(
                      onPressed: () => onRespond(item),
                      child: const Text('Responder'),
                    )
                  : const Icon(Icons.check_circle_outline),
            );
          }),
        ],
      ),
    ),
  );

  static String _requestStatus(String value) => switch (value) {
    'PENDING' => 'Aguardando sua resposta ⏳',
    'APPROVED' => 'Solicitação aprovada',
    'PARTIALLY_APPROVED' => 'Atendida parcialmente',
    'REJECTED' => 'Solicitação rejeitada',
    'EXPIRED' => 'Prazo perdido pelo brechó ⏰',
    'CANCELLED' => 'Solicitação cancelada',
    _ => value,
  };

  static String _remaining(DateTime expiresAt) {
    final value = expiresAt.toLocal().difference(DateTime.now());
    if (value.isNegative) return 'encerrando';
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  static String _itemStatus(PurchaseRequestItem item) => switch (item.status) {
    'PENDING' => 'aguardando',
    'APPROVED' => 'confirmada',
    'PARTIALLY_APPROVED' => '${item.confirmedQuantity ?? 0} confirmada(s)',
    'REJECTED' => 'indisponível',
    _ => item.status,
  };
}

class _ResponseSheet extends StatefulWidget {
  const _ResponseSheet({required this.item});
  final PurchaseRequestItem item;

  @override
  State<_ResponseSheet> createState() => _ResponseSheetState();
}

class _ResponseSheetState extends State<_ResponseSheet> {
  late int _quantity = widget.item.quantity;
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      24,
      8,
      24,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Quantas peças você confirma?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        Slider(
          value: _quantity.toDouble(),
          min: 0,
          max: widget.item.quantity.toDouble(),
          divisions: widget.item.quantity,
          label: '$_quantity',
          onChanged: (value) => setState(() => _quantity = value.round()),
        ),
        Text(
          _quantity == 0
              ? 'Nenhuma disponível'
              : '$_quantity de ${widget.item.quantity}',
          textAlign: TextAlign.center,
        ),
        if (_quantity == 0) ...[
          const SizedBox(height: 14),
          TextField(
            controller: _reason,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Motivo da indisponibilidade',
              hintText: 'Ex.: peça já foi vendida',
            ),
          ),
        ],
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _quantity == 0 && _reason.text.trim().isEmpty
              ? null
              : () => Navigator.pop(
                  context,
                  _SellerResponse(
                    quantity: _quantity,
                    reason: _quantity == 0 ? _reason.text : null,
                  ),
                ),
          icon: const Icon(Icons.send_outlined),
          label: const Text('Enviar resposta'),
        ),
      ],
    ),
  );
}

class _SellerResponse {
  const _SellerResponse({required this.quantity, this.reason});
  final int quantity;
  final String? reason;
}

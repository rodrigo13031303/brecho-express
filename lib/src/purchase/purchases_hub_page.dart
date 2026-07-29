import 'package:flutter/material.dart';

import '../auth/brecho_session.dart';
import '../branding/brecho_mark.dart';
import '../cart/cart_service.dart';
import '../catalog/catalog_service.dart';
import '../delivery/delivery_address_page.dart';
import '../order/orders_page.dart';
import 'purchase_service.dart';

class PurchasesHubPage extends StatefulWidget {
  const PurchasesHubPage({
    required this.cartPage,
    required this.session,
    required this.catalog,
    required this.refreshToken,
    super.key,
  });

  final Widget cartPage;
  final BrechoSession session;
  final Future<CatalogSnapshot> catalog;
  final int refreshToken;

  @override
  State<PurchasesHubPage> createState() => _PurchasesHubPageState();
}

class _PurchasesHubPageState extends State<PurchasesHubPage> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 0,
                icon: Icon(Icons.shopping_cart_outlined),
                label: Text('Carrinho'),
              ),
              ButtonSegment(
                value: 1,
                icon: Icon(Icons.inventory_2_outlined),
                label: Text('Solicitações'),
              ),
              ButtonSegment(
                value: 2,
                icon: Icon(Icons.receipt_long_outlined),
                label: Text('Pedidos'),
              ),
            ],
            selected: {_selected},
            onSelectionChanged: (value) =>
                setState(() => _selected = value.first),
          ),
        ),
      ),
      Expanded(
        child: IndexedStack(
          index: _selected,
          children: [
            widget.cartPage,
            _BuyerRequestsPage(
              session: widget.session,
              catalog: widget.catalog,
              refreshToken: widget.refreshToken,
            ),
            OrdersPage(session: widget.session),
          ],
        ),
      ),
    ],
  );
}

class _BuyerRequestsPage extends StatefulWidget {
  const _BuyerRequestsPage({
    required this.session,
    required this.catalog,
    required this.refreshToken,
  });

  final BrechoSession session;
  final Future<CatalogSnapshot> catalog;
  final int refreshToken;

  @override
  State<_BuyerRequestsPage> createState() => _BuyerRequestsPageState();
}

class _BuyerRequestsPageState extends State<_BuyerRequestsPage> {
  final _service = PurchaseService();
  late Future<List<PurchaseRequest>> _requests;

  @override
  void initState() {
    super.initState();
    _requests = _service.listBuyer(widget.session);
  }

  @override
  void didUpdateWidget(covariant _BuyerRequestsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _requests = _service.listBuyer(widget.session);
    }
  }

  @override
  void dispose() {
    _service.close();
    super.dispose();
  }

  void _retry() =>
      setState(() => _requests = _service.listBuyer(widget.session));

  @override
  Widget build(BuildContext context) => FutureBuilder<List<PurchaseRequest>>(
    future: _requests,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return _RequestMessage(
          icon: Icons.cloud_off_outlined,
          title: 'Não foi possível carregar suas solicitações',
          action: TextButton.icon(
            onPressed: _retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        );
      }
      final requests = snapshot.data ?? const <PurchaseRequest>[];
      if (requests.isEmpty) {
        return const _RequestMessage(
          icon: Icons.inventory_2_outlined,
          title: 'Nenhuma solicitação ainda 📦',
          message: 'As peças enviadas aos brechós aparecerão aqui.',
        );
      }
      return FutureBuilder<CatalogSnapshot>(
        future: widget.catalog,
        builder: (context, catalogSnapshot) {
          final products = {
            for (final product
                in catalogSnapshot.data?.products ?? const <CatalogProduct>[])
              product.publicId: product,
          };
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            children: [
              const Row(
                children: [
                  BrechoMark(size: 34),
                  SizedBox(width: 10),
                  Text(
                    'Minhas solicitações 📦',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ...requests.map(
                (request) => _BuyerRequestCard(
                  request: request,
                  products: products,
                  session: widget.session,
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

class _BuyerRequestCard extends StatelessWidget {
  const _BuyerRequestCard({
    required this.request,
    required this.products,
    required this.session,
  });

  final PurchaseRequest request;
  final Map<String, CatalogProduct> products;
  final BrechoSession session;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_statusIcon(request.status)),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  _statusLabel(request.status),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(_date(request.requestedAt.toLocal())),
            ],
          ),
          const Divider(height: 24),
          ...request.items.map((item) {
            final product = products[item.productPublicId];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: product?.primaryImageUrl == null
                  ? const CircleAvatar(child: Icon(Icons.checkroom_outlined))
                  : CircleAvatar(
                      foregroundImage: NetworkImage(product!.primaryImageUrl!),
                    ),
              title: Text(product?.title ?? 'Peça solicitada'),
              subtitle: Text(
                '${item.quantity} un. • ${_itemStatus(item.status)}'
                '${item.rejectReason == null ? '' : '\n${_rejectReason(item.rejectReason!)}'}',
              ),
            );
          }),
          if (request.status == 'APPROVED' ||
              request.status == 'PARTIALLY_APPROVED') ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DeliveryAddressPage(
                    session: session,
                    requestPublicId: request.publicId,
                  ),
                ),
              ),
              icon: const Icon(Icons.local_shipping_outlined),
              label: const Text('Informar endereço de entrega'),
            ),
          ],
        ],
      ),
    ),
  );

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  static String _statusLabel(String value) => switch (value) {
    'PENDING' => 'Aguardando os brechós ⏳',
    'APPROVED' => 'Tudo confirmado! 🎉',
    'PARTIALLY_APPROVED' => 'Confirmação parcial',
    'REJECTED' => 'Itens indisponíveis',
    'EXPIRED' => 'Solicitação expirada',
    'CANCELLED' => 'Solicitação cancelada',
    _ => value,
  };

  static IconData _statusIcon(String value) => switch (value) {
    'APPROVED' => Icons.check_circle_outline,
    'PARTIALLY_APPROVED' => Icons.rule_outlined,
    'REJECTED' => Icons.cancel_outlined,
    _ => Icons.hourglass_top_outlined,
  };

  static String _rejectReason(String reason) {
    if (reason == 'SELLER_TIMEOUT' ||
        reason.startsWith('Prazo de 5 minutos')) {
      return 'Prazo de 5 minutos não atendido pelo brechó';
    }
    return reason;
  }

  static String _itemStatus(String value) => switch (value) {
    'PENDING' => 'aguardando confirmação',
    'APPROVED' => 'confirmada',
    'PARTIALLY_APPROVED' => 'quantidade parcial',
    'REJECTED' => 'indisponível',
    _ => value,
  };
}

class _RequestMessage extends StatelessWidget {
  const _RequestMessage({
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 68, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(message!, textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: 10), action!],
        ],
      ),
    ),
  );
}

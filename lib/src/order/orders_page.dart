import 'package:flutter/material.dart';

import '../auth/brecho_session.dart';
import '../seller/seller_service.dart';
import 'order_pending_page.dart';
import 'order_service.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({required this.session, this.store, this.onBack, super.key});

  final BrechoSession session;
  final SellerStore? store;
  final VoidCallback? onBack;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final _service = OrderService();
  late Future<List<OrderSnapshot>> _orders;
  String? _busy;

  bool get _seller => widget.store != null;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _orders = _seller
        ? _service.listStore(
            session: widget.session,
            storePublicId: widget.store!.publicId,
          )
        : _service.listBuyer(widget.session);
  }

  @override
  void dispose() {
    _service.close();
    super.dispose();
  }

  Future<void> _open(OrderSnapshot order) async {
    if (_seller) return;
    setState(() => _busy = order.publicId);
    try {
      final detail = await _service.get(
        session: widget.session,
        orderPublicId: order.publicId,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OrderPendingPage(order: detail),
        ),
      );
      if (mounted) setState(_reload);
    } on OrderException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _cancel(OrderSnapshot order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar pedido?'),
        content: const Text('A reserva das peças será liberada imediatamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar pedido'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = order.publicId);
    try {
      await _service.cancel(
        session: widget.session,
        orderPublicId: order.publicId,
      );
      if (!mounted) return;
      setState(_reload);
      _message('Pedido cancelado e peças liberadas.');
    } on OrderException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<OrderSnapshot>>(
    future: _orders,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(
          child: FilledButton.icon(
            onPressed: () => setState(_reload),
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        );
      }
      final orders = snapshot.data ?? const <OrderSnapshot>[];
      return ListView(
        padding: EdgeInsets.fromLTRB(20, _seller ? 0 : 14, 20, 36),
        children: [
          Row(
            children: [
              if (widget.onBack != null)
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
              const Icon(Icons.receipt_long_outlined, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _seller ? 'Pedidos recebidos 🛍️' : 'Meus pedidos 🛍️',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (orders.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.shopping_bag_outlined),
                title: Text('Nenhum pedido por enquanto'),
                subtitle: Text('Os novos pedidos aparecerão aqui.'),
              ),
            )
          else
            ...orders.map(_card),
        ],
      );
    },
  );

  Widget _card(OrderSnapshot order) {
    final waiting = order.status == 'PAYMENT_PENDING';
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _busy == null ? () => _open(order) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_statusIcon(order.status)),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _statusLabel(order.status),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(_date(order.createdAt.toLocal())),
                ],
              ),
              const Divider(height: 22),
              Text(order.number),
              const SizedBox(height: 8),
              ...order.items.map(
                (item) => Text('• ${item.quantity}× ${item.title}'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total: ${_money(order.total)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (_busy == order.publicId)
                    const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              if (!_seller && waiting) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _busy == null ? () => _cancel(order) : null,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar pedido'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _statusLabel(String value) => switch (value) {
    'PAYMENT_PENDING' => 'Aguardando pagamento ⏳',
    'PAID' => 'Pagamento confirmado ✅',
    'PROCESSING' => 'Em preparação 📦',
    'SHIPPED' => 'Enviado 🚚',
    'COMPLETED' => 'Concluído 🎉',
    'CANCELLED' => 'Cancelado',
    _ => value,
  };

  static IconData _statusIcon(String value) => switch (value) {
    'PAID' => Icons.check_circle_outline,
    'PROCESSING' => Icons.inventory_2_outlined,
    'SHIPPED' => Icons.local_shipping_outlined,
    'COMPLETED' => Icons.celebration_outlined,
    'CANCELLED' => Icons.cancel_outlined,
    _ => Icons.schedule_outlined,
  };

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
  static String _money(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
}

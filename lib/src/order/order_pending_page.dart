import 'package:flutter/material.dart';

import 'order_service.dart';

class OrderPendingPage extends StatelessWidget {
  const OrderPendingPage({required this.order, super.key});

  final OrderSnapshot order;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pedido criado 🎉')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Icon(
          Icons.schedule_outlined,
          size: 72,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 14),
        const Text(
          'Aguardando pagamento',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          'Pedido ${order.number}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _line('Produtos', _money(order.subtotal)),
                const SizedBox(height: 8),
                _line('Frete', _money(order.shipping)),
                const Divider(height: 24),
                _line('Total', _money(order.total), strong: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        ...order.shipments.map(
          (shipping) => Card(
            child: ListTile(
              leading: Icon(
                shipping.method == 'PICKUP'
                    ? Icons.storefront_outlined
                    : Icons.local_shipping_outlined,
              ),
              title: Text(shipping.storeName),
              subtitle: Text(
                '${shipping.methodLabel} • '
                '${shipping.minDays}–${shipping.maxDays} dias',
              ),
              trailing: Text(
                shipping.price == 0 ? 'Grátis' : _money(shipping.price),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: null,
          icon: const Icon(Icons.pix),
          label: const Text('Pagar com Pix — próxima etapa'),
        ),
        const SizedBox(height: 10),
        const Text(
          'Nenhuma cobrança foi realizada. Na próxima etapa conectaremos '
          'o provedor de pagamento.',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  static Widget _line(String label, String value, {bool strong = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(fontWeight: strong ? FontWeight.w800 : null),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: strong ? 18 : null,
          fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
        ),
      ),
    ],
  );

  static String _money(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
}

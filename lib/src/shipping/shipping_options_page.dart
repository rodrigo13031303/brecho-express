import 'package:flutter/material.dart';

import '../auth/brecho_session.dart';
import 'shipping_service.dart';

class ShippingOptionsPage extends StatefulWidget {
  const ShippingOptionsPage({
    required this.session,
    required this.requestPublicId,
    super.key,
  });

  final BrechoSession session;
  final String requestPublicId;

  @override
  State<ShippingOptionsPage> createState() => _ShippingOptionsPageState();
}

class _ShippingOptionsPageState extends State<ShippingOptionsPage> {
  final _service = ShippingService();
  late Future<List<ShippingOption>> _options;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _options = _service.quote(
      session: widget.session,
      requestPublicId: widget.requestPublicId,
    );
  }

  @override
  void dispose() {
    _service.close();
    super.dispose();
  }

  void _reload() => setState(
    () => _options = _service.quote(
      session: widget.session,
      requestPublicId: widget.requestPublicId,
    ),
  );

  Future<void> _select(ShippingOption option) async {
    setState(() => _busy = true);
    try {
      final updated = await _service.select(
        session: widget.session,
        requestPublicId: widget.requestPublicId,
        optionPublicId: option.publicId,
      );
      if (!mounted) return;
      setState(() => _options = Future.value(updated));
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('${option.methodLabel} selecionada! 🚚')),
        );
    } on ShippingException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Escolha o frete 🚚')),
    body: FutureBuilder<List<ShippingOption>>(
      future: _options,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _Message(
            icon: Icons.local_shipping_outlined,
            title: 'Não foi possível calcular o frete',
            message: snapshot.error.toString(),
            action: FilledButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              label: const Text('Calcular novamente'),
            ),
          );
        }
        final options = snapshot.data ?? const <ShippingOption>[];
        if (options.isEmpty) {
          return const _Message(
            icon: Icons.location_off_outlined,
            title: 'Nenhuma entrega disponível',
            message:
                'Os brechós ainda não possuem uma modalidade disponível '
                'para este endereço.',
          );
        }
        final groups = <String, List<ShippingOption>>{};
        for (final option in options) {
          groups.putIfAbsent(option.storePublicId, () => []).add(option);
        }
        final selectedStores = groups.values
            .where((items) => items.any((item) => item.isSelected))
            .length;
        final total = options
            .where((option) => option.isSelected)
            .fold<double>(0, (sum, option) => sum + option.price);
        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
              children: [
                Text(
                  'Cada brechó envia um pacote 📦',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Escolha uma modalidade para cada brechó da solicitação.',
                ),
                const SizedBox(height: 20),
                ...groups.values.map(_storeCard),
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text(
                      '$selectedStores de ${groups.length} pacotes definidos',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      'Frete selecionado: ${_money(total)}\n'
                      'As cotações valem por 30 minutos.',
                    ),
                    isThreeLine: true,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: selectedStores == groups.length ? () {} : null,
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Pagamento — próxima etapa'),
                ),
              ],
            ),
            if (_busy)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x33000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    ),
  );

  Widget _storeCard(List<ShippingOption> options) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              options.first.storeName,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 6),
          ...options.map(
            (option) => RadioGroup<String>(
              groupValue: options
                  .where((item) => item.isSelected)
                  .map((item) => item.publicId)
                  .firstOrNull,
              onChanged: (value) {
                if (!_busy && value != null) _select(option);
              },
              child: RadioListTile<String>(
                value: option.publicId,
                title: Text(option.methodLabel),
                subtitle: Text(_description(option)),
                secondary: Icon(
                  option.method == 'PICKUP'
                      ? Icons.storefront_outlined
                      : Icons.delivery_dining_outlined,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  static String _description(ShippingOption option) {
    final price = option.price == 0 ? 'Grátis' : _money(option.price);
    final distance = option.distanceKm == null
        ? ''
        : ' • ${option.distanceKm!.toStringAsFixed(1)} km';
    return '$price$distance • ${option.minDays}–${option.maxDays} dias';
  }

  static String _money(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
}

class _Message extends StatelessWidget {
  const _Message({
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
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    ),
  );
}

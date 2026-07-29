import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth/brecho_session.dart';
import 'seller_service.dart';

class SellerShippingPage extends StatefulWidget {
  const SellerShippingPage({
    required this.session,
    required this.store,
    required this.onBack,
    super.key,
  });

  final BrechoSession session;
  final SellerStore store;
  final VoidCallback onBack;

  @override
  State<SellerShippingPage> createState() => _SellerShippingPageState();
}

class _SellerShippingPageState extends State<SellerShippingPage> {
  final _service = SellerService();
  final _form = GlobalKey<FormState>();
  final _basePrice = TextEditingController();
  final _pricePerKm = TextEditingController();
  final _maxDistance = TextEditingController();
  final _preparationDays = TextEditingController();
  late Future<StoreShippingConfig> _config;
  bool _pickup = true;
  bool _local = true;
  bool _filled = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _config = _service.loadShippingConfig(
      session: widget.session,
      storePublicId: widget.store.publicId,
    );
  }

  @override
  void dispose() {
    _service.close();
    _basePrice.dispose();
    _pricePerKm.dispose();
    _maxDistance.dispose();
    _preparationDays.dispose();
    super.dispose();
  }

  void _fill(StoreShippingConfig value) {
    if (_filled) return;
    _filled = true;
    _pickup = value.pickupEnabled;
    _local = value.localDeliveryEnabled;
    _basePrice.text = _decimal(value.localBasePrice);
    _pricePerKm.text = _decimal(value.localPricePerKm);
    _maxDistance.text = _decimal(value.localMaxDistanceKm);
    _preparationDays.text = '${value.preparationDays}';
  }

  Future<void> _save() async {
    if (!_pickup && !_local) {
      _message('Ative pelo menos retirada ou entrega local.');
      return;
    }
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final saved = await _service.saveShippingConfig(
        session: widget.session,
        storePublicId: widget.store.publicId,
        config: StoreShippingConfig(
          pickupEnabled: _pickup,
          localDeliveryEnabled: _local,
          localBasePrice: _number(_basePrice.text),
          localPricePerKm: _number(_pricePerKm.text),
          localMaxDistanceKm: _number(_maxDistance.text),
          preparationDays: int.parse(_preparationDays.text),
        ),
      );
      if (!mounted) return;
      setState(() {
        _filled = false;
        _fill(saved);
      });
      _message('Configuração de entrega salva! 🚚');
    } on SellerException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<StoreShippingConfig>(
    future: _config,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(
          child: FilledButton.icon(
            onPressed: () => setState(() {
              _filled = false;
              _config = _service.loadShippingConfig(
                session: widget.session,
                storePublicId: widget.store.publicId,
              );
            }),
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        );
      }
      _fill(snapshot.data!);
      return Form(
        key: _form,
        child: Column(
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
                Text(
                  'Entregas e retirada 🚚',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Defina como seus clientes podem receber as peças. '
              'Uma alteração recalcula as cotações ainda não pagas.',
            ),
            const SizedBox(height: 18),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    value: _pickup,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _pickup = value),
                    secondary: const Icon(Icons.storefront_outlined),
                    title: const Text('Retirada no brechó'),
                    subtitle: const Text(
                      'Grátis para o comprador. O endereço completo só será '
                      'mostrado após o fechamento.',
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _local,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _local = value),
                    secondary: const Icon(Icons.delivery_dining_outlined),
                    title: const Text('Entrega local'),
                    subtitle: const Text(
                      'Preço calculado pela distância até o comprador.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AnimatedOpacity(
              opacity: _local ? 1 : 0.45,
              duration: const Duration(milliseconds: 180),
              child: IgnorePointer(
                ignoring: !_local,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Preço da entrega local',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _moneyField(
                                controller: _basePrice,
                                label: 'Taxa inicial',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _moneyField(
                                controller: _pricePerKm,
                                label: 'Preço por km',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _numberField(
                          controller: _maxDistance,
                          label: 'Distância máxima (km)',
                          maximum: 500,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _integerField(
                  controller: _preparationDays,
                  label: 'Dias para preparar o pedido',
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Salvando...' : 'Salvar configuração'),
            ),
          ],
        ),
      );
    },
  );

  Widget _moneyField({
    required TextEditingController controller,
    required String label,
  }) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
    decoration: InputDecoration(labelText: label, prefixText: 'R\$ '),
    validator: (value) {
      final number = _tryNumber(value);
      return number == null || number < 0 ? 'Valor inválido' : null;
    },
  );

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required double maximum,
  }) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
    decoration: InputDecoration(labelText: label),
    validator: (value) {
      final number = _tryNumber(value);
      return number == null || number <= 0 || number > maximum
          ? 'Informe de 0,1 até ${maximum.toInt()}'
          : null;
    },
  );

  Widget _integerField({
    required TextEditingController controller,
    required String label,
  }) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(labelText: label, suffixText: 'dias'),
    validator: (value) {
      final number = int.tryParse(value ?? '');
      return number == null || number < 0 || number > 90
          ? 'Informe de 0 até 90 dias'
          : null;
    },
  );

  static double _number(String value) =>
      double.parse(value.replaceAll(',', '.'));
  static double? _tryNumber(String? value) =>
      double.tryParse((value ?? '').replaceAll(',', '.'));
  static String _decimal(double value) =>
      value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);
}

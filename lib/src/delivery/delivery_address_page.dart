import 'package:flutter/material.dart';

import '../auth/brecho_session.dart';
import '../location/store_location_service.dart';
import '../shipping/shipping_options_page.dart';
import 'delivery_service.dart';

class DeliveryAddressPage extends StatefulWidget {
  const DeliveryAddressPage({
    required this.session,
    required this.requestPublicId,
    super.key,
  });

  final BrechoSession session;
  final String requestPublicId;

  @override
  State<DeliveryAddressPage> createState() => _DeliveryAddressPageState();
}

class _DeliveryAddressPageState extends State<DeliveryAddressPage> {
  final _service = DeliveryService();
  final _location = StoreLocationService();
  late Future<_DeliveryData> _data;
  bool _showForm = false;
  bool _busy = false;

  final _label = TextEditingController(text: 'Minha casa');
  final _zip = TextEditingController();
  final _street = TextEditingController();
  final _number = TextEditingController();
  final _complement = TextEditingController();
  final _district = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_DeliveryData> _load() async {
    final results = await Future.wait([
      _service.listAddresses(widget.session),
      _service.getDelivery(
        session: widget.session,
        requestPublicId: widget.requestPublicId,
      ),
    ]);
    return _DeliveryData(
      addresses: results[0] as List<SavedAddress>,
      delivery: results[1] as PurchaseDelivery?,
    );
  }

  @override
  void dispose() {
    _service.close();
    _location.close();
    for (final controller in [
      _label,
      _zip,
      _street,
      _number,
      _complement,
      _district,
      _city,
      _state,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _reload() => setState(() => _data = _load());

  Future<void> _lookupZip() async {
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final address = await _location.lookupPostalCode(_zip.text);
      if (!mounted) return;
      _zip.text = address.postalCode;
      _street.text = address.street;
      _district.text = address.district;
      _city.text = address.city;
      _state.text = address.state;
      _number.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CEP encontrado! Complete o número 📍')),
      );
    } on StoreLocationException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveAddress() async {
    final locationDraft = StoreLocationDraft(
      postalCode: _zip.text,
      street: _street.text,
      number: _number.text,
      complement: _complement.text,
      district: _district.text,
      city: _city.text,
      state: _state.text,
    );
    try {
      locationDraft.validate();
    } on StoreLocationException catch (error) {
      _message(error.message);
      return;
    }
    setState(() => _busy = true);
    try {
      final located = await _location.ensureCoordinates(locationDraft);
      final saved = await _service.createAddress(
        session: widget.session,
        draft: AddressDraft(
          label: _label.text,
          zipCode: located.postalCode,
          street: located.street,
          number: located.number,
          complement: located.complement,
          district: located.district,
          city: located.city,
          state: located.state,
          latitude: located.latitude,
          longitude: located.longitude,
          isDefault: true,
        ),
      );
      await _select(saved);
    } on StoreLocationException catch (error) {
      _message(error.message);
    } on DeliveryException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _select(SavedAddress address) async {
    setState(() => _busy = true);
    try {
      await _service.selectAddress(
        session: widget.session,
        requestPublicId: widget.requestPublicId,
        addressPublicId: address.publicId,
      );
      if (!mounted) return;
      setState(() {
        _showForm = false;
        _data = _load();
      });
      _message('Endereço de entrega confirmado! 🚚');
    } on DeliveryException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Endereço de entrega 📍')),
    body: FutureBuilder<_DeliveryData>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: FilledButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          );
        }
        final data = snapshot.data!;
        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
              children: [
                if (data.delivery != null) _confirmed(data.delivery!),
                Text(
                  data.delivery == null
                      ? 'Onde você quer receber?'
                      : 'Trocar o endereço',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text('Escolha um endereço salvo ou cadastre um novo.'),
                const SizedBox(height: 18),
                ...data.addresses.map(
                  (address) => Card(
                    child: ListTile(
                      leading: Icon(
                        address.isDefault
                            ? Icons.home
                            : Icons.location_on_outlined,
                      ),
                      title: Text(address.title),
                      subtitle: Text('${address.line1}\n${address.line2}'),
                      isThreeLine: true,
                      trailing:
                          data.delivery?.addressPublicId == address.publicId
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.chevron_right),
                      onTap: _busy ? null : () => _select(address),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _showForm = !_showForm),
                  icon: Icon(_showForm ? Icons.close : Icons.add_location_alt),
                  label: Text(
                    _showForm ? 'Cancelar novo endereço' : 'Novo endereço',
                  ),
                ),
                if (_showForm) ...[const SizedBox(height: 18), _addressForm()],
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

  Widget _confirmed(PurchaseDelivery delivery) => Card(
    color: Theme.of(context).colorScheme.primaryContainer,
    margin: const EdgeInsets.only(bottom: 22),
    child: Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: const Icon(Icons.local_shipping_outlined),
            title: const Text(
              'Entrega confirmada ✅',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text('${delivery.line1}\n${delivery.line2}'),
            isThreeLine: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ShippingOptionsPage(
                    session: widget.session,
                    requestPublicId: widget.requestPublicId,
                  ),
                ),
              ),
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Calcular e escolher o frete'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _addressForm() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        controller: _label,
        decoration: const InputDecoration(
          labelText: 'Apelido',
          prefixIcon: Icon(Icons.label_outline),
        ),
      ),
      const SizedBox(height: 12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _zip,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'CEP',
                prefixIcon: Icon(Icons.pin_drop_outlined),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(onPressed: _lookupZip, child: const Text('Buscar')),
        ],
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _street,
        decoration: const InputDecoration(labelText: 'Rua'),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _number,
              decoration: const InputDecoration(labelText: 'Número'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _complement,
              decoration: const InputDecoration(
                labelText: 'Complemento (opcional)',
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _district,
        decoration: const InputDecoration(labelText: 'Bairro'),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'Cidade'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _state,
              maxLength: 2,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'UF',
                counterText: '',
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: _saveAddress,
        icon: const Icon(Icons.check),
        label: const Text('Salvar e usar este endereço'),
      ),
    ],
  );
}

class _DeliveryData {
  const _DeliveryData({required this.addresses, required this.delivery});
  final List<SavedAddress> addresses;
  final PurchaseDelivery? delivery;
}

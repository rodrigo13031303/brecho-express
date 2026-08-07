import 'dart:async';

import 'package:flutter/material.dart';

import '../auth/brecho_session.dart';
import '../delivery/delivery_service.dart';
import 'buyer_location_store.dart';
import 'store_location_service.dart';

class BuyerLocationPage extends StatefulWidget {
  const BuyerLocationPage({
    required this.session,
    required this.locationService,
    required this.currentLocation,
    required this.currentLabel,
    super.key,
  });

  final BrechoSession session;
  final StoreLocationService locationService;
  final GeoPoint? currentLocation;
  final String? currentLabel;

  @override
  State<BuyerLocationPage> createState() => _BuyerLocationPageState();
}

class _BuyerLocationPageState extends State<BuyerLocationPage> {
  final _search = TextEditingController();
  final _deliveryService = DeliveryService();
  Timer? _debounce;
  late Future<List<SavedAddress>> _addresses;
  List<AddressSearchSuggestion> _suggestions = const [];
  bool _searching = false;
  bool _locating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _addresses = _deliveryService.listAddresses(widget.session);
    _search.addListener(_scheduleSearch);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search
      ..removeListener(_scheduleSearch)
      ..dispose();
    _deliveryService.close();
    super.dispose();
  }

  void _scheduleSearch() {
    _debounce?.cancel();
    final query = _search.text.trim();
    if (query.length < 3) {
      setState(() {
        _suggestions = const [];
        _searching = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
    });
    _debounce = Timer(
      const Duration(milliseconds: 550),
      () => _runSearch(query),
    );
  }

  Future<void> _runSearch(String query) async {
    try {
      final result = await widget.locationService.searchAddresses(
        query,
        origin: widget.currentLocation,
      );
      if (!mounted || query != _search.text.trim()) return;
      setState(() {
        _suggestions = result;
        _searching = false;
        _error = result.isEmpty
            ? 'Nenhum endereço encontrado. Tente incluir cidade e UF.'
            : null;
      });
    } on StoreLocationException catch (error) {
      if (!mounted || query != _search.text.trim()) return;
      setState(() {
        _suggestions = const [];
        _searching = false;
        _error = error.message;
      });
    }
  }

  Future<void> _useCurrent() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final draft = await widget.locationService.useCurrentLocation();
      if (!mounted) return;
      Navigator.pop(
        context,
        BuyerCatalogLocation(
          point: GeoPoint(draft.latitude!, draft.longitude!),
          label: _labelForDraft(draft),
          isDeviceLocation: true,
        ),
      );
    } on StoreLocationException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _useSaved(SavedAddress address) async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final point = address.latitude != null && address.longitude != null
          ? GeoPoint(address.latitude!, address.longitude!)
          : await widget.locationService.coordinatesForBuyerReference(
              StoreLocationDraft(
                postalCode: address.zipCode,
                street: address.street,
                number: address.number,
                complement: address.complement ?? '',
                district: address.district,
                city: address.city,
                state: address.state,
              ),
            );
      if (!mounted) return;
      Navigator.pop(
        context,
        BuyerCatalogLocation(point: point, label: address.line1),
      );
    } on StoreLocationException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  static String _labelForDraft(StoreLocationDraft draft) {
    final street = draft.street.trim();
    final number = draft.number.trim();
    if (street.isNotEmpty) return number.isEmpty ? street : '$street, $number';
    return draft.publicLabel;
  }

  void _useSuggestion(AddressSearchSuggestion suggestion) => Navigator.pop(
    context,
    BuyerCatalogLocation(
      point: suggestion.location.point,
      label: suggestion.location.label,
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Endereço de referência')),
    body: Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
          children: [
            TextField(
              controller: _search,
              autofocus: false,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Busque rua, bairro, cidade ou CEP',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _search.clear,
                        icon: const Icon(Icons.cancel),
                      ),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_searching) const LinearProgressIndicator(minHeight: 2),
            if (_search.text.trim().length >= 3) ...[
              const SizedBox(height: 18),
              ..._suggestions.map(_suggestionTile),
            ] else ...[
              const SizedBox(height: 28),
              Text(
                'Localização atual',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.my_location, size: 32),
                title: const Text('Usar minha localização'),
                subtitle: Text(
                  widget.currentLabel ?? 'Toque para localizar o aparelho',
                ),
                trailing: const Icon(Icons.refresh),
                onTap: _locating ? null : _useCurrent,
              ),
              const SizedBox(height: 24),
              Text(
                'Endereços recentes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<SavedAddress>>(
                future: _addresses,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Text(
                      'Não foi possível carregar seus endereços salvos.',
                    );
                  }
                  final addresses = snapshot.data ?? const [];
                  if (addresses.isEmpty) {
                    return const Text(
                      'Você ainda não possui endereços salvos.',
                    );
                  }
                  return Column(children: addresses.map(_savedTile).toList());
                },
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
        if (_locating)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x22000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    ),
  );

  Widget _savedTile(SavedAddress address) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      leading: Icon(
        address.isDefault ? Icons.home : Icons.location_on_outlined,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              address.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (address.isDefault) ...[
            const SizedBox(width: 8),
            const Chip(
              label: Text('Principal'),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
      subtitle: Text('${address.line1}\n${address.line2}'),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
      onTap: _locating ? null : () => _useSaved(address),
    ),
  );

  Widget _suggestionTile(AddressSearchSuggestion suggestion) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.location_on_outlined),
    title: Text(
      suggestion.primaryLabel,
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: suggestion.secondaryLabel.isEmpty
        ? null
        : Text(suggestion.secondaryLabel),
    trailing: suggestion.distanceKm == null
        ? null
        : Text('${suggestion.distanceKm!.round()} km'),
    onTap: () => _useSuggestion(suggestion),
  );
}

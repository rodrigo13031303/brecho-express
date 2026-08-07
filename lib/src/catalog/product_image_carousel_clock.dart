import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class ProductImageCarouselClock extends ValueNotifier<int> {
  ProductImageCarouselClock() : super(0) {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => value++);
  }

  late final Timer _timer;

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

class ProductImageCarouselScope
    extends InheritedNotifier<ProductImageCarouselClock> {
  const ProductImageCarouselScope({
    required ProductImageCarouselClock clock,
    required super.child,
    super.key,
  }) : super(notifier: clock);

  static ProductImageCarouselClock of(BuildContext context) {
    final scope = context
        .getInheritedWidgetOfExactType<ProductImageCarouselScope>();
    assert(scope != null, 'ProductImageCarouselScope não encontrado.');
    return scope!.notifier!;
  }
}

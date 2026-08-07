import 'package:flutter/material.dart';

class SlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const SlidePageTransitionsBuilder();

  static const _curve = Curves.easeOutCubic;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    final incoming = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).chain(CurveTween(curve: _curve));
    final outgoing = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.18, 0),
    ).chain(CurveTween(curve: _curve));

    return SlideTransition(
      position: secondaryAnimation.drive(outgoing),
      child: SlideTransition(position: animation.drive(incoming), child: child),
    );
  }
}

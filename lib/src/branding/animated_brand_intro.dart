import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'brecho_mark.dart';

class AnimatedBrandIntro extends StatefulWidget {
  const AnimatedBrandIntro({required this.onFinished, super.key});

  final VoidCallback onFinished;

  @override
  State<AnimatedBrandIntro> createState() => _AnimatedBrandIntroState();
}

class _AnimatedBrandIntroState extends State<AnimatedBrandIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1050),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) widget.onFinished();
        });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final progress = Curves.easeOutCubic.transform(_controller.value);
            final settle = 1 - progress;
            final horizontal = -width * 0.82 * settle;
            final vertical = math.sin(progress * math.pi * 5) * 10 * settle;
            final rotation = math.sin(progress * math.pi * 4) * 0.09 * settle;
            final opacity = (_controller.value / 0.18).clamp(0.0, 1.0);
            return Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(horizontal, vertical),
                child: Transform.rotate(angle: rotation, child: child),
              ),
            );
          },
          child: const BrechoMark(size: 230),
        ),
      ),
    );
  }
}

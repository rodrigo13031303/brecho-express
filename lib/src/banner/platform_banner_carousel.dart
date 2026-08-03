import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'platform_banner_service.dart';

class PlatformBannerCarousel extends StatefulWidget {
  const PlatformBannerCarousel({
    required this.banners,
    required this.onOpen,
    super.key,
  });

  final Future<List<PlatformBanner>> banners;
  final ValueChanged<PlatformBanner> onOpen;

  @override
  State<PlatformBannerCarousel> createState() => _PlatformBannerCarouselState();
}

class _PlatformBannerCarouselState extends State<PlatformBannerCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;
  int _count = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _schedule(int count) {
    if (_count == count && _timer != null) return;
    _timer?.cancel();
    _count = count;
    if (count < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_controller.hasClients) return;
      final next = (_page + 1) % count;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<PlatformBanner>>(
    future: widget.banners,
    builder: (context, snapshot) {
      final banners = snapshot.data ?? const <PlatformBanner>[];
      if (banners.isEmpty) return const SizedBox.shrink();
      _schedule(banners.length);
      return Column(
        children: [
          AspectRatio(
            aspectRatio: 2,
            child: PageView.builder(
              controller: _controller,
              itemCount: banners.length,
              onPageChanged: (value) => setState(() => _page = value),
              itemBuilder: (context, index) {
                final banner = banners[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Semantics(
                    button: true,
                    label: banner.altText,
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      margin: EdgeInsets.zero,
                      child: InkWell(
                        onTap: () => widget.onOpen(banner),
                        child: CachedNetworkImage(
                          imageUrl: banner.imageUrl!,
                          fit: BoxFit.cover,
                          memCacheWidth: 1200,
                          placeholder: (_, _) => ColoredBox(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, _, _) => ColoredBox(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            child: const Icon(
                              Icons.campaign_outlined,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (banners.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                banners.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: index == _page ? 18 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: index == _page
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    },
  );
}

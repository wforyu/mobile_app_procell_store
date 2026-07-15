import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../helpers/theme.dart';

class AnimatedCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> banners;
  final void Function(Map<String, dynamic>)? onTap;

  const AnimatedCarousel({super.key, required this.banners, this.onTap});

  @override
  State<AnimatedCarousel> createState() => _AnimatedCarouselState();
}

class _AnimatedCarouselState extends State<AnimatedCarousel> {
  final _pageC = PageController();
  int _current = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.banners.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (_pageC.hasClients) {
          final next = (_current + 1) % widget.banners.length;
          _pageC.animateToPage(next,
              duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageC,
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) {
              final b = widget.banners[i];
              final image = b['image'] as String?;
              final link = b['link'] as String?;
              final title = b['title'] as String?;
              if (image == null) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GestureDetector(
                  onTap: link != null ? () => widget.onTap?.call(b) : null,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: image,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(color: Colors.grey[200]),
                          errorWidget: (_, _, _) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                        ),
                        if (title != null)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Colors.black54, Colors.transparent],
                                ),
                              ),
                              child: Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          if (widget.banners.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.banners.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _current == i ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _current == i ? AppColors.primary : Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

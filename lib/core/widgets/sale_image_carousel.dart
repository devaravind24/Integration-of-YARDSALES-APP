import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Feature 3 — Sale image display.
///
/// Renders a main image, a swipeable carousel + dot indicator when multiple
/// images exist, and graceful handling of loading / invalid / missing URLs.
/// Uses `cached_network_image` so repeat views don't re-download.
class SaleImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  final BorderRadius borderRadius;

  const SaleImageCarousel({
    super.key,
    required this.imageUrls,
    this.height = 220,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  State<SaleImageCarousel> createState() => _SaleImageCarouselState();
}

class _SaleImageCarouselState extends State<SaleImageCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Missing images: render nothing (caller controls spacing).
    if (widget.imageUrls.isEmpty) return const SizedBox.shrink();

    if (widget.imageUrls.length == 1) {
      return ClipRRect(
        borderRadius: widget.borderRadius,
        child: _Tile(url: widget.imageUrls.first, height: widget.height),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: widget.borderRadius,
          child: SizedBox(
            height: widget.height,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.imageUrls.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) =>
                  _Tile(url: widget.imageUrls[i], height: widget.height),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.imageUrls.length, (i) {
            final active = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFE8843A)
                    : const Color(0xFFCED4DA),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final String url;
  final double height;
  const _Tile({required this.url, required this.height});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      placeholder: (context, _) => Container(
        width: double.infinity,
        height: height,
        color: Colors.grey.shade100,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          color: Color(0xFFE8843A),
          strokeWidth: 2.5,
        ),
      ),
      // Invalid / broken URL fallback.
      errorWidget: (context, _, __) => Container(
        width: double.infinity,
        height: height,
        color: Colors.grey.shade100,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined,
                size: 36, color: Colors.grey.shade400),
            const SizedBox(height: 6),
            Text('Image unavailable',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

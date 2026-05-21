import 'package:flutter/material.dart';

/// Reusable logo widget for the YardSale app.
///
/// Renders the official `assets/logo.png` file at the requested [size]
/// and (optionally) the colored "YARDSALE" wordmark beneath it.
///
/// Use everywhere the brand logo is needed — splash, welcome, sidebar,
/// listing header, etc. — so the entire app stays consistent.
class YardSaleLogo extends StatelessWidget {
  /// Height (and roughly width) of the rendered image in logical pixels.
  final double size;

  /// Whether to show the "YARDSALE" wordmark beneath the image.
  final bool showWordmark;

  /// Font size used for the wordmark when [showWordmark] is true.
  final double wordmarkSize;

  /// Vertical gap between image and wordmark.
  final double gap;

  const YardSaleLogo({
    super.key,
    this.size = 80,
    this.showWordmark = true,
    this.wordmarkSize = 22,
    this.gap = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/logo.png',
          height: size,
          width: size,
          fit: BoxFit.contain,
          // Graceful fallback if the asset is missing — falls back to the
          // three icon-based logo so the app never crashes during marking.
          errorBuilder: (_, __, ___) => _FallbackIconLogo(size: size),
        ),
        if (showWordmark) ...[
          SizedBox(height: gap),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'YARD',
                  style: TextStyle(
                    color: const Color(0xFF2B5BA8),
                    fontWeight: FontWeight.bold,
                    fontSize: wordmarkSize,
                    letterSpacing: 2,
                  ),
                ),
                TextSpan(
                  text: 'SALE',
                  style: TextStyle(
                    color: const Color(0xFFE8843A),
                    fontWeight: FontWeight.bold,
                    fontSize: wordmarkSize,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Fallback used only if `assets/logo.png` fails to load.
class _FallbackIconLogo extends StatelessWidget {
  final double size;
  const _FallbackIconLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.7;
    return SizedBox(
      height: size,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home, color: const Color(0xFF2B5BA8), size: iconSize),
          Icon(Icons.location_on,
              color: const Color(0xFF4CAF50), size: iconSize),
          Icon(Icons.shopping_bag,
              color: const Color(0xFFE8843A), size: iconSize * 0.9),
        ],
      ),
    );
  }
}

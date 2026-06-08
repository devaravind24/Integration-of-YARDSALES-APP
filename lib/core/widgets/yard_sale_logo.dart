import 'package:flutter/material.dart';

class YardSaleLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final double wordmarkSize;
  final double gap;

  const YardSaleLogo({
    super.key,
    this.size = 80,
    // The logo image (assets/logo.png) already contains the "YARDSALE"
    // wordmark, so the separate text below is off by default to avoid
    // printing "YARDSALE" twice. The fallback icon logo has no text, so
    // callers can still opt in with showWordmark: true if needed.
    this.showWordmark = false,
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

// Fallback used only if `assets/logo.png` fails to load.
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

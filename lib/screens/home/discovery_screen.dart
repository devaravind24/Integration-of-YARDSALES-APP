import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/widgets/custom_drawer.dart';
import '../../core/widgets/filter_modal.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final AuthService _auth = AuthService();

  /// Dynamic display name for the greeting — resolved from FirebaseAuth +
  /// Firestore, falls back to the email prefix or "there".
  String _displayName = 'there';

  late final AnimationController _pulseCtrl;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _loadDisplayName();

    // Re-resolve whenever the signed-in user changes (login / logout / signup).
    _authSub = FirebaseAuth.instance.authStateChanges().listen((_) {
      if (mounted) _loadDisplayName();
    });
  }

  Future<void> _loadDisplayName() async {
    final name = await _auth.resolveDisplayName();
    if (!mounted) return;
    setState(() => _displayName = name.split(' ').first); // first name only
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pulseCtrl.dispose();
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFDFECFF),
      drawer: const CustomDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header bar ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF2B5BA8),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                    const Expanded(
                      child: Text(
                        'Discovery',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.account_circle_outlined,
                          color: Colors.white),
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.profile),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ── Greeting (dynamic name) ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Hi, ',
                                style: TextStyle(
                                  color: Color(0xFF1A1A2E),
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: _displayName,
                                style: const TextStyle(
                                  color: Color(0xFF1A1A2E),
                                  fontSize: 26,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'Yard Sale Treasure Map',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const Text(
                          'San Jose, CA',
                          style:
                              TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // ── Search bar ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search Yard sales',
                          hintStyle:
                              TextStyle(color: Color(0xFF2B5BA8), fontSize: 14),
                          prefixIcon: Icon(Icons.search,
                              color: Color(0xFF2B5BA8), size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _IconCircle(
                    icon: Icons.tune,
                    onTap: () => FilterModal.show(context),
                  ),
                  const SizedBox(width: 8),
                  _IconCircle(
                    icon: Icons.bookmark_border,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.schedule),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // ── Map (improved, realistic) ───────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _ImprovedMapView(pulseCtrl: _pulseCtrl),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Improved map view — building blocks, parks, water, multi-width streets,
//  drop-shadowed pins, animated user-location pulse, live sales counter.
// ─────────────────────────────────────────────────────────────────────────────
class _ImprovedMapView extends StatelessWidget {
  final AnimationController pulseCtrl;
  const _ImprovedMapView({required this.pulseCtrl});

  // Sale pin positions (fractions of map width/height).
  static const _pinPositions = [
    Offset(0.18, 0.22),
    Offset(0.55, 0.16),
    Offset(0.72, 0.42),
    Offset(0.83, 0.62),
    Offset(0.15, 0.66),
    Offset(0.42, 0.80),
    Offset(0.68, 0.84),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Base canvas (water, land, parks, building blocks, streets) ──
        Positioned.fill(
          child: CustomPaint(painter: _RealisticMapPainter()),
        ),

        // ── Sales pins with drop shadow ─────────────────────────────
        ..._pinPositions.map((pos) {
          return Positioned.fill(
            child: FractionalTranslation(
              translation: Offset(pos.dx - 0.5, pos.dy - 0.5),
              child: const Center(child: _DollarPin()),
            ),
          );
        }),

        // ── Animated user location pulse, centered ──────────────────
        Center(
          child: AnimatedBuilder(
            animation: pulseCtrl,
            builder: (_, __) {
              final scale = 1.0 + 0.6 * pulseCtrl.value;
              final opacity = 1.0 - pulseCtrl.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 60 * scale,
                    height: 60 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          const Color(0xFF2B5BA8).withOpacity(0.25 * opacity),
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2B5BA8),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // ── Live sales-count chip (top-right) ───────────────────────
        Positioned(
          top: 12,
          right: 12,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('sales').snapshots(),
            builder: (_, snap) {
              final count =
                  snap.data?.docs.length ?? _pinPositions.length; // fallback
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_offer,
                        size: 14, color: Color(0xFFE8843A)),
                    const SizedBox(width: 6),
                    Text(
                      '$count nearby sales',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Sales pin — orange circle with $, soft drop shadow, pointed tail.
// ─────────────────────────────────────────────────────────────────────────────
class _DollarPin extends StatelessWidget {
  const _DollarPin();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 56,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF5A55D), Color(0xFFE8843A)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Text(
              '\$',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            child: CustomPaint(
              size: const Size(14, 14),
              painter: _PinTailPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFE8843A);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
//  The realistic map painter — water, land, parks, building blocks, streets.
//  All deterministic (no rng) so the map looks identical on every rebuild.
// ─────────────────────────────────────────────────────────────────────────────
class _RealisticMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // ── Base land color (gentle warm-gray, like Google Maps base) ──
    final base = Paint()..color = const Color(0xFFE9EEF5);
    canvas.drawRect(Offset.zero & size, base);

    // ── Water (river running diagonally) ──
    final water = Paint()..color = const Color(0xFFB6D8F2);
    final riverPath = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.30,
        size.height * 0.60,
        size.width * 0.55,
        size.height * 0.78,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.92,
        size.width,
        size.height * 0.86,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(riverPath, water);

    // ── Park (green patch) ──
    final park = Paint()..color = const Color(0xFFCEEAC9);
    final parkRect = Rect.fromLTWH(
      size.width * 0.05,
      size.height * 0.05,
      size.width * 0.22,
      size.height * 0.14,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(parkRect, const Radius.circular(8)),
      park,
    );

    // ── Building blocks (city blocks scattered between roads) ──
    final block = Paint()..color = const Color(0xFFD9DEE6);
    final blocks = <Rect>[
      Rect.fromLTWH(size.width * 0.40, size.height * 0.05,
          size.width * 0.16, size.height * 0.08),
      Rect.fromLTWH(size.width * 0.60, size.height * 0.05,
          size.width * 0.20, size.height * 0.06),
      Rect.fromLTWH(size.width * 0.85, size.height * 0.08,
          size.width * 0.12, size.height * 0.10),
      Rect.fromLTWH(size.width * 0.05, size.height * 0.26,
          size.width * 0.18, size.height * 0.10),
      Rect.fromLTWH(size.width * 0.30, size.height * 0.26,
          size.width * 0.18, size.height * 0.12),
      Rect.fromLTWH(size.width * 0.55, size.height * 0.28,
          size.width * 0.12, size.height * 0.08),
      Rect.fromLTWH(size.width * 0.74, size.height * 0.30,
          size.width * 0.22, size.height * 0.10),
      Rect.fromLTWH(size.width * 0.06, size.height * 0.46,
          size.width * 0.16, size.height * 0.10),
      Rect.fromLTWH(size.width * 0.30, size.height * 0.48,
          size.width * 0.14, size.height * 0.08),
      Rect.fromLTWH(size.width * 0.52, size.height * 0.46,
          size.width * 0.18, size.height * 0.12),
      Rect.fromLTWH(size.width * 0.78, size.height * 0.48,
          size.width * 0.18, size.height * 0.08),
    ];
    for (final rect in blocks) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        block,
      );
    }

    // ── Streets ───────────────────────────────────────────────────
    final major = Paint()
      ..color = const Color(0xFFF7DDA0)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke;

    final majorEdge = Paint()
      ..color = const Color(0xFFE8C77B)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke;

    final minor = Paint()
      ..color = Colors.white
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;

    final minorEdge = Paint()
      ..color = const Color(0xFFD6DCE5)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;

    void hLine(double yFrac, Paint p) => canvas.drawLine(
        Offset(0, size.height * yFrac),
        Offset(size.width, size.height * yFrac),
        p);

    void vLine(double xTop, double xBot, Paint p) => canvas.drawLine(
        Offset(size.width * xTop, 0),
        Offset(size.width * xBot, size.height),
        p);

    // Draw edges first (so each road has a clean border).
    hLine(0.20, minorEdge);
    hLine(0.40, majorEdge);
    hLine(0.58, minorEdge);
    vLine(0.28, 0.30, minorEdge);
    vLine(0.50, 0.52, majorEdge);
    vLine(0.72, 0.74, minorEdge);

    // Roads
    hLine(0.20, minor);
    hLine(0.40, major);
    hLine(0.58, minor);
    vLine(0.28, 0.30, minor);
    vLine(0.50, 0.52, major);
    vLine(0.72, 0.74, minor);

    // Dashed centerline on the major horizontal road
    final centerPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashLen = 8.0;
    const gapLen = 6.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height * 0.40),
        Offset(x + dashLen, size.height * 0.40),
        centerPaint,
      );
      x += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _IconCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconCircle({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF2B5BA8), size: 22),
      ),
    );
  }
}

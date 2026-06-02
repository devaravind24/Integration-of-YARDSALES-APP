import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/widgets/custom_drawer.dart';
import '../../core/widgets/filter_modal.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';

// Demo yard-sale locations around San Jose (fallback when Firestore
// documents don't yet have lat/lng fields).
const List<Map<String, dynamic>> _demoSales = [
  {'title': 'Free Giveaway',        'lat': 37.3890, 'lng': -121.9847},
  {'title': 'Estate Sale Bellevue', 'lat': 37.2358, 'lng': -121.9624},
  {'title': 'Furniture Sale',       'lat': 37.3522, 'lng': -121.9350},
  {'title': 'Toys SALES',           'lat': 37.5944, 'lng': -122.0438},
  {'title': 'MK Sale',              'lat': 37.4323, 'lng': -121.8996},
  {'title': 'Weekend Finds',        'lat': 37.3700, 'lng': -121.9200},
  {'title': 'Garage Clearance',     'lat': 37.3100, 'lng': -121.8500},
];

const LatLng _kSanJose = LatLng(37.3382, -121.8863);

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final AuthService _auth = AuthService();
  String _displayName = 'there';

  // Google Maps
  final Completer<GoogleMapController> _mapController = Completer();
  Set<Marker> _markers = {};

  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _loadDisplayName();
    _loadMarkers();

    _authSub = FirebaseAuth.instance.authStateChanges().listen((_) {
      if (mounted) _loadDisplayName();
    });
  }

  Future<void> _loadDisplayName() async {
    final name = await _auth.resolveDisplayName();
    if (!mounted) return;
    setState(() => _displayName = name.split(' ').first);
  }

  Future<void> _loadMarkers() async {
    final Set<Marker> markers = {};

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('sales').get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final dynamic rawLat = data['lat'];
        final dynamic rawLng = data['lng'];
        if (rawLat != null && rawLng != null) {
          markers.add(Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(
              (rawLat as num).toDouble(),
              (rawLng as num).toDouble(),
            ),
            infoWindow: InfoWindow(
              title: data['title']?.toString() ?? 'Yard Sale',
              snippet: data['address']?.toString() ?? '',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange),
          ));
        }
      }
    } catch (e) {
      debugPrint('Marker load error: $e');
    }

    // Fall back to demo pins
    if (markers.isEmpty) {
      for (int i = 0; i < _demoSales.length; i++) {
        final s = _demoSales[i];
        markers.add(Marker(
          markerId: MarkerId('demo_$i'),
          position: LatLng(s['lat'] as double, s['lng'] as double),
          infoWindow: InfoWindow(title: s['title'] as String),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange),
        ));
      }
    }

    if (mounted) setState(() => _markers = markers);
  }

  @override
  void dispose() {
    _searchController.dispose();
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
            // ── Header ──────────────────────────────────────────────
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
                      onPressed: () =>
                          _scaffoldKey.currentState?.openDrawer(),
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

            // ── Greeting ─────────────────────────────────────────────
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
                          style: TextStyle(
                              color: Color(0xFF8E8E93), fontSize: 12),
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

            // ── Search bar ────────────────────────────────────────────
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
                          hintStyle: TextStyle(
                              color: Color(0xFF2B5BA8), fontSize: 14),
                          prefixIcon: Icon(Icons.search,
                              color: Color(0xFF2B5BA8), size: 20),
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ),
                  // const SizedBox(width: 10),
                  // _IconCircle(
                  //   icon: Icons.tune,
                  //   onTap: () => FilterModal.show(context),
                  // ),
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

            // ── Real Google Map ───────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Google Map
                      GoogleMap(
                        onMapCreated: (c) => _mapController.complete(c),
                        initialCameraPosition: const CameraPosition(
                          target: _kSanJose,
                          zoom: 12.0,
                        ),
                        markers: _markers,
                        myLocationEnabled: false,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                      ),

                      // Live sales-count chip (top-right overlay)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('sales')
                              .snapshots(),
                          builder: (_, snap) {
                            final count = snap.data?.docs.length ??
                                _demoSales.length;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withOpacity(0.12),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.local_offer,
                                      size: 14,
                                      color: Color(0xFFE8843A)),
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
                  ),
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
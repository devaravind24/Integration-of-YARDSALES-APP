import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const List<Map<String, dynamic>> _demoSaleLocations = [
  {
    'title': 'Free Giveaway',
    'address': '240 El Camino Real',
    'lat': 37.3890,
    'lng': -121.9847,
  },
  {
    'title': 'Estate Sale on Bellevue',
    'address': '139 Bellevue Dr, Los Gatos',
    'lat': 37.2358,
    'lng': -121.9624,
  },
  {
    'title': 'Furniture Sale',
    'address': '2490 The Alameda St.',
    'lat': 37.3522,
    'lng': -121.9350,
  },
  {
    'title': 'Toys SALES',
    'address': 'Union City, CA',
    'lat': 37.5944,
    'lng': -122.0438,
  },
  {
    'title': 'MK Sale',
    'address': '500 Main St, Milpitas',
    'lat': 37.4323,
    'lng': -121.8996,
  },
];

const LatLng _kDefaultCenter = LatLng(37.3382, -121.8863);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  Set<Marker> _markers = {};

  String _statusText = 'Tap the button to find nearby yard sales';
  double? _lat;
  double? _lng;
  bool _isLoading = false;

  // Tracks the selected sale for the "Get Directions" card
  Map<String, dynamic>? _selectedSale;

  @override
  void initState() {
    super.initState();
    _buildMarkers();
  }

  Future<void> _buildMarkers({Position? userPosition}) async {
    final Set<Marker> markers = {};
    List<Map<String, dynamic>> salesToPin = [];

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('sales').get();
      if (snapshot.docs.isNotEmpty) {
        for (final doc in snapshot.docs) {
          final data = doc.data();
          if (data['lat'] != null && data['lng'] != null) {
            salesToPin.add({...data, 'id': doc.id});
          }
        }
      }
    } catch (e) {
      debugPrint('Firestore marker fetch error: $e');
    }

    if (salesToPin.isEmpty) salesToPin = _demoSaleLocations;

    for (int i = 0; i < salesToPin.length; i++) {
      final sale = salesToPin[i];
      final lat = (sale['lat'] as num).toDouble();
      final lng = (sale['lng'] as num).toDouble();
      markers.add(
        Marker(
          markerId: MarkerId(sale['id']?.toString() ?? 'demo_$i'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: sale['title']?.toString() ?? 'Yard Sale',
            snippet: sale['address']?.toString() ?? '',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange),
          // Tapping a marker shows the directions card
          onTap: () => setState(() => _selectedSale = sale),
        ),
      );
    }

    if (userPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(userPosition.latitude, userPosition.longitude),
          infoWindow: const InfoWindow(title: 'You are here'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure),
        ),
      );
    }

    if (mounted) setState(() => _markers = markers);
  }

  // Opens Google Maps app with turn-by-turn directions
  Future<void> _openDirections(double lat, double lng) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$lat,$lng'
      '&travelmode=driving',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps.')),
        );
      }
    }
  }

  Future<void> _getLocation() async {
    setState(() {
      _isLoading = true;
      _statusText = 'Requesting permission…';
    });

    if (!await Geolocator.isLocationServiceEnabled()) {
      setState(() {
        _statusText = 'Location services are disabled. Enable them in Settings.';
        _isLoading = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _statusText = 'Location permission denied.';
          _isLoading = false;
        });
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _statusText =
            'Location permission permanently denied. Enable it in Settings.';
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() => _statusText = 'Getting your location…');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _statusText = 'Showing sales near you.';
        _isLoading = false;
      });

      await _buildMarkers(userPosition: position);

      final controller = await _mapController.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 13.0,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _statusText = 'Could not get location. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF2B5BA8),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Map View',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Google Map ───────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: GoogleMap(
                    onMapCreated: (c) => _mapController.complete(c),
                    initialCameraPosition: const CameraPosition(
                      target: _kDefaultCenter,
                      zoom: 12.0,
                    ),
                    markers: _markers,
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    // Tapping the map background dismisses the card
                    onTap: (_) => setState(() => _selectedSale = null),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Directions card (shown when a marker is tapped) ──────
            if (_selectedSale != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFECFF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_offer,
                          color: Color(0xFFE8843A), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedSale!['title']?.toString() ??
                                  'Yard Sale',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1B3A6B),
                              ),
                            ),
                            if ((_selectedSale!['address']?.toString() ?? '')
                                .isNotEmpty)
                              Text(
                                _selectedSale!['address']!.toString(),
                                style: const TextStyle(
                                    color: Color(0xFF2B5BA8), fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _openDirections(
                          (_selectedSale!['lat'] as num).toDouble(),
                          (_selectedSale!['lng'] as num).toDouble(),
                        ),
                        icon: const Icon(Icons.directions,
                            color: Colors.white, size: 16),
                        label: const Text(
                          'Directions',
                          style: TextStyle(
                              color: Colors.white, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B5BA8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Status card ──────────────────────────────────────────
            if (_selectedSale == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFECFF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Color(0xFF4CAF50), size: 20),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _statusText,
                              style: const TextStyle(
                                color: Color(0xFF1B3A6B),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_lat != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Latitude:  ${_lat!.toStringAsFixed(5)}',
                          style: const TextStyle(
                              color: Color(0xFF2B5BA8), fontSize: 13),
                        ),
                        Text(
                          'Longitude: ${_lng!.toStringAsFixed(5)}',
                          style: const TextStyle(
                              color: Color(0xFF2B5BA8), fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // ── Find Sales button ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _getLocation,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location, color: Colors.white),
                  label: Text(
                    _isLoading ? 'Getting location…' : 'Find Sales Near Me',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8843A),
                    disabledBackgroundColor:
                        const Color(0xFFE8843A).withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
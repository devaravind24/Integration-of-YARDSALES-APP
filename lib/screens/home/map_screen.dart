import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _statusText  = 'Tap the button to find nearby yard sales';
  double? _lat;
  double? _lng;
  bool _isLoading = false;

  Future<void> _getLocation() async {
    setState(() {
      _isLoading = true;
      _statusText = 'Requesting permission...';
    });

    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _statusText = 'Location services are disabled. Please enable them in Settings.';
        _isLoading = false;
      });
      return;
    }

    // Request permission
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
        _statusText = 'Location permission permanently denied. Enable it in app Settings.';
        _isLoading = false;
      });
      return;
    }

    // Get position
    try {
      setState(() => _statusText = 'Getting your location...');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _statusText = 'Location found! Showing sales near you.';
        _isLoading = false;
      });
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
            // Header
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
            // Map placeholder with pins
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Map background
                      Container(
                        color: const Color(0xFFE8EDF5),
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: _MapPainter(),
                        ),
                      ),
                      // Sale pins
                      ..._buildSalePins(),
                      // User location pin (shown after permission granted)
                      if (_lat != null)
                        const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.my_location, color: Color(0xFF2B5BA8), size: 40),
                              Text(
                                'You',
                                style: TextStyle(
                                  color: Color(0xFF2B5BA8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Location info card
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
                        const Icon(Icons.location_on, color: Color(0xFF4CAF50), size: 20),
                        const SizedBox(width: 6),
                        Text(
                          _statusText,
                          style: const TextStyle(
                            color: Color(0xFF1B3A6B),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    if (_lat != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Latitude:  ${_lat!.toStringAsFixed(5)}',
                        style: const TextStyle(color: Color(0xFF2B5BA8), fontSize: 13),
                      ),
                      Text(
                        'Longitude: ${_lng!.toStringAsFixed(5)}',
                        style: const TextStyle(color: Color(0xFF2B5BA8), fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Get location button
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
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location, color: Colors.white),
                  label: Text(
                    _isLoading ? 'Getting location...' : 'Find Sales Near Me',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8843A),
                    disabledBackgroundColor: const Color(0xFFE8843A).withOpacity(0.6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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

  List<Widget> _buildSalePins() {
    final positions = [
      const Offset(0.15, 0.28),
      const Offset(0.55, 0.18),
      const Offset(0.65, 0.55),
      const Offset(0.80, 0.60),
      const Offset(0.12, 0.72),
      const Offset(0.70, 0.82),
    ];
    return positions.map((pos) {
      return Positioned.fill(
        child: FractionalTranslation(
          translation: Offset(pos.dx - 0.5, pos.dy - 0.5),
          child: Center(child: _DollarPin()),
        ),
      );
    }).toList();
  }
}

class _DollarPin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 52,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: Color(0xFFE8843A), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Text('\$', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          ),
          Positioned(
            bottom: 0,
            child: CustomPaint(size: const Size(14, 14), painter: _PinTailPainter()),
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

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road  = Paint()..color = Colors.white..strokeWidth = 12..style = PaintingStyle.stroke;
    final major = Paint()..color = const Color(0xFFF5D88A)..strokeWidth = 18..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height * 0.35), Offset(size.width, size.height * 0.35), major);
    canvas.drawLine(Offset(0, size.height * 0.60), Offset(size.width, size.height * 0.65), road);
    canvas.drawLine(Offset(size.width * 0.3, 0),   Offset(size.width * 0.35, size.height), road);
    canvas.drawLine(Offset(size.width * 0.6, 0),   Offset(size.width * 0.65, size.height), major);
    canvas.drawLine(Offset(0, size.height * 0.15), Offset(size.width, size.height * 0.18), road);
    canvas.drawLine(Offset(0, size.height * 0.80), Offset(size.width, size.height * 0.82), road);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

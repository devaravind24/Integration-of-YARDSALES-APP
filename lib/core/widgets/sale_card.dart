import 'package:flutter/material.dart';

class SaleCard extends StatelessWidget {
  final String title;
  final String location;
  final String distance;

  const SaleCard({
    super.key,
    required this.title,
    required this.location,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(location),
            const SizedBox(height: 8),
            Text(distance),
          ],
        ),
      ),
    );
  }
}
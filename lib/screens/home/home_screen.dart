import 'package:flutter/material.dart';
import '../../core/widgets/sale_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yard Sale Treasure Map'),
      ),
      drawer: const Drawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search Yard Sales',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: const [
                  SaleCard(
                    title: 'Estate Sale',
                    location: 'San Jose',
                    distance: '4.1 miles away',
                  ),
                  SaleCard(
                    title: 'Furniture Sale',
                    location: 'Los Gatos',
                    distance: '7 miles away',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
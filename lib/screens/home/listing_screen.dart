import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/widgets/filter_modal.dart';
import '../../core/widgets/yard_sale_logo.dart';
import '../../routes/app_routes.dart';

class ListingScreen extends StatefulWidget {
  const ListingScreen({super.key});

  @override
  State<ListingScreen> createState() => _ListingScreenState();
}

class _ListingScreenState extends State<ListingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  static const List<Map<String, dynamic>> _fallback = [
    {
      'title': 'Free Giveaway',
      'address': '240 El Camino Real',
      'datetime': 'Sat, Apr 18, 2:00 PM',
      'distance': '7 miles',
    },
    {
      'title': 'Estate Sale on Bellevue',
      'address': '139 Bellevue Dr, Los Gatos, CA',
      'datetime': 'Sat, Apr 4 • 8:00 AM - 2:00 PM',
      'distance': '4.1 miles away',
    },
    {
      'title': 'Furniture Sale',
      'address': '2490 The Alameda St.',
      'datetime': 'Sun, Apr 19, 5:00 PM',
      'distance': '7.6 miles',
    },
    {
      'title': 'Toys SALES',
      'address': 'Union city, CA',
      'datetime': 'Sun, Apr 5 • 10:00 AM - 8:00 PM',
      'distance': '8.1 miles away',
    },
    {
      'title': 'MK Sale',
      'address': '500 Main St, Milpitas',
      'datetime': 'Sat, Apr 25, 9:00 AM',
      'distance': '5.3 miles',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Real brand logo (Figma asset) ──────────────
                  const YardSaleLogo(size: 48, wordmarkSize: 13, gap: 2),
                  const SizedBox(height: 6),
                  const Text(
                    'Yard Sale Treasure Map',
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Text(
                    'San Jose, CA',
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5EDE6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) =>
                            setState(() => _searchQuery = v.toLowerCase()),
                        decoration: const InputDecoration(
                          hintText: 'Search Yard sales',
                          hintStyle:
                              TextStyle(color: Colors.black54, fontSize: 14),
                          prefixIcon: Icon(Icons.search,
                              color: Colors.black54, size: 22),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5EDE6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.tune,
                          color: Colors.black54, size: 22),
                      onPressed: () => FilterModal.show(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Firestore-backed list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('sales')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  List<Map<String, dynamic>> sales;

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFFE8843A)));
                  }

                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    sales = _fallback;
                  } else {
                    sales = snapshot.data!.docs
                        .map((doc) => doc.data() as Map<String, dynamic>)
                        .toList();
                  }

                  if (_searchQuery.isNotEmpty) {
                    sales = sales
                        .where((s) =>
                            (s['title'] ?? '')
                                .toString()
                                .toLowerCase()
                                .contains(_searchQuery) ||
                            (s['address'] ?? '')
                                .toString()
                                .toLowerCase()
                                .contains(_searchQuery))
                        .toList();
                  }

                  if (sales.isEmpty) {
                    return const Center(child: Text('No sales found.'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    itemCount: sales.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final sale = sales[index];
                      return _SaleListCard(
                        sale: sale,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.details,
                          arguments: sale,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleListCard extends StatelessWidget {
  final Map<String, dynamic> sale;
  final VoidCallback onTap;
  const _SaleListCard({required this.sale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE8843A), Color(0xFFF5D4C0)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                sale['title']?.toString() ?? '',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87),
              ),
              const SizedBox(height: 4),
              if ((sale['address']?.toString() ?? '').isNotEmpty)
                Text(sale['address']!.toString(),
                    style: const TextStyle(
                        color: Colors.black54, fontSize: 13)),
              if ((sale['datetime']?.toString() ?? '').isNotEmpty)
                Text(sale['datetime']!.toString(),
                    style: const TextStyle(
                        color: Colors.black54, fontSize: 13)),
              if ((sale['distance']?.toString() ?? '').isNotEmpty)
                Text(sale['distance']!.toString(),
                    style: const TextStyle(
                        color: Colors.black54, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

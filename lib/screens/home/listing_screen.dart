import 'dart:async';
import '../../core/widgets/filter_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  Set<String> _favoriteIds = {};
  StreamSubscription<User?>? _authSub;

  List<Map<String, dynamic>> _allSales = [];
  bool _isLoading = true;

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
  FilterData? _activeFilter;
  @override
  void initState() {
    super.initState();

    _loadInitialData();

    _authSub = FirebaseAuth.instance.authStateChanges().listen((_) {
      if (mounted) {
        _loadInitialData();
      }
    });
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    await _loadFavorites();
    await _fetchSalesData();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchSalesData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('sales')
          .orderBy('createdAt', descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        _allSales = List.from(_fallback);
      } else {
        _allSales = snapshot.docs.map((doc) {
          final data = doc.data();
          if (!data.containsKey('id')) {
            data['id'] = doc.id;
          }
          return data;
        }).toList();
      }
    } catch (e) {
      debugPrint("Error fetching sales, using fallback: $e");
      _allSales = List.from(_fallback);
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final List<dynamic> favList = userDoc.data()?['favorites'] ?? [];
        setState(() {
          _favoriteIds = favList.map((id) => id.toString()).toSet();
        });
      }
    } catch (e) {
      debugPrint("Error loading favorites: $e");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _toggleFavorite(String saleId) async {
    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(_currentUserId);
    final isCurrentlyFav = _favoriteIds.contains(saleId);

    setState(() {
      if (_favoriteIds.contains(saleId)) {
        _favoriteIds.remove(saleId);
      } else {
        _favoriteIds.add(saleId);
      }
    });

    try {
      if (isCurrentlyFav) {
        // Remove ID from array
        await userDocRef.update({
          'favorites': FieldValue.arrayRemove([saleId]),
        });
      } else {
        // Add ID to array dynamically (creates the field if it doesn't exist)
        await userDocRef.set({
          'favorites': FieldValue.arrayUnion([saleId]),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Error updating favorite in Firestore: $e");
      // Revert UI state if the network request fails completely
      _loadFavorites();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> displayedSales = List.from(_allSales);

// Search Filter
    if (_searchQuery.isNotEmpty) {
      displayedSales = displayedSales.where((sale) {
        return (sale['title'] ?? '')
                .toString()
                .toLowerCase()
                .contains(_searchQuery) ||
            (sale['address'] ?? '')
                .toString()
                .toLowerCase()
                .contains(_searchQuery);
      }).toList();
    }

// Category Filter
    if (_activeFilter != null && _activeFilter!.categories.isNotEmpty) {
      displayedSales = displayedSales.where((sale) {
        final tag = (sale['tags'] ?? '').toString().toLowerCase();

        return _activeFilter!.categories.any(
          (category) => category.toLowerCase() == tag,
        );
      }).toList();
    }

// Min Price Filter
    if (_activeFilter?.minPrice != null) {
      displayedSales = displayedSales.where((sale) {
        final price = double.tryParse(
              sale['price']?.toString() ?? '0',
            ) ??
            0;

        return price >= _activeFilter!.minPrice!;
      }).toList();
    }

// Max Price Filter
    if (_activeFilter?.maxPrice != null) {
      displayedSales = displayedSales.where((sale) {
        final price = double.tryParse(
              sale['price']?.toString() ?? '0',
            ) ??
            0;

        return price <= _activeFilter!.maxPrice!;
      }).toList();
    }

// Sorting
    if (_activeFilter != null) {
      switch (_activeFilter!.sortBy) {
        case 'High Price':
          displayedSales.sort((a, b) {
            final aPrice = double.tryParse(a['price']?.toString() ?? '0') ?? 0;

            final bPrice = double.tryParse(b['price']?.toString() ?? '0') ?? 0;

            return bPrice.compareTo(aPrice);
          });
          break;

        case 'Low Price':
          displayedSales.sort((a, b) {
            final aPrice = double.tryParse(a['price']?.toString() ?? '0') ?? 0;

            final bPrice = double.tryParse(b['price']?.toString() ?? '0') ?? 0;

            return aPrice.compareTo(bPrice);
          });
          break;

        case 'Newest':
          displayedSales.sort((a, b) {
            final aTime = a['createdAt'] as Timestamp?;
            final bTime = b['createdAt'] as Timestamp?;

            if (aTime == null || bTime == null) {
              return 0;
            }

            return bTime.compareTo(aTime);
          });
          break;
      }
    }

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
                      onPressed: () async {
                        final filter = await FilterModal.show(
                          context,
                          _activeFilter,
                        );
                        if (filter != null) {
                          setState(() {
                            _activeFilter = filter;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Firestore-backed list
            Expanded(
              // Body UI strictly switches using a standard local variable state machine instead of an inline builder
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFE8843A)),
                    )
                  : displayedSales.isEmpty
                      ? const Center(child: Text('No sales found.'))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          itemCount: displayedSales.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final sale = displayedSales[index];
                            final String saleId = sale['id']?.toString() ??
                                sale['title']?.toString() ??
                                'unknown_$index';
                            final bool isFav = _favoriteIds.contains(saleId);

                            return _SaleListCard(
                              sale: sale,
                              isFavorite: isFav,
                              onFavorite: () => _toggleFavorite(saleId),
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.details,
                                arguments: sale,
                              ),
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
  final bool isFavorite;
  final VoidCallback onFavorite;

  const _SaleListCard(
      {required this.sale,
      required this.onTap,
      required this.isFavorite,
      required this.onFavorite});

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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
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
                    if ((sale['']?.toString() ?? '').isNotEmpty)
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
              IconButton(
                  onPressed: onFavorite,
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Color(0xFFE8843A) : Colors.black45,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

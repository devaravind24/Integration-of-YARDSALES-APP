import 'package:flutter/material.dart';
import '../home/discovery_screen.dart';
import '../home/listing_screen.dart';
import '../home/map_screen.dart';
import '../profile/profile_screen.dart';

class BottomNavScreen extends StatefulWidget {
  final int initialTab;
  final String initialSearch;

  const BottomNavScreen({
    super.key,
    this.initialTab = 0,
    this.initialSearch = '',
  });

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  late int _currentIndex;
  late String _searchQuery;

  static const _selectedColor = Color(0xFF2B5BA8);
  static const _items = <_NavItemData>[
    _NavItemData(Icons.explore_outlined,   Icons.explore,   'Discover'),
    _NavItemData(Icons.view_list_outlined, Icons.view_list, 'Listings'),
    _NavItemData(Icons.map_outlined,       Icons.map,       'Map'),
    _NavItemData(Icons.person_outline,     Icons.person,    'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _searchQuery = widget.initialSearch;
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _currentIndex = 1;
    });
  }

  void _onTabTap(int index) {
    setState(() {
      // Leaving listings tab — clear the search so it doesn't persist
      if (_currentIndex == 1 && index != 1) _searchQuery = '';
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DiscoveryScreen(onSearch: _onSearch),
      ListingScreen(
        key: const ValueKey('listing'),
        initialSearch: _searchQuery,
      ),
      const MapScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 6, 20, 16),
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(_items.length, (i) {
              final selected = _currentIndex == i;
              final data = _items[i];
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(40),
                  onTap: () => _onTabTap(i),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      width: selected ? 44 : 36,
                      height: selected ? 44 : 36,
                      decoration: BoxDecoration(
                        color: selected ? _selectedColor : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        selected ? data.activeIcon : data.icon,
                        size: 26,
                        color: selected ? Colors.white : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItemData(this.icon, this.activeIcon, this.label);
}

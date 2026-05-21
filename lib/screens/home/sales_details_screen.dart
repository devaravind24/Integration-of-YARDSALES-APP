import 'package:flutter/material.dart';

class SaleDetailsScreen extends StatelessWidget {
  final Map<String, String> sale;

  const SaleDetailsScreen({super.key, required this.sale});
  String? get _imageUrl {
    final raw = sale['imageUrl']?.trim();
    if (raw == null || raw.isEmpty || raw.toLowerCase() == 'null') return null;
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrl;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.chevron_left,
                            color: Colors.black54, size: 22),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
            if (imageUrl != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          width: double.infinity,
                          height: 220,
                          color: Colors.grey.shade100,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(
                            color: Color(0xFFE8843A),
                            strokeWidth: 2.5,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  imageUrl == null ? 8 : 20, // tighter spacing without hero
                  20,
                  32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale['title'] ?? 'Sale Details',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if ((sale['address'] ?? '').isNotEmpty)
                      _MetaRow(
                        icon: Icons.location_on_outlined,
                        text: sale['address']!,
                      ),
                    if ((sale['datetime'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _MetaRow(
                        icon: Icons.access_time_outlined,
                        text: sale['datetime']!,
                      ),
                    ],
                    if ((sale['distance'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _MetaRow(
                        icon: Icons.directions_car_outlined,
                        text: sale['distance']!,
                      ),
                    ],
                    const Divider(height: 32, color: Color(0xFFE5E5EA)),
                    const Text(
                      'Descriptions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      (sale['description'] != null &&
                              sale['description']!.trim().isNotEmpty)
                          ? sale['description']!
                          : 'Large neighborhood yard sale with Furniture, Home items, Decor and Collectibles.\n\nInventory may change throughout the day.',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    const Divider(height: 32, color: Color(0xFFE5E5EA)),
                    const Text(
                      'Seller Info',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Posted by Local Seller\nUpdated 2 hours ago.',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF8E8E93)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

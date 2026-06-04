import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/widgets/sale_image_carousel.dart';
import '../../routes/app_routes.dart';
import '../../services/chat_service.dart';
import '../../services/notification_service.dart';
import '../../services/sale_service.dart';

/// Sale Details — now carries `Map<String, dynamic>` (was `Map<String,String>`)
/// so the image URL list survives. Adds:
///   * Feature 3 — image carousel (main + multi-image + states)
///   * Feature 1 — "Contact Seller" → opens/creates a chat
///   * Feature 6 — Share button (share_plus)
class SaleDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> sale;

  const SaleDetailsScreen({super.key, required this.sale});

  @override
  State<SaleDetailsScreen> createState() => _SaleDetailsScreenState();
}

class _SaleDetailsScreenState extends State<SaleDetailsScreen> {
  final _chatService = ChatService();
  bool _contacting = false;

  /// Configure this to your deployed deep-link domain (must be set up for
  /// Android App Links / iOS Universal Links to open the app directly).
  static const _shareBaseUrl = 'https://yardsale.app';

  Map<String, dynamic> get sale => widget.sale;

  String get _saleId =>
      (sale['id'] ?? sale['saleId'] ?? '').toString();

  String? get _sellerId {
    final v = sale['sellerId']?.toString().trim();
    if (v == null || v.isEmpty || v.toLowerCase() == 'null') return null;
    return v;
  }

  List<String> get _images => SaleService.imagesFromSale(sale);

  Future<String> _fetchSellerUsername(String? sellerId) async {
    if (sellerId == null || sellerId.isEmpty) return 'Local Seller';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(sellerId)
          .get();
      if (doc.exists && doc.data() != null) {
        return doc.data()?['displayName'] ?? 'Local Seller';
      }
    } catch (e) {
      debugPrint('Error fetching seller username: $e');
    }
    return 'Local Seller';
  }

  // ── Feature 6: Share ───────────────────────────────────────────────
  void _shareListing() {
    final title = (sale['title'] ?? 'Yard sale item').toString();
    final price = (sale['price'] ?? '').toString().trim();
    final desc = (sale['description'] ?? '').toString().trim();
    final location = (sale['address'] ?? '').toString().trim();
    final images = _images;
    final link = _saleId.isNotEmpty
        ? '$_shareBaseUrl${AppRoutes.details}/$_saleId'
        : _shareBaseUrl;

    final buffer = StringBuffer()
      ..write('Check out this yard sale item: $title');
    if (price.isNotEmpty) buffer.write(' - \$$price');
    buffer.write('\n');
    if (desc.isNotEmpty) buffer.write('\n$desc\n');
    if (location.isNotEmpty) buffer.write('\nLocation: $location');
    buffer.write('\n\nView listing: $link');
    if (images.isNotEmpty) buffer.write('\nPhoto: ${images.first}');

    Share.share(buffer.toString(), subject: title);
  }

  // ── Feature 1: Contact Seller ──────────────────────────────────────
  Future<void> _contactSeller() async {
    final sellerId = _sellerId;
    if (sellerId == null) {
      _snack('Seller information is unavailable for this listing.');
      return;
    }
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) {
      _snack('Please sign in to contact the seller.');
      return;
    }
    if (me.uid == sellerId) {
      _snack('This is your own listing.');
      return;
    }

    setState(() => _contacting = true);
    try {
      final sellerName = await _fetchSellerUsername(sellerId);
      final title = (sale['title'] ?? 'Yard sale item').toString();

      final chatId = await _chatService.openOrCreateChat(
        sellerId: sellerId,
        sellerName: sellerName,
        saleId: _saleId,
        saleTitle: title,
      );

      // Feature 4 — notify the seller that a buyer expressed interest.
      await NotificationService.instance.notifyInterest(
        sellerId: sellerId,
        buyerName: me.displayName ?? me.email ?? 'A buyer',
        saleId: _saleId,
        saleTitle: title,
      );

      if (!mounted) return;
      context.pushNamed(
        AppRoutes.nChat,
        pathParameters: {'chatId': chatId},
        extra: {'otherUserName': sellerName, 'otherUserId': sellerId},
      );
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _contacting = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final images = _images;
    final hasImages = images.isNotEmpty;

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
                    // Feature 6 — Share button
                    IconButton(
                      tooltip: 'Share listing',
                      icon: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.share_outlined,
                            color: Color(0xFF2B5BA8), size: 20),
                      ),
                      onPressed: _shareListing,
                    ),
                  ],
                ),
              ),
            ),

            // Feature 3 — image carousel (main + multi-image + states)
            if (hasImages)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: SaleImageCarousel(imageUrls: images),
                ),
              ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  hasImages ? 20 : 8,
                  20,
                  32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            sale['title']?.toString() ?? 'Sale Details',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                        if ((sale['price']?.toString() ?? '').trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              '\$${sale['price']}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE8843A),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if ((sale['address']?.toString() ?? '').isNotEmpty)
                      _MetaRow(
                        icon: Icons.location_on_outlined,
                        text: sale['address'].toString(),
                      ),
                    if ((sale['datetime']?.toString() ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _MetaRow(
                        icon: Icons.access_time_outlined,
                        text: sale['datetime'].toString(),
                      ),
                    ],
                    if ((sale['distance']?.toString() ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _MetaRow(
                        icon: Icons.directions_car_outlined,
                        text: sale['distance'].toString(),
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
                              sale['description'].toString().trim().isNotEmpty)
                          ? sale['description'].toString()
                          : 'Large neighborhood yard sale with Furniture, Home items, Decor and Collectibles.\n\nInventory may change throughout the day.',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    const Divider(height: 32, color: Color(0xFFE5E5EA)),
                    const Text(
                      'Seller Infos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<String>(
                      future: _fetchSellerUsername(_sellerId),
                      builder: (context, snapshot) {
                        final username = snapshot.data ?? 'Loading...';
                        return Text(
                          'Posted by $username\n 2 hours ago.',
                          style: TextStyle(
                            color: snapshot.hasData
                                ? Colors.black87
                                : Colors.black45,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Feature 1 — Contact Seller
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _contacting ? null : _contactSeller,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B5BA8),
                          disabledBackgroundColor:
                              const Color(0xFF2B5BA8).withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                        icon: _contacting
                            ? const SizedBox.shrink()
                            : const Icon(Icons.chat_bubble_outline,
                                color: Colors.white, size: 20),
                        label: _contacting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Contact Seller',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
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

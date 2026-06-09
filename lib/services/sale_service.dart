import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Feature 3 — Sale creation + image persistence.
///
/// ROOT CAUSE that this fixes: the old `create_listing.dart` saved only
/// `hasImage: true/false` and never uploaded the picked file, so the Sale
/// Details page had no `imageUrl` to render. This service uploads every
/// picked image to Firebase Storage and writes both:
///   - `imageUrls`: List<String>  (canonical, supports a carousel)
///   - `imageUrl` : String        (first image; back-compat with old readers)
class SaleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Uploads [images] (may be empty) and creates a `sales` document.
  /// Returns the new document id.
  Future<String> createListing({
    required String title,
    required String description,
    required String tags,
    required String date,
    required String startTime,
    required String address,
    required String price,
    required String condition,
    List<File> images = const [],
    double? lat,
    double? lng,
  }) async {
    final uid = _auth.currentUser?.uid ?? 'anonymous';

    // Create the doc first so images can be foldered under its id.
    final docRef = _db.collection('sales').doc();

    final List<String> urls =
        await _uploadImages(saleId: docRef.id, images: images);

    await docRef.set({
      'title': title.trim(),
      'description': description.trim(),
      'tags': tags.trim(),
      'datetime': '${date.trim()} ${startTime.trim()}'.trim(),
      'date': date.trim(),
      'starttime': startTime.trim(),
      'address': address.trim(),
      'price': price.trim(),
      'condition': condition.trim(),
      'distance': 'Nearby',
      'sellerId': uid,
      'hasImage': urls.isNotEmpty,
      'imageUrls': urls, // canonical list
      'imageUrl': urls.isNotEmpty ? urls.first : null, // back-compat
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  Future<List<String>> _uploadImages({
    required String saleId,
    required List<File> images,
  }) async {
    final List<String> urls = [];
    for (var i = 0; i < images.length; i++) {
      try {
        final ref = _storage.ref(
          'sale_images/$saleId/${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
        );
        final task = await ref.putFile(
          images[i],
          SettableMetadata(contentType: 'image/jpeg'),
        );
        urls.add(await task.ref.getDownloadURL());
      } catch (e) {
        // Upload failed for this image — listing still saves without it.
        print('Image $i upload failed: $e');
      }
    }
    return urls;
  }

  /// Normalizes the image list off any `sales` document map. Handles legacy
  /// docs that only have a single `imageUrl`, the newer `imageUrls` list, and
  /// the GoRouter case where everything arrives stringified.
  static List<String> imagesFromSale(Map<String, dynamic> sale) {
    final out = <String>[];

    final dynamic list = sale['imageUrls'];
    if (list is List) {
      out.addAll(list
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty && e.toLowerCase() != 'null'));
    } else if (list is String && list.trim().isNotEmpty) {
      // Stringified list e.g. "[https://a, https://b]" coming through routing.
      out.addAll(list
          .replaceAll('[', '')
          .replaceAll(']', '')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && e.toLowerCase() != 'null'));
    }

    if (out.isEmpty) {
      final single = sale['imageUrl']?.toString().trim();
      if (single != null &&
          single.isNotEmpty &&
          single.toLowerCase() != 'null') {
        out.add(single);
      }
    }
    return out;
  }
}

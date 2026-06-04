import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw _friendly(e.code);
    }
  }
  Future<UserCredential> signUp(
    String email,
    String password, {
    String? firstName,
    String? lastName,
    String? phone,
    String? role, // 'buyer' or 'seller'
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final fullName = [
        if (firstName != null && firstName.trim().isNotEmpty) firstName.trim(),
        if (lastName != null && lastName.trim().isNotEmpty) lastName.trim(),
      ].join(' ').trim();
      if (fullName.isNotEmpty) {
        await cred.user?.updateDisplayName(fullName);
      }
      await _db.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'firstName': firstName?.trim() ?? '',
        'lastName': lastName?.trim() ?? '',
        'displayName': fullName,
        'email': email.trim(),
        'phone': phone?.trim() ?? '',
        'role': role ?? 'buyer',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return cred;
    } on FirebaseAuthException catch (e) {
      throw _friendly(e.code);
    }
  }
  Future<Map<String, dynamic>?> fetchCurrentUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final snap = await _db.collection('users').doc(uid).get();
    return snap.exists ? snap.data() : null;
  }
  Future<String> resolveDisplayName() async {
    final user = _auth.currentUser;
    if (user == null) return 'there';
    if ((user.displayName ?? '').trim().isNotEmpty) return user.displayName!.trim();

    final profile = await fetchCurrentUserProfile();
    final stored = (profile?['displayName'] as String?)?.trim();
    if (stored != null && stored.isNotEmpty) return stored;

    final email = user.email ?? '';
    if (email.contains('@')) return email.split('@').first;
    return 'there';
  }

  Future<List<Map<String, dynamic>>> fetchUserFavorites() async {
  final uid = _auth.currentUser?.uid;
  if (uid == null) return [];

  try {
    final userSnap = await _db.collection('users').doc(uid).get();
    if (!userSnap.exists) return [];

    final userData = userSnap.data();
    if (userData == null || !userData.containsKey('favorites')) return [];

    final List<dynamic> rawFavorites = userData['favorites'] ?? [];
    if (rawFavorites.isEmpty) return [];

    final List<String> favoriteIds = rawFavorites
        .map((id) => id.toString())
        .where((id) => id.isNotEmpty)
        .take(30) // Firestore whereIn limit protection
        .toList();

    final salesSnap = await _db
        .collection('sales')
        .where(FieldPath.documentId, whereIn: favoriteIds)
        .get();

    return salesSnap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Injecting document ID for UI/Hero animation keys
      return data;
    }).toList();

  } catch (e) {
    debugPrint('Error fetching favorite sales profiles: $e');
    return [];
  }
}

  /// Feature 2 — Forgot Password.
  /// Sends a Firebase Auth password-reset email. Throws a friendly,
  /// user-facing message on failure (reuses the existing `_friendly` map).
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _friendly(e.code);
    }
  }

  Future<void> signOut() => _auth.signOut();

  String _friendly(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'Something went wrong ($code). Please try again.';
    }
  }
}

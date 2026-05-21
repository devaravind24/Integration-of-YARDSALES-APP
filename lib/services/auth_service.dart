import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Wraps Firebase Auth + a `/users/{uid}` Firestore document so the rest of
/// the app can read the logged-in user's real name everywhere.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Currently signed-in Firebase user (null if logged out).
  User? get currentUser => _auth.currentUser;

  /// Stream that emits whenever auth state changes — used to react to
  /// login / logout from anywhere in the widget tree.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email + password. Throws a human-readable [String] on error.
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

  /// Create a new account.
  ///
  /// If [firstName] / [lastName] are provided, they're saved to:
  ///   • the FirebaseAuth user's `displayName` (used as a quick cache), AND
  ///   • a Firestore document at `users/{uid}` for richer profile data.
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

      // Cache the name on the FirebaseAuth user so every screen can read
      // `currentUser.displayName` synchronously without a Firestore round-trip.
      if (fullName.isNotEmpty) {
        await cred.user?.updateDisplayName(fullName);
      }

      // Persist the full profile in Firestore for richer data access.
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

  /// Fetch the user profile document for the currently signed-in user.
  /// Returns `null` if the user isn't logged in or the doc doesn't exist.
  Future<Map<String, dynamic>?> fetchCurrentUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final snap = await _db.collection('users').doc(uid).get();
    return snap.exists ? snap.data() : null;
  }

  /// Returns the best display name available for the current user.
  /// Order of preference: FirebaseAuth displayName → Firestore profile →
  /// email prefix → "there" (so greetings still feel personal).
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

  /// Sign out the current user.
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

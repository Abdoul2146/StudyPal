import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/users_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Sign up
  Future<AppUser?> signUp({
    required String name,
    required String email,
    required String password,
    required String gradeLevel,
  }) async {
    final userCred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = AppUser(
      uid: userCred.user!.uid,
      name: name,
      email: email,
      gradeLevel: gradeLevel,
    );
    await _db.collection('users').doc(user.uid).set(user.toMap());
    return user;
  }

  // Login
  Future<AppUser?> login({
    required String email,
    required String password,
  }) async {
    final userCred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final doc = await _db.collection('users').doc(userCred.user!.uid).get();

    // If there's no Firestore profile, sign out and fail the login.
    if (!doc.exists) {
      await _auth.signOut();
      throw Exception(
        'No user profile found for this account. Please sign up to continue.',
      );
    }

    return AppUser.fromMap(doc.data()!);
  }

  // Forgot password
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Get current user
  Future<AppUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    return AppUser.fromMap(doc.data()!);
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Sign in with Google
  Future<AppUser?> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();

    // Optionally, initialize with clientId/serverClientId if needed:
    // await googleSignIn.initialize(clientId: ..., serverClientId: ...);

    GoogleSignInAccount? googleUser;
    try {
      // For web, you may want to check supportsAuthenticate and use authenticate()
      googleUser = await googleSignIn.signIn();
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }

    if (googleUser == null) return null; // User cancelled

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    if (googleAuth.idToken == null) {
      throw Exception('Google sign-in failed: Missing idToken.');
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCred = await _auth.signInWithCredential(credential);

    // Check if user exists in Firestore, if not create
    final doc = await _db.collection('users').doc(userCred.user!.uid).get();
    if (!doc.exists) {
      final user = AppUser(
        uid: userCred.user!.uid,
        name: userCred.user!.displayName ?? '',
        email: userCred.user!.email ?? '',
        gradeLevel: '', // Prompt for this after sign-in
      );
      await _db.collection('users').doc(user.uid).set(user.toMap());
      return user;
    }
    return AppUser.fromMap(doc.data()!);
  }

  // Add this method:
  Future<void> updateUserGradeLevel(String uid, String gradeLevel) async {
    await _db.collection('users').doc(uid).update({'gradeLevel': gradeLevel});
  }

  // Stream that emits AppUser? based on Firebase Auth state
  Stream<AppUser?> userStream() {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      final doc = await _db.collection('users').doc(firebaseUser.uid).get();
      if (!doc.exists) return null;
      return AppUser.fromMap(doc.data()!);
    });
  }
}

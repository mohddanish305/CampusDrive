import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Google Sign-In instance
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static Future<void> initialize() async {
    // Initialization code if needed
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user != null) {
        await result.user!.updateDisplayName(name);
        await result.user!.reload();
      }
      return _auth.currentUser;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      // Note: In some versions authentication is a Future, in others it's a property.
      // We use await to be safe for Future, but if it's not, Dart handles it.
      // However, if IDE complains about 'await' on non-future, we can remove it.
      // But for compatibility with standard google_sign_in, it's usually a Future.
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      debugPrint("idToken: ${googleAuth.idToken}");
      debugPrint("accessToken: ${googleAuth.accessToken}");

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final UserCredential userCred = await _auth.signInWithCredential(
        credential,
      );

      debugPrint("User: ${userCred.user?.uid}");
      return userCred.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('CODE: ${e.code}');
      debugPrint('MESSAGE: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}

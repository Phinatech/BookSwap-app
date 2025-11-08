import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Authentication service wrapper
/// Handles user authentication, email verification, and password reset
class AuthService {
  final _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signIn({required String email, required String password}) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> signUp({required String email, required String password}) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() => _auth.signOut();

  // NEW: send verification email for current user
  Future<void> sendVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    } else {
      throw FirebaseAuthException(
        code: 'no-user-or-verified',
        message: 'No signed-in user or already verified.',
      );
    }
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // (From earlier steps, if you added forgot password)
  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email);
}

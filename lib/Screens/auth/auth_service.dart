import 'package:firebase_auth/firebase_auth.dart';

class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Signup
  Future<String?> signup(String email, String password) async {
    try {

      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return "Signup Successful";

    } on FirebaseAuthException catch (e) {

      if (e.code == 'weak-password') {
        return "Password is too weak";
      }

      if (e.code == 'email-already-in-use') {
        return "Email already exists";
      }

      if (e.code == 'invalid-email') {
        return "Invalid email address";
      }

      return e.message;
    }
  }

  // Login
  Future<String?> login(String email, String password) async {
    try {

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return "Login Successful";

    } on FirebaseAuthException catch (e) {

      if (e.code == 'user-not-found') {
        return "User not found";
      }

      if (e.code == 'wrong-password') {
        return "Wrong password";
      }

      if (e.code == 'invalid-email') {
        return "Invalid email";
      }

      return e.message;
    }
  }

  Future<String?> signOut() async {
    try {
      await _auth.signOut();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Could not sign out. Please try again.';
    } catch (_) {
      return 'Could not sign out. Please try again.';
    }
  }
}
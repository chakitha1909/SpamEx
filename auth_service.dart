import 'package:firebase_auth/firebase_auth.dart';
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Sign in method
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("🔥 Firebase Auth Error: ${e.code} - ${e.message}");
      throw e;  // Properly throw the error
    }}
  // Sign up method
  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("🔥 Firebase Auth Error: ${e.code} - ${e.message}");
      throw e;  // Properly throw the error
    }}
  // Sign out method
  Future<void> signOut() async {
    await _auth.signOut();}
  // Check if user is logged in
  User? getCurrentUser() {
    return _auth.currentUser;}}

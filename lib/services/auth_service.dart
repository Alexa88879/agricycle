import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to listen for authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign up with email, password, full name, and role
  Future<UserCredential?> signUpWithEmailAndPassword(
      String email, String password, String fullName, String role) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        // Store additional user information in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'fullName': fullName,
          'role': role,
          'createdAt': Timestamp.now(),
        });
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle Firebase specific errors (e.g., email-already-in-use)
      print('FirebaseAuthException during sign up: ${e.message}');
      throw e; // Re-throw the exception to be caught by the UI
    } catch (e) {
      // Handle other errors
      print('Error during sign up: $e');
      throw e; // Re-throw the exception
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle Firebase specific errors (e.g., user-not-found, wrong-password)
      print('FirebaseAuthException during sign in: ${e.message}');
      throw e; // Re-throw the exception
    } catch (e) {
      // Handle other errors
      print('Error during sign in: $e');
      throw e; // Re-throw the exception
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error during sign out: $e');
      throw e; // Re-throw the exception
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      throw e; // Re-throw the exception
    }
  }
}

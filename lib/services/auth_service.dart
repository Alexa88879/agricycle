// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// It's good practice to import your AppUser model if you have one,
// but for this service, direct map operations are also fine.
// import '../models/user_model.dart';

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
        // IMPORTANT: Ensure this Firestore write completes before returning
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'fullName': fullName,
          'role': role,
          'createdAt': Timestamp.now(),
        });
        print("User profile created in Firestore for UID: ${user.uid}");
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during sign up: ${e.code} - ${e.message}');
      throw e;
    } catch (e) {
      print('Error during sign up: $e');
      throw e;
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
      print('FirebaseAuthException during sign in: ${e.code} - ${e.message}');
      throw e;
    } catch (e) {
      print('Error during sign in: $e');
      throw e;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print("User signed out successfully.");
    } catch (e) {
      print('Error during sign out: $e');
      throw e;
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
      print("User document not found for UID: $uid");
      return null;
    } catch (e) {
      print('Error fetching user data for UID $uid: $e');
      // It's often better not to throw here but return null,
      // allowing AuthGate to handle the "no data" scenario.
      return null;
      // throw e; // Original behavior
    }
  }

  // Get user role directly (can be useful for quick checks, but getUserData is more comprehensive)
  Future<String?> getUserRole(String uid) async {
    try {
      final userData = await getUserData(uid);
      return userData?['role'] as String?;
    } catch (e) {
      print('Error fetching user role directly for UID $uid: $e');
      return null;
    }
  }
}

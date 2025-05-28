// lib/services/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart' as AppUserModel; 

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<AppUserModel.AppUser?> getCurrentAppUser() async {
    final firebaseUser = getCurrentUser();
    if (firebaseUser == null) return null;
    return await _firestoreService.getUser(firebaseUser.uid);
  }

  Future<UserCredential?> signUpWithEmailPassword(String email, String password, String name, AppUserModel.UserRole role) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        AppUserModel.AppUser newUser = AppUserModel.AppUser(
          uid: userCredential.user!.uid,
          email: email,
          name: name,
          role: role,
          createdAt: Timestamp.now(), 
        );
        await _firestoreService.createUser(newUser);
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during sign up: ${e.message}');
      throw e; 
    } catch (e) {
      print('Error during sign up: $e');
      throw e; 
    }
  }

  Future<UserCredential?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during sign in: ${e.message}');
      throw e; 
    } catch (e) {
      print('Error during sign in: $e');
      throw e; 
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateUserRole(String uid, AppUserModel.UserRole role) async {
    try {
      await _firestoreService.updateUserRole(uid, role);
    } catch (e) {
      print('Error updating user role: $e');
      throw e;
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}

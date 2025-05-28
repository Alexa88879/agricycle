// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart'; // Your AppUser model

class AppUser {
  final String uid;
  final String? email;
  final String? fullName;
  final String role; // 'Farmer' or 'Company'
  final String? avatarUrl; // Could be populated from Firebase Auth if available (e.g. from Google/Apple sign in)
  final Timestamp? createdAt;

  AppUser({
    required this.uid,
    this.email,
    this.fullName,
    required this.role,
    this.avatarUrl,
    this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String documentId) {
    return AppUser(
      uid: documentId,
      email: data['email'] as String?,
      fullName: data['fullName'] as String?,
      role: data['role'] as String? ?? 'Farmer', 
      avatarUrl: data['avatarUrl'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'role': role,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(), 
    };
  }
}


// lib/services/firestore_service.dart

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String usersCollection = 'users';

  Future<void> createUser({
    required String uid,
    required String email,
    required String fullName,
    required String role,
    String? avatarUrl, // This might be null for email/password signups initially
  }) async {
    final newUser = AppUser(
      uid: uid,
      email: email,
      fullName: fullName,
      role: role,
      avatarUrl: avatarUrl, // Pass along if available
      createdAt: null, 
    );
    try {
      await _db.collection(usersCollection).doc(uid).set(newUser.toMap());
      print('User created in Firestore with UID: $uid, Role: $role');
    } catch (e) {
      print('Error creating user in Firestore: $e');
      throw Exception('Failed to create user profile.');
    }
  }

  Future<AppUser?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection(usersCollection).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      print('User document not found in Firestore for UID: $uid');
      return null; 
    } catch (e) {
      print('Error fetching user data for UID $uid: $e');
      return null; 
    }
  }

  Stream<AppUser?> streamUserData(String uid) {
    return _db
        .collection(usersCollection)
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return AppUser.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
      }
      return null;
    }).handleError((error) {
      print("Error in streamUserData for UID $uid: $error");
      return null;
    });
  }

  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection(usersCollection).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return data['role'] as String?;
      }
      return null; 
    } catch (e) {
      print('Error fetching user role for UID $uid: $e');
      return null;
    }
  }
   // Optional: Method to update user data if needed later
  Future<void> updateUserData(AppUser user) async {
    try {
      // Ensure 'createdAt' is not overwritten with null if it exists.
      // The toMap() method in AppUser should ideally handle this,
      // or you can explicitly fetch existing data and merge.
      // For simplicity, using SetOptions(merge: true) is often sufficient.
      await _db.collection(usersCollection).doc(user.uid).set(user.toMap(), SetOptions(merge: true));
      print('User data updated for UID: ${user.uid}');
    } catch (e) {
      print('Error updating user data in Firestore: $e');
      throw Exception('Failed to update user data.');
    }
  }
}

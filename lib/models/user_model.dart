// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { farmer, company, unknown }

class AppUser {
  final String uid;
  final String email;
  String? name;
  UserRole role;
  Timestamp? createdAt;
  String? phoneNumber; 
  String? profilePictureUrl; 

  AppUser({
    required this.uid,
    required this.email,
    this.name,
    this.role = UserRole.unknown,
    this.createdAt,
    this.phoneNumber,
    this.profilePictureUrl,
  });

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return AppUser(
      uid: data?['uid'] ?? snapshot.id,
      email: data?['email'] ?? '',
      name: data?['name'],
      role: _parseUserRole(data?['role']),
      createdAt: data?['createdAt'] as Timestamp?,
      phoneNumber: data?['phoneNumber'],
      profilePictureUrl: data?['profilePictureUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      if (name != null) 'name': name,
      'role': role.name, 
      if (createdAt != null) 'createdAt': createdAt,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
    };
  }

  static UserRole _parseUserRole(String? roleString) {
    if (roleString == 'farmer') return UserRole.farmer;
    if (roleString == 'company') return UserRole.company;
    return UserRole.unknown;
  }
}

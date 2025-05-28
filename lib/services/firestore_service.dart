// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart' as Firestore;
import '../models/user_model.dart' as AppUserModel;
import '../models/waste_item_model.dart'; 

class FirestoreService {
  final Firestore.FirebaseFirestore _db = Firestore.FirebaseFirestore.instance;

  Future<void> createUser(AppUserModel.AppUser user) async {
    try {
      await _db.collection('users').doc(user.uid).set(user.toFirestore());
    } catch (e) {
      print('Error creating user in Firestore: $e');
      rethrow;
    }
  }

  Future<AppUserModel.AppUser?> getUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUserModel.AppUser.fromFirestore(doc as Firestore.DocumentSnapshot<Map<String, dynamic>>, null);
      }
      return null;
    } catch (e) {
      print('Error fetching user from Firestore: $e');
      rethrow;
    }
  }
  
  Future<void> updateUserRole(String uid, AppUserModel.UserRole role) async {
    try {
      await _db.collection('users').doc(uid).update({'role': role.name});
    } catch (e) {
      print('Error updating user role in Firestore: $e');
      rethrow;
    }
  }

  Future<String> addWasteItem(WasteItem wasteItem) async {
    try {
      Firestore.DocumentReference docRef = await _db.collection('waste_items').add(wasteItem.toFirestore());
      // Update the waste item with its ID
      await docRef.update({'id': docRef.id});
      return docRef.id;
    } catch (e) {
      print('Error adding waste item to Firestore: $e');
      rethrow;
    }
  }

  Stream<List<WasteItem>> getWasteItems() {
    try {
      return _db.collection('waste_items')
              .where('status', isEqualTo: 'available') // Only show available items
              .orderBy('postedAt', descending: true) 
              .snapshots()
              .map((snapshot) {
        return snapshot.docs.map((doc) {
          return WasteItem.fromFirestore(doc as Firestore.DocumentSnapshot<Map<String, dynamic>>, null);
        }).toList();
      });
    } catch (e) {
      print('Error getting waste items stream: $e');
      return Stream.value([]); 
    }
  }
  
  Stream<List<WasteItem>> getFarmerWasteItems(String farmerId) {
    try {
      return _db.collection('waste_items')
              .where('farmerId', isEqualTo: farmerId)
              .orderBy('postedAt', descending: true)
              .snapshots()
              .map((snapshot) {
        return snapshot.docs.map((doc) {
          return WasteItem.fromFirestore(doc as Firestore.DocumentSnapshot<Map<String, dynamic>>, null);
        }).toList();
      });
    } catch (e) {
      print('Error getting farmer waste items stream: $e');
      return Stream.value([]);
    }
  }

  Future<WasteItem?> getWasteItemById(String itemId) async {
    try {
      final doc = await _db.collection('waste_items').doc(itemId).get();
      if (doc.exists) {
        return WasteItem.fromFirestore(doc as Firestore.DocumentSnapshot<Map<String, dynamic>>, null);
      }
      return null;
    } catch (e) {
      print('Error fetching waste item by ID: $e');
      rethrow;
    }
  }
}

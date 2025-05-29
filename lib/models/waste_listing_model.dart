// lib/models/waste_listing_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class WasteListing {
  final String id;
  final String userId;
  final String? userEmail;
  final String? mediaUrl;
  final String? mediaType; // 'image' or 'video'
  final String? cropType;
  final String quantity;
  final String location;
  final String? wasteType; // From AI or manual input
  final String? suggestedUse;
  final String? suggestedPrice;
  final String? co2SavedEstimate;
  final String? geminiRawResponse;
  final String status; // e.g., 'active', 'sold', 'pending_approval'
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final String? farmerName; // Denormalized for easier display

  WasteListing({
    required this.id,
    required this.userId,
    this.userEmail,
    this.mediaUrl,
    this.mediaType,
    this.cropType,
    required this.quantity,
    required this.location,
    this.wasteType,
    this.suggestedUse,
    this.suggestedPrice,
    this.co2SavedEstimate,
    this.geminiRawResponse,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.farmerName,
  });

  factory WasteListing.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Missing data for WasteListing ${snapshot.id}');
    }
    return WasteListing(
      id: snapshot.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] as String?,
      mediaUrl: data['mediaUrl'] as String?,
      mediaType: data['mediaType'] as String?,
      cropType: data['cropType'] as String?,
      quantity: data['quantity'] ?? '',
      location: data['location'] ?? '',
      wasteType: data['wasteType'] as String?,
      suggestedUse: data['suggestedUse'] as String?,
      suggestedPrice: data['suggestedPrice'] as String?,
      co2SavedEstimate: data['co2SavedEstimate'] as String?,
      geminiRawResponse: data['geminiRawResponse'] as String?,
      status: data['status'] ?? 'unknown',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
      farmerName: data['farmerName'] as String?, // Attempt to get farmerName
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'cropType': cropType,
      'quantity': quantity,
      'location': location,
      'wasteType': wasteType,
      'suggestedUse': suggestedUse,
      'suggestedPrice': suggestedPrice,
      'co2SavedEstimate': co2SavedEstimate,
      'geminiRawResponse': geminiRawResponse,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
      'farmerName': farmerName,
    };
  }
}

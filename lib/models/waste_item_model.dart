// lib/models/waste_item_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class WasteItem {
  final String? id; 
  final String farmerId; 
  final String farmerName; 
  final String cropType; 
  final String wasteType; 
  final double quantity; 
  final String unit; 
  
  final String address; 
  final double latitude;
  final double longitude;

  final String? imageUrl; 
  final String status; 
  final Timestamp postedAt;
  final Timestamp? lastUpdatedAt;

  final double? suggestedPrice; 
  final String? autoCategorizedWasteType; 
  final List<String>? valorizationPathways; 
  final double? carbonSavedEstimate; 

  WasteItem({
    this.id,
    required this.farmerId,
    required this.farmerName,
    required this.cropType,
    required this.wasteType,
    required this.quantity,
    required this.unit,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.status = 'available', 
    required this.postedAt,
    this.lastUpdatedAt,
    this.suggestedPrice,
    this.autoCategorizedWasteType,
    this.valorizationPathways,
    this.carbonSavedEstimate,
  });

  factory WasteItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError("Missing data for WasteItem ${snapshot.id}");
    }
    
    return WasteItem(
      id: data['id'] ?? snapshot.id, // Use field 'id' if present, else snapshot.id
      farmerId: data['farmerId'] ?? '',
      farmerName: data['farmerName'] ?? '',
      cropType: data['cropType'] ?? '',
      wasteType: data['wasteType'] ?? '',
      quantity: (data['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: data['unit'] ?? 'kg',
      address: data['address'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['imageUrl'],
      status: data['status'] ?? 'available',
      postedAt: data['postedAt'] as Timestamp? ?? Timestamp.now(), 
      lastUpdatedAt: data['lastUpdatedAt'] as Timestamp?,
      suggestedPrice: (data['suggestedPrice'] as num?)?.toDouble(),
      autoCategorizedWasteType: data['autoCategorizedWasteType'],
      valorizationPathways: data['valorizationPathways'] != null ? List<String>.from(data['valorizationPathways']) : null,
      carbonSavedEstimate: (data['carbonSavedEstimate'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      // 'id': id, // ID is usually the document ID, not stored in fields unless necessary for specific queries
      'farmerId': farmerId,
      'farmerName': farmerName,
      'cropType': cropType,
      'wasteType': wasteType,
      'quantity': quantity,
      'unit': unit,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'status': status,
      'postedAt': postedAt, 
      'lastUpdatedAt': lastUpdatedAt ?? FieldValue.serverTimestamp(), 
      if (suggestedPrice != null) 'suggestedPrice': suggestedPrice,
      if (autoCategorizedWasteType != null) 'autoCategorizedWasteType': autoCategorizedWasteType,
      if (valorizationPathways != null) 'valorizationPathways': valorizationPathways,
      if (carbonSavedEstimate != null) 'carbonSavedEstimate': carbonSavedEstimate,
    };
  }
}

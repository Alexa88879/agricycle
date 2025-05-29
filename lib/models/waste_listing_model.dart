// lib/models/waste_listing_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class WasteListing {
  final String id;
  final String userId; // ID of the farmer who listed it
  final String? userEmail;
  final String? farmerName; // Denormalized for easier display on company dashboard
  final String? mediaUrl;
  final String? mediaType; // 'image' or 'video'
  final String? cropType; // e.g., 'Rice Straw', 'Sugarcane Bagasse'
  final String quantity; // e.g., '10 tons', '500 kg', '1000 bundles'
  final String location; // e.g., 'Village Name, District'
  final String? wasteType; // Primary category, e.g., 'Sugarcane Bagasse' (can be same as cropType or more specific)
  final String? specificItems; // e.g., 'Dried leaves and stalks'
  final String? conditionNotes; // e.g., 'Dry, ready for processing'
  final List<String>? suggestedUses; // e.g., ['Biofuel', 'Composting']
  final Map<String, String>? composition; // e.g., {'Cellulose': '40%', 'Lignin': '20%'}
  final String? suggestedPrice; // e.g., '₹1500 per ton'
  final String? co2SavedEstimate; // e.g., 'Approx 50kg CO2e offset per ton'
  final String? geminiRawResponse; // Full raw response from Gemini for reference
  final String status; // e.g., 'active', 'sold', 'pending_approval', 'expired'
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  WasteListing({
    required this.id,
    required this.userId,
    this.userEmail,
    this.farmerName,
    this.mediaUrl,
    this.mediaType,
    this.cropType,
    required this.quantity,
    required this.location,
    this.wasteType,
    this.specificItems,
    this.conditionNotes,
    this.suggestedUses,
    this.composition,
    this.suggestedPrice,
    this.co2SavedEstimate,
    this.geminiRawResponse,
    required this.status,
    required this.createdAt,
    this.updatedAt,
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
      farmerName: data['farmerName'] as String?, // Farmer's name
      mediaUrl: data['mediaUrl'] as String?,
      mediaType: data['mediaType'] as String?,
      cropType: data['cropType'] as String?,
      quantity: data['quantity'] ?? '',
      location: data['location'] ?? '',
      wasteType: data['wasteType'] as String?,
      specificItems: data['specificItems'] as String?,
      conditionNotes: data['conditionNotes'] as String?,
      suggestedUses: (data['suggestedUse'] as String?)?.split(',').map((e) => e.trim()).toList() ?? [], // Assuming comma-separated string
      composition: Map<String, String>.from(data['composition'] ?? {}),
      suggestedPrice: data['suggestedPrice'] as String?,
      co2SavedEstimate: data['co2SavedEstimate'] as String?,
      geminiRawResponse: data['geminiRawResponse'] as String?,
      status: data['status'] ?? 'unknown',
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'farmerName': farmerName,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'cropType': cropType,
      'quantity': quantity,
      'location': location,
      'wasteType': wasteType,
      'specificItems': specificItems,
      'conditionNotes': conditionNotes,
      'suggestedUse': suggestedUses?.join(', '), // Store as comma-separated string
      'composition': composition,
      'suggestedPrice': suggestedPrice,
      'co2SavedEstimate': co2SavedEstimate,
      'geminiRawResponse': geminiRawResponse,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }
}

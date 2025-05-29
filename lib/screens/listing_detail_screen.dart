// lib/screens/listing_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/waste_listing_model.dart';

class ListingDetailScreen extends StatefulWidget {
  static const String routeName = '/listing-detail';
  final String listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  Stream<WasteListing?>? _listingStream;

  @override
  void initState() {
    super.initState();
    _listingStream = FirebaseFirestore.instance
        .collection('wasteListings')
        .doc(widget.listingId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return WasteListing.fromFirestore(snapshot as DocumentSnapshot<Map<String, dynamic>>);
      }
      return null;
    }).handleError((error) {
      print("Error fetching listing details: $error");
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listing Details'),
      ),
      body: StreamBuilder<WasteListing?>(
        stream: _listingStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
                child: Text(snapshot.hasError ? 'Error: Could not load listing details.' : 'Listing not found.',
                style: TextStyle(color: theme.colorScheme.error, fontSize: 16)));
          }

          final listing = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (listing.mediaUrl != null && listing.mediaType == 'image')
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      listing.mediaUrl!,
                      width: double.infinity,
                      height: 280, // Increased height for detail view
                      fit: BoxFit.cover,
                       errorBuilder: (context, error, stackTrace) => Container(
                        height: 280,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12)
                        ),
                        child: Center(child: Icon(Icons.broken_image, color: Colors.grey.shade400, size: 60)),
                      ),
                       loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return SizedBox(
                          height: 280,
                          width: double.infinity,
                          child: Center(child: CircularProgressIndicator(
                             value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          )),
                        );
                      },
                    ),
                  )
                else if (listing.mediaType == 'video')
                   Container(
                      width: double.infinity,
                      height: 280,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: Icon(Icons.play_circle_outline, color: Colors.white, size: 80)),
                    )
                else
                  Container(
                    width: double.infinity,
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Icon(Icons.inventory_2_outlined, color: Colors.grey.shade400, size: 80)),
                  ),

                const SizedBox(height: 20),
                Text(
                  listing.wasteType ?? listing.cropType ?? 'Unknown Waste Type',
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(theme, Icons.scale_outlined, "Quantity:", listing.quantity),
                _buildDetailRow(theme, Icons.location_on_outlined, "Location:", listing.location),
                if (listing.farmerName != null && listing.farmerName!.isNotEmpty)
                  _buildDetailRow(theme, Icons.person_outline, "Listed by:", listing.farmerName!),
                if (listing.userEmail != null && listing.userEmail!.isNotEmpty)
                  _buildDetailRow(theme, Icons.email_outlined, "Contact:", listing.userEmail!),
                if (listing.suggestedUses != null && listing.suggestedUses!.isNotEmpty)
                  _buildDetailRow(theme, Icons.recycling_outlined, "Suggested Uses:", listing.suggestedUses?.join(', ') ?? 'N/A'),
                if (listing.suggestedPrice != null && listing.suggestedPrice!.isNotEmpty)
                  _buildDetailRow(theme, Icons.price_change_outlined, "Suggested Price:", listing.suggestedPrice!),
                 if (listing.co2SavedEstimate != null && listing.co2SavedEstimate!.isNotEmpty)
                  _buildDetailRow(theme, Icons.eco_outlined, "CO₂ Saved Est.:", listing.co2SavedEstimate!),
                 if (listing.conditionNotes != null && listing.conditionNotes!.isNotEmpty)
                  _buildDetailRow(theme, Icons.notes_outlined, "Condition/Notes:", listing.conditionNotes!),
                
                const SizedBox(height: 8),
                 Text(
                    "Listed on: ${DateFormat.yMMMd().add_jm().format(listing.createdAt.toDate())}",
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                  ),
                
                if (listing.geminiRawResponse != null && listing.geminiRawResponse!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: Text("View Full AI Analysis", style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w500)),
                    childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    tilePadding: EdgeInsets.zero,
                    initiallyExpanded: false,
                    children: [
                      SelectableText(listing.geminiRawResponse!, style: theme.textTheme.bodySmall),
                    ],
                  )
                ],
                
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.gavel_rounded),
                    label: const Text('Make an Offer / Contact Farmer'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Contact/Bidding (Not Implemented Yet)')),
                      );
                      // Implement contact or bidding functionality
                      // e.g., launch mailto:listing.userEmail or navigate to a chat screen
                    },
                  ),
                ),
                 const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.primaryColor.withOpacity(0.9)),
          const SizedBox(width: 12),
          Text("$label ", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, style: theme.textTheme.bodyLarge?.copyWith(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.85)))),
        ],
      ),
    );
  }
}

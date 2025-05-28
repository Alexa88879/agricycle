// lib/screens/company/waste_item_details_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../../models/waste_item_model.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

class WasteItemDetailsScreen extends StatelessWidget {
  const WasteItemDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final WasteItem? wasteItem = ModalRoute.of(context)?.settings.arguments as WasteItem?;

    if (wasteItem == null) {
      // Handle case where argument is not passed correctly
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Waste item details not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(wasteItem.wasteType),
        backgroundColor: kPrimarySwatch.shade500,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Image
            if (wasteItem.imageUrl != null && wasteItem.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                child: Image.network(
                  wasteItem.imageUrl!,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 250,
                      color: Colors.grey[300],
                      child: Icon(Icons.image_not_supported_outlined, size: 50, color: Colors.grey[600]),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: double.infinity,
                      height: 250,
                      color: Colors.grey[300],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                           color: kPrimarySwatch.shade600,
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                ),
                child: Icon(Icons.eco_outlined, size: 100, color: Colors.grey[400]),
              ),
            const SizedBox(height: kMediumPadding),

            // Waste Type and Crop Type
            Text(
              wasteItem.wasteType,
              style: kHeadlineStyle.copyWith(fontSize: 28, color: kPrimarySwatch.shade700),
            ),
            Text(
              'From: ${wasteItem.cropType}',
              style: kBodyTextStyle.copyWith(fontSize: 18, color: kSecondaryTextColor),
            ),
            const SizedBox(height: kDefaultPadding),
            Divider(color: kPrimarySwatch.shade200),
            const SizedBox(height: kDefaultPadding),

            // Quantity and Unit
            _buildDetailRow(Icons.inventory_2_outlined, 'Quantity:', '${wasteItem.quantity} ${wasteItem.unit}'),
            
            // Location
            _buildDetailRow(Icons.location_on_outlined, 'Location:', wasteItem.address),
            if (wasteItem.latitude != 0.0 && wasteItem.longitude != 0.0)
              Padding(
                padding: const EdgeInsets.only(left: 40.0, top: kSmallPadding / 2), // Indent lat/lng
                child: Text(
                  'Lat: ${wasteItem.latitude.toStringAsFixed(4)}, Lng: ${wasteItem.longitude.toStringAsFixed(4)}',
                  style: kSubtleTextStyle.copyWith(fontSize: 14),
                ),
              ),

            // Farmer Info
            _buildDetailRow(Icons.person_outline, 'Listed by:', wasteItem.farmerName),
            
            // Posted Date
            _buildDetailRow(
              Icons.calendar_today_outlined, 
              'Posted on:', 
              DateFormat('dd MMM, yyyy - hh:mm a').format(wasteItem.postedAt.toDate())
            ),

            // Status
             _buildDetailRow(
              Icons.info_outline, 
              'Status:', 
              wasteItem.status[0].toUpperCase() + wasteItem.status.substring(1),
              statusColor: wasteItem.status == 'available' ? kPrimarySwatch.shade600 : Colors.orange.shade700,
            ),


            const SizedBox(height: kMediumPadding * 1.5),

            // Action Button (Placeholder for now)
            CustomButton(
              text: 'Contact Farmer / Make Offer',
              icon: Icons.contact_mail_outlined,
              onPressed: () {
                // TODO: Implement contact or offer functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contact/Offer feature coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kSmallPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kPrimarySwatch.shade600, size: 22),
          const SizedBox(width: kDefaultPadding / 2),
          Text('$label ', style: kBodyTextStyle.copyWith(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(
              value, 
              style: kBodyTextStyle.copyWith(color: statusColor ?? kSecondaryTextColor),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

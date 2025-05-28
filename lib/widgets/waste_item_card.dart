// lib/widgets/waste_item_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/waste_item_model.dart';
import '../utils/constants.dart';

class WasteItemCard extends StatelessWidget {
  final WasteItem wasteItem;
  final VoidCallback onTap;

  const WasteItemCard({
    super.key,
    required this.wasteItem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      // Using CardTheme from main.dart for consistent styling
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kDefaultPadding / 2), // Match CardTheme
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(kDefaultPadding / 3),
                child: wasteItem.imageUrl != null && wasteItem.imageUrl!.isNotEmpty
                    ? Image.network(
                        wasteItem.imageUrl!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          Image.asset('assets/images/placeholder.png', width: 100, height: 100, fit: BoxFit.cover), // Local placeholder
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[200],
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2.0, color: kPrimarySwatch.shade300)),
                          );
                        },
                      )
                    : Image.asset('assets/images/placeholder.png', width: 100, height: 100, fit: BoxFit.cover), // Local placeholder
              ),
              const SizedBox(width: kDefaultPadding / 2),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wasteItem.wasteType,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: kPrimarySwatch.shade700,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'From: ${wasteItem.cropType}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: kSecondaryTextColor),
                       maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: kSmallPadding / 2),
                    Text(
                      '${wasteItem.quantity} ${wasteItem.unit}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: kSmallPadding / 2),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            wasteItem.address.split(',').first, // Show first part of address
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                            overflow: TextOverflow.ellipsis,
                             maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                     const SizedBox(height: kSmallPadding / 2),
                    Text(
                      'Posted: ${DateFormat('dd MMM, yy').format(wasteItem.postedAt.toDate())}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

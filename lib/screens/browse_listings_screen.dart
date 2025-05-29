// lib/screens/browse_listings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

import '../models/waste_listing_model.dart';
// import 'listing_detail_screen.dart'; // For future navigation

class BrowseListingsScreen extends StatefulWidget {
  static const String routeName = '/browse-listings';
  const BrowseListingsScreen({super.key});

  @override
  State<BrowseListingsScreen> createState() => _BrowseListingsScreenState();
}

class _BrowseListingsScreenState extends State<BrowseListingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Stream<List<WasteListing>>? _allActiveListingsStream;

  // State for filters
  String _searchTerm = "";
  String? _selectedCategory; // e.g., 'Rice Straw', 'Sugarcane Bagasse'
  String? _selectedLocation; // Could be a text field or dropdown of common locations

  // Sample categories - in a real app, these might be fetched or predefined more robustly
  final List<String> _wasteCategories = [
    'All Categories', 'Rice Straw', 'Wheat Straw', 'Corn Stover', 
    'Sugarcane Bagasse', 'Cotton Stalks', 'Banana Pseudostem', 
    'Jute Sticks', 'Other Agricultural Residue', 'Mixed Organic',
    'Paper', 'Plastic', 'Metal', 'Glass' // Added some non-agri for broader example
  ];


  @override
  void initState() {
    super.initState();
    _selectedCategory = _wasteCategories[0]; // Default to "All Categories"
    _loadAllActiveListings();
  }

  void _loadAllActiveListings() {
    Query query = _firestore.collection('wasteListings').where('status', isEqualTo: 'active').orderBy('createdAt', descending: true);

    if (_searchTerm.isNotEmpty) {
      // Basic search: checks wasteType, cropType, and location.
      // Firestore doesn't support case-insensitive search directly on multiple fields with OR.
      // For more advanced search, consider a third-party search service (e.g., Algolia) or
      // structuring your data for search (e.g., an array of keywords).
      // This is a simplified example. A common approach is to convert search term and fields to lowercase
      // and store a searchable array of keywords in your documents.
      // query = query.where('searchKeywords', arrayContains: _searchTerm.toLowerCase()); // Example if you have a searchKeywords field
    }

    if (_selectedCategory != null && _selectedCategory != 'All Categories') {
      // This assumes 'wasteType' or 'cropType' field stores the category.
      // You might need to query on both if the category could be in either.
      // For simplicity, let's assume it's primarily in 'wasteType' or 'cropType'.
       query = query.where('cropType', isEqualTo: _selectedCategory);
      // Or, if categories can also be in 'wasteType':
      // query = query.where('wasteType', isEqualTo: _selectedCategory);
    }
    
    if (_selectedLocation != null && _selectedLocation!.isNotEmpty) {
        // This is a simple exact match. For partial matches or radius search, more complex queries or services are needed.
        query = query.where('location', isEqualTo: _selectedLocation);
    }


    _allActiveListingsStream = query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => WasteListing.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
        .where((listing) {
          // Client-side filtering for search term if not handled by Firestore query directly
          // This is less efficient for large datasets but works for basic text matching.
          if (_searchTerm.isEmpty) return true;
          final searchTermLower = _searchTerm.toLowerCase();
          bool matches = (listing.wasteType?.toLowerCase().contains(searchTermLower) ?? false) ||
                         (listing.cropType?.toLowerCase().contains(searchTermLower) ?? false) ||
                         (listing.location.toLowerCase().contains(searchTermLower)) ||
                         (listing.suggestedUse?.toLowerCase().contains(searchTermLower) ?? false);
          return matches;
        })
        .toList());
    
    if(mounted) setState(() {}); // To rebuild with the new stream
  }
  
  void _onSearchChanged(String value) {
    setState(() {
      _searchTerm = value;
      _loadAllActiveListings(); // Re-fetch or re-filter
    });
  }

  void _onCategoryChanged(String? newValue) {
    setState(() {
      _selectedCategory = newValue;
      _loadAllActiveListings(); // Re-fetch or re-filter
    });
  }
  
  void _onLocationFilterChanged(String value) {
    setState(() {
      _selectedLocation = value.trim();
      _loadAllActiveListings();
    });
  }


  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Waste Listings'),
        elevation: 1,
      ),
      body: Column(
        children: [
          _buildFilterBar(theme),
          Expanded(
            child: StreamBuilder<List<WasteListing>>(
              stream: _allActiveListingsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print("Error in BrowseListingsScreen stream: ${snapshot.error}");
                  return Center(
                      child: Text("Error loading listings: ${snapshot.error}", style: TextStyle(color: theme.colorScheme.error)));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        "No active waste listings match your criteria.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  );
                }

                final listings = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    return _buildListingCard(context, listing, theme);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by type, crop, location...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  value: _selectedCategory,
                  isExpanded: true,
                  items: _wasteCategories.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: _onCategoryChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField( // Simple text field for location filter for now
                  decoration: InputDecoration(
                    hintText: 'Filter by Location',
                    prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14), // Adjusted padding
                  ),
                  onChanged: _onLocationFilterChanged, // Debounce might be good here in a real app
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildListingCard(BuildContext context, WasteListing listing, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      clipBehavior: Clip.antiAlias, // Ensures the InkWell ripple respects border radius
      child: InkWell(
        onTap: () {
          // Navigate to a detailed listing view
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tapped on ${listing.wasteType ?? listing.cropType}')),
          );
          // Navigator.pushNamed(context, ListingDetailScreen.routeName, arguments: listing.id);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (listing.mediaUrl != null && listing.mediaType == 'image')
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  listing.mediaUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade300,
                    child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 50)),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ));
                  },
                ),
              )
            else if (listing.mediaType == 'video')
               AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.black87,
                  child: Center(child: Icon(Icons.play_circle_outline, color: Colors.white, size: 60)),
                ),
              )
            else // Placeholder if no media or not an image
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.grey.shade200,
                  child: Center(child: Icon(Icons.inventory_2_outlined, color: Colors.grey.shade400, size: 60)),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.wasteType ?? listing.cropType ?? 'Unknown Waste',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.scale_outlined, size: 16, color: theme.hintColor),
                      const SizedBox(width: 4),
                      Expanded(child: Text('Quantity: ${listing.quantity}', style: theme.textTheme.bodyMedium)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: theme.hintColor),
                      const SizedBox(width: 4),
                      Expanded(child: Text('Location: ${listing.location}', style: theme.textTheme.bodyMedium)),
                    ],
                  ),
                   if (listing.farmerName != null && listing.farmerName!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                     Row(
                      children: [
                        Icon(Icons.person_outline, size: 16, color: theme.hintColor),
                        const SizedBox(width: 4),
                        Expanded(child: Text('Listed by: ${listing.farmerName}', style: theme.textTheme.bodySmall)),
                      ],
                    ),
                   ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Listed: ${DateFormat.yMMMd().format(listing.createdAt.toDate())}',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                      ),
                      if (listing.suggestedPrice != null && listing.suggestedPrice!.isNotEmpty)
                        Chip(
                          label: Text(listing.suggestedPrice!, style: TextStyle(color: theme.colorScheme.onSecondaryContainer, fontSize: 12, fontWeight: FontWeight.bold)),
                          backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          visualDensity: VisualDensity.compact,
                        )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

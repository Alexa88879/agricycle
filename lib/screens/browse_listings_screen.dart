// lib/screens/browse_listings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/waste_listing_model.dart';
import 'listing_detail_screen.dart'; // For navigation

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
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationFilterController = TextEditingController();
  String? _selectedCategory;

  // Sample categories - in a real app, these might be fetched or predefined more robustly
  final List<String> _wasteCategories = [
    'All Categories', 'Rice Straw', 'Wheat Straw', 'Corn Stover', 
    'Sugarcane Bagasse', 'Cotton Stalks', 'Banana Pseudostem', 
    'Jute Sticks', 'Other Agricultural Residue', 'Mixed Organic',
    'Paper', 'Plastic', 'Metal', 'Glass'
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = _wasteCategories[0]; // Default to "All Categories"
    _applyFiltersAndLoadListings(); // Initial load
     _searchController.addListener(() {
      if (mounted) {
        _applyFiltersAndLoadListings();
      }
    });
    _locationFilterController.addListener(() {
      if (mounted) {
        _applyFiltersAndLoadListings();
      }
    });
  }

  void _applyFiltersAndLoadListings() {
    Query query = _firestore
        .collection('wasteListings')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true);

    String searchTerm = _searchController.text.trim().toLowerCase();
    String locationTerm = _locationFilterController.text.trim().toLowerCase();

    // Note: Firestore's querying capabilities for partial text search are limited.
    // For robust search, consider a dedicated search service (e.g., Algolia) or
    // structuring your data with an array of searchable keywords.
    // The client-side filtering below will work for smaller datasets but is not ideal for large scale.

    if (_selectedCategory != null && _selectedCategory != 'All Categories') {
      // This assumes 'cropType' is the primary field for agricultural categories.
      // You might need to adjust if 'wasteType' also holds these.
      query = query.where('cropType', isEqualTo: _selectedCategory);
      // If you also want to check wasteType for the same category:
      // query = query.where('wasteType', isEqualTo: _selectedCategory); // This would be an AND, not OR
    }

    // For location, Firestore equality check is simple. Partial match needs client-side or different data structure.
    // If locationTerm is not empty, we might need to do more client-side filtering if exact match isn't desired.

    _allActiveListingsStream = query.snapshots().map((snapshot) {
      var listings = snapshot.docs
          .map((doc) => WasteListing.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();

      // Client-side filtering for search term and location (if not perfectly handled by query)
      if (searchTerm.isNotEmpty) {
        listings = listings.where((listing) {
          return (listing.wasteType?.toLowerCase().contains(searchTerm) ?? false) ||
                 (listing.cropType?.toLowerCase().contains(searchTerm) ?? false) ||
                 (listing.specificItems?.toLowerCase().contains(searchTerm) ?? false) ||
                 (listing.farmerName?.toLowerCase().contains(searchTerm) ?? false);
        }).toList();
      }
      if (locationTerm.isNotEmpty) {
         listings = listings.where((listing) {
          return (listing.location.toLowerCase().contains(locationTerm));
        }).toList();
      }
      return listings;
    }).handleError((error){
      print("Error in _allActiveListingsStream: $error");
      return <WasteListing>[];
    });
    
    if(mounted) setState(() {});
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _locationFilterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Active Listings'),
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
                  print("Error in BrowseListingsScreen stream builder: ${snapshot.error}");
                  return Center(
                      child: Text("Error loading listings. Please try again.", style: TextStyle(color: theme.colorScheme.error)));
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
      padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 8.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by type, crop, farmer...',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        // _applyFiltersAndLoadListings(); // Listener will trigger this
                      },
                    )
                  : null,
            ),
            // onChanged: (value) => _applyFiltersAndLoadListings(), // Listener does this
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    // labelText: 'Category',
                    hintText: 'Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  value: _selectedCategory,
                  isExpanded: true,
                  items: _wasteCategories.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                      _applyFiltersAndLoadListings();
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _locationFilterController,
                  decoration: InputDecoration(
                    hintText: 'Filter by Location',
                    prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                     suffixIcon: _locationFilterController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _locationFilterController.clear();
                               // _applyFiltersAndLoadListings(); // Listener will trigger this
                            },
                          )
                        : null,
                  ),
                  // onChanged: (value) => _applyFiltersAndLoadListings(), // Listener does this
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, ListingDetailScreen.routeName, arguments: listing.id);
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
                    color: Colors.grey.shade200,
                    child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40)),
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
                  color: Colors.black,
                  child: const Center(child: Icon(Icons.play_circle_outline, color: Colors.white, size: 50)),
                ),
              )
            else
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.grey.shade200,
                  child: Center(child: Icon(Icons.inventory_2_outlined, color: Colors.grey.shade400, size: 50)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.wasteType ?? listing.cropType ?? 'Unknown Waste',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quantity: ${listing.quantity}',
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Location: ${listing.location}',
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (listing.farmerName != null && listing.farmerName!.isNotEmpty)
                    Text(
                      'By: ${listing.farmerName}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Listed: ${DateFormat.yMMMd().format(listing.createdAt.toDate())}',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (listing.suggestedPrice != null && listing.suggestedPrice!.isNotEmpty)
                        Chip(
                          label: Text(
                            listing.suggestedPrice!,
                            style: TextStyle(color: theme.colorScheme.onSecondaryContainer, fontSize: 11, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.7),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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

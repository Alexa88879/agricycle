// lib/screens/my_listings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/waste_listing_model.dart';
import 'listing_detail_screen.dart'; // For navigation

class MyListingsScreen extends StatefulWidget {
  static const String routeName = '/my-listings';
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Stream<List<WasteListing>>? _myListingsStream;

  // State for filters
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus;

  // Status options for filtering
  final List<String> _statusOptions = [
    'All Statuses', 'active', 'sold', 'expired', 'pending_approval'
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = _statusOptions[0]; // Default to "All Statuses"
    _loadMyListings(); // Initial load
    _searchController.addListener(() {
      if (mounted) {
        _loadMyListings();
      }
    });
  }

  void _loadMyListings() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    Query query = _firestore
        .collection('wasteListings')
        .where('userId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true);

    String searchTerm = _searchController.text.trim().toLowerCase();

    if (_selectedStatus != null && _selectedStatus != 'All Statuses') {
      query = query.where('status', isEqualTo: _selectedStatus);
    }

    _myListingsStream = query.snapshots().map((snapshot) {
      var listings = snapshot.docs
          .map((doc) => WasteListing.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();

      // Client-side filtering for search term
      if (searchTerm.isNotEmpty) {
        listings = listings.where((listing) {
          return (listing.wasteType?.toLowerCase().contains(searchTerm) ?? false) ||
                 (listing.cropType?.toLowerCase().contains(searchTerm) ?? false) ||
                 (listing.specificItems?.toLowerCase().contains(searchTerm) ?? false) ||
                 (listing.location.toLowerCase().contains(searchTerm));
        }).toList();
      }
      return listings;
    }).handleError((error){
      print("Error in _myListingsStream: $error");
      return <WasteListing>[];
    });
    
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        elevation: 1,
      ),
      body: Column(
        children: [
          _buildFilterBar(theme),
          Expanded(
            child: StreamBuilder<List<WasteListing>>(
              stream: _myListingsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error loading listings: ${snapshot.error}",
                      style: TextStyle(color: theme.colorScheme.error)),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text("You don't have any listings yet.",
                      style: TextStyle(fontSize: 16)),
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
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search your listings',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                hintText: 'Status',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              value: _selectedStatus,
              isExpanded: true,
              items: _statusOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedStatus = newValue;
                  _loadMyListings();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(BuildContext context, WasteListing listing, ThemeData theme) {
    // Get status color and display text
    Color statusColor;
    String statusDisplay;
    
    switch(listing.status.toLowerCase()) {
      case 'active':
        statusColor = Colors.green;
        statusDisplay = 'Active';
        break;
      case 'sold':
        statusColor = Colors.blue;
        statusDisplay = 'Sold';
        break;
      case 'expired':
        statusColor = Colors.red;
        statusDisplay = 'Expired';
        break;
      case 'pending_approval':
        statusColor = Colors.orange;
        statusDisplay = 'Pending';
        break;
      default:
        statusColor = Colors.grey;
        statusDisplay = listing.status.isEmpty ? 'Unknown' : listing.status;
    }

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
                    child: Center(child: Icon(Icons.broken_image, color: Colors.grey.shade400, size: 50)),
                  ),
                ),
              )
            else if (listing.mediaUrl != null && listing.mediaType == 'video')
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
                  // Fix for the first row with title and status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start, // Align to top
                    children: [
                      Expanded(
                        flex: 3, // Give more space to the title
                        child: Text(
                          listing.wasteType ?? listing.cropType ?? 'Unknown Waste Type',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8), // Add spacing between title and chip
                      Chip(
                        label: Text(
                          statusDisplay,
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                          maxLines: 1,
                        ),
                        backgroundColor: statusColor,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
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
                  const SizedBox(height: 6),
                  // Fix for the bottom row with date and price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 2, // Give more space to the date
                        child: Text(
                          'Listed: ${DateFormat.yMMMd().format(listing.createdAt.toDate())}',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (listing.suggestedPrice != null && listing.suggestedPrice!.isNotEmpty) ...[  
                        const SizedBox(width: 8), // Add spacing between date and price chip
                        Chip(
                          label: Text(
                            listing.suggestedPrice!,
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onPrimaryContainer),
                            maxLines: 1,
                          ),
                          backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.7),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                          visualDensity: VisualDensity.compact,
                        )
                      ]
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
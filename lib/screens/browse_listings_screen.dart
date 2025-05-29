// lib/screens/browse_listings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/waste_listing_model.dart';
import 'listing_detail_screen.dart';

class BrowseListingsScreen extends StatefulWidget {
  static const String routeName = '/browse-listings';
  final String? specificUserId;
  final String? initialSearchQuery;

  const BrowseListingsScreen({
    super.key,
    this.specificUserId,
    this.initialSearchQuery,
  });

  @override
  State<BrowseListingsScreen> createState() => _BrowseListingsScreenState();
}

class _BrowseListingsScreenState extends State<BrowseListingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Stream<List<WasteListing>>? _allActiveListingsStream;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationFilterController = TextEditingController();
  String? _selectedCategory;
  String? _selectedStatus = 'All Statuses';

  final List<String> _wasteCategories = [
    'All Categories', 'Rice Straw', 'Wheat Straw', 'Corn Stover',
    'Sugarcane Bagasse', 'Cotton Stalks', 'Banana Pseudostem',
    'Jute Sticks', 'Other Agricultural Residue', 'Mixed Organic',
    'Paper', 'Plastic', 'Metal', 'Glass'
  ];
  final List<String> _statuses = ['All Statuses', 'active', 'sold', 'pending_approval', 'expired'];

  @override
  void initState() {
    super.initState();
    _selectedCategory = _wasteCategories[0];
    if (widget.initialSearchQuery != null) {
      _searchController.text = widget.initialSearchQuery!;
    }
    _applyFiltersAndLoadListings();
    _searchController.addListener(_onFilterChanged);
    _locationFilterController.addListener(_onFilterChanged);
  }

  void _onFilterChanged() {
    if (mounted) {
      _applyFiltersAndLoadListings();
    }
  }

  void _applyFiltersAndLoadListings() {
    Query query = _firestore.collection('wasteListings');

    String searchTerm = _searchController.text.trim().toLowerCase();
    String locationTerm = _locationFilterController.text.trim().toLowerCase();

    if (widget.specificUserId != null) {
      query = query.where('userId', isEqualTo: widget.specificUserId);
    }

    if (_selectedStatus != null && _selectedStatus != 'All Statuses') {
      query = query.where('status', isEqualTo: _selectedStatus);
    }

    if (_selectedCategory != null && _selectedCategory != 'All Categories') {
      query = query.where('wasteType', isEqualTo: _selectedCategory);
    }
    
    query = query.orderBy('createdAt', descending: true);

    _allActiveListingsStream = query.snapshots().map((snapshot) {
      var listings = snapshot.docs
          .map((doc) => WasteListing.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();

      if (searchTerm.isNotEmpty) {
        listings = listings.where((listing) {
          final title = listing.wasteType?.toLowerCase() ?? listing.cropType?.toLowerCase() ?? '';
          final farmer = listing.farmerName?.toLowerCase() ?? '';
          final items = listing.specificItems?.toLowerCase() ?? '';
          final price = listing.suggestedPrice?.toLowerCase() ?? '';
          return title.contains(searchTerm) ||
                 farmer.contains(searchTerm) ||
                 items.contains(searchTerm) ||
                 price.contains(searchTerm);
        }).toList();
      }
      if (locationTerm.isNotEmpty) {
        listings = listings.where((listing) {
          return (listing.location.toLowerCase().contains(locationTerm));
        }).toList();
      }
      return listings;
    }).handleError((error) {
      print("Error in _allActiveListingsStream: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error loading listings: ${error.toString()}")));
      }
      return <WasteListing>[];
    });

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_onFilterChanged);
    _locationFilterController.removeListener(_onFilterChanged);
    _searchController.dispose();
    _locationFilterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final appBarTitle = widget.specificUserId != null ? 'My Listings' : 'Browse Agri-Waste';

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
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
                  return Center(
                      child: Text("Error: ${snapshot.error}",
                          style: TextStyle(color: theme.colorScheme.error)));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        "No listings match your criteria.\nTry adjusting your filters.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  );
                }

                final listings = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    // Using the new alternative card design
                    return _buildListingCardRedesignedAlt(context, listing, theme);
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
              hintText: widget.specificUserId != null ? 'Search your listings...' : 'Search by type, crop, farmer...',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    hintText: 'Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    hintText: 'Status',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  value: _selectedStatus,
                  isExpanded: true,
                  items: _statuses.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedStatus = newValue;
                      _applyFiltersAndLoadListings();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _locationFilterController,
            decoration: InputDecoration(
              hintText: 'Filter by Location...',
              prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              suffixIcon: _locationFilterController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => _locationFilterController.clear(),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // Alternative Listing Card Design
  Widget _buildListingCardRedesignedAlt(BuildContext context, WasteListing listing, ThemeData theme) {
    Color statusColor = Colors.grey.shade400;
    String statusText = listing.status.isNotEmpty ? listing.status[0].toUpperCase() + listing.status.substring(1) : "Unknown";

    switch (listing.status) {
      case 'active': statusColor = theme.colorScheme.primary; break;
      case 'sold': statusColor = Colors.blueGrey.shade500; break;
      case 'pending_approval': statusColor = Colors.orange.shade700; break;
      case 'expired': statusColor = Colors.red.shade700; break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, ListingDetailScreen.routeName, arguments: listing.id);
        },
        child: SizedBox( // Constrain height of the card
          height: 150, // Adjust height as needed
          child: Row(
            children: [
              // Image Section (Left)
              SizedBox(
                width: 130, // Fixed width for the image
                height: double.infinity, // Take full height of the card
                child: listing.mediaUrl != null && listing.mediaType == 'image'
                    ? CachedNetworkImage(
                        imageUrl: listing.mediaUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 30)),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade300,
                        child: Center(
                          child: Icon(
                            listing.mediaType == 'video' ? Icons.videocam_outlined : Icons.inventory_2_outlined,
                            color: Colors.grey.shade600,
                            size: 40,
                          ),
                        ),
                      ),
              ),
              // Details Section (Right)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute space
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing.wasteType ?? listing.cropType ?? 'Unknown Waste Type',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          _buildDetailItem(theme, Icons.scale_outlined, listing.quantity, size: 13),
                          _buildDetailItem(theme, Icons.location_on_outlined, listing.location, size: 13, maxLines: 1),
                        ],
                      ),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (listing.suggestedPrice != null && listing.suggestedPrice!.isNotEmpty)
                            Flexible( // Use Flexible for price to allow it to take space but not overflow
                              child: Text(
                                listing.suggestedPrice!,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.secondary,
                                  fontSize: 14
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          const Spacer(), // Pushes status chip to the right
                           Chip(
                            label: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
                            backgroundColor: statusColor,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                            labelPadding: const EdgeInsets.symmetric(horizontal: 2.0),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(ThemeData theme, IconData icon, String text, {double size = 14, int maxLines = 2}) {
    return Padding(
      padding: const EdgeInsets.only(top: 3.0),
      child: Row(
        children: [
          Icon(icon, size: size + 1, color: theme.colorScheme.onSurface.withOpacity(0.7)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: size, color: theme.colorScheme.onSurface.withOpacity(0.9)),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Original card design - kept for reference or if you want to switch back
  Widget _buildListingCardOriginal(BuildContext context, WasteListing listing, ThemeData theme) {
    Color statusColor = Colors.grey.shade400;
    String statusText = listing.status.isNotEmpty ? listing.status[0].toUpperCase() + listing.status.substring(1) : "Unknown";

    switch (listing.status) {
      case 'active': statusColor = Colors.green.shade600; break;
      case 'sold': statusColor = Colors.blue.shade600; break;
      case 'pending_approval': statusColor = Colors.orange.shade600; break;
      case 'expired': statusColor = Colors.red.shade600; break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, ListingDetailScreen.routeName, arguments: listing.id);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: listing.mediaUrl != null && listing.mediaType == 'image'
                      ? CachedNetworkImage(
                          imageUrl: listing.mediaUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40)),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade300,
                          child: Center(
                            child: Icon(
                              listing.mediaType == 'video' ? Icons.videocam_outlined : Icons.inventory_2_outlined,
                              color: Colors.grey.shade600,
                              size: 50,
                            ),
                          ),
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Chip(
                    label: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    backgroundColor: statusColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.wasteType ?? listing.cropType ?? 'Unknown Waste Type',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _buildInfoRowOriginal(theme, Icons.scale_outlined, 'Quantity:', listing.quantity),
                  _buildInfoRowOriginal(theme, Icons.location_on_outlined, 'Location:', listing.location),
                  if (listing.farmerName != null && listing.farmerName!.isNotEmpty)
                     _buildInfoRowOriginal(theme, Icons.person_outline, 'Listed by:', listing.farmerName!),
                  
                  const SizedBox(height: 8),
                  if (listing.suggestedPrice != null && listing.suggestedPrice!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        listing.suggestedPrice!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Listed: ${DateFormat.yMMMd().format(listing.createdAt.toDate())}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRowOriginal(ThemeData theme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.85)),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

}

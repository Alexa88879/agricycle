// lib/screens/browse_listings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/waste_listing_model.dart';
import 'listing_detail_screen.dart'; // For navigation

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Listings'),
      ),
      body: Column(
        children: [
          // TODO: Implement listing view and filters
          const Center(
            child: Text('Listings will be displayed here'),
          ),
        ],
      ),
    );
  }
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Stream<List<WasteListing>>? _allActiveListingsStream;

  // State for filters
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationFilterController = TextEditingController();
  String? _selectedCategory;
  String? _selectedStatus = 'All Statuses'; // Added for status filter

  // Sample categories - in a real app, these might be fetched or predefined more robustly
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
    _selectedCategory = _wasteCategories[0]; // Default to "All Categories"
    
    // Initialize search controller with initialSearchQuery if provided
    if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty) {
      _searchController.text = widget.initialSearchQuery!;
    }
    
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
    Query query = _firestore.collection('wasteListings');
    
    // Filter by specificUserId if provided
    if (widget.specificUserId != null && widget.specificUserId!.isNotEmpty) {
      query = query.where('userId', isEqualTo: widget.specificUserId);
    }
    
    // ... existing filtering code ...
}
} // Closing brace for _BrowseListingsScreenState class

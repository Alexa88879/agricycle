// lib/screens/company/waste_listings_screen.dart
import 'package:flutter/material.dart';
import 'package:modern_auth_app/models/waste_item_model.dart'; //
import 'package:modern_auth_app/services/firestore_service.dart'; //
import 'package:modern_auth_app/widgets/waste_item_card.dart'; //
import 'package:modern_auth_app/utils/constants.dart'; //
import 'package:modern_auth_app/utils/routes.dart'; //

class WasteListingsScreen extends StatefulWidget {
  const WasteListingsScreen({super.key});

  @override
  State<WasteListingsScreen> createState() => _WasteListingsScreenState();
}

class _WasteListingsScreenState extends State<WasteListingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _searchTerm = '';
  String? _selectedWasteTypeFilter;
  // Add other filter states here e.g., quantity, state

  // Debounce for search term
  // Timer? _debounce;

  // @override
  // void dispose() {
  //   _debounce?.cancel();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waste Marketplace'),
        backgroundColor: kPrimarySwatch.shade500, //
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<List<WasteItem>>(
              stream: _firestoreService.getWasteItems(
                // Pass filter parameters here once FirestoreService is updated
                // wasteType: _selectedWasteTypeFilter,
                // searchTerm: _searchTerm (for client-side filtering or specific backend search)
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: kPrimarySwatch.shade600)); //
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}')); //
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center( //
                    child: Padding(
                      padding: EdgeInsets.all(kDefaultPadding),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.eco_outlined, size: 80, color: Colors.grey),
                          SizedBox(height: kDefaultPadding),
                          Text(
                            'No agricultural waste items currently match your criteria.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                List<WasteItem> wasteItems = snapshot.data!;
                
                // Apply client-side filtering (simple version)
                if (_searchTerm.isNotEmpty) {
                  wasteItems = wasteItems.where((item) =>
                    item.wasteType.toLowerCase().contains(_searchTerm.toLowerCase()) ||
                    item.cropType.toLowerCase().contains(_searchTerm.toLowerCase()) ||
                    item.address.toLowerCase().contains(_searchTerm.toLowerCase())
                  ).toList();
                }
                if (_selectedWasteTypeFilter != null) {
                    wasteItems = wasteItems.where((item) => item.wasteType == _selectedWasteTypeFilter).toList();
                }


                if (wasteItems.isEmpty) {
                     return const Center(
                        child: Padding(
                        padding: EdgeInsets.all(kDefaultPadding),
                        child: Text(
                            'No items match your current filters.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        ),
                    );
                }


                return ListView.builder(
                  padding: const EdgeInsets.all(kSmallPadding / 2), //
                  itemCount: wasteItems.length,
                  itemBuilder: (context, index) {
                    final item = wasteItems[index];
                    return WasteItemCard(
                      wasteItem: item,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.wasteDetails,
                          arguments: item,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(kSmallPadding),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by type, crop, location...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: kDefaultPadding),
            ),
            onChanged: (value) {
              // // Debouncing logic
              // if (_debounce?.isActive ?? false) _debounce!.cancel();
              // _debounce = Timer(const Duration(milliseconds: 500), () {
                setState(() {
                  _searchTerm = value;
                });
              // });
            },
          ),
          const SizedBox(height: kSmallPadding),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    hintText: 'Filter by Waste Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: kSmallPadding),
                     fillColor: Colors.white,
                    filled: true,
                  ),
                  value: _selectedWasteTypeFilter,
                  items: [
                     const DropdownMenuItem<String>(
                      value: null, // Represents 'All'
                      child: Text('All Waste Types'),
                    ),
                    ...kCommonWasteTypes.map((String value) { //
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList()],
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedWasteTypeFilter = newValue;
                    });
                  },
                ),
              ),
              // Add more filters for quantity, state (location) here
              // e.g., IconButton for location filter, RangeSlider for quantity
            ],
          ),
        ],
      ),
    );
  }
}
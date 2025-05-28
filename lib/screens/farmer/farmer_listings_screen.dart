// lib/screens/farmer/farmer_listings_screen.dart
import 'package:flutter/material.dart';
import 'package:modern_auth_app/models/waste_item_model.dart'; //
import 'package:modern_auth_app/services/auth_service.dart'; //
import 'package:modern_auth_app/services/firestore_service.dart'; //
import 'package:modern_auth_app/widgets/waste_item_card.dart'; //
import 'package:modern_auth_app/utils/constants.dart'; //
import 'package:modern_auth_app/utils/routes.dart'; //

class FarmerListingsScreen extends StatefulWidget {
  const FarmerListingsScreen({super.key});

  @override
  State<FarmerListingsScreen> createState() => _FarmerListingsScreenState();
}

class _FarmerListingsScreenState extends State<FarmerListingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  String? _currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    setState(() => _isLoading = true);
    _currentUserId = _authService.getCurrentUser()?.uid;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
          appBar: AppBar(title: const Text('My Waste Listings')),
          body: Center(child: CircularProgressIndicator(color: kPrimarySwatch.shade600)));
    }
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Waste Listings')),
        body: const Center(
            child: Text('Could not load user information. Please log in again.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Waste Listings'),
        backgroundColor: kPrimarySwatch.shade500,
      ),
      body: StreamBuilder<List<WasteItem>>(
        stream: _firestoreService.getFarmerWasteItems(_currentUserId!), //
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: kPrimarySwatch.shade600));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(kDefaultPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.eco_outlined, size: 80, color: Colors.grey),
                    SizedBox(height: kDefaultPadding),
                    Text(
                      'You have not listed any agricultural waste yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          final wasteItems = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(kSmallPadding / 2),
            itemCount: wasteItems.length,
            itemBuilder: (context, index) {
              final item = wasteItems[index];
              return WasteItemCard(
                wasteItem: item,
                onTap: () {
                  // Farmers might want to edit or see details differently.
                  // For now, navigate to the same details screen.
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
    );
  }
}
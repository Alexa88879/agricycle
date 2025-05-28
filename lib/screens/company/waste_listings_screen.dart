// lib/screens/company/waste_listings_screen.dart
import 'package:flutter/material.dart';
import '../../models/waste_item_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/waste_item_card.dart';
import '../../utils/constants.dart';
import '../../utils/routes.dart';

class WasteListingsScreen extends StatefulWidget {
  const WasteListingsScreen({super.key});

  @override
  State<WasteListingsScreen> createState() => _WasteListingsScreenState();
}

class _WasteListingsScreenState extends State<WasteListingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waste Marketplace'),
        backgroundColor: kPrimarySwatch.shade500,
      ),
      body: StreamBuilder<List<WasteItem>>(
        stream: _firestoreService.getWasteItems(),
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
                      'No agricultural waste items currently listed.',
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
            padding: const EdgeInsets.all(kSmallPadding / 2), // Minimal padding around the list
            itemCount: wasteItems.length,
            itemBuilder: (context, index) {
              final item = wasteItems[index];
              return WasteItemCard(
                wasteItem: item,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.wasteDetails,
                    arguments: item, // Pass the whole WasteItem object
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

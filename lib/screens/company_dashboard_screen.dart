// lib/screens/company_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting

import '../services/auth_service.dart';
import '../models/waste_listing_model.dart'; // Import the model
import 'browse_listings_screen.dart'; // Import the new screen
// import 'map_view_screen.dart'; // Placeholder for future screen
// import 'market_trends_screen.dart'; // Placeholder for future screen
// import 'my_bids_offers_screen.dart'; // Placeholder for future screen

class CompanyDashboardScreen extends StatefulWidget {
  static const String routeName = '/company-dashboard';

  const CompanyDashboardScreen({super.key});

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<WasteListing>>? _activeListingsStream;
  int _totalActiveListingsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
  }

  void _loadCompanyData() {
    // Stream for active listings count
    _firestore
        .collection('wasteListings')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _totalActiveListingsCount = snapshot.docs.length;
        });
      }
    });

    // Stream for a limited number of recent active listings for the dashboard preview
    _activeListingsStream = _firestore
        .collection('wasteListings')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(5) // Show a few recent ones on the dashboard
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WasteListing.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();
      // AuthGate will handle navigation
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _authService.currentUser;
    final String userName =
        currentUser?.displayName ?? currentUser?.email ?? "Company User";
    ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Re-trigger data loading if necessary, though streams update automatically
              setState(() {
                // If you had one-time fetches, you'd re-call them here.
                // For streams, this can just force a rebuild if needed.
                _loadCompanyData();
              });
            },
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          Text(
            'Welcome, $userName!',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Access tools to find waste listings, analyze market trends, and manage your bids.',
            style: theme.textTheme.titleMedium?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 24),
          _buildStatsOverview(theme),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1, // Adjusted for potentially more text
            children: [
              _buildDashboardCard(
                context,
                icon: Icons.search_outlined,
                title: 'Browse All Listings',
                onTap: () {
                  Navigator.pushNamed(context, BrowseListingsScreen.routeName);
                },
              ),
              _buildDashboardCard(
                context,
                icon: Icons.map_outlined,
                title: 'Map View',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Map View (Not Implemented Yet)')),
                  );
                  // Example: Navigator.pushNamed(context, MapViewScreen.routeName);
                },
              ),
              _buildDashboardCard(
                context,
                icon: Icons.trending_up_outlined,
                title: 'Market Trends',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Market Trends (Not Implemented Yet)')),
                  );
                  // Example: Navigator.pushNamed(context, MarketTrendsScreen.routeName);
                },
              ),
              _buildDashboardCard(
                context,
                icon: Icons.gavel_outlined, // Changed from business_center
                title: 'My Bids/Offers',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('My Bids/Offers (Not Implemented Yet)')),
                  );
                  // Example: Navigator.pushNamed(context, MyBidsOffersScreen.routeName);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildRecentListingsSection(theme),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Market Overview", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatPill(theme, Icons.list_alt_outlined, "Active Listings", _totalActiveListingsCount.toString(), Colors.blue.shade700),
                _buildStatPill(theme, Icons.local_shipping_outlined, "Bids Made", "0", Colors.orange.shade700), // Placeholder
                _buildStatPill(theme, Icons.check_circle_outline, "Acquired", "0", Colors.green.shade700), // Placeholder
              ],
            )
          ],
        ),
      )
    );
  }

  Widget _buildStatPill(ThemeData theme, IconData icon, String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color)),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
      ],
    );
  }

  Widget _buildDashboardCard(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    ThemeData theme = Theme.of(context);
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 36.0, color: theme.primaryColor),
              const SizedBox(height: 10.0),
              Text(title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentListingsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recently Added Listings",
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<WasteListing>>(
          stream: _activeListingsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text("Error loading listings: ${snapshot.error}", style: TextStyle(color: theme.colorScheme.error));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("No active waste listings found at the moment.", style: TextStyle(fontSize: 16, color: Colors.grey)),
                ),
              );
            }
            final listings = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: listings.length,
              itemBuilder: (context, index) {
                final listing = listings[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    leading: listing.mediaUrl != null && listing.mediaType == 'image'
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4.0),
                            child: Image.network(
                              listing.mediaUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, size: 50),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const SizedBox(width: 50, height: 50, child: Center(child: CircularProgressIndicator(strokeWidth: 2,)));
                              },
                            ),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Icon(listing.mediaType == 'video' ? Icons.videocam_outlined : Icons.image_not_supported_outlined, color: Colors.grey.shade700),
                          ),
                    title: Text(listing.wasteType ?? listing.cropType ?? 'Unknown Waste Type', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Quantity: ${listing.quantity}"),
                        Text("Location: ${listing.location}"),
                        Text("Listed: ${DateFormat.yMMMd().add_jm().format(listing.createdAt.toDate())}", style: theme.textTheme.bodySmall),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.hintColor),
                    onTap: () {
                      // Navigate to ListingDetailScreen (placeholder for now)
                       ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('View details for ${listing.wasteType ?? listing.cropType}')),
                      );
                      // Navigator.pushNamed(context, ListingDetailScreen.routeName, arguments: listing.id);
                    },
                  ),
                );
              },
            );
          },
        ),
         if (_totalActiveListingsCount > 5)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, BrowseListingsScreen.routeName);
                },
                child: const Text("View All Active Listings"),
              ),
            ),
          ),
      ],
    );
  }
}

// lib/screens/company_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../services/auth_service.dart';
import '../models/waste_listing_model.dart';
import 'browse_listings_screen.dart';
import 'listing_detail_screen.dart'; 
import 'market_trends_screen.dart'; // Import the MarketTrendsScreen

class CompanyDashboardScreen extends StatefulWidget {
  static const String routeName = '/company-dashboard';

  const CompanyDashboardScreen({super.key});

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<WasteListing>>? _recentActiveListingsStream;
  int _totalActiveListingsCount = 0;
  // Add more state for other stats if needed, e.g., bids made, acquired items

  @override
  void initState() {
    super.initState();
    _loadCompanyDashboardData();
  }

  void _loadCompanyDashboardData() {
    // Stream for total active listings count
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
    }, onError: (error) {
      print("Error listening to active listings count: $error");
      if (mounted) {
        // Optionally show a subtle error to the user or log it
      }
    });

    // Stream for a limited number of recent active listings for the dashboard preview
    _recentActiveListingsStream = _firestore
        .collection('wasteListings')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(5) // Show a few recent ones on the dashboard
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
            .map((doc) => WasteListing.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList();
        })
        .handleError((error) {
           print("Error fetching recent active listings: $error");
           if (mounted) {
            // Optionally show a subtle error to the user or log it
           }
           return <WasteListing>[]; // Return empty list on error
        });
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
              if(mounted) {
                setState(() {
                  _loadCompanyDashboardData(); // Re-fetch data
                });
              }
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
            'Discover waste listings, track market data, and manage your procurement.',
            style: theme.textTheme.titleMedium?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 24),
          _buildStatsOverview(theme),
          const SizedBox(height: 24),
          _buildActionGrid(context, theme),
          const SizedBox(height: 24),
          _buildRecentListingsSection(theme),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(ThemeData theme) {
    // Placeholder values for bids and acquired, replace with actual data fetching
    int bidsMade = 0; 
    int itemsAcquired = 0;

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
                _buildStatPill(theme, Icons.gavel_outlined, "Bids Made", bidsMade.toString(), Colors.orange.shade700),
                _buildStatPill(theme, Icons.check_circle_outline, "Items Acquired", itemsAcquired.toString(), Colors.green.shade700),
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

  Widget _buildActionGrid(BuildContext context, ThemeData theme) {
     return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), 
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.15,
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
                  // Placeholder for Map View
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Map View (Not Implemented Yet)')),
                  );
                },
              ),
              _buildDashboardCard(
                context,
                icon: Icons.trending_up_outlined, // Changed Icon
                title: 'Market Trends',
                onTap: () {
                  // Navigate to MarketTrendsScreen
                  Navigator.pushNamed(context, MarketTrendsScreen.routeName);
                },
              ),
              _buildDashboardCard(
                context,
                icon: Icons.gavel_outlined,
                title: 'My Bids/Offers',
                onTap: () {
                  // Placeholder for My Bids/Offers
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('My Bids/Offers (Not Implemented Yet)')),
                  );
                },
              ),
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
          stream: _recentActiveListingsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return Text("Error loading recent listings: ${snapshot.error}", style: TextStyle(color: theme.colorScheme.error));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
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
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                    leading: listing.mediaUrl != null && listing.mediaType == 'image'
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6.0),
                            child: Image.network(
                              listing.mediaUrl!,
                              width: 70, 
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(width: 70, height: 70, color: Colors.grey.shade200, child: const Icon(Icons.broken_image, size: 30, color: Colors.grey)),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return SizedBox(width: 70, height: 70, child: Center(child: CircularProgressIndicator(strokeWidth: 2.5, value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null)));
                              },
                            ),
                          )
                        : Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: Icon(listing.mediaType == 'video' ? Icons.videocam_outlined : Icons.image_not_supported_outlined, color: Colors.grey.shade600, size: 30),
                          ),
                    title: Text(listing.wasteType ?? listing.cropType ?? 'Unknown Waste', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text("Qty: ${listing.quantity}", style: theme.textTheme.bodyMedium),
                        Text("Loc: ${listing.location}", style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
                        Text("By: ${listing.farmerName ?? 'Unknown Farmer'}", style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                        Text("Listed: ${DateFormat.yMMMd().format(listing.createdAt.toDate())}", style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.hintColor),
                    onTap: () {
                      Navigator.pushNamed(context, ListingDetailScreen.routeName, arguments: listing.id);
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

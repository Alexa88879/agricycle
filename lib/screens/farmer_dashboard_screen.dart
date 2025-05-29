import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting, add to pubspec.yaml if not present

import '../services/auth_service.dart'; 
import 'new_waste_listing_screen.dart'; 
// This should be your detailed Gemini analysis screen (ID: flutter_waste_classification_screen_gemini_detailed)
import 'waste_classification_screen.dart'; 

// Model for Farmer Stats
class FarmerStats {
  final double monthlyEarnings;
  final String monthlyEarningsComparison; 
  final double totalCo2Saved; 
  final double co2YearlyTarget; 
  final double co2YearlyProgress;
  final int activeListingsCount;
  final List<Map<String, String>> recentActiveListings; 

  FarmerStats({
    this.monthlyEarnings = 0.0,
    this.monthlyEarningsComparison = "+0% from last month", // Placeholder
    this.totalCo2Saved = 0.0,
    this.co2YearlyTarget = 5000.0, // Example target in kg
    this.co2YearlyProgress = 0.0,
    this.activeListingsCount = 0,
    this.recentActiveListings = const [],
  });
}

class FarmerDashboardScreen extends StatefulWidget {
  static const String routeName = '/farmer-dashboard';
  const FarmerDashboardScreen({super.key});

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  final AuthService _authService = AuthService();
  late Future<FarmerStats> _farmerStatsFuture;
  
  // This could be fetched from user settings or a global config. Unit: kg
  final double _co2YearlyTarget = 5000.0; 

  @override
  void initState() {
    super.initState();
    _farmerStatsFuture = _fetchFarmerStats();
  }

  double _parseNumericValueFromString(String? valueString) {
    if (valueString == null || valueString.isEmpty) return 0.0;
    final numericPart = valueString.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(numericPart) ?? 0.0;
  }

  Future<FarmerStats> _fetchFarmerStats() async {
    final User? currentUser = _authService.currentUser;
    if (currentUser == null) {
      return FarmerStats(co2YearlyTarget: _co2YearlyTarget);
    }

    double currentMonthEarnings = 0.0;
    double lifetimeCo2Saved = 0.0; // Total CO2 saved by this user ever
    double currentYearCo2Saved = 0.0; // CO2 saved in the current year for target progress
    int activeListings = 0;
    List<Map<String, String>> recentActiveListingsData = [];

    try {
      final now = DateTime.now();
      final startOfMonth = Timestamp.fromDate(DateTime(now.year, now.month, 1));
      final startOfYear = Timestamp.fromDate(DateTime(now.year, 1, 1));

      final listingsSnapshot = await FirebaseFirestore.instance
          .collection('wasteListings')
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true) // Get recent ones first for display
          .get();

      for (var doc in listingsSnapshot.docs) {
        Map<String, dynamic> data = doc.data();

        // Active Listings
        if (data['status'] == 'active') {
          activeListings++;
          if (recentActiveListingsData.length < 3) {
            recentActiveListingsData.add({
              "name": data['wasteType']?.toString() ?? data['cropType']?.toString() ?? 'Unknown Waste',
              "status": "Active" // Or fetch a more detailed status if available
            });
          }
        }

        // Earnings for the current month
        // Assumes 'status' == 'sold', 'soldAt' (Timestamp), 'soldPrice' (Number or String to parse)
        if (data['status'] == 'sold' && data['soldAt'] is Timestamp) {
           final soldAtTimestamp = data['soldAt'] as Timestamp;
           if (soldAtTimestamp.toDate().isAfter(startOfMonth.toDate().subtract(const Duration(days:1))) && 
               soldAtTimestamp.toDate().month == now.month &&
               soldAtTimestamp.toDate().year == now.year) {
             // soldPrice could be a direct number or a string like "₹500"
             final price = _parseNumericValueFromString(data['soldPrice']?.toString() ?? data['suggestedPrice']?.toString());
             currentMonthEarnings += price;
           }
        }
        
        // CO2 Saved
        double listingCo2Saved = _parseNumericValueFromString(data['co2SavedEstimate']?.toString());
        lifetimeCo2Saved += listingCo2Saved;

        // CO2 Saved for current year (for progress bar)
        if (data['createdAt'] is Timestamp) {
          final createdAtTimestamp = data['createdAt'] as Timestamp;
          if (createdAtTimestamp.toDate().isAfter(startOfYear.toDate().subtract(const Duration(days:1))) &&
              createdAtTimestamp.toDate().year == now.year) {
             currentYearCo2Saved += listingCo2Saved; // Assuming CO2 saved is per listing creation
          }
        }
      }
    } catch (e) {
      print("Error fetching farmer stats: $e");
    }
    
    double co2Progress = 0.0;
    if (_co2YearlyTarget > 0) {
      co2Progress = (currentYearCo2Saved / _co2YearlyTarget).clamp(0.0, 1.0);
    }
    
    // Placeholder for earnings comparison - requires fetching previous month's data
    String earningsComparison = "+0% from last month"; 

    return FarmerStats(
      monthlyEarnings: currentMonthEarnings,
      monthlyEarningsComparison: earningsComparison,
      totalCo2Saved: lifetimeCo2Saved, 
      co2YearlyTarget: _co2YearlyTarget,
      co2YearlyProgress: co2Progress,
      activeListingsCount: activeListings,
      recentActiveListings: recentActiveListingsData,
    );
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
    final String userName = currentUser?.displayName ?? currentUser?.email ?? "Farmer";
    ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
               setState(() {
                _farmerStatsFuture = _fetchFarmerStats();
              });
            },
            tooltip: 'Refresh Stats',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _farmerStatsFuture = _fetchFarmerStats();
          });
        },
        child: ListView( 
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            Text(
              'Welcome, $userName!',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your waste listings, analyze waste, and track your progress.',
              style: theme.textTheme.titleMedium?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: 24),
            
            FutureBuilder<FarmerStats>(
              future: _farmerStatsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ));
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error loading stats: ${snapshot.error}", style: TextStyle(color: theme.colorScheme.error)));
                }
                final stats = snapshot.data ?? FarmerStats(co2YearlyTarget: _co2YearlyTarget);
                return _buildUserStatsSection(theme, stats);
              }
            ),
            const SizedBox(height: 24),

            GridView.count(
              shrinkWrap: true, 
              physics: const NeverScrollableScrollPhysics(), 
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.15, // Adjusted for potentially more text
              children: [
                _buildDashboardCard(
                  context,
                  icon: Icons.add_circle_outline, 
                  title: 'List New Waste',
                   onTap: () {
                    Navigator.pushNamed(context, NewWasteListingScreen.routeName).then((_){
                      // Refresh stats if a listing might have been added
                      setState(() { _farmerStatsFuture = _fetchFarmerStats(); });
                    });
                  },
                ),
                _buildDashboardCard( // Explicit Waste Categorization Card
                  context,
                  icon: Icons.science_outlined, 
                  title: 'Waste Categorization', 
                   onTap: () {
                    // Navigates to the standalone Gemini analysis screen
                    Navigator.pushNamed(context, WasteClassificationScreen.routeName);
                  },
                ),
                _buildDashboardCard(
                  context,
                  icon: Icons.list_alt_outlined,
                  title: 'My Listings',
                  onTap: () {
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('My Listings (Not Implemented Yet)')),
                    );
                    // Example: Navigator.pushNamed(context, '/my-listings');
                  },
                ),
                 _buildDashboardCard(
                  context,
                  icon: Icons.history_outlined,
                  title: 'Transaction History',
                   onTap: () {
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transaction History (Not Implemented Yet)')),
                    );
                     // Example: Navigator.pushNamed(context, '/transaction-history');
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildQuickTipsCard(theme, theme.cardColor, theme.hintColor),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStatsSection(ThemeData theme, FarmerStats stats) {
    String co2TargetNote = "${(stats.co2YearlyProgress * 100).toStringAsFixed(0)}% of your yearly target (${stats.co2YearlyTarget.toStringAsFixed(0)} kg)";

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Your Stats", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            _buildStatItem(theme, Icons.currency_rupee, "This Month's Earnings", "₹${stats.monthlyEarnings.toStringAsFixed(0)}", stats.monthlyEarningsComparison, Colors.green.shade700),
            const SizedBox(height: 16),
            _buildStatItem(theme, Icons.eco_outlined, "CO₂ Saved this Year", "${(stats.co2YearlyProgress * stats.co2YearlyTarget).toStringAsFixed(1)} kg", co2TargetNote, Colors.blue.shade700, progress: stats.co2YearlyProgress),
            const SizedBox(height: 16),
             _buildStatItem(theme, Icons.inventory_2_outlined, "Active Listings", stats.activeListingsCount.toString(), "", theme.colorScheme.secondary),
            if (stats.recentActiveListings.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 24.0), // Indent list under "Active Listings"
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: stats.recentActiveListings.map((listing) => Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(listing["name"]!, style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis)),
                        Chip(
                          label: Text(listing["status"]!, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSecondaryContainer)),
                          backgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.7),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          visualDensity: VisualDensity.compact,
                        )
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ] else if (stats.activeListingsCount > 0) ... [ // If count > 0 but list is empty (e.g., didn't fetch details)
                 Padding(
                   padding: const EdgeInsets.only(top: 4.0, left: 24),
                   child: Text("Details for active listings not shown here.", style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                 )
            ]
          ],
        ),
      ),
    );
  }

   Widget _buildStatItem(ThemeData theme, IconData icon, String label, String value, String note, Color valueColor, {double? progress}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(label, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.headlineMedium?.copyWith(color: valueColor, fontWeight: FontWeight.bold)),
        if (note.isNotEmpty) 
            Text(note, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
        if (progress != null) ...[
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.dividerColor.withOpacity(0.5),
            valueColor: AlwaysStoppedAnimation<Color>(valueColor),
            minHeight: 8, // Made progress bar thicker
            borderRadius: BorderRadius.circular(4),
          ),
        ]
      ],
    );
  }

  Widget _buildDashboardCard(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
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
              Text(title, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

   Widget _buildQuickTipsCard(ThemeData theme, Color cardColor, Color subtleTextColor) {
    return Card(
      elevation: 2,
      color: cardColor, // Use passed cardColor
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Quick Tips", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.photo_camera_back_outlined, size: 20, color: Colors.orangeAccent.shade700),
                const SizedBox(width: 10),
                Expanded(child: Text("Add clear photos and videos to increase chances of selling by up to 85%.", style: TextStyle(color: subtleTextColor))),
              ],
            ),
            const SizedBox(height: 10),
             Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.price_check_outlined, size: 20, color: Colors.green.shade700),
                const SizedBox(width: 10),
                Expanded(child: Text("Research current market rates to set competitive prices for your waste.", style: TextStyle(color: subtleTextColor))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

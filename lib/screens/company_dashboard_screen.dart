import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // To handle logout

class CompanyDashboardScreen extends StatefulWidget {
  static const String routeName = '/company-dashboard';

  const CompanyDashboardScreen({super.key});

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  final AuthService _authService = AuthService();
  // Add state variables for company data if needed

  @override
  void initState() {
    super.initState();
    // Fetch company-specific data here if needed
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
    final userName = _authService.currentUser?.displayName ?? _authService.currentUser?.email ?? "Company User";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Dashboard'),
        automaticallyImplyLeading: false, // No back button
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Welcome, $userName!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            const Text(
              'This is your Company Dashboard. Tools for managing listings and connections will appear here.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            // --- Placeholder for Company-Specific Features ---
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildDashboardCard(
                    context,
                    icon: Icons.search, // Example icon
                    title: 'Browse Listings',
                    onTap: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Navigate to Browse Listings (Not Implemented Yet)')),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    icon: Icons.map_outlined, // Example icon
                    title: 'Map View',
                     onTap: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Navigate to Map View (Not Implemented Yet)')),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    icon: Icons.analytics_outlined,
                    title: 'Market Trends',
                    onTap: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Navigate to Market Trends (Not Implemented Yet)')),
                      );
                    },
                  ),
                   _buildDashboardCard(
                    context,
                    icon: Icons.business_center_outlined,
                    title: 'My Bids/Offers',
                     onTap: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Navigate to My Bids/Offers (Not Implemented Yet)')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
   Widget _buildDashboardCard(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 48.0, color: Theme.of(context).primaryColor),
            const SizedBox(height: 10.0),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16.0)),
          ],
        ),
      ),
    );
  }
}

// lib/screens/marketplace_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:modern_auth_app/models/user_model.dart' as AppUserModel; //
import 'package:modern_auth_app/services/auth_service.dart'; //
import 'package:modern_auth_app/utils/constants.dart'; //
import 'package:modern_auth_app/utils/routes.dart'; //
import 'package:modern_auth_app/widgets/custom_button.dart'; //

class MarketplaceDashboardScreen extends StatefulWidget {
  const MarketplaceDashboardScreen({super.key});

  @override
  State<MarketplaceDashboardScreen> createState() =>
      _MarketplaceDashboardScreenState();
}

class _MarketplaceDashboardScreenState
    extends State<MarketplaceDashboardScreen> {
  final AuthService _authService = AuthService();
  AppUserModel.AppUser? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    setState(() => _isLoading = true);
    _currentUser = await _authService.getCurrentAppUser();
    setState(() => _isLoading = false);
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    Navigator.pushNamedAndRemoveUntil(
        context, AppRoutes.welcome, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AgriCycle Dashboard'),
        backgroundColor: kPrimarySwatch.shade500,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: kPrimarySwatch.shade600))
          : _currentUser == null
              ? const Center(
                  child: Text('User not found. Please try logging in again.'))
              : _buildDashboardContent(),
    );
  }

  Widget _buildDashboardContent() {
    if (_currentUser!.role == AppUserModel.UserRole.farmer) {
      return _buildFarmerDashboard();
    } else if (_currentUser!.role == AppUserModel.UserRole.company) {
      return _buildCompanyDashboard();
    } else {
      return const Center(child: Text('Unknown user role.'));
    }
  }

  Widget _buildFarmerDashboard() {
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome, Farmer ${_currentUser!.name ?? ''}!',
              style: kHeadlineStyle.copyWith(fontSize: 20)),
          const SizedBox(height: kMediumPadding),
          CustomButton(
            text: 'List New Waste',
            icon: Icons.add_circle_outline,
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.uploadWaste);
            },
          ),
          const SizedBox(height: kDefaultPadding),
          CustomButton(
            text: 'View My Listings',
            icon: Icons.list_alt_outlined,
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.farmerListings);
            },
          ),
          const SizedBox(height: kMediumPadding),
          // Placeholder for "My Earnings/Impact" - Line 5
          const Text('My Earnings & Impact:', style: kHeadlineStyle),
          const SizedBox(height: kSmallPadding),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(kDefaultPadding),
              child: Text(
                  'Earnings and CO2 saved data will appear here once implemented (Line 5).'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyDashboard() {
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome, Company ${_currentUser!.name ?? ''}!',
              style: kHeadlineStyle.copyWith(fontSize: 20)),
          const SizedBox(height: kMediumPadding),
          CustomButton(
            text: 'Browse Waste Marketplace',
            icon: Icons.store_outlined,
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.viewWasteListings);
            },
          ),
          const SizedBox(height: kMediumPadding),
          // Placeholder for "My Procurements" & "ESG Impact" - Line 5
          const Text('My Procurements & ESG Impact:', style: kHeadlineStyle),
          const SizedBox(height: kSmallPadding),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(kDefaultPadding),
              child: Text(
                  'Procurement history and ESG impact data will appear here once implemented (Line 5).'),
            ),
          )
        ],
      ),
    );
  }
}
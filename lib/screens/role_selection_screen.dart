// lib/screens/role_selection_screen.dart
import 'package:flutter/material.dart';
import '../utils/routes.dart';
import '../models/user_model.dart';
import '../widgets/custom_button.dart';
import '../utils/constants.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void _navigateToAuth(BuildContext context, UserRole role) {
    Navigator.pushNamed(context, AppRoutes.signup, arguments: role);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Role'),
        backgroundColor: kPrimarySwatch.shade500,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimarySwatch.shade200, kPrimarySwatch.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'Are you a...',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kPrimaryTextColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                _RoleCard(
                  role: UserRole.farmer,
                  icon: Icons.agriculture_outlined,
                  description: 'List your agricultural waste for sale.',
                  onTap: () => _navigateToAuth(context, UserRole.farmer),
                ),
                const SizedBox(height: 20),
                _RoleCard(
                  role: UserRole.company,
                  icon: Icons.business_center_outlined,
                  description: 'Find and procure agricultural waste.',
                  onTap: () => _navigateToAuth(context, UserRole.company),
                ),
                const SizedBox(height: 40),
                TextButton(
                  onPressed: () {
                     Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                  },
                  child: Text(
                    'Already have an account? Login',
                    style: TextStyle(color: kPrimarySwatch.shade700, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final UserRole role;
  final IconData icon;
  final String description;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.icon,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          child: Column(
            children: [
              Icon(icon, size: 50, color: kPrimarySwatch.shade600),
              const SizedBox(height: 15),
              Text(
                role.name[0].toUpperCase() + role.name.substring(1), 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimarySwatch.shade700),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

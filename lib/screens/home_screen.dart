// lib/screens/home_screen.dart
import 'package:flutter/material.dart';

// Relative imports for project files
import '../services/auth_service.dart';
import '../models/user_model.dart'; // For UserRole enum
import '../utils/constants.dart'; // For kPrimaryTextColor, kSecondaryTextColor
import '../utils/routes.dart'; // For AppRoutes
// import '../widgets/custom_button_all_screen.dart'; // Assuming this is your CustomButton
// If your CustomButton is in lib/widgets/custom_button.dart, use:
import '../widgets/custom_button.dart'; 
// import '../utils/update_checker.dart'; // If you still need this

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // final AuthService authService = AuthService(); // Not directly used for navigation here
    
    // If you have an UpdateChecker, you might call it here:
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   UpdateChecker.checkForUpdate(context); 
    // });

    return Scaffold(
      backgroundColor: Colors.white, // Or kBackgroundColor from constants
      appBar: AppBar(
        title: const Text('Nivaran - AgriWaste'),
        backgroundColor: kPrimarySwatch.shade500, // Using theme color
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Consider adding your app logo here if you have one for this screen
                // Image.asset('assets/images/your_logo.png', height: 80),
                const SizedBox(height: 32),
                const Text(
                  'Welcome to Nivaran AgriWaste',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryTextColor, // Using constant
                  ),
                ),
                const SizedBox(height: 40),
                CustomButton( // Assuming this is your custom button widget
                  text: 'Login / Sign Up',
                  onPressed: () {
                    // This screen doesn't know the role yet.
                    // Navigate to a screen that handles role selection OR directly to login/signup
                    // then after successful auth, navigate to MarketplaceDashboardScreen.
                    // For simplicity, let's assume WelcomeScreen handles the next step.
                    Navigator.pushNamed(context, AppRoutes.welcome);
                  },
                  // buttonColor: Colors.black, // Style via CustomButton or theme
                  height: 48,
                  width: double.infinity,
                ),
                const SizedBox(height: 20),
                // Example: If you want separate Login and Signup buttons
                // CustomButton(
                //   text: 'Login',
                //   onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                // ),
                // const SizedBox(height: 12),
                // CustomButton(
                //   text: 'Sign up',
                //   onPressed: () => Navigator.pushNamed(context, AppRoutes.signup),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

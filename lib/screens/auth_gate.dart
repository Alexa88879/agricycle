import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'farmer_dashboard_screen.dart'; // Import new farmer dashboard
import 'company_dashboard_screen.dart'; // Import new company dashboard
import 'role_selection_screen.dart';
// Remove import for the old generic 'dashboard_screen.dart' if you are replacing it.

class AuthGate extends StatelessWidget {
  static const String routeName = '/auth-gate';
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, authSnapshot) {
        // User is authenticating
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User is logged in
        if (authSnapshot.hasData && authSnapshot.data != null) {
          // Now fetch user data to determine role
          return FutureBuilder<Map<String, dynamic>?>(
            future: authService.getUserData(authSnapshot.data!.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.orange))),
                );
              }

              if (userSnapshot.hasError) {
                // Handle error fetching user data, maybe navigate to login/error screen
                print("Error fetching user data in AuthGate: ${userSnapshot.error}");
                // Optionally, sign out the user if their profile is inaccessible
                // Future.microtask(() => authService.signOut()); 
                return const RoleSelectionScreen(); // Or a dedicated error screen
              }

              if (userSnapshot.hasData && userSnapshot.data != null) {
                final String? role = userSnapshot.data!['role'] as String?;
                if (role == 'farmer') {
                  return const FarmerDashboardScreen();
                } else if (role == 'company') {
                  return const CompanyDashboardScreen();
                } else {
                  // Role is missing or invalid, navigate to role selection or error/login
                  print("User role missing or invalid in AuthGate: $role. UID: ${authSnapshot.data!.uid}");
                  // It might be safer to sign out the user and send to role selection
                  // if a valid role isn't found after they are authenticated.
                  // Future.microtask(() => authService.signOut()); // Consider this
                  return const RoleSelectionScreen(); // Or a more specific error/role selection page
                }
              } else {
                // User data not found, could be a new user whose profile isn't created yet
                // or an issue with Firestore.
                print("User data not found in AuthGate for UID: ${authSnapshot.data!.uid}. This might happen briefly during signup before profile is written.");
                // This state should ideally be handled during the signup process itself
                // ensuring profile is written before navigating away from signup.
                // For safety, redirect to role selection or login.
                // Future.microtask(() => authService.signOut()); // Consider this for safety
                return const RoleSelectionScreen(); 
              }
            },
          );
        }

        // User is not logged in
        return const RoleSelectionScreen(); // Navigate to Role Selection
      },
    );
  }
}

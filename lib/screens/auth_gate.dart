// lib/screens/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'farmer_dashboard_screen.dart';
import 'company_dashboard_screen.dart';
import 'role_selection_screen.dart';
import 'login_screen.dart'; // For fallback if role is indeterminate

class AuthGate extends StatelessWidget {
  static const String routeName = '/auth-gate';
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, authSnapshot) {
        // User is authenticating or auth state is initializing
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(key: ValueKey("AuthGateLoading"))),
          );
        }

        // User is logged in
        if (authSnapshot.hasData && authSnapshot.data != null) {
          final User user = authSnapshot.data!;
          print("AuthGate: User is logged in - UID: ${user.uid}");

          // Now fetch user data to determine role
          return FutureBuilder<Map<String, dynamic>?>(
            // Adding a key here can help if you need to re-trigger this future,
            // though with stream-based auth, it's usually managed well.
            key: ValueKey(user.uid), 
            future: authService.getUserData(user.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                print("AuthGate: Fetching user data for UID: ${user.uid}...");
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator(key: ValueKey("UserDataLoading"), valueColor: AlwaysStoppedAnimation<Color>(Colors.orange))),
                );
              }

              if (userSnapshot.hasError) {
                print("AuthGate: Error fetching user data for UID ${user.uid}: ${userSnapshot.error}");
                // Consider logging out if critical user data is missing and unrecoverable
                // Future.microtask(() => authService.signOut());
                // Fallback to RoleSelectionScreen or a dedicated error screen
                return const RoleSelectionScreen(); 
              }

              if (userSnapshot.hasData && userSnapshot.data != null) {
                final String? role = userSnapshot.data!['role'] as String?;
                print("AuthGate: User data fetched. Role: $role for UID: ${user.uid}");
                if (role == 'Farmer') { // Ensure case sensitivity matches Firestore
                  return const FarmerDashboardScreen();
                } else if (role == 'Company') { // Ensure case sensitivity matches Firestore
                  return const CompanyDashboardScreen();
                } else {
                  print("AuthGate: User role is missing or invalid ('$role') for UID: ${user.uid}. Navigating to RoleSelectionScreen.");
                  // If role is indeterminate, it's safer to guide the user to re-establish context
                  // Potentially sign out if this state is unexpected after login/signup
                  // Future.microtask(() => authService.signOut()); 
                  return const RoleSelectionScreen();
                }
              } else {
                // User data not found in Firestore. This can happen if:
                // 1. Firestore write failed/delayed during signup.
                // 2. User was deleted from Firestore but not Firebase Auth.
                // 3. Network issue preventing Firestore read.
                print("AuthGate: User document not found in Firestore for UID: ${user.uid}. This is unexpected after login/signup. Navigating to RoleSelectionScreen.");
                // Signing out is a safe default here to prevent an inconsistent state.
                // However, if this happens frequently, investigate Firestore write consistency in AuthService.
                // Future.microtask(() => authService.signOut());
                return const RoleSelectionScreen(); // Or LoginScreen if preferred after a failed data fetch
              }
            },
          );
        }

        // User is not logged in
        print("AuthGate: No authenticated user. Navigating to RoleSelectionScreen.");
        return const RoleSelectionScreen();
      },
    );
  }
}

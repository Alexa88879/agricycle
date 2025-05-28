// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';

// Relative imports for project files - ENSURE THESE ARE THE ONLY ONES FOR THESE FILES
// AND THAT NO OTHER FILE RE-EXPORTS THESE FROM OLD LOCATIONS
// import 'firebase_options.dart'; // Removed this import as per previous request

import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/home_screen.dart'; // This should be the sole provider of HomeScreen
import 'services/auth_service.dart';
import 'utils/routes.dart'; // This should be the sole provider of AppRoutes
import 'utils/constants.dart';
import 'screens/farmer/upload_waste_screen.dart';
import 'screens/company/waste_listings_screen.dart';
import 'screens/company/waste_item_details_screen.dart';
// CRITICAL: Search your ENTIRE lib folder for "package:modern_auth_app/" and remove/fix those imports.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase without explicit options.
  // This relies on google-services.json (Android) and GoogleService-Info.plist (iOS)
  // being correctly configured in your native project folders.
  await Firebase.initializeApp(); 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return MaterialApp(
      title: 'Nivaran AgriWaste', 
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: kPrimaryColor,
        scaffoldBackgroundColor: kBackgroundColor,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimarySwatch.shade500,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25.0),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0), 
             borderSide: BorderSide(color: kPrimarySwatch.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: kPrimarySwatch.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: kPrimarySwatch.shade600, width: 2),
          ),
          filled: true,
          fillColor: Colors.white, 
          contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
        ),
        cardTheme: CardTheme(
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          ),
          margin: const EdgeInsets.symmetric(vertical: kSmallPadding, horizontal: kSmallPadding /2 ),
        )
      ),
      initialRoute: authService.getCurrentUser() != null ? AppRoutes.home : AppRoutes.welcome,
      routes: {
        AppRoutes.welcome: (context) => const WelcomeScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.signup: (context) => const SignupScreen(),
        AppRoutes.roleSelection: (context) => const RoleSelectionScreen(),
        AppRoutes.home: (context) => const HomeScreen(), 
        AppRoutes.uploadWaste: (context) => const UploadWasteScreen(),
        AppRoutes.viewWasteListings: (context) => const WasteListingsScreen(),
        AppRoutes.wasteDetails: (context) => const WasteItemDetailsScreen(), 
      },
    );
  }
}

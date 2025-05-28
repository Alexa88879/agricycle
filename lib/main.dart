// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';

// Relative imports for project files
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/role_selection_screen.dart';
// import 'screens/home_screen.dart'; // HomeScreen is likely replaced by MarketplaceDashboardScreen
import 'screens/marketplace_dashboard_screen.dart'; // New dashboard screen
import 'screens/farmer/upload_waste_screen.dart';
import 'screens/farmer/farmer_listings_screen.dart'; // New farmer listings screen
import 'screens/company/waste_listings_screen.dart';
import 'screens/company/waste_item_details_screen.dart';

import 'services/auth_service.dart';
import 'utils/routes.dart';
import 'utils/constants.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase. This relies on google-services.json (Android)
  // and GoogleService-Info.plist (iOS) being correctly configured.
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return MaterialApp(
      title: 'AgriCycle', // Updated app title to reflect project
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: kPrimaryColor, // [cite: alexa88879/agricycle/agricycle-e9b49532dcf3b0ce4d0381d2b06b2d93bc37c499/lib/main.dart]
        scaffoldBackgroundColor: kBackgroundColor, // [cite: alexa88879/agricycle/agricycle-e9b49532dcf3b0ce4d0381d2b06b2d93bc37c499/lib/main.dart]
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme), // [cite: alexa88879/agricycle/agricycle-e9b49532dcf3b0ce4d0381d2b06b2d93bc37c499/lib/main.dart]
        elevatedButtonTheme: ElevatedButtonThemeData( // [cite: alexa88879/agricycle/agricycle-e9b49532dcf3b0ce4d0381d2b06b2d93bc37c499/lib/main.dart]
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
        inputDecorationTheme: InputDecorationTheme( // [cite: alexa88879/agricycle/agricycle-e9b49532dcf3b0ce4d0381d2b06b2d93bc37c499/lib/main.dart]
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
        cardTheme: CardTheme( // [cite: alexa88879/agricycle/agricycle-e9b49532dcf3b0ce4d0381d2b06b2d93bc37c499/lib/main.dart]
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          ),
          margin: const EdgeInsets.symmetric(vertical: kSmallPadding, horizontal: kSmallPadding / 2),
        ),
      ),
      // Updated initialRoute logic:
      // If user is logged in, go to MarketplaceDashboardScreen, else go to WelcomeScreen.
      initialRoute: authService.getCurrentUser() != null ? AppRoutes.marketplaceDashboard : AppRoutes.welcome,
      routes: {
        AppRoutes.welcome: (context) => const WelcomeScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.signup: (context) => const SignupScreen(),
        AppRoutes.roleSelection: (context) => const RoleSelectionScreen(),
        // AppRoutes.home: (context) => const HomeScreen(), // Commented out as MarketplaceDashboard is the new home
        AppRoutes.marketplaceDashboard: (context) => const MarketplaceDashboardScreen(), // Added new dashboard route
        AppRoutes.uploadWaste: (context) => const UploadWasteScreen(),
        AppRoutes.farmerListings: (context) => const FarmerListingsScreen(), // Added farmer listings route
        AppRoutes.viewWasteListings: (context) => const WasteListingsScreen(),
        AppRoutes.wasteDetails: (context) => const WasteItemDetailsScreen(),
      },
    );
  }
}

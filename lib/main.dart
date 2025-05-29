// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth_gate.dart';
import 'screens/role_selection_screen.dart';
import 'screens/login_or_signup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/farmer_dashboard_screen.dart';
import 'screens/company_dashboard_screen.dart';
import 'screens/waste_classification_screen.dart';
import 'screens/new_waste_listing_screen.dart';
import 'screens/browse_listings_screen.dart'; // New import
import 'screens/listing_detail_screen.dart'; // New import

// Import google_fonts if you plan to use it for styling
// import 'package:google_fonts/google_fonts.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriLoop App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        // Example of using Google Fonts:
        // textTheme: GoogleFonts.latoTextTheme(
        //   Theme.of(context).textTheme,
        // ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true, // Optional: enable Material 3 design
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, secondary: Colors.teal), // Example color scheme
        cardTheme: CardTheme(
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
         inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.green.shade700, width: 2.0),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: AuthGate.routeName,
      routes: {
        AuthGate.routeName: (context) => const AuthGate(),
        RoleSelectionScreen.routeName: (context) => const RoleSelectionScreen(),
        LoginOrSignupScreen.routeName: (context) {
          final role = ModalRoute.of(context)!.settings.arguments as String;
          return LoginOrSignupScreen(role: role);
        },
        LoginScreen.routeName: (context) {
          final role = ModalRoute.of(context)!.settings.arguments as String;
          return LoginScreen(role: role);
        },
        SignUpScreen.routeName: (context) {
          final role = ModalRoute.of(context)!.settings.arguments as String;
          return SignUpScreen(role: role);
        },
        FarmerDashboardScreen.routeName: (context) => const FarmerDashboardScreen(),
        CompanyDashboardScreen.routeName: (context) => const CompanyDashboardScreen(),
        WasteClassificationScreen.routeName: (context) => const WasteClassificationScreen(),
        NewWasteListingScreen.routeName: (context) => const NewWasteListingScreen(),
        BrowseListingsScreen.routeName: (context) => const BrowseListingsScreen(), // Added route
        ListingDetailScreen.routeName: (context) { // Added route
          final listingId = ModalRoute.of(context)!.settings.arguments as String;
          return ListingDetailScreen(listingId: listingId);
        },
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
      },
    );
  }
}

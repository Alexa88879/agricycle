import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth_gate.dart';
import 'screens/role_selection_screen.dart';
import 'screens/login_or_signup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/farmer_dashboard_screen.dart'; // New Farmer Dashboard
import 'screens/company_dashboard_screen.dart'; // New Company Dashboard
import 'screens/waste_classification_screen.dart'; 
import 'screens/new_waste_listing_screen.dart'; // Added this import

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
      ),
      debugShowCheckedModeBanner: false,
      // Initial route is AuthGate to check authentication state
      initialRoute: AuthGate.routeName,
      routes: {
        // Route for checking authentication state and redirecting
        AuthGate.routeName: (context) => const AuthGate(),
        // Route for selecting user role
        RoleSelectionScreen.routeName: (context) => const RoleSelectionScreen(),
        // Route for deciding between login or signup after role selection
        LoginOrSignupScreen.routeName: (context) {
          final role = ModalRoute.of(context)!.settings.arguments as String;
          return LoginOrSignupScreen(role: role);
        },
        // Route for the login screen
        LoginScreen.routeName: (context) {
          final role = ModalRoute.of(context)!.settings.arguments as String;
          return LoginScreen(role: role);
        },
        // Route for the signup screen
        SignUpScreen.routeName: (context) {
          final role = ModalRoute.of(context)!.settings.arguments as String;
          return SignUpScreen(role: role);
        },
        // Routes for role-specific dashboards
        FarmerDashboardScreen.routeName: (context) => const FarmerDashboardScreen(),
        CompanyDashboardScreen.routeName: (context) => const CompanyDashboardScreen(),
        // Route for the Waste Classification screen (using Gemini)
        WasteClassificationScreen.routeName: (context) => const WasteClassificationScreen(),
        // Route for the New Waste Listing screen
        NewWasteListingScreen.routeName: (context) => const NewWasteListingScreen(), // Added this route
        // The old generic DashboardScreen.routeName can be removed if AuthGate handles all dashboard navigation
      },
      // Optional: Define onUnknownRoute for handling undefined routes
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

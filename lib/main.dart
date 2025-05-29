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
import 'screens/browse_listings_screen.dart'; 
import 'screens/listing_detail_screen.dart'; 
import 'screens/my_listings_screen.dart'; // Add this import

// Import google_fonts if you plan to use it for styling
// import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        // textTheme: GoogleFonts.latoTextTheme(
        //   Theme.of(context).textTheme,
        // ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true, 
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green.shade700, 
          secondary: Colors.teal.shade600,
          brightness: Brightness.light, // Or Brightness.dark for dark theme
        ),
        cardTheme: CardTheme(
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0), // Consistent border radius
          ),
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0), // Default card margin
        ),
         inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0), // Consistent border radius
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.green.shade700, width: 2.0),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0), // Consistent border radius
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0)
            )
          )
        ),
        appBarTheme: AppBarTheme(
          elevation: 0.5,
          backgroundColor: Colors.white, // Or your desired app bar color
          foregroundColor: Colors.green.shade800, // Icon and title color
          titleTextStyle: TextStyle(
            color: Colors.green.shade900,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          )
        )
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
        BrowseListingsScreen.routeName: (context) => const BrowseListingsScreen(),
        ListingDetailScreen.routeName: (context) {
          final listingId = ModalRoute.of(context)!.settings.arguments as String;
          return ListingDetailScreen(listingId: listingId);
        },
        // In the routes map, add:
        MyListingsScreen.routeName: (context) => const MyListingsScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Error - Page Not Found')),
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
      },
    );
  }
}

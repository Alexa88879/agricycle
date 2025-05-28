import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth_gate.dart';
import 'screens/role_selection_screen.dart';
import 'screens/login_or_signup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/dashboard_screen.dart';
// Import google_fonts if you plan to use it for styling
// import 'package:google_fonts/google_fonts.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  // Note: No need to pass FirebaseOptions.currentPlatform if google-services.json/GoogleService-Info.plist is set up
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
        // Route for the main dashboard after login/signup
        DashboardScreen.routeName: (context) => const DashboardScreen(),
      },
    );
  }
}

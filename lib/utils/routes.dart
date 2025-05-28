// lib/utils/routes.dart

// This file should only contain the static route constants.
// It typically does not need to import other project files unless
// a route itself is dynamically generated based on some model, which is rare.

class AppRoutes {
  // Initial auth flow routes (from your existing Nivaran structure)
  static const String home = '/home'; // Your initial screen with Login/Signup buttons
  static const String login = '/login';
  static const String signup = '/signup';
  
  // AgriWaste specific routes
  static const String welcome = '/agri_welcome'; // Differentiated from your main home
  static const String roleSelection = '/role-selection';
  static const String marketplaceDashboard = '/marketplace-dashboard'; 
  
  // Farmer routes
  static const String uploadWaste = '/farmer/upload-waste';
  static const String farmerListings = '/farmer/listings'; 

  // Company routes
  static const String viewWasteListings = '/company/waste-listings'; 
  static const String wasteDetails = '/waste-details'; 

  // Other potential routes from your Nivaran app can be added here
  // For example, if your original '/welcome' was different:
  // static const String originalWelcome = '/original-welcome';
}

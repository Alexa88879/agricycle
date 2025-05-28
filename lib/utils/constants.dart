// lib/utils/constants.dart
import 'package:flutter/material.dart';

// Colors
const MaterialColor kPrimaryColor = Colors.green; 
const Color kPrimaryTextColor = Color(0xFF2E3A59); // Darker, more professional
const Color kSecondaryTextColor = Color(0xFF57606F); // Softer grey
const Color kBackgroundColor = Color(0xFFF7F9FC); // Very light grey/blueish

MaterialColor kPrimarySwatch = const MaterialColor(
  0xFF27AE60, // A slightly more vibrant green
  <int, Color>{
    50: Color(0xFFE4F6EB),  
    100: Color(0xFFBDECCA),
    200: Color(0xFF92E2A9),
    300: Color(0xFF67D888),
    400: Color(0xFF46CF70),
    500: Color(0xFF27AE60),  // Primary
    600: Color(0xFF23A058),
    700: Color(0xFF1E8C4E),
    800: Color(0xFF197944),
    900: Color(0xFF105C34),  
  },
);


// Text Styles
const TextStyle kHeadlineStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: kPrimaryTextColor,
);

const TextStyle kBodyTextStyle = TextStyle(
  fontSize: 16,
  color: kSecondaryTextColor,
  height: 1.4, // Improved line spacing
);

const TextStyle kSubtleTextStyle = TextStyle(
  fontSize: 12,
  color: Colors.blueGrey, // Softer than plain grey
);

// Padding & Margins
const double kDefaultPadding = 16.0;
const double kSmallPadding = 8.0;
const double kMediumPadding = 24.0;

// Common Waste Types (Example for dropdowns)
final List<String> kCommonWasteTypes = [
  'Rice Straw',
  'Sugarcane Bagasse',
  'Wheat Straw',
  'Corn Stover (Maize Stalks)',
  'Coconut Husk / Shell',
  'Banana Pseudostem / Leaves',
  'Cotton Stalks',
  'Jute Stick',
  'Mustard Husk / Straw',
  'Paddy Husk (Rice Husk)',
  'Fruit & Vegetable Peels/Waste',
  'Other Agricultural Residue', // Generic option
  'Other', // For user to specify
];

final List<String> kCommonCropTypes = [
  'Rice (Paddy)',
  'Sugarcane',
  'Wheat',
  'Corn (Maize)',
  'Coconut',
  'Banana',
  'Cotton',
  'Jute',
  'Mustard',
  'Pulses (Lentils, Gram, etc.)',
  'Vegetables (Mixed)',
  'Fruits (Mixed)',
  'Other', // For user to specify
];

final List<String> kQuantityUnits = [
  'Tons',
  'Quintals', 
  'Kg',
  'Truck Loads',
  'Tractor Trolleys',
  'Bags (specify size if possible)',
  'Bundles',
];

// lib/services/market_trends_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/waste_listing_model.dart'; // Assuming this model exists
import '../models/market_trend_data.dart';

class MarketTrendsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper function to parse quantity string (e.g., "10 tons", "500 kg") into kilograms.
  // This is a simplified parser and might need to be more robust in a production app.
  double _parseQuantityToKg(String quantityStr) {
    if (quantityStr.isEmpty) return 0.0;
    final parts = quantityStr.toLowerCase().split(" ");
    double value = 0.0;
    String unit = "";

    if (parts.isNotEmpty) {
      value = double.tryParse(parts[0].replaceAll(RegExp(r'[^0-9.]'),'')) ?? 0.0;
    }
    if (parts.length > 1) {
      unit = parts[1];
    }

    if (unit.contains("ton")) {
      return value * 1000.0; // 1 ton = 1000 kg
    } else if (unit.contains("kg")) {
      return value;
    } else if (unit.contains("quintal")) {
      return value * 100.0; // 1 quintal = 100 kg
    }
    // Add more unit conversions as needed (e.g., bundles, items - may need different handling)
    // For items/bundles, volume might not be directly in kg unless an average weight is assumed.
    // For simplicity, if unit is unknown or not weight-based, we might return the value or 0.
    return value; // Default to value if unit is unclear or not a weight
  }

  // Helper function to parse price string (e.g., "₹1500 per ton") into a numeric value.
  // This is simplified; assumes price is the first numeric part.
  double _parsePrice(String? priceStr) {
    if (priceStr == null || priceStr.isEmpty) return 0.0;
    final numericPart = priceStr.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(numericPart) ?? 0.0;
  }

  // Fetches and aggregates volume data for different waste types over time.
  // Returns a map where keys are waste types and values are lists of TrendDataPoints.
  Future<Map<String, List<TrendDataPoint>>> getVolumeTrendsOverTime({
    String? specificWasteType, // Optional: filter by a specific waste type
    String? timePeriod, // Optional: "monthly", "weekly", "all" (default: "monthly")
  }) async {
    Map<String, List<TrendDataPoint>> volumeTrends = {};
    Query query = _firestore.collection('wasteListings');

    // Filter by status (e.g., only 'active' or 'sold' listings)
    // For volume trends, 'active' listings might represent supply.
    query = query.where('status', whereIn: ['active', 'sold']);

    if (specificWasteType != null && specificWasteType.toLowerCase() != 'all categories') {
      query = query.where('wasteType', isEqualTo: specificWasteType);
      // Or query = query.where('cropType', isEqualTo: specificWasteType); if that's the primary field
    }

    try {
      QuerySnapshot snapshot = await query.get();
      Map<String, Map<String, double>> aggregatedData = {}; // Key: timeKey (e.g., YYYY-MM), Value: {wasteType: totalVolume}

      for (var doc in snapshot.docs) {
        WasteListing listing = WasteListing.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
        
        String wasteType = listing.wasteType ?? listing.cropType ?? "Unknown";
        double volumeInKg = _parseQuantityToKg(listing.quantity);
        DateTime date = listing.createdAt.toDate();
        
        String timeKey;
        // Determine time key based on the selected period
        if (timePeriod == "weekly") {
          // Format as Year-WeekNumber (e.g., 2023-W23)
          int weekYear = date.year;
          int weekNumber = ((date.difference(DateTime(date.year, 1, 1)).inDays + DateTime(date.year, 1, 1).weekday) / 7).ceil();
          if (DateTime(date.year, 1, 1).weekday > 4) weekNumber -=1; // Adjust if year starts late in week
          if (weekNumber == 0) { // Belongs to last week of previous year
             weekYear -=1;
             weekNumber = ((DateTime(weekYear, 12, 31).difference(DateTime(weekYear, 1, 1)).inDays + DateTime(weekYear, 1, 1).weekday) / 7).ceil();
          }
          timeKey = '$weekYear-W${weekNumber.toString().padLeft(2, '0')}';

        } else { // Default to monthly
          timeKey = DateFormat('yyyy-MM').format(date); // Monthly aggregation
        }

        aggregatedData.putIfAbsent(timeKey, () => {});
        aggregatedData[timeKey]!.putIfAbsent(wasteType, () => 0.0);
        aggregatedData[timeKey]![wasteType] = aggregatedData[timeKey]![wasteType]! + volumeInKg;
      }

      // Convert aggregated data to TrendDataPoint lists for each waste type
      Map<String, List<TrendDataPoint>> tempTrendsData = {};
      aggregatedData.forEach((timeKey, wasteVolumes) {
        DateTime dateForPoint;
        if (timePeriod == "weekly") {
            List<String> parts = timeKey.split('-W');
            int year = int.parse(parts[0]);
            int week = int.parse(parts[1]);
            // Calculate the first day of that week
            dateForPoint = DateTime(year, 1, 1).add(Duration(days: (week -1) * 7));
            // Adjust to Monday of that week
            dateForPoint = dateForPoint.subtract(Duration(days: dateForPoint.weekday - 1));

        } else { // Monthly
            dateForPoint = DateFormat('yyyy-MM').parse(timeKey);
        }

        wasteVolumes.forEach((wasteType, totalVolume) {
          tempTrendsData.putIfAbsent(wasteType, () => []);
          tempTrendsData[wasteType]!.add(TrendDataPoint(date: dateForPoint, value: totalVolume, category: wasteType));
        });
      });
      
      // Sort data points by date for each waste type
      tempTrendsData.forEach((wasteType, dataPoints) {
        dataPoints.sort((a, b) => a.date.compareTo(b.date));
        volumeTrends[wasteType] = dataPoints;
      });

    } catch (e) {
      print("Error fetching volume trends: $e");
      // Rethrow or handle as appropriate for your app
    }
    return volumeTrends;
  }


  // Fetches and aggregates price data for different waste types over time.
  // Returns a map where keys are waste types and values are lists of TrendDataPoints.
  Future<Map<String, List<TrendDataPoint>>> getPriceTrendsOverTime({
    String? specificWasteType,
    String? timePeriod, // "monthly", "weekly", "all"
  }) async {
    Map<String, List<TrendDataPoint>> priceTrends = {};
    Query query = _firestore.collection('wasteListings').where('status', isEqualTo: 'sold'); // Typically, price trends are based on sold items

    if (specificWasteType != null && specificWasteType.toLowerCase() != 'all categories') {
      query = query.where('wasteType', isEqualTo: specificWasteType);
    }
    
    // Add ordering if needed, e.g., by 'soldAt' if that field exists and is a Timestamp
    // query = query.orderBy('soldAt', descending: false); // Assuming 'soldAt' exists

    try {
      QuerySnapshot snapshot = await query.get();
      Map<String, Map<String, List<double>>> aggregatedPrices = {}; // Key: timeKey, Value: {wasteType: [list of prices]}

      for (var doc in snapshot.docs) {
        WasteListing listing = WasteListing.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
        
        String wasteType = listing.wasteType ?? listing.cropType ?? "Unknown";
        double price = _parsePrice(listing.suggestedPrice); // Or a 'soldPrice' field
        
        // Use 'createdAt' or ideally a 'soldAt' Timestamp field
        DateTime date = (listing.updatedAt ?? listing.createdAt).toDate(); // Prefer updatedAt if it reflects sold date

        if (price <= 0) continue; // Skip items with no valid price for trend analysis

        String timeKey;
         if (timePeriod == "weekly") {
          int weekYear = date.year;
          int weekNumber = ((date.difference(DateTime(date.year, 1, 1)).inDays + DateTime(date.year, 1, 1).weekday) / 7).ceil();
          if (DateTime(date.year, 1, 1).weekday > 4) weekNumber -=1;
          if (weekNumber == 0) {
             weekYear -=1;
             weekNumber = ((DateTime(weekYear, 12, 31).difference(DateTime(weekYear, 1, 1)).inDays + DateTime(weekYear, 1, 1).weekday) / 7).ceil();
          }
          timeKey = '$weekYear-W${weekNumber.toString().padLeft(2, '0')}';
        } else { // Default to monthly
          timeKey = DateFormat('yyyy-MM').format(date);
        }


        aggregatedPrices.putIfAbsent(timeKey, () => {});
        aggregatedPrices[timeKey]!.putIfAbsent(wasteType, () => []);
        aggregatedPrices[timeKey]![wasteType]!.add(price);
      }

      // Calculate average price for each period and waste type
      Map<String, List<TrendDataPoint>> tempTrendsData = {};
      aggregatedPrices.forEach((timeKey, wastePriceLists) {
        DateTime dateForPoint;
         if (timePeriod == "weekly") {
            List<String> parts = timeKey.split('-W');
            int year = int.parse(parts[0]);
            int week = int.parse(parts[1]);
            dateForPoint = DateTime(year, 1, 1).add(Duration(days: (week-1) * 7));
            dateForPoint = dateForPoint.subtract(Duration(days: dateForPoint.weekday - 1));
        } else { // Monthly
            dateForPoint = DateFormat('yyyy-MM').parse(timeKey);
        }

        wastePriceLists.forEach((wasteType, prices) {
          if (prices.isNotEmpty) {
            double averagePrice = prices.reduce((a, b) => a + b) / prices.length;
            tempTrendsData.putIfAbsent(wasteType, () => []);
            tempTrendsData[wasteType]!.add(TrendDataPoint(date: dateForPoint, value: averagePrice, category: wasteType));
          }
        });
      });
      
      tempTrendsData.forEach((wasteType, dataPoints) {
        dataPoints.sort((a, b) => a.date.compareTo(b.date));
        priceTrends[wasteType] = dataPoints;
      });

    } catch (e) {
      print("Error fetching price trends: $e");
    }
    return priceTrends;
  }

  // Helper to get a list of unique waste types for filter dropdowns
  Future<List<String>> getUniqueWasteTypes() async {
    Set<String> wasteTypes = {'All Categories'}; // Use a Set to store unique values
    try {
      QuerySnapshot snapshot = await _firestore.collection('wasteListings').get();
      for (var doc in snapshot.docs) {
        WasteListing listing = WasteListing.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
        if (listing.wasteType != null && listing.wasteType!.isNotEmpty) {
          wasteTypes.add(listing.wasteType!);
        } else if (listing.cropType != null && listing.cropType!.isNotEmpty) {
          // Fallback to cropType if wasteType is not specific enough or missing
          wasteTypes.add(listing.cropType!);
        }
      }
    } catch (e) {
      print("Error fetching unique waste types: $e");
    }
    // Convert Set to List and sort, keeping "All Categories" at the top if desired
    List<String> sortedTypes = wasteTypes.toList();
    sortedTypes.remove('All Categories');
    sortedTypes.sort();
    return ['All Categories', ...sortedTypes];
  }
}

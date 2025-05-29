// lib/models/market_trend_data.dart
import 'package:cloud_firestore/cloud_firestore.dart';

// Represents a single data point for a trend chart.
// Can be used for price, volume, or other metrics over time.
class TrendDataPoint {
  final DateTime date; // The date for this data point
  final double value;  // The value (e.g., average price, total volume)
  final String? category; // Optional category (e.g., waste type)

  TrendDataPoint({
    required this.date,
    required this.value,
    this.category,
  });

  // Factory constructor to create a TrendDataPoint from a map (e.g., from Firestore)
  factory TrendDataPoint.fromMap(Map<String, dynamic> map) {
    return TrendDataPoint(
      date: (map['date'] as Timestamp).toDate(),
      value: (map['value'] as num).toDouble(),
      category: map['category'] as String?,
    );
  }

  // Method to convert a TrendDataPoint instance to a map
  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'value': value,
      'category': category,
    };
  }
}

// Represents a collection of trend data, typically for a specific chart.
class MarketTrend {
  final String trendName; // e.g., "Price Trend for Rice Straw"
  final List<TrendDataPoint> dataPoints; // List of data points for the trend

  MarketTrend({
    required this.trendName,
    required this.dataPoints,
  });
}

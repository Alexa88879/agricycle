// lib/screens/market_trends_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/market_trends_service.dart';
import '../models/market_trend_data.dart';

class MarketTrendsScreen extends StatefulWidget {
  static const String routeName = '/market-trends';
  const MarketTrendsScreen({super.key});

  @override
  State<MarketTrendsScreen> createState() => _MarketTrendsScreenState();
}

class _MarketTrendsScreenState extends State<MarketTrendsScreen> {
  final MarketTrendsService _trendsService = MarketTrendsService();

  // State variables for filters and data
  String? _selectedWasteType = 'All Categories';
  String _selectedTimePeriod = 'Monthly'; // Default time period
  List<String> _availableWasteTypes = ['All Categories'];
  final List<String> _timePeriods = ['Monthly', 'Weekly', 'All Time'];

  Map<String, List<TrendDataPoint>> _priceTrendData = {};
  Map<String, List<TrendDataPoint>> _volumeTrendData = {};

  bool _isLoading = true;
  String? _errorMessage;

  // Colors for charts (can be expanded)
  final List<Color> _chartColors = [
    Colors.blue, Colors.green, Colors.red, Colors.orange, Colors.purple,
    Colors.teal, Colors.pink, Colors.amber, Colors.cyan, Colors.lime,
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final types = await _trendsService.getUniqueWasteTypes();
      if (!mounted) return;
      setState(() {
        _availableWasteTypes = types;
        // Ensure _selectedWasteType is valid, default if not
        if (!_availableWasteTypes.contains(_selectedWasteType)) {
          _selectedWasteType = _availableWasteTypes.isNotEmpty ? _availableWasteTypes.first : null;
        }
      });
      await _fetchTrendData();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error loading initial data: ${e.toString()}";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchTrendData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final priceData = await _trendsService.getPriceTrendsOverTime(
        specificWasteType: _selectedWasteType == 'All Categories' ? null : _selectedWasteType,
        timePeriod: _selectedTimePeriod.toLowerCase().replaceAll(' ', ''),
      );
      final volumeData = await _trendsService.getVolumeTrendsOverTime(
        specificWasteType: _selectedWasteType == 'All Categories' ? null : _selectedWasteType,
        timePeriod: _selectedTimePeriod.toLowerCase().replaceAll(' ', ''),
      );
      if (!mounted) return;
      setState(() {
        _priceTrendData = priceData;
        _volumeTrendData = volumeData;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error fetching trend data: ${e.toString()}";
          _priceTrendData = {};
          _volumeTrendData = {};
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Trends'),
        elevation: 1,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTrendData,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildFilterSection(theme),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Center(child: Text(_errorMessage!, style: TextStyle(color: theme.colorScheme.error)))
            else ...[
              if (_priceTrendData.isNotEmpty)
                _buildChartCard(
                  theme,
                  title: 'Price Trends (Avg. Sold Price)',
                  chart: _buildLineChart(_priceTrendData, isPriceChart: true),
                )
              else
                 _buildNoDataCard(theme, "No price trend data available for the selected filters."),
              const SizedBox(height: 20),
              if (_volumeTrendData.isNotEmpty)
                _buildChartCard(
                  theme,
                  title: 'Volume Trends (Total Quantity in Kg)',
                  chart: _buildLineChart(_volumeTrendData, isPriceChart: false), // Can also use BarChart
                )
              else
                _buildNoDataCard(theme, "No volume trend data available for the selected filters."),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(ThemeData theme) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Filters", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Waste Type',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    value: _selectedWasteType,
                    isExpanded: true,
                    items: _availableWasteTypes.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedWasteType = newValue;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Time Period',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    value: _selectedTimePeriod,
                    isExpanded: true,
                    items: _timePeriods.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedTimePeriod = newValue!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.filter_list_alt),
                label: const Text('Apply Filters'),
                onPressed: _isLoading ? null : _fetchTrendData,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(ThemeData theme, {required String title, required Widget chart}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(height: 300, child: chart), // Fixed height for the chart
          ],
        ),
      ),
    );
  }

   Widget _buildNoDataCard(ThemeData theme, String message) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, color: theme.hintColor, size: 40),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(color: theme.hintColor)),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildLineChart(Map<String, List<TrendDataPoint>> trendDataMap, {required bool isPriceChart}) {
    if (trendDataMap.isEmpty) {
      return const Center(child: Text("No data to display."));
    }

    List<LineChartBarData> lineBarsData = [];
    int colorIndex = 0;

    double minY = double.maxFinite;
    double maxY = double.minPositive;
    double minX = double.maxFinite; // Earliest date timestamp
    double maxX = double.minPositive; // Latest date timestamp

    trendDataMap.forEach((wasteType, dataPoints) {
      if (dataPoints.isEmpty) return;

      List<FlSpot> spots = dataPoints.map((point) {
        final xValue = point.date.millisecondsSinceEpoch.toDouble();
        final yValue = point.value;
        
        if (xValue < minX) minX = xValue;
        if (xValue > maxX) maxX = xValue;
        if (yValue < minY) minY = yValue;
        if (yValue > maxY) maxY = yValue;
        
        return FlSpot(xValue, yValue);
      }).toList();

      if (spots.isNotEmpty) {
        lineBarsData.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: _chartColors[colorIndex % _chartColors.length],
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(show: dataPoints.length < 15), // Show dots for fewer points
            belowBarData: BarAreaData(show: false),
            // legend: Legend(isVisible: true, title: wasteType) // Not directly supported here
          ),
        );
        colorIndex++;
      }
    });
     if (lineBarsData.isEmpty) return const Center(child: Text("Not enough data points to draw chart."));

    // Adjust minY and maxY for padding
    if (minY == double.maxFinite) minY = 0; // Default if no data
    if (maxY == double.minPositive) maxY = 10; // Default if no data
    
    final yRange = maxY - minY;
    minY = (minY - yRange * 0.1).floorToDouble(); // Add 10% padding below
    maxY = (maxY + yRange * 0.1).ceilToDouble();   // Add 10% padding above
    if (minY < 0 && !isPriceChart) minY = 0; // Volume can't be negative
    if (minY < 0 && isPriceChart && yRange < 100) minY = 0; // Price usually not negative, unless it's a delta

    if (minY == maxY) { // Handle case where all Y values are the same
        minY = minY > 0 ? minY - (minY * 0.5) : -5;
        maxY = maxY + (maxY.abs() * 0.5) + 5;
        if (minY == 0 && maxY == 0) maxY = 10;
    }


    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 0.5),
          getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) {
            return Text(NumberFormat.compact().format(value), style: const TextStyle(fontSize: 10));
          })),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: _calculateXAxisInterval(minX, maxX), getTitlesWidget: (value, meta) {
            DateTime date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
            String format = (_selectedTimePeriod == 'Weekly' || (maxX - minX) < Duration(days: 90).inMilliseconds) ? 'dd MMM' : 'MMM yy';
            return SideTitleWidget(axisSide: meta.axisSide, space: 4, child: Text(DateFormat(format).format(date), style: const TextStyle(fontSize: 10)));
          })),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withOpacity(0.5), width: 0.5)),
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        lineBarsData: lineBarsData,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final flSpot = barSpot;
                final DateTime date = DateTime.fromMillisecondsSinceEpoch(flSpot.x.toInt());
                final String dateStr = DateFormat('MMM d, yyyy').format(date);
                
                String seriesName = "Trend"; // Default
                // Try to find the series name (waste type)
                int barIndex = touchedBarSpots.indexOf(barSpot);
                 if (barIndex < trendDataMap.keys.length) {
                   seriesName = trendDataMap.keys.elementAt(barSpot.barIndex);
                 }

                return LineTooltipItem(
                  '$seriesName\n',
                  TextStyle(color: flSpot.bar.color, fontWeight: FontWeight.bold, fontSize: 12),
                  children: <TextSpan>[
                    TextSpan(
                      text: '${isPriceChart ? '₹' : ''}${NumberFormat.compactCurrency(decimalDigits: 1, symbol: isPriceChart ? '' : '').format(flSpot.y)} ${isPriceChart ? '' : 'kg'}\n',
                      style: TextStyle(color: flSpot.bar.color, fontSize: 11),
                    ),
                    TextSpan(
                      text: dateStr,
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    ),
                  ],
                  textAlign: TextAlign.left
                );
              }).toList();
            },
          ),
        ),
        // Add legend here if multiple lines are shown and _selectedWasteType is 'All Categories'
        // This requires a custom legend widget as fl_chart's built-in legend is basic.
        // For simplicity, I'm omitting a complex custom legend for now.
        // You can build a Row of colored boxes and text widgets below the chart.
      ),
    );
  }

  double _calculateXAxisInterval(double minX, double maxX) {
    final double range = maxX - minX;
    if (range <= 0) return Duration(days: 1).inMilliseconds.toDouble();

    // Aim for 5-10 labels
    if (_selectedTimePeriod == 'Weekly' || range < Duration(days: 90).inMilliseconds) {
        return (range / 5).ceilToDouble(); // More frequent for shorter periods
    } else if (range < Duration(days: 365 * 2).inMilliseconds) { // Up to 2 years, show monthly
        return Duration(days: 30).inMilliseconds.toDouble();
    } else { // Longer, show quarterly or semi-annually
        return Duration(days: 90).inMilliseconds.toDouble();
    }
  }

}

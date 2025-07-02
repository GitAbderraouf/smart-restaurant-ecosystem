import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hungerz_delivery/Config/app_config.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hungerz_delivery/Themes/colors.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

// Updated API base URL
const String _apiBaseUrl =  AppConfig.baseUrl; 
const String _hardcodedDriverId = "default_driver_test_001"; // Keep for now, used in Analytics

class InsightPage extends StatefulWidget {
  const InsightPage({Key? key}) : super(key: key);

  @override
  _InsightPageState createState() => _InsightPageState();
}

class _InsightPageState extends State<InsightPage> {
  // Period selection for trends chart
  String _selectedTrendPeriod = 'WEEKLY';
  final List<String> _trendPeriodOptions = ['TODAY', 'WEEKLY', 'MONTHLY', 'YEARLY'];

  // Firebase Analytics instance
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // --- Data state ---
  bool _isLoading = true;

  // Current Period Metrics
  double _newOrdersRevenue = 0.0;
  int _periodOrders = 0;
  double _averageOrderValue = 0.0;
  double _newOrdersProfit = 0.0;
  List<Map<String, dynamic>> _periodDeliveries = [];

  // Previous Period Metrics (for comparison)
  double _previousPeriodRevenue = 0.0;
  int _previousPeriodOrders = 0;
  double _previousPeriodProfit = 0.0;

  // All-Time Metrics
  double _totalEarnings = 0.0;
  double _totalProfit = 0.0;

  // Peak Activity Data
  Map<int, int> _peakHoursOrderData = {}; // Hour (0-23) -> Order Count
  Map<String, int> _peakDaysOrderData = {}; // Day (Mon, Tue) -> Order Count

  // Goals Data (Hardcoded for now)
  final double _weeklyEarningsGoal = 5000.0; // Example goal
  final int _monthlyOrdersGoal = 100; // Example goal
  double _currentWeeklyEarningsForGoal = 0.0;
  int _currentMonthlyOrdersForGoal = 0;

  // Payout Data (Hardcoded for now)
  final DateTime _lastPayoutDate = DateTime.now().subtract(Duration(days: 10));
  double _earningsSinceLastPayout = 0.0;


  @override
  void initState() {
    super.initState();
    _fetchInsightData();
  }

  // --- API Helper Functions ---

  Future<List<Map<String, dynamic>>> _fetchOrdersFromApi({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Map<String, String> queryParams = {
    };
    if (startDate != null) {
      queryParams['startDate'] =DateFormat("yyyy-MM-ddTHH:mm:ss'Z'").format(startDate.toUtc());
    }
    if (endDate != null) {
      queryParams['endDate'] = DateFormat("yyyy-MM-ddTHH:mm:ss'Z'").format(endDate.toUtc());
    }
    final uri = Uri.parse('$_apiBaseUrl/orders/delivered').replace(queryParameters: queryParams);
    print("Fetching DELIVERED orders from API: $uri");
    try {
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final List<dynamic> decodedData = json.decode(response.body)['orders'] ?? json.decode(response.body); // Handle if API wraps in 'orders' key
        return decodedData.map((item) => item as Map<String, dynamic>).toList();
      } else {
        print("API Error fetching orders: ${response.statusCode} - ${response.body}");
        throw Exception('Failed to load orders from API. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching orders from API: $e");
      throw Exception('Failed to load orders: $e');
    }
  }

  Future<void> _acceptTaskApiCall(String orderId) async {
    final uri = Uri.parse('$_apiBaseUrl/orders/$orderId/accept-task');
    print("Calling Accept Task API: $uri");
    try {
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        // No body needed if the backend doesn't expect one for this specific action
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        print("Order $orderId task accepted successfully via API.");
        // TODO: Firebase Analytics logging if needed
      } else {
        print("API Error accepting task: ${response.statusCode} - ${response.body}");
        throw Exception('Failed to accept task. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print("Error calling accept task API: $e");
      throw Exception('Failed to accept task: $e');
    }
  }

  Future<void> _confirmDeliveryApiCall(String orderId) async {
    final uri = Uri.parse('$_apiBaseUrl/orders/$orderId/confirm-delivery');
    print("Calling Confirm Delivery API: $uri");
    try {
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        // No body needed if the backend doesn't expect one for this specific action
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        print("Order $orderId delivery confirmed successfully via API.");
        // TODO: Firebase Analytics logging if needed
      } else {
        print("API Error confirming delivery: ${response.statusCode} - ${response.body}");
        throw Exception('Failed to confirm delivery. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print("Error calling confirm delivery API: $e");
      throw Exception('Failed to confirm delivery: $e');
    }
  }

  // --- Public methods to be called from other parts of the app ---
  Future<void> markOrderAsAccepted(String orderId) async {
    // You might want to show loading indicators or feedback to the user
    try {
      await _acceptTaskApiCall(orderId);
      // Handle success (e.g., show a snackbar, refresh a list, update UI state)
      print("Order $orderId marked as accepted successfully.");
      // Potentially refetch data or update UI to reflect the change immediately
      // _fetchInsightData(); // Or a more lightweight UI update
    } catch (e) {
      // Handle error (e.g., show an error message)
      print("Failed to mark order $orderId as accepted: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept task: ${e.toString()}')),
      );
    }
  }

  Future<void> markOrderAsDelivered(String orderId) async {
    try {
      await _confirmDeliveryApiCall(orderId); 
      print("Order $orderId marked as delivered successfully.");
      // After successful delivery confirmation, insights must be refreshed.
      _fetchInsightData(); // Refresh insights data
      // Log to Firebase Analytics
      _analytics.logEvent(
        name: 'order_delivered_confirmed',
        parameters: {
          'order_id': orderId,
          'driver_id': _hardcodedDriverId,
          'timestamp': DateTime.now().toIso8601String(),
        }
      );
    } catch (e) {
      print("Failed to mark order $orderId as delivered: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to confirm delivery: ${e.toString()}')),
      );
    }
  }
  // --- End Public methods ---

  Future<void> _fetchInsightData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });
    print("--- Starting _fetchInsightData (API) ---");
    print("_selectedTrendPeriod: $_selectedTrendPeriod");

    const String driverId = _hardcodedDriverId; // This is for analytics, not for API query to fetch data
    const double profitMargin = 0.6; // Assuming this remains constant

    try {
      // 1. Fetch All-Time Data (for totals)
      print("Fetching all-time data from API..."); // Removed driverId from this log message
      // Assuming 'delivered' is the status for completed orders relevant for earnings
      final List<Map<String, dynamic>> allTimeApiDeliveries = await _fetchOrdersFromApi(
        // driverId: driverId, // driverId argument removed
      );
      print("All-time API deliveries count: ${allTimeApiDeliveries.length}");

      double allTimeEarningsSum = 0;
      List<Map<String, dynamic>> allTimeDeliveriesForPeak = [];
      for (var deliveryData in allTimeApiDeliveries) {
        // Assuming API returns 'deliveryFee' as num and 'updatedAt' as ISO String
        final deliveryFee = (deliveryData['deliveryFee'] as num?)?.toDouble() ?? 0.0;
        allTimeEarningsSum += deliveryFee;
        // For peak calculations, we need 'updatedAt'
        // Ensure 'updatedAt' is present and parseable
        if (deliveryData['updatedAt'] != null) {
             allTimeDeliveriesForPeak.add(deliveryData);
        }
      }
      print("Total all-time earnings sum from API: $allTimeEarningsSum");
      double calculatedTotalProfit = allTimeEarningsSum * profitMargin;

      // 2. Define Current Period Dates
      DateTime now = DateTime.now();
      // now = DateTime(2025, 5, 27); // TEMP DEBUG FOR 2025 DATA
      print("Current 'now' for period calculation: $now");

      DateTime currentPeriodStartDate;
      DateTime currentPeriodEndDate = now;

      switch (_selectedTrendPeriod) {
        case 'TODAY':
          currentPeriodStartDate = DateTime(now.year, now.month, now.day);
          currentPeriodEndDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
          break;
        case 'WEEKLY':
          currentPeriodStartDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
          currentPeriodEndDate = currentPeriodStartDate.add(Duration(days: 6, hours: 23, minutes: 59, seconds: 59, milliseconds: 999));
          break;
        case 'MONTHLY':
          currentPeriodStartDate = DateTime(now.year, now.month, 1);
          currentPeriodEndDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
          break;
        case 'YEARLY':
          currentPeriodStartDate = DateTime(now.year, 1, 1);
          currentPeriodEndDate = DateTime(now.year, 12, 31, 23, 59, 59, 999);
          break;
        default:
          currentPeriodStartDate = DateTime(now.year, now.month, now.day);
      }
      print("Current period: $currentPeriodStartDate to $currentPeriodEndDate");

      // 3. Fetch Current Period Data from API
      print("Fetching current period data from API...");
      final List<Map<String, dynamic>> currentPeriodApiDeliveries = await _fetchOrdersFromApi(
        // driverId: driverId, // driverId argument removed
        startDate: currentPeriodStartDate,
        endDate: currentPeriodEndDate,
      );
      print("Current period API deliveries count: ${currentPeriodApiDeliveries.length}");

      double currentPeriodEarningsSum = 0;
      // Sort by 'updatedAt' descending for display if needed (API might already do this)
      // For calculations, order doesn't strictly matter here, but for chart data later it will.
      // We'll handle chart sorting separately.
      currentPeriodApiDeliveries.sort((a,b) {
          final aDate = a['updatedAt'] != null ? DateTime.tryParse(a['updatedAt'] as String) : null;
          final bDate = b['updatedAt'] != null ? DateTime.tryParse(b['updatedAt'] as String) : null;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1; // nulls last
          if (bDate == null) return -1; // nulls last
          return bDate.compareTo(aDate); // Descending
      });
      
      _periodDeliveries = currentPeriodApiDeliveries; // Store for chart usage

      for (var deliveryData in currentPeriodApiDeliveries) {
        currentPeriodEarningsSum += (deliveryData['deliveryFee'] as num?)?.toDouble() ?? 0.0;
      }
      print("Total current period earnings sum from API: $currentPeriodEarningsSum");
      int currentPeriodOrdersCount = currentPeriodApiDeliveries.length;
      double currentPeriodAvgOrderValue = currentPeriodOrdersCount > 0 ? currentPeriodEarningsSum / currentPeriodOrdersCount : 0.0;
      double currentPeriodProfitSum = currentPeriodEarningsSum * profitMargin;

      // 4. Define and Fetch Previous Period Data (for comparison) from API
      DateTime previousPeriodStartDate;
      DateTime previousPeriodEndDate;

      switch (_selectedTrendPeriod) {
        case 'TODAY':
          previousPeriodStartDate = currentPeriodStartDate.subtract(const Duration(days: 1));
          previousPeriodEndDate = currentPeriodEndDate.subtract(const Duration(days: 1));
          break;
        case 'WEEKLY':
          previousPeriodStartDate = currentPeriodStartDate.subtract(const Duration(days: 7));
          previousPeriodEndDate = currentPeriodEndDate.subtract(const Duration(days: 7));
          break;
        case 'MONTHLY':
          previousPeriodStartDate = DateTime(currentPeriodStartDate.year, currentPeriodStartDate.month - 1, 1);
          previousPeriodEndDate = DateTime(currentPeriodStartDate.year, currentPeriodStartDate.month, 0, 23, 59, 59, 999);
          break;
        case 'YEARLY':
          previousPeriodStartDate = DateTime(currentPeriodStartDate.year - 1, 1, 1);
          previousPeriodEndDate = DateTime(currentPeriodStartDate.year - 1, 12, 31, 23, 59, 59, 999);
          break;
        default:
          previousPeriodStartDate = currentPeriodStartDate.subtract(const Duration(days: 1));
          previousPeriodEndDate = currentPeriodEndDate.subtract(const Duration(days: 1));
      }
      print("Previous period: $previousPeriodStartDate to $previousPeriodEndDate");

      final List<Map<String, dynamic>> previousPeriodApiDeliveries = await _fetchOrdersFromApi(
        // driverId: driverId, // driverId argument removed
        startDate: previousPeriodStartDate,
        endDate: previousPeriodEndDate,
      );
      print("Previous period API deliveries count: ${previousPeriodApiDeliveries.length}");
      double prevPeriodEarningsSum = 0;
      int prevPeriodOrdersCount = previousPeriodApiDeliveries.length;
      for (var deliveryData in previousPeriodApiDeliveries) {
        prevPeriodEarningsSum += (deliveryData['deliveryFee'] as num?)?.toDouble() ?? 0.0;
      }
      double prevPeriodProfitSum = prevPeriodEarningsSum * profitMargin;
      
      // 5. Calculate Peak Activity Data (using all-time deliveries)
      Map<int, int> hourlyData = {};
      Map<String, int> dailyData = {};
      final DateFormat hourFormat = DateFormat('H'); 
      final DateFormat dayFormat = DateFormat('E'); 

      for (var delivery in allTimeDeliveriesForPeak) { // Using the list fetched earlier
        final updatedAtString = delivery['updatedAt'] as String?;
        if (updatedAtString != null) {
          final timestamp = DateTime.tryParse(updatedAtString);
          if (timestamp != null) {
            int hour = int.parse(hourFormat.format(timestamp));
            hourlyData[hour] = (hourlyData[hour] ?? 0) + 1;

            String day = dayFormat.format(timestamp);
            dailyData[day] = (dailyData[day] ?? 0) + 1;
          }
        }
      }

      // 6. Calculate Earnings Since Last Payout from API
      double earningsSincePayoutSum = 0;
      print("Last Payout Date for query: $_lastPayoutDate");

      // API needs a start date. No end date means 'up to now'.
      final List<Map<String, dynamic>> payoutPeriodApiDeliveries = await _fetchOrdersFromApi(
        // driverId: driverId, // driverId argument removed
        startDate: _lastPayoutDate, // API handles "greater than this date"
      );
      print("Payout period API deliveries count: ${payoutPeriodApiDeliveries.length}");
      for (var deliveryData in payoutPeriodApiDeliveries) {
          earningsSincePayoutSum += (deliveryData['deliveryFee'] as num?)?.toDouble() ?? 0.0;
      }
      print("Earnings since last payout from API: $earningsSincePayoutSum");
      
      // 7. Update Goal Progress based on current period
      double currentWkGoalProg = 0.0;
      int currentMthGoalProg = 0;
      if (_selectedTrendPeriod == 'WEEKLY') {
          currentWkGoalProg = currentPeriodEarningsSum;
      }
      if (_selectedTrendPeriod == 'MONTHLY') {
          currentMthGoalProg = currentPeriodOrdersCount;
      }

      print("--- Before setState (API) ---");
      print("_totalEarnings to be set: $allTimeEarningsSum");
      print("_periodDeliveries.length to be set: ${currentPeriodApiDeliveries.length}");
      print("_periodOrders to be set: $currentPeriodOrdersCount");

      // Log successful data fetch to Firebase Analytics
      _analytics.logEvent(
        name: 'insights_data_loaded',
        parameters: {
          'driver_id': driverId, // Keep for analytics logging: who viewed the page
          'period': _selectedTrendPeriod,
          'total_earnings_loaded': allTimeEarningsSum,
          'current_period_orders_loaded': currentPeriodOrdersCount,
          'timestamp': DateTime.now().toIso8601String(),
        }
      );

      if (mounted) {
        setState(() {
          // All-time
          _totalEarnings = allTimeEarningsSum;
          _totalProfit = calculatedTotalProfit;

          // Current Period (already set _periodDeliveries above)
          _periodOrders = currentPeriodOrdersCount;
          _newOrdersRevenue = currentPeriodEarningsSum;
          _averageOrderValue = currentPeriodAvgOrderValue;
          _newOrdersProfit = currentPeriodProfitSum;

          // Previous Period
          _previousPeriodOrders = prevPeriodOrdersCount;
          _previousPeriodRevenue = prevPeriodEarningsSum;
          _previousPeriodProfit = prevPeriodProfitSum;
          
          // Peak Data
          _peakHoursOrderData = hourlyData;
          _peakDaysOrderData = dailyData;

          // Payout Data
          _earningsSinceLastPayout = earningsSincePayoutSum;
          
          // Goal Data
          _currentWeeklyEarningsForGoal = currentWkGoalProg;
          _currentMonthlyOrdersForGoal = currentMthGoalProg;

          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error in _fetchInsightData (API): $e");
      if (mounted) {
        setState(() { _isLoading = false; });
        // Optionally show an error message to the user, e.g., using a SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load insights: ${e.toString()}')),
        );
      }
      // Log this error to Firebase Analytics
      _analytics.logEvent(
        name: 'insights_load_failed',
        parameters: {
          'driver_id': driverId, // Keep for analytics logging: who viewed the page when error occurred
          'period': _selectedTrendPeriod, // And for which period view
          'error_message': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        }
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: kMainColor ?? Theme.of(context).primaryColor))
          : SingleChildScrollView( 
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: (_periodDeliveries.isEmpty && _totalEarnings == 0 && !_isLoading) 
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 50.0),
                      child: Text(
                        "No delivery data found yet to generate insights.\nComplete some deliveries to see your stats!",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.5),
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildStatsCardGrid(),
                      const SizedBox(height: 24),
                      _buildPayoutInfoCard(),
                      const SizedBox(height: 24),
                      _buildGoalsProgressSection(),
                      const SizedBox(height: 24),
                      _buildPerformanceComparisonSection(),
                      const SizedBox(height: 24),
                      _buildPeakActivitySection(),
                      const SizedBox(height: 24),
                      _buildEarningsOverviewSection(),
                      const SizedBox(height: 24),
                      _buildSalesTimeSeriesSection(),
                      const SizedBox(height: 24),
                      _buildProfitTrendsSection(),
                    ],
                  ),
              ),
            ),
    );
  }

  Widget _buildStatsCardGrid() {
    String formatComparison(num current, num previous) {
      if (previous == 0) return "(vs N/A)";
      double change = ((current - previous) / previous) * 100;
      String sign = change > 0 ? '+' : '';
      return "(vs ${previous.toStringAsFixed(0)}, ${sign}${change.toStringAsFixed(0)}%)";
    }

    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 1.5, // Adjusted for more text
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard(
          'Period Orders',
          _periodOrders.toString(),
          Colors.teal.shade50,
          Colors.teal,
          subValue: formatComparison(_periodOrders, _previousPeriodOrders)
        ),
        _buildStatCard(
          'Period Revenue',
          '${_newOrdersRevenue.toStringAsFixed(2)} da',
          Colors.blue.shade50,
          Colors.blue,
          subValue: formatComparison(_newOrdersRevenue, _previousPeriodRevenue)
        ),
        _buildStatCard('Avg. Order Value', '${_averageOrderValue.toStringAsFixed(2)} da', Colors.cyan.shade50, Colors.cyan),
        _buildStatCard(
          'Period Profit',
          '${_newOrdersProfit.toStringAsFixed(2)} da',
          Colors.lime.shade50,
          Colors.lime,
          subValue: formatComparison(_newOrdersProfit, _previousPeriodProfit)
        ),
        _buildStatCard('Total Revenue (All Time)', '${_totalEarnings.toStringAsFixed(2)} da', Colors.orange.shade50, Colors.orange),
        _buildStatCard('Total Profit (All Time)', '${_totalProfit.toStringAsFixed(2)} da', Colors.green.shade50, Colors.green),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color backgroundColor, MaterialColor textColor, {String? subValue}) {
    return Card(
      elevation: 1, 
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            Text(title, 
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textColor.shade700), 
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6), 
            Text(value, 
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textColor.shade900), 
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subValue != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(subValue,
                  style: TextStyle(fontSize: 10, color: textColor.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutInfoCard() {
    final DateFormat formatter = DateFormat('MMM dd, yyyy');
    return Card(
      elevation: 1,
      color: Colors.indigo.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payout Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.indigo.shade800),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.history_toggle_off, color: Colors.indigo.shade400, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_earningsSinceLastPayout.toStringAsFixed(2)} da',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo.shade700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Earnings since last payout on ${formatter.format(_lastPayoutDate)}',
                        style: TextStyle(fontSize: 12, color: Colors.indigo.shade500),
                         maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // You could add a hypothetical next payout date or threshold here
            // Text("Next payout expected: ...", style: TextStyle(fontSize: 12, color: Colors.indigo.shade400)),
          ],
        )
      ),
    );
  }

  Widget _buildGoalsProgressSection() {
    double weeklyGoalProgress = 0;
    if (_weeklyEarningsGoal > 0) {
      weeklyGoalProgress = (_currentWeeklyEarningsForGoal / _weeklyEarningsGoal).clamp(0.0, 1.0);
    }
    double monthlyGoalProgress = 0;
    if (_monthlyOrdersGoal > 0) {
      monthlyGoalProgress = (_currentMonthlyOrdersForGoal / _monthlyOrdersGoal).clamp(0.0, 1.0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Goals',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          color: Colors.purple.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildGoalItem(
                  title: 'Weekly Earnings Goal: ${_weeklyEarningsGoal.toStringAsFixed(0)} da',
                  currentValue: _currentWeeklyEarningsForGoal,
                  goalValue: _weeklyEarningsGoal,
                  progress: weeklyGoalProgress,
                  color: Colors.purple,
                  unit: 'da',
                  isMonetary: true
                ),
                const SizedBox(height: 16),
                 _buildGoalItem(
                  title: 'Monthly Orders Goal: ${_monthlyOrdersGoal} orders',
                  currentValue: _currentMonthlyOrdersForGoal.toDouble(),
                  goalValue: _monthlyOrdersGoal.toDouble(),
                  progress: monthlyGoalProgress,
                  color: Colors.deepOrange,
                  unit: 'orders',
                  isMonetary: false
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalItem({
    required String title,
    required double currentValue,
    required double goalValue,
    required double progress,
    required MaterialColor color,
    required String unit,
    bool isMonetary = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color.shade700)),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.shade100,
          valueColor: AlwaysStoppedAnimation<Color>(color.shade400),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isMonetary ? currentValue.toStringAsFixed(2) : currentValue.toInt().toString(),
              style: TextStyle(fontSize: 12, color: color.shade600)
            ),
            Text(
             (progress * 100).toStringAsFixed(0) + '%',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color.shade800)
            ),
          ],
        )
      ],
    );
  }

  Widget _buildPerformanceComparisonSection() {
    return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_selectedTrendPeriod Performance vs. Previous',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          color: Colors.lightBlue.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildComparisonRow('Orders', _periodOrders.toDouble(), _previousPeriodOrders.toDouble(), Colors.lightBlue, isMonetary: false),
                Divider(height: 20, color: Colors.lightBlue.shade100),
                _buildComparisonRow('Revenue', _newOrdersRevenue, _previousPeriodRevenue, Colors.lightBlue, unit: 'da'),
                Divider(height: 20, color: Colors.lightBlue.shade100),
                _buildComparisonRow('Profit', _newOrdersProfit, _previousPeriodProfit, Colors.lightBlue, unit: 'da'),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildComparisonRow(String metric, double currentValue, double previousValue, MaterialColor color, {String unit = '', bool isMonetary = true}) {
    double change = 0;
    bool isPositiveChange = false;
    bool isNoPreviousData = previousValue == 0;

    if (!isNoPreviousData) {
      change = ((currentValue - previousValue) / previousValue) * 100;
      isPositiveChange = currentValue >= previousValue;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(metric, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color.shade700)),
            const SizedBox(height: 2),
                  Text(
              isMonetary ? '${currentValue.toStringAsFixed(2)} $unit' : '${currentValue.toInt()} $unit',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color.shade900)
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              isNoPreviousData 
                ? 'N/A (Prev)' 
                : (isPositiveChange ? '↑' : '↓') + ' ${change.abs().toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isNoPreviousData ? color.shade400 : (isPositiveChange ? Colors.green.shade600 : Colors.red.shade600),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isMonetary ? 'Prev: ${previousValue.toStringAsFixed(2)} $unit' : 'Prev: ${previousValue.toInt()} $unit',
              style: TextStyle(fontSize: 12, color: color.shade500)
            ),
          ],
        )
      ],
    );
  }

  Widget _buildPeakActivitySection() {
    // Find peak hour
    MapEntry<int, int>? peakHourEntry;
    if(_peakHoursOrderData.isNotEmpty) {
      peakHourEntry = _peakHoursOrderData.entries.reduce((a, b) => a.value > b.value ? a : b);
    }

    // Find peak day
    MapEntry<String, int>? peakDayEntry;
     if(_peakDaysOrderData.isNotEmpty) {
      peakDayEntry = _peakDaysOrderData.entries.reduce((a, b) => a.value > b.value ? a : b);
    }

    // For simplicity, showing as text. Can be enhanced with charts later.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Peak Activity (All Time)',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          color: Colors.amber.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.wb_sunny_outlined, color: Colors.amber.shade700, size: 28),
                    const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Busiest Hour', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.amber.shade800)),
                        Text(
                          peakHourEntry != null ? '${peakHourEntry.key}:00 - ${(peakHourEntry.key + 1)}:00 (${peakHourEntry.value} orders)' : 'No data',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.amber.shade900)
                        ),
                      ],
                    )
                  ],
                ),
                Divider(height: 24, color: Colors.amber.shade100),
                 Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, color: Colors.orange.shade700, size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Busiest Day of Week', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.orange.shade800)),
                  Text(
                          peakDayEntry != null ? '${peakDayEntry.key} (${peakDayEntry.value} orders)' : 'No data',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.orange.shade900)
                        ),
                      ],
                    )
                  ],
                  ),
                ],
              ),
          ),
        )
      ],
    );
  }

  Widget _buildEarningsOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lifetime Earnings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 1,
          color: Colors.grey.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.green.shade600, size: 40),
                const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_totalEarnings.toStringAsFixed(2)} da',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                    ),
                    const SizedBox(height: 4),
                  Text(
                      'Total Gross Revenue',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ],
    );
  }

  Widget _buildSalesTimeSeriesSection() {
    return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_selectedTrendPeriod.capitalizeFirst()} Revenue Trend',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: _selectedTrendPeriod,
              dropdownColor: Colors.white,
              style: TextStyle(color: kMainColor ?? Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
              icon: Icon(Icons.arrow_drop_down, color: kMainColor ?? Theme.of(context).primaryColor),
              underline: Container(),
              onChanged: (String? newValue) {
                if (newValue != null && newValue != _selectedTrendPeriod) {
                  if (mounted) {
                    setState(() {
                      _selectedTrendPeriod = newValue;
                      _fetchInsightData();
                    });
                  }
                }
              },
              items: _trendPeriodOptions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value.capitalizeFirst()),
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 230,
          padding: const EdgeInsets.only(top: 5, right: 5),
          child: _buildEarningsChart(),
        ),
      ],
    );
  }

  Widget _buildProfitTrendsSection() {
    return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_selectedTrendPeriod.capitalizeFirst()} Profit Trend',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        const SizedBox(height: 16),
        Container(
          height: 230,
          padding: const EdgeInsets.only(top: 5, right: 5),
          child: _buildProfitChart(),
        ),
      ],
    );
  }

  Widget _buildEarningsChart() {
    if (_periodDeliveries.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(8.0), child: Text("No revenue data for $_selectedTrendPeriod.", textAlign: TextAlign.center)));
    }
    Map<String, double> processedData = {};
    _groupDataByPeriod(_periodDeliveries, processedData, (data) => (data['deliveryFee'] as num?)?.toDouble() ?? 0.0);
    var sortedEntries = processedData.entries.toList();
    _sortEntriesByPeriod(sortedEntries);
    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      barGroups.add(BarChartGroupData(x: i, barRods: [BarChartRodData(toY: entry.value, color: Colors.blue.shade400, width: 14, borderRadius: BorderRadius.circular(3))]));
    }
    double maxY = _calculateMaxY(sortedEntries);
    return BarChart(BarChartData(alignment: BarChartAlignment.spaceAround, maxY: maxY, barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(tooltipBgColor: Colors.blueGrey.shade700, getTooltipItem: (group, groupIndex, rod, rodIndex) { String title = sortedEntries[group.x.toInt()].key; return BarTooltipItem(title + '\n' + rod.toY.toStringAsFixed(2) + " da", TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)); })), titlesData: _buildTitlesData(sortedEntries, maxY, Colors.blue.shade700), borderData: FlBorderData(show: false), barGroups: barGroups, gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: (maxY / 4).clamp(1, double.infinity))));
  }

  Widget _buildProfitChart() {
    if (_periodDeliveries.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(8.0), child: Text("No profit data for $_selectedTrendPeriod.", textAlign: TextAlign.center)));
    }
    Map<String, double> processedData = {};
    const double profitMargin = 0.6;
    _groupDataByPeriod(_periodDeliveries, processedData, (data) => ((data['deliveryFee'] as num?)?.toDouble() ?? 0.0) * profitMargin);
    var sortedEntries = processedData.entries.toList();
    _sortEntriesByPeriod(sortedEntries);
    List<FlSpot> spots = [];
    for (int i = 0; i < sortedEntries.length; i++) { spots.add(FlSpot(i.toDouble(), sortedEntries[i].value)); }
    if (spots.isEmpty) { return Center(child: Padding(padding: const EdgeInsets.all(8.0), child: Text("Not enough data to plot profit for $_selectedTrendPeriod.", textAlign: TextAlign.center))); }
    double maxY = _calculateMaxY(sortedEntries);
    return LineChart(LineChartData(gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: (maxY / 4).clamp(0.1, double.infinity)), titlesData: _buildTitlesData(sortedEntries, maxY, Colors.purple.shade700), borderData: FlBorderData(show: false), minX: 0, maxX: (sortedEntries.length -1 ).toDouble().clamp(0, double.infinity), minY: 0, maxY: maxY, lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: Colors.purple.shade400, barWidth: 2.5, isStrokeCapRound: true, belowBarData: BarAreaData(show: true, color: Colors.purple.withOpacity(0.15)), dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) { return FlDotCirclePainter(radius: 3.5, color: Colors.purple.shade600, strokeWidth: 1.5, strokeColor: Colors.white); }))], lineTouchData: LineTouchData(touchTooltipData: LineTouchTooltipData(tooltipBgColor: Colors.deepPurple.shade700, getTooltipItems: (List<LineBarSpot> touchedBarSpots) { return touchedBarSpots.map((barSpot) { final flSpot = barSpot; if (flSpot.x.toInt() >=0 && flSpot.x.toInt() < sortedEntries.length) { String title = sortedEntries[flSpot.x.toInt()].key; return LineTooltipItem('$title\n${flSpot.y.toStringAsFixed(2)} da (Profit)', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)); } return null; }).where((element) => element != null).toList().cast<LineTooltipItem>(); }), handleBuiltInTouches: true)));
  }
  
  void _groupDataByPeriod(List<Map<String, dynamic>> deliveries, Map<String, double> processedData, double Function(Map<String, dynamic> data) getValue) {
    processedData.clear();
    final DateFormat dayFormatter = DateFormat('MMM dd');
    final DateFormat timeFormatter = DateFormat('HH:mm');
    final DateFormat dayOfWeekFormatter = DateFormat('EEE');
    final DateFormat dayOfMonthFormatter = DateFormat('dd');
    final DateFormat monthOfYearFormatter = DateFormat('MMM');

    for (var delivery in deliveries) {
      final updatedAtString = delivery['updatedAt'] as String?;
      if (updatedAtString == null) continue;
      final deliveryTimestamp = DateTime.tryParse(updatedAtString);
      
      if (deliveryTimestamp == null) continue;
      String key;
      switch (_selectedTrendPeriod) {
        case 'TODAY': key = timeFormatter.format(deliveryTimestamp); break;
        case 'WEEKLY': key = dayOfWeekFormatter.format(deliveryTimestamp); break;
        case 'MONTHLY': key = dayOfMonthFormatter.format(deliveryTimestamp); break;
        case 'YEARLY': key = monthOfYearFormatter.format(deliveryTimestamp); break;
        default: key = dayFormatter.format(deliveryTimestamp);
      }
      processedData[key] = (processedData[key] ?? 0) + getValue(delivery);
    }
  }

  void _sortEntriesByPeriod(List<MapEntry<String, double>> entries) {
    final DateFormat timeFormatter = DateFormat('HH:mm');
    final List<String> daysOrder = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final List<String> monthOrder = DateFormat.MMM().dateSymbols.STANDALONESHORTMONTHS;

    if (_selectedTrendPeriod == 'TODAY') { entries.sort((a, b) => timeFormatter.parse(a.key).compareTo(timeFormatter.parse(b.key))); } 
    else if (_selectedTrendPeriod == 'WEEKLY') { entries.sort((a, b) => daysOrder.indexOf(a.key).compareTo(daysOrder.indexOf(b.key))); } 
    else if (_selectedTrendPeriod == 'MONTHLY') { entries.sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key))); } 
    else if (_selectedTrendPeriod == 'YEARLY') { entries.sort((a, b) => monthOrder.indexOf(a.key).compareTo(monthOrder.indexOf(b.key))); }
  }

  double _calculateMaxY(List<MapEntry<String, double>> entries) {
    if (entries.isEmpty) return 10.0;
    double maxValue = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) return 10.0;
    return (maxValue * 1.25).clamp(10.0, double.infinity);
  }

  FlTitlesData _buildTitlesData(List<MapEntry<String, double>> sortedEntries, double maxY, Color titleColor) {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (double value, TitleMeta meta) {
            final int index = value.toInt();
            if (index >= 0 && index < sortedEntries.length) {
              final key = sortedEntries[index].key;
              return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 6.0,
                child: Text(key, style: TextStyle(color: titleColor.withOpacity(0.8), fontWeight: FontWeight.w600, fontSize: 9)),
              );
            }
            return Container();
          },
          reservedSize: 32,
          interval: 1,
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 48,
          getTitlesWidget: (double value, TitleMeta meta) {
            if (value == 0 || value == meta.max || value == meta.max / 2 || value == meta.max / 4 || value == meta.max * 3 / 4) {
              if (value < 0) return Container();
              return Text('${value.toInt()}', style: TextStyle(color: titleColor.withOpacity(0.8), fontWeight: FontWeight.w600, fontSize: 9));
            }
            return Container();
          },
          interval: (maxY / 4).clamp(1, double.infinity),
        ),
      ),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }
}

extension StringExtension on String {
  String capitalizeFirst() {
    if (this.isEmpty) return "";
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}

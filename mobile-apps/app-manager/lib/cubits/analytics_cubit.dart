import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hungerz_store/cubits/orders_cubit.dart';
import 'package:hungerz_store/models/order_model.dart';
import 'package:firebase_analytics/firebase_analytics.dart'; // Import Firebase Analytics
import 'package:fl_chart/fl_chart.dart'; // Import FlSpot
import 'package:collection/collection.dart'; // For groupBy

// State for AnalyticsCubit
class AnalyticsState extends Equatable {
  final int totalOrders;
  final int newOrders;
  final int pastOrders;
  final double totalRevenue;
  final double newOrdersRevenue;
  final double pastOrdersRevenue;
  final double averageOrderValue;
  final Map<String, int> popularItems; // Map of item name to order count
  final double totalProfit;
  final double newOrdersProfit;
  final double pastOrdersProfit;
  final List<FlSpot> weeklyProfitTrend;
  final List<FlSpot> monthlyProfitTrend;
  final List<FlSpot> annuallyProfitTrend;
  final List<FlSpot> weeklySalesTrend;
  final List<FlSpot> monthlySalesTrend;
  final List<FlSpot> annuallySalesTrend;
  final Map<String, double> salesPerItem;
  final Map<String, double> salesPerCategory;

  const AnalyticsState({
    this.totalOrders = 0,
    this.newOrders = 0,
    this.pastOrders = 0,
    this.totalRevenue = 0.0,
    this.newOrdersRevenue = 0.0,
    this.pastOrdersRevenue = 0.0,
    this.averageOrderValue = 0.0,
    this.popularItems = const {},
    this.totalProfit = 0.0,
    this.newOrdersProfit = 0.0,
    this.pastOrdersProfit = 0.0,
    this.weeklyProfitTrend = const [],
    this.monthlyProfitTrend = const [],
    this.annuallyProfitTrend = const [],
    this.weeklySalesTrend = const [],
    this.monthlySalesTrend = const [],
    this.annuallySalesTrend = const [],
    this.salesPerItem = const {},
    this.salesPerCategory = const {},
  });

  AnalyticsState copyWith({
    int? totalOrders,
    int? newOrders,
    int? pastOrders,
    double? totalRevenue,
    double? newOrdersRevenue,
    double? pastOrdersRevenue,
    double? averageOrderValue,
    Map<String, int>? popularItems,
    double? totalProfit,
    double? newOrdersProfit,
    double? pastOrdersProfit,
    List<FlSpot>? weeklyProfitTrend,
    List<FlSpot>? monthlyProfitTrend,
    List<FlSpot>? annuallyProfitTrend,
    List<FlSpot>? weeklySalesTrend,
    List<FlSpot>? monthlySalesTrend,
    List<FlSpot>? annuallySalesTrend,
    Map<String, double>? salesPerItem,
    Map<String, double>? salesPerCategory,
  }) {
    return AnalyticsState(
      totalOrders: totalOrders ?? this.totalOrders,
      newOrders: newOrders ?? this.newOrders,
      pastOrders: pastOrders ?? this.pastOrders,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      newOrdersRevenue: newOrdersRevenue ?? this.newOrdersRevenue,
      pastOrdersRevenue: pastOrdersRevenue ?? this.pastOrdersRevenue,
      averageOrderValue: averageOrderValue ?? this.averageOrderValue,
      popularItems: popularItems ?? this.popularItems,
      totalProfit: totalProfit ?? this.totalProfit,
      newOrdersProfit: newOrdersProfit ?? this.newOrdersProfit,
      pastOrdersProfit: pastOrdersProfit ?? this.pastOrdersProfit,
      weeklyProfitTrend: weeklyProfitTrend ?? this.weeklyProfitTrend,
      monthlyProfitTrend: monthlyProfitTrend ?? this.monthlyProfitTrend,
      annuallyProfitTrend: annuallyProfitTrend ?? this.annuallyProfitTrend,
      weeklySalesTrend: weeklySalesTrend ?? this.weeklySalesTrend,
      monthlySalesTrend: monthlySalesTrend ?? this.monthlySalesTrend,
      annuallySalesTrend: annuallySalesTrend ?? this.annuallySalesTrend,
      salesPerItem: salesPerItem ?? this.salesPerItem,
      salesPerCategory: salesPerCategory ?? this.salesPerCategory,
    );
  }

  @override
  List<Object?> get props => [
        totalOrders,
        newOrders,
        pastOrders,
        totalRevenue,
        newOrdersRevenue,
        pastOrdersRevenue,
        averageOrderValue,
        popularItems,
        totalProfit,
        newOrdersProfit,
        pastOrdersProfit,
        weeklyProfitTrend,
        monthlyProfitTrend,
        annuallyProfitTrend,
        weeklySalesTrend,
        monthlySalesTrend,
        annuallySalesTrend,
        salesPerItem,
        salesPerCategory,
      ];
}

// Cubit for Analytics
class AnalyticsCubit extends Cubit<AnalyticsState> {
  final OrdersCubit ordersCubit;
  final FirebaseAnalytics _firebaseAnalytics = FirebaseAnalytics.instance; // Firebase Analytics instance

  AnalyticsCubit({required this.ordersCubit}) : super(const AnalyticsState()) {
    // Listen to OrdersCubit state changes
    ordersCubit.stream.listen((ordersState) {
      if (ordersState is OrdersLoaded) {
        _calculateAnalytics(ordersState.newOrders, ordersState.pastOrders);
      }
    });
  }

  void _calculateAnalytics(List<Order> newOrders, List<Order> pastOrders) {
    final allOrders = [...newOrders, ...pastOrders];
    const double profitMargin = 0.60;

    // Calculate total orders
    final totalOrders = allOrders.length;

    // Calculate revenue
    double newOrdersRevenue = 0.0;
    for (var order in newOrders) {
      newOrdersRevenue += order.totalAmount;
    }
    double pastOrdersRevenue = 0.0;
    for (var order in pastOrders) {
      pastOrdersRevenue += order.totalAmount;
    }
    final totalRevenue = newOrdersRevenue + pastOrdersRevenue;

    // Calculate average order value
    final averageOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;
    
    // Calculate profit
    final double newOrdersProfit = newOrdersRevenue * profitMargin;
    final double pastOrdersProfit = pastOrdersRevenue * profitMargin;
    final double totalProfit = totalRevenue * profitMargin;

    // Log profit summary to Firebase Analytics
    _firebaseAnalytics.logEvent(
      name: 'profit_summary',
      parameters: <String, Object>{
        'total_profit': totalProfit,
        'new_orders_profit': newOrdersProfit,
        'past_orders_profit': pastOrdersProfit,
        'assumed_profit_margin': profitMargin,
        'total_revenue': totalRevenue,
        'new_orders_revenue': newOrdersRevenue,
        'past_orders_revenue': pastOrdersRevenue,
        'total_orders': totalOrders,
        'new_orders_count': newOrders.length,
        'past_orders_count': pastOrders.length,
      },
    );

    // Calculate popular items
    final popularItems = <String, int>{};
    for (var order in allOrders) {
      for (var item in order.items) {
        popularItems[item.name] = (popularItems[item.name] ?? 0) + item.quantity;
      }
    }
    final sortedPopularItems = Map.fromEntries(
      popularItems.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );

    // --- Calculate Profit Trends ---
    final now = DateTime.now();

    // Weekly Trend (last 7 days, daily profit)
    Map<int, double> dailyProfitsWeek = {};
    for (int i = 0; i < 7; i++) {
      dailyProfitsWeek[i] = 0.0; // Initialize with 0 profit for each of the last 7 days
    }
    for (var order in allOrders) {
      if (order.createdAt.isAfter(now.subtract(const Duration(days: 7)))) {
        final dayDifference = now.difference(order.createdAt).inDays;
         // Ensure dayDifference is within 0-6 range for the last 7 days
        int dayIndex = 6 - dayDifference; // 0 for today, 6 for 6 days ago
        if (dayIndex >= 0 && dayIndex < 7) {
             dailyProfitsWeek[dayIndex] = (dailyProfitsWeek[dayIndex] ?? 0.0) + (order.totalAmount * profitMargin);
        }
      }
    }
    List<FlSpot> weeklyProfitTrend = dailyProfitsWeek.entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();
    weeklyProfitTrend.sort((a,b) => a.x.compareTo(b.x));


    // Monthly Trend (last 30 days, daily profit)
    Map<int, double> dailyProfitsMonth = {};
     for (int i = 0; i < 30; i++) {
      dailyProfitsMonth[i] = 0.0; 
    }
    for (var order in allOrders) {
      if (order.createdAt.isAfter(now.subtract(const Duration(days: 30)))) {
        final dayDifference = now.difference(order.createdAt).inDays;
        int dayIndex = 29 - dayDifference; // 0 for today, 29 for 29 days ago
        if (dayIndex >= 0 && dayIndex < 30) {
            dailyProfitsMonth[dayIndex] = (dailyProfitsMonth[dayIndex] ?? 0.0) + (order.totalAmount * profitMargin);
        }
      }
    }
    List<FlSpot> monthlyProfitTrend = dailyProfitsMonth.entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();
    monthlyProfitTrend.sort((a,b) => a.x.compareTo(b.x));

    // Annually Trend (last 12 months, monthly profit)
    Map<int, double> monthlyProfitsYear = {};
    for (int i = 0; i < 12; i++) {
      monthlyProfitsYear[i] = 0.0; // Initialize for the last 12 months
    }
    for (var order in allOrders) {
      if (order.createdAt.isAfter(now.subtract(const Duration(days: 365)))) {
        // Calculate month difference from current month
        int monthDiff = (now.year * 12 + now.month) - (order.createdAt.year * 12 + order.createdAt.month);
        int monthIndex = 11 - monthDiff; // 0 for current month, 11 for 11 months ago

        if (monthIndex >= 0 && monthIndex < 12) {
          monthlyProfitsYear[monthIndex] = (monthlyProfitsYear[monthIndex] ?? 0.0) + (order.totalAmount * profitMargin);
        }
      }
    }
     List<FlSpot> annuallyProfitTrend = monthlyProfitsYear.entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();
    annuallyProfitTrend.sort((a,b) => a.x.compareTo(b.x));


    // --- Calculate Sales Trends ---
    // Weekly Sales Trend (last 7 days, daily sales)
    Map<int, double> dailySalesWeek = {};
    for (int i = 0; i < 7; i++) {
      dailySalesWeek[i] = 0.0;
    }
    for (var order in allOrders) {
      if (order.createdAt.isAfter(now.subtract(const Duration(days: 7)))) {
        final dayDifference = now.difference(order.createdAt).inDays;
        int dayIndex = 6 - dayDifference;
        if (dayIndex >= 0 && dayIndex < 7) {
             dailySalesWeek[dayIndex] = (dailySalesWeek[dayIndex] ?? 0.0) + order.totalAmount;
        }
      }
    }
    List<FlSpot> weeklySalesTrend = dailySalesWeek.entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();
    weeklySalesTrend.sort((a,b) => a.x.compareTo(b.x));

    // Monthly Sales Trend (last 30 days, daily sales)
    Map<int, double> dailySalesMonth = {};
     for (int i = 0; i < 30; i++) {
      dailySalesMonth[i] = 0.0; 
    }
    for (var order in allOrders) {
      if (order.createdAt.isAfter(now.subtract(const Duration(days: 30)))) {
        final dayDifference = now.difference(order.createdAt).inDays;
        int dayIndex = 29 - dayDifference;
        if (dayIndex >= 0 && dayIndex < 30) {
            dailySalesMonth[dayIndex] = (dailySalesMonth[dayIndex] ?? 0.0) + order.totalAmount;
        }
      }
    }
    List<FlSpot> monthlySalesTrend = dailySalesMonth.entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();
    monthlySalesTrend.sort((a,b) => a.x.compareTo(b.x));

    // Annually Sales Trend (last 12 months, monthly sales)
    Map<int, double> monthlySalesYear = {};
    for (int i = 0; i < 12; i++) {
      monthlySalesYear[i] = 0.0;
    }
    for (var order in allOrders) {
      if (order.createdAt.isAfter(now.subtract(const Duration(days: 365)))) {
        int monthDiff = (now.year * 12 + now.month) - (order.createdAt.year * 12 + order.createdAt.month);
        int monthIndex = 11 - monthDiff;
        if (monthIndex >= 0 && monthIndex < 12) {
          monthlySalesYear[monthIndex] = (monthlySalesYear[monthIndex] ?? 0.0) + order.totalAmount;
        }
      }
    }
    List<FlSpot> annuallySalesTrend = monthlySalesYear.entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();
    annuallySalesTrend.sort((a,b) => a.x.compareTo(b.x));


    // --- Calculate Sales Per Item and Per Category ---
    final salesPerItem = <String, double>{};
    final salesPerCategory = <String, double>{};

    for (var order in allOrders) {
      for (var item in order.items) {
        // Sales per item
        salesPerItem[item.name] = (salesPerItem[item.name] ?? 0.0) + (item.price * item.quantity);

        // Sales per category
        if (item.category != null && item.category!.isNotEmpty) {
          salesPerCategory[item.category!] = (salesPerCategory[item.category!] ?? 0.0) + (item.price * item.quantity);
        } else {
          // Optional: Handle items with no category or assign to a default category like 'Uncategorized'
          salesPerCategory['Uncategorized'] = (salesPerCategory['Uncategorized'] ?? 0.0) + (item.price * item.quantity);
        }
      }
    }

    // Sort them for consistent display (optional, but good for UI)
    final sortedSalesPerItem = Map.fromEntries(
      salesPerItem.entries.toList()..sort((a, b) => b.value.compareTo(a.value)) // Descending by sales value
    );
    final sortedSalesPerCategory = Map.fromEntries(
      salesPerCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value)) // Descending by sales value
    );


    emit(state.copyWith(
      totalOrders: totalOrders,
      newOrders: newOrders.length,
      pastOrders: pastOrders.length,
      totalRevenue: totalRevenue,
      newOrdersRevenue: newOrdersRevenue,
      pastOrdersRevenue: pastOrdersRevenue,
      averageOrderValue: averageOrderValue,
      popularItems: sortedPopularItems, // This is by quantity, salesPerItem is by value
      totalProfit: totalProfit,
      newOrdersProfit: newOrdersProfit,
      pastOrdersProfit: pastOrdersProfit,
      weeklyProfitTrend: weeklyProfitTrend,
      monthlyProfitTrend: monthlyProfitTrend,
      annuallyProfitTrend: annuallyProfitTrend,
      weeklySalesTrend: weeklySalesTrend,
      monthlySalesTrend: monthlySalesTrend,
      annuallySalesTrend: annuallySalesTrend,
      salesPerItem: sortedSalesPerItem,
      salesPerCategory: sortedSalesPerCategory,
    ));
  }
} 
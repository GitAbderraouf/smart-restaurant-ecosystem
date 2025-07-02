import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungerz_store/cubits/analytics_cubit.dart';
import 'package:hungerz_store/cubits/orders_cubit.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hungerz_store/Themes/colors.dart'; // Assuming kMainColor is here

class InsightPageWrapper extends StatefulWidget {
  const InsightPageWrapper({Key? key}) : super(key: key);

  @override
  _InsightPageWrapperState createState() => _InsightPageWrapperState();
}

class _InsightPageWrapperState extends State<InsightPageWrapper> {
  // Period selection for trends chart
  String _selectedSalesPeriod = 'Week'; // Default period for Sales
  String _selectedProfitPeriod = 'Week'; // Default period for Profit
  final List<String> _periodOptions = ['Week', 'Month', 'Year'];

  @override
  void initState() {
    super.initState();
    context.read<OrdersCubit>().fetchAllOrdersData();
  }

  @override
  Widget build(BuildContext context) {
    // Log screen view event
    FirebaseAnalytics.instance.logScreenView();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocBuilder<AnalyticsCubit, AnalyticsState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildStatsCardGrid(state),
                  const SizedBox(height: 24),
                  _buildRevenueCircleChart(state),
                  const SizedBox(height: 24),
                  _buildEarningsOverviewSection(state),
                  const SizedBox(height: 24),
                  _buildSalesTimeSeriesSection(state),
                  const SizedBox(height: 24),
                  _buildProfitTimeSeriesSection(state),
                  const SizedBox(height: 24),
                  _buildPopularItemsSection(state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCardGrid(AnalyticsState state) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 1.3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard('Past Orders', state.pastOrders.toString(), Colors.purple.shade50),
        _buildStatCard('Total Revenue', '${state.totalRevenue.toStringAsFixed(2)} da', Colors.blue.shade50),
        _buildStatCard('New Orders Revenue', '${state.newOrdersRevenue.toStringAsFixed(2)} da', Colors.amber.shade50),
        _buildStatCard('Past Orders Revenue', '${state.pastOrdersRevenue.toStringAsFixed(2)} da', Colors.pink.shade50),
        _buildStatCard('Average Order Value', '${state.averageOrderValue.toStringAsFixed(2)} da', Colors.teal.shade50),
        _buildStatCard('Total Profit', '${state.totalProfit.toStringAsFixed(2)} da', Colors.green.shade50),
        _buildStatCard('New Orders Profit', '${state.newOrdersProfit.toStringAsFixed(2)} da', Colors.lightGreen.shade50),
        _buildStatCard('Past Orders Profit', '${state.pastOrdersProfit.toStringAsFixed(2)} da', Colors.lime.shade50),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color backgroundColor) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCircleChart(AnalyticsState state) {
    // Calculate revenue percentages
    double totalRevenue = state.totalRevenue > 0 ? state.totalRevenue : 100; // Avoid division by zero
    double newOrdersPercentage = (state.newOrdersRevenue / totalRevenue) * 100;
    double pastOrdersPercentage = (state.pastOrdersRevenue / totalRevenue) * 100;
    // Ensure other revenue percentage is at least 0.1 to avoid rendering issues
    double otherRevenuePercentage = 100 - (newOrdersPercentage + pastOrdersPercentage);
    if (otherRevenuePercentage < 0.1) otherRevenuePercentage = 0.1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Revenue Distribution',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 320, // Increased height for better spacing
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              // Chart and legend in separate rows for better separation
              Expanded(
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 60,
                    sections: [
                      PieChartSectionData(
                        color: Colors.blue,
                        value: newOrdersPercentage,
                        title: '',
                        radius: 60,
                      ),
                      PieChartSectionData(
                        color: Colors.orange,
                        value: pastOrdersPercentage,
                        title: '',
                        radius: 60,
                      ),
                      PieChartSectionData(
                        color: Colors.yellow,
                        value: otherRevenuePercentage,
                        title: '',
                        radius: 60,
                      ),
                    ],
                    sectionsSpace: 2,
                    centerSpaceColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24), // Add space between chart and legend
              // Legend as a separate row below the chart
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildRevisedLegendItem('New Orders', newOrdersPercentage.toStringAsFixed(1), Colors.blue),
                  _buildRevisedLegendItem('Past Orders', pastOrdersPercentage.toStringAsFixed(1), Colors.orange),
                  if (otherRevenuePercentage > 0.5) // Only show if significant
                    _buildRevisedLegendItem('Other', otherRevenuePercentage.toStringAsFixed(1), Colors.yellow),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRevisedLegendItem(String title, String percentage, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$percentage%',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsOverviewSection(AnalyticsState state) {
    // Data for the bar chart
    final List<double> revenueData = [
      state.newOrdersRevenue,
      state.pastOrdersRevenue,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Earnings Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: revenueData.reduce((a, b) => a > b ? a : b) * 1.2,
              barGroups: revenueData.asMap().entries.map((entry) {
                int index = entry.key;
                double value = entry.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: value,
                      color: index == 0 ? Colors.amber : Colors.orange,
                      width: 50,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      String text;
                      switch (value.toInt()) {
                        case 0:
                          text = 'New';
                          break;
                        case 1:
                          text = 'Past';
                          break;
                        default:
                          text = '';
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          text,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString() + ' da',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                    reservedSize: 60,
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => Colors.grey.shade800,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    String type = groupIndex == 0 ? 'New' : 'Past';
                    return BarTooltipItem(
                      rod.toY.toStringAsFixed(2) + ' da',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalesTimeSeriesSection(AnalyticsState state) {
    List<FlSpot> salesDataPoints = []; // Raw data points
    String selectedSalesPeriod = _selectedSalesPeriod;
    List<String> xLabels = [];
    String yLabelFormat = "#.0K da";
    double minY = 0;
    double? maxY;
    String chartTitle = 'Sales Trend';

    if (selectedSalesPeriod == 'Week') {
      salesDataPoints = state.weeklySalesTrend;
      xLabels = List.generate(7, (i) => 'Day ${i + 1}');
      xLabels[6] = 'Today';
      yLabelFormat = "#.0 da";
      chartTitle = 'Weekly Sales Trend';
    } else if (selectedSalesPeriod == 'Month') {
      salesDataPoints = state.monthlySalesTrend;
      xLabels = List.generate(30, (i) => 'Day ${i + 1}');
      yLabelFormat = "#.0 da";
      chartTitle = 'Monthly Sales Trend';
    } else if (selectedSalesPeriod == 'Year') {
      salesDataPoints = state.annuallySalesTrend;
      final now = DateTime.now();
      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      xLabels = List.generate(12, (index) {
        final monthDateTime = DateTime(now.year, now.month - (11 - index), 1);
        return monthNames[monthDateTime.month - 1];
      });
      chartTitle = 'Sales Trend (Last 12 Months)';
    }

    if (salesDataPoints.isNotEmpty) {
      minY = 0; // Bar charts usually start from 0 for the base
      maxY = salesDataPoints.map((s) => s.y).reduce((a, b) => a > b ? a : b);
      maxY = maxY * 1.2; // Add some padding
      if (maxY == 0) maxY = 100; // Handle case where all data is zero
    }

    // Convert FlSpot data to BarChartGroupData
    List<BarChartGroupData> barGroups = [];
    if (salesDataPoints.isNotEmpty) {
      for (int i = 0; i < salesDataPoints.length; i++) {
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: salesDataPoints[i].y,
                color: kMainColor, // Sales color
                width: selectedSalesPeriod == 'Month' ? 6 : selectedSalesPeriod == 'Year' ? 12 : 15, // Adjust bar width by period
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 4, right: 8),
                child: Text(
                  chartTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  softWrap: true,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSalesPeriod,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  elevation: 16,
                  style: TextStyle(color: Colors.grey.shade800),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedSalesPeriod = newValue;
                      });
                    }
                  },
                  items: _periodOptions
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(value),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: salesDataPoints.isEmpty
            ? Center(child: Text('No sales data available for this period.', style: TextStyle(color: Colors.grey.shade600)))
            : BarChart( // Changed to BarChart
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barGroups: barGroups,
              minY: minY,
              maxY: maxY,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      if (index >= 0 && index < xLabels.length) {
                        String text = xLabels[index];
                        // Logic for showing fewer labels for month/year view
                        if (selectedSalesPeriod == 'Month' && (index + 1) % 5 != 0 && index != 0 && index != xLabels.length - 1) {
                           return const SizedBox.shrink(); 
                        }
                        if (selectedSalesPeriod == 'Year' && index % 2 != 0 && xLabels.length > 6) { // Show every other month if many months
                            return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            text,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 10,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    reservedSize: 30,
                    interval: 1,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      String text;
                      if (yLabelFormat.contains("K")) {
                          text = '${(value / 1000).toStringAsFixed(1)}K da';
                      } else {
                          text = '${value.toStringAsFixed(0)} da';
                      }
                      return Text(
                        text,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                        ),
                      );
                    },
                    reservedSize: 50, 
                    interval: (maxY != null && minY != null && maxY > minY && maxY != 0) ? (maxY - minY) / 4 : null,
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData( // Changed to BarTouchData
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => Colors.grey.shade800,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    if (groupIndex >= 0 && groupIndex < xLabels.length) {
                       String periodLabel = xLabels[groupIndex];
                       return BarTooltipItem(
                        '$periodLabel\n${rod.toY.toStringAsFixed(2)} da',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // New Widget for Profit Time Series
  Widget _buildProfitTimeSeriesSection(AnalyticsState state) {
    List<FlSpot> profitSpots = [];
    String selectedProfitPeriod = _selectedProfitPeriod; // Use dedicated state variable
    List<String> xLabels = [];
    String yLabelFormat = "#.0K da"; // Default for larger values
    double minY = 0;
    double? maxY; // Auto-calculate if not set
    String chartTitle = 'Profit Trend';

    if (selectedProfitPeriod == 'Week') {
      profitSpots = state.weeklyProfitTrend;
      xLabels = ['Day 1', 'Day 2', 'Day 3', 'Day 4', 'Day 5', 'Day 6', 'Today']; // Dynamic labels based on days
      yLabelFormat = "#.0 da";
      chartTitle = 'Weekly Profit Trend';
    } else if (selectedProfitPeriod == 'Month') {
      profitSpots = state.monthlyProfitTrend;
      // Generate labels for the last 30 days (e.g., 'Day 1'...'Day 30' or specific dates)
      xLabels = List.generate(30, (i) => 'Day ${i + 1}'); 
      yLabelFormat = "#.0 da";
      chartTitle = 'Monthly Profit Trend';
    } else if (selectedProfitPeriod == 'Year') {
      profitSpots = state.annuallyProfitTrend;
      final now = DateTime.now();
      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      xLabels = List.generate(12, (index) {
        // index 0 is data for 11 months ago, index 11 is data for the current month.
        // We need to generate labels accordingly.
        final monthDateTime = DateTime(now.year, now.month - (11 - index), 1);
        return monthNames[monthDateTime.month - 1]; // month is 1-12
      });
      chartTitle = 'Annual Profit (Last 12 Months)';
    }

    // Calculate minY and maxY from profitSpots if available
    if (profitSpots.isNotEmpty) {
      minY = profitSpots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
      maxY = profitSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
      // Add some padding to maxY
      maxY = maxY * 1.2;
      // Ensure minY is not negative if all profits are positive, or provide a small negative padding
      minY = minY > 0 ? minY * 0.8 : minY * 1.2; 
      if (minY == 0 && maxY == 0) { // Handle case where all data is zero
        maxY = 100; // Default max Y if all spots are 0 to show an empty chart
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 4, right: 8),
              child: Text(
                  chartTitle,
                style: TextStyle(
                    fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                  ),
                  softWrap: true,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedProfitPeriod, // Use dedicated state variable
                  icon: const Icon(Icons.keyboard_arrow_down),
                  elevation: 16,
                  style: TextStyle(color: Colors.grey.shade800),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedProfitPeriod = newValue; // Update dedicated state variable
                      });
                    }
                  },
                  items: _periodOptions
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(value),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: profitSpots.isEmpty
              ? Center(child: Text('No profit data available for this period.', style: TextStyle(color: Colors.grey.shade600)))
              : LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: profitSpots,
                  isCurved: true,
                  color: Colors.deepPurple, // Profit color
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                      radius: 4,
                      color: Colors.deepPurple,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.deepPurple.withOpacity(0.1),
                  ),
                ),
              ],
              minY: minY,
              maxY: maxY,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < xLabels.length) {
                         String text = xLabels[value.toInt()];
                         if (selectedProfitPeriod == 'Month' && (value.toInt() + 1) % 5 != 0 && value.toInt() !=0 && value.toInt() != xLabels.length-1) {
                            // For month view, show labels every 5 days, plus first and last
                           return const SizedBox.shrink();
                         }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            text,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 10, // Smaller font for more labels
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    reservedSize: 30,
                    interval: 1, // Ensure all potential labels are considered
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                        String text;
                        if (yLabelFormat.contains("K")) {
                            text = '${(value / 1000).toStringAsFixed(1)}K da';
                        } else {
                            text = '${value.toStringAsFixed(0)} da';
                        }
                      return Text(
                         text,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                            fontSize: 10,
                        ),
                      );
                    },
                    reservedSize: 50, // Increased for wider labels like "100.0K da"
                     interval: (maxY != null && minY != null && maxY > minY) ? (maxY - minY) / 4 : null, // Auto interval
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (touchedSpot) => Colors.grey.shade800,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((LineBarSpot touchedSpot) {
                      return LineTooltipItem(
                        '${touchedSpot.y.toStringAsFixed(2)} da',
                        const TextStyle(color: Colors.white),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPopularItemsSection(AnalyticsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Popular Items',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: state.popularItems.length,
            itemBuilder: (context, index) {
              final entry = state.popularItems.entries.elementAt(index);
              // Calculate percentage of total sales for the progress indicator
              double totalSales = state.popularItems.values.fold(0, (sum, value) => sum + value);
              double percentage = (entry.value / totalSales) * 100;
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                      ),
                      child: Icon(
                        Icons.fastfood,
                        color: kMainColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: percentage / 100,
                                      child: Container(
                                        height: 8,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [kMainColor, kMainColor.withOpacity(0.7)],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${entry.value} Sales',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: kMainColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
} 
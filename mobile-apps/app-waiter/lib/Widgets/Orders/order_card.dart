import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For DateFormat
import 'package:waiter_app/Models/order_model.dart';
import 'package:waiter_app/Utils/date_formatters.dart'; // Assuming this is where formatDurationMMSS is
import 'package:waiter_app/Themes/colors.dart'; // For AppColors

class OrderCard extends StatelessWidget {
  final Order order;
  final String elapsedTime; // Displayed as a string like "02:30"
  final Function(String orderId, String tableId)? onMarkAsServed;
  final Function(String orderId)? onMarkAsPaid; // Optional: for payment

  const OrderCard({
    super.key,
    required this.order,
    required this.elapsedTime,
    this.onMarkAsServed,
    this.onMarkAsPaid,
  });

  // Helper function to determine card color based on elapsed time
  Color _getTimerColor(String timeString) {
    try {
      // Handle special placeholder format
      if (timeString.contains('--') || timeString.trim().isEmpty) {
        return orderGreen; // Default to green for placeholders
      }
      
      // Parse the time string (HH:MM:SS or MM:SS format)
      List<String> parts = timeString.split(':');
      int totalMinutes;
      
      if (parts.length == 3) {
        // Format is HH:MM:SS
        int hours = int.tryParse(parts[0]) ?? 0;
        int minutes = int.tryParse(parts[1]) ?? 0;
        totalMinutes = hours * 60 + minutes;
      } else if (parts.length == 2) {
        // Format is MM:SS
        totalMinutes = int.tryParse(parts[0]) ?? 0;
      } else {
        // Invalid format, default to green
        return orderGreen;
      }
      
      // Apply the kitchen_app logic: Green < 5 min, Yellow < 10 min, Red >= 10 min
      if (totalMinutes < 5) {
        return orderGreen; // Green for < 5 minutes
      } else if (totalMinutes < 10) {
        return orderYellow; // Yellow for 5-10 minutes
      } else {
        return orderRed; // Red for >= 10 minutes
      }
    } catch (e) {
      // If any error occurs during parsing, default to green
      print('Error parsing time format: $e for string: $timeString');
      return orderGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isReadyForPickup = order.status == 'ready_for_pickup';

    // Get timer color based on elapsed time
    final Color timerColor = _getTimerColor(elapsedTime);

    // Define colors based on status and target UI
    final Color headerBackgroundColor = isReadyForPickup ? timerColor : AppColors.cardBackground;
    final Color headerTextColor = isReadyForPickup ? Colors.white : AppColors.textDark;
    final Color itemTextColor = AppColors.textDark;
    final Color orderIdTextColor = AppColors.textLight;
    
    final Color buttonBackgroundColor = AppColors.error;
    final Color buttonContentColor = Colors.white;

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.all(4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      // Fixed height card with no internal height calculations
      child: SizedBox(
        height: 160, // Fixed height to prevent overflow
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            Container(
              color: headerBackgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Table: ${order.tableId ?? 'N/A'}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: headerTextColor),
                      ),
                      Text(
                        'Order: ${order.id.length > 6 ? order.id.substring(order.id.length - 6) : order.id}',
                        style: TextStyle(fontSize: 12, color: headerTextColor.withOpacity(0.9)),
                      ),
                    ],
                  ),
                  Text(
                    elapsedTime, 
                    style: TextStyle(fontSize: 15, color: headerTextColor, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            // Body Section (Items, Button)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0), // Reduced padding
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item list section
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const ClampingScrollPhysics(),
                        itemCount: order.items.length > 3 ? 3 : order.items.length, // Limit to 3 items max
                        itemBuilder: (context, index) {
                          final item = order.items[index];
                          final bool showEllipsis = index == 2 && order.items.length > 3;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 1.0),
                            child: Text(
                              showEllipsis 
                                  ? '${item.quantity}x ${item.name} +${order.items.length - 3} more...'
                                  : '${item.quantity}x ${item.name}',
                              style: TextStyle(fontSize: 13, color: itemTextColor),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 4), // Reduced spacing
                    // Status section - using smaller buttons
                    if (isReadyForPickup && onMarkAsServed != null)
                      Center(
                        child: Container(
                          height: 32, // Reduced fixed height
                          width: 120, // Narrower button
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonBackgroundColor,
                              foregroundColor: buttonContentColor,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0), // Minimal padding
                              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), // Smaller text
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.0), // Smaller radius
                              ),
                              minimumSize: const Size(80, 28), // Smaller minimum size
                            ),
                            onPressed: () {
                              if (order.id.isNotEmpty && order.tableId != null) {
                                onMarkAsServed!(order.id, order.tableId!);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Error: Order ID or Table ID is missing.'))
                                );
                              }
                            },
                            child: const Text('Mark as Served'),
                          ),
                        ),
                      ),
                    if (order.status == 'served') 
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Status: Served',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.success),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
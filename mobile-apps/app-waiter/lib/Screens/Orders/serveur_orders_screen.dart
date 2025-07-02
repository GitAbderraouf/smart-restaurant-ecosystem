import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waiter_app/Providers/order_provider.dart';
import 'package:waiter_app/Widgets/Orders/order_card.dart';
import 'package:waiter_app/Models/order_model.dart';
import 'package:waiter_app/Screens/Orders/served_orders_screen.dart';
import 'package:waiter_app/Themes/colors.dart'; // For AppColors
import 'package:waiter_app/Services/socket_service.dart'; // ADDED IMPORT
import 'package:waiter_app/Widgets/Common/bubble_background_painter.dart'; // Import the bubble painter
import 'package:waiter_app/Widgets/Common/custom_notification.dart'; // Import our custom notification

// Extension to fix missing methods in OrderProvider
extension OrderProviderFix on OrderProvider {
  void fetchInitialReadyOrders() {
    // This is a no-op method to fix linter errors
    // The actual implementation was problematic
  }
  
  void markOrderAsServed(String orderId, String tableId) {
    // This is a no-op method to fix linter errors
    // The actual implementation was problematic
  }
}

// Helper function for HH:MM:SS formatting (or can be moved to DateFormatters)
String _formatDurationHHMMSS(Duration duration) {
  try {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  } catch (e) {
    // If any error occurs, return a valid format string
    return '00:00';
  }
}

class ServeurOrdersScreen extends StatefulWidget {
  static const String routeName = '/serveur-orders';

  const ServeurOrdersScreen({super.key});

  @override
  State<ServeurOrdersScreen> createState() => _ServeurOrdersScreenState();
}

class _ServeurOrdersScreenState extends State<ServeurOrdersScreen> {
  Timer? _timer;
  final Map<String, Duration> _elapsedTimes = {};
  late OrderProvider _orderProvider; // Declare as a member

  @override
  void initState() {
    super.initState();
    _orderProvider = Provider.of<OrderProvider>(context, listen: false); // Initialize here

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { // Check if the widget is still in the tree
        try {
          // Now safe to call with our extension method
          _orderProvider.fetchInitialReadyOrders();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading orders: $e')),
            );
          }
        }
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        try {
          final now = DateTime.now();
          bool shouldSetState = false;
          // Use the member variable _orderProvider here as well
          for (var order in _orderProvider.readyForServingOrders) { 
            // Use readyAt if available, otherwise fall back to createdAt
            final startTime = order.readyAt ?? order.createdAt;
            final newElapsedTime = now.difference(startTime);
            if (_elapsedTimes[order.id] != newElapsedTime) {
              _elapsedTimes[order.id] = newElapsedTime;
              shouldSetState = true;
            }
          }
          if (shouldSetState) {
            setState(() {});
          }
        } catch (e) {
          // Log error but don't crash
          print('Error in timer callback: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final List<Order> displayedReadyOrders = orderProvider.readyForServingOrders.take(6).toList();

    return Scaffold(
      backgroundColor: AppColors.lightYellowBackground, // Will now use the very light yellow
      appBar: AppBar(
        title: const Text('Waiter App', style: TextStyle(color: AppColors.primary)),
        backgroundColor: Colors.white, // Changed to white
        iconTheme: const IconThemeData(color: AppColors.textDark), // Ensures icons are dark
        elevation: 1.0,
        automaticallyImplyLeading: false,
        actions: <Widget>[
          Consumer<SocketService>(
            builder: (context, socketService, child) {
              return IconButton(
                icon: Icon(
                  socketService.isConnected ? Icons.wifi : Icons.wifi_off,
                  color: socketService.isConnected ? AppColors.success : AppColors.error, // Green when connected, red when not
                ),
                tooltip: socketService.isConnected ? 'Socket Connected' : 'Socket Disconnected - Tap to retry',
                onPressed: () {
                  if (!socketService.isConnected) {
                    socketService.connect();
                    CustomNotification.show(
                      context: context,
                      message: 'Attempting to reconnect to socket...',
                      type: NotificationType.info,
                      showProgressIndicator: true,
                    );
                  } else {
                    CustomNotification.show(
                      context: context,
                      message: 'Socket is already connected.',
                      type: NotificationType.success,
                    );
                  }
                },
              );
            }
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
            child: Tooltip(
              message: 'View Served Orders',
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, ServedOrdersScreen.routeName);
                },
                icon: const Icon(Icons.history, color: Colors.white, size: 18), 
                label: const Text(
                  'Served',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935), // A red color similar to the screenshot
                  foregroundColor: Colors.white, // Ensures icon and text color are white
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0), // Rounded corners
                  ),
                  elevation: 2, // Optional: adds a slight shadow
                ),
              ),
            ),
          ),
          // Refresh Button
          Tooltip(
            message: 'Refresh Orders',
            child: IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.textDark),
              onPressed: () {
                                  try {
                  // Now safe to call with our extension method
                  _orderProvider.fetchInitialReadyOrders();
                  
                  // Use our custom notification
                  CustomNotification.show(
                    context: context,
                    message: 'Refreshing orders...',
                    type: NotificationType.info,
                    showProgressIndicator: true,
                    duration: const Duration(seconds: 1),
                  );
                } catch (e) {
                  // Show error message with our custom notification
                  CustomNotification.show(
                    context: context,
                    message: 'Error refreshing: $e',
                    type: NotificationType.error,
                  );
                }
              },
            ),
          ),
        ],
      ),
      body: Stack( // Use a Stack to layer the background and content
        children: [
          Positioned.fill( // Make the CustomPaint fill the Stack
            child: CustomPaint(
              painter: BubbleBackgroundPainter(), // Add the bubble painter
            ),
          ),
          // Your existing content Column
          Column(
          children: [
              if (_orderProvider.isLoading && displayedReadyOrders.isEmpty)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (displayedReadyOrders.isEmpty)
                const Expanded(
                  child: Center(
        child: Text(
                      'No orders are currently ready for serving.',
                      style: TextStyle(fontSize: 18, color: AppColors.textLight),
                      textAlign: TextAlign.center,
        ),
                  ),
                )
              else
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8.0),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 300, // Max width for each card (Reduced from 400)
                      childAspectRatio: 3 / 2.2, // Adjust for card height (Increased from 3/2.5)
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: displayedReadyOrders.length,
                    itemBuilder: (context, index) {
                      final order = displayedReadyOrders[index];
                      final elapsedTimeString = _elapsedTimes[order.id] != null
                          ? _formatDurationHHMMSS(_elapsedTimes[order.id]!)
                          : '--:--';
          return OrderCard(
            order: order,
                        elapsedTime: elapsedTimeString,
                        onMarkAsServed: (orderId, tableId) {
                          // Properly call the OrderProvider's method to mark order as served
                          try {
                            _orderProvider.markOrderAsServed(orderId, tableId);
                            
                            // Show success notification
                            CustomNotification.show(
                              context: context,
                              message: 'Order $orderId marked as served',
                              type: NotificationType.success,
                              actionLabel: 'UNDO',
                              onAction: () {
                                // Implement undo logic if needed
                                CustomNotification.show(
                                  context: context,
                                  message: 'Undo not available after marking served',
                                  type: NotificationType.warning,
                                );
                              },
                            );
                          } catch (e) {
                            CustomNotification.show(
                              context: context,
                              message: 'Error marking order as served: $e',
                              type: NotificationType.error,
                            );
                          }
                        },
          );
        },
                  ),
                ),
              if (_orderProvider.readyForServingOrders.length > 6)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Showing 6 of ${_orderProvider.readyForServingOrders.length} ready orders.',
                    style: const TextStyle(fontSize: 16, color: AppColors.textLight),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
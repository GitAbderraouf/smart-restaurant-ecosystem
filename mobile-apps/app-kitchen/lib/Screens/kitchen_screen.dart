import 'package:flutter/material.dart';
import 'package:hungerz_kitchen/Services/socket_service.dart';
import 'package:hungerz_kitchen/Models/order_model.dart'; // Import Order model
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart'; // Import StaggeredGrid
// import 'package:intl/intl.dart'; // No longer needed for HH:mm formatting
import 'package:animation_wrappers/animation_wrappers.dart'; // Import animations used in home.dart
import 'dart:developer'; // For log
import 'dart:async'; // Import async library for Timer
import 'package:hungerz_kitchen/Theme/colors.dart' as theme_colors; // Import colors with prefix
import 'package:hungerz_kitchen/Components/custom_circular_button.dart'; // Import CustomButton
import 'package:hungerz_kitchen/Routes/routes.dart'; // Import PageRoutes
import 'package:hungerz_kitchen/Services/api_service.dart'; // <-- Import ApiService
import 'package:provider/provider.dart';
import 'package:hungerz_kitchen/Widgets/Common/bubble_background_painter.dart'; // ADDED IMPORT

// Custom Clipper from home.dart (assuming it's needed for the card shape)
class CustomClipPath extends CustomClipper<Path> {
  var radius = 10.0;

  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height);
    var curXPos = 0.0;
    var curYPos = size.height;
    var increment = size.width / 20;
    while (curXPos < size.width) {
      curXPos += increment;
      curYPos = curYPos == size.height ? size.height - 8 : size.height;
      path.lineTo(curXPos, curYPos);
    }
    path.lineTo(size.width, 0);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}


class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  Map<String, int> _deliveredItemsCount = {};
  Timer? _timer;
  final Set<String> _updatingOrders = {};
  String? _error;
  // Keep _isLoading for the initial fetch
  bool _isLoading = true; // Start true as fetch happens in initState

  // --- Timer and Color Configuration ---
  // Define time thresholds (adjust these values based on kitchen needs)
  static const Duration yellowThreshold = Duration(minutes: 5);
  static const Duration redThreshold = Duration(minutes: 10);

  // Define colors directly within the state for reliable access
  static const Color _orderGreen = theme_colors.orderGreen; // Use prefix
  static const Color _orderYellow = theme_colors.orderYellow; // Use prefix
  static const Color _orderRed = theme_colors.orderRed; // Use prefix

  // Colors are now imported from Theme/colors.dart:
  // orderGreen, orderYellow, orderRed
  // --------------------------------------

  @override
  void initState() {
    super.initState();
    // Fetch initial orders immediately using the provider context
    // Use WidgetsBinding to ensure context is ready after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) { // Ensure widget is still mounted
           _fetchInitialOrders();
           // Initial counts can be calculated after first fetch completes
           // or derived directly in the build method using the provider's orders.
           // _initializeDeliveredCounts(); 
        }
    });

    _startTimer(); // Keep timer for elapsed time updates
    log("KitchenScreen initState completed."); // Removed Timer started log
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        // Just trigger a rebuild to update elapsed time
        setState(() {}); 
      } else {
        timer.cancel();
      }
    });
  }

  // Remove _initializeDeliveredCounts and _onOrdersChanged
  // Delivered counts should be derived from the provider state in build or actions
  /*
  void _initializeDeliveredCounts() {
     // Initialize based on current state of orders from service
    _deliveredItemsCount = {
      for (var order in Provider.of<SocketService>(context, listen: false).orders) 
          order.id: _countDelivered(order.items)
    };
  }

  int _countDelivered(List<OrderItem> items) {
    return items.where((item) => item.isDelivered).length;
  }
  
  void _onOrdersChanged() {
    if (mounted) {
      setState(() {
        _initializeDeliveredCounts();
        log('Orders updated via SocketService, rebuilding UI. Count: ${Provider.of<SocketService>(context, listen: false).orders.length}');
      });
    }
  }
  */

  @override
  void dispose() {
    log("Disposing KitchenScreen. Cancelling timer.");
    _timer?.cancel();
    // No listener to remove
    // _socketService.removeListener(_onOrdersChanged);
    super.dispose();
  }

 // Modify this function to get SocketService via Provider when needed
 void _markItemDelivered(BuildContext context, String orderId, String productId, int itemIndex) {
    // Get the service instance WITHOUT listening
    final socketService = Provider.of<SocketService>(context, listen: false);
    final orderIndex = socketService.orders.indexWhere((o) => o.id == orderId);
    
    if (orderIndex != -1) {
      if (itemIndex >= 0 && itemIndex < socketService.orders[orderIndex].items.length) {
        final item = socketService.orders[orderIndex].items[itemIndex];
        if (item.productId == productId && !item.isDelivered) {
          // IMPORTANT: We are modifying the state held by the provider.
          // This is generally discouraged directly. Ideally, SocketService
          // would have methods to update its internal state.
          // For now, we proceed knowing this limitation.
          setState(() {
             item.isDelivered = true; // Modify the item directly (potential issue)
             // Re-calculate delivered count on the fly or manage in SocketService
             _deliveredItemsCount[orderId] = (socketService.orders[orderIndex].items.where((i) => i.isDelivered).length);
             
             // Check if all items are now delivered
             if (_deliveredItemsCount[orderId] == socketService.orders[orderIndex].items.length) {
                 log('Order $orderId completed locally.');
                 // Trigger API call to mark ready (pass context)
                 _markOrderReadyForPickup(context, orderId);
             }
          });
        }
      } else {
         log('Error marking item delivered: Invalid itemIndex $itemIndex for order $orderId');
      }
    } else {
      log('Error marking item delivered: Order ID $orderId not found');
    }
 }

  // --- Show Nicer Success Notification ---
  void _showSuccessNotification(String orderIdentifier) {
     if (!mounted) return; // Check if the widget is still active

     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
         content: Row(
           children: [
             const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
             const SizedBox(width: 12),
             Expanded(
               child: Text(
                 'Order #$orderIdentifier Marked as Ready!',
                 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                 overflow: TextOverflow.ellipsis,
               ),
             ),
           ],
         ),
         backgroundColor: const Color.fromRGBO(0, 153, 70, 1), // Use the theme's green color (make sure _orderGreen is defined in your state)
         behavior: SnackBarBehavior.floating, // Make it float
         shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(12.0), // Rounded corners
         ),
         margin: EdgeInsets.only( // Position near top-center
           bottom: MediaQuery.of(context).size.height - 120, // Adjust vertical position from bottom
           left: MediaQuery.of(context).size.width * 0.2, // Indent from left
           right: MediaQuery.of(context).size.width * 0.2, // Indent from right
         ),
         duration: const Duration(seconds: 3), // Slightly longer duration
         elevation: 6.0, // Add some elevation
       ),
     );
  }
  // --- End Show Nicer Success Notification ---

  // --- Modify API call method to accept context --- 
  Future<void> _markOrderReadyForPickup(BuildContext context, String orderId) async {
    // Get services using context
    final socketService = Provider.of<SocketService>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);
    
    // Find order number for display
    final order = socketService.orders.firstWhere(
      (o) => o.id == orderId,
      orElse: () => Order(id: orderId, orderNumber: orderId, items: [], createdAt: DateTime.now(), orderType: 'N/A', tableId: 'N/A') 
    );
    final String displayOrderId = order.orderNumber;

    if (_updatingOrders.contains(orderId)) {
      log('Order $orderId is already being updated.');
      return; 
    }

    // Check mount status before async gap and setState
    if (!mounted) return;
    setState(() {
      _updatingOrders.add(orderId);
    });

    try {
      final success = await apiService.updateOrderStatus(orderId, 'ready_for_pickup');
      if (!mounted) return; // Check again after await
      
      if (success) {
        log('Successfully called API to mark order $orderId as ready_for_pickup.');
        _showSuccessNotification(displayOrderId);
        // Socket event should remove the order from SocketService state
      } else {
        log('API call to update order $orderId status returned false.');
        _showErrorSnackBar('Failed to update order status.');
      }
    } catch (e) {
      log('Error calling API to update order $orderId status: $e');
      if (mounted) {
          _showErrorSnackBar('Error updating order: ${e.toString()}');
      }
    } finally {
      if (mounted) {
         setState(() {
           _updatingOrders.remove(orderId);
         });
      }
    }
  }

  // --- Show Error SnackBar ---
  void _showErrorSnackBar(String message) {
     if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(message), backgroundColor: Colors.red),
       );
     }
  }
  // -----------------------------------------------------

  // Helper function to format duration as MM:SS
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    // Handle negative durations if createdAt is somehow in the future
    final totalSeconds = duration.inSeconds.abs();
    final minutes = twoDigits((totalSeconds ~/ 60) % 60); // Modulo 60 for minutes part
    final seconds = twoDigits(totalSeconds % 60);
    // For durations longer than an hour, you might want HH:MM:SS
    // if (totalSeconds >= 3600) {
    //    final hours = twoDigits(totalSeconds ~/ 3600);
    //    return "$hours:$minutes:$seconds";
    // }
    return "$minutes:$seconds";
  }

  // Helper function to get header color based on elapsed time
  Color _getHeaderColorForElapsedTime(Duration elapsed) {
    if (elapsed.isNegative) return _orderGreen;
    if (elapsed >= redThreshold) return _orderRed;
    if (elapsed >= yellowThreshold) return _orderYellow;
    return _orderGreen;
  }

  Future<void> _fetchInitialOrders() async {
    if (!mounted) return; // Check mount status at the beginning
    final socketService = Provider.of<SocketService>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);
    
    debugPrint('[KitchenScreen] Attempting to fetch initial orders...'); 

    // Set loading state only if mounted
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('[KitchenScreen] Calling apiService.fetchActiveKitchenOrders()...');
      final fetchedOrders = await apiService.fetchActiveKitchenOrders();
      debugPrint('[KitchenScreen] API call finished. Found ${fetchedOrders.length} orders.');
      
      if (!mounted) return; // Check again after await
      socketService.setInitialActiveOrders(fetchedOrders);

    } catch (e) {
      debugPrint('[KitchenScreen] ERROR during fetchInitialOrders: ${e.toString()}');
      if (!mounted) return; 
      setState(() {
        _error = "Failed to load initial orders: ${e.toString()}";
      });
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_error!), duration: Duration(seconds: 5)),
          );
      }
    } finally {
       debugPrint('[KitchenScreen] fetchInitialOrders finally block executing.');
       if (mounted) { 
         setState(() {
            _isLoading = false;
          });
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtain SocketService using Provider
    final socketService = Provider.of<SocketService>(context);
    final orders = socketService.orders;
    
    // Theme related color definitions (moved from original spot for clarity)
    final appBarBackgroundColor = Theme.of(context).canvasColor; // Example color
    final appBarTitleColor = Theme.of(context).textTheme.bodyLarge!.color!; // Example color
    final headerTextColor = Theme.of(context).colorScheme.onPrimary; // For text on colored header
    final itemStrikeThroughColor = theme_colors.strikeThroughColor; // From your theme
    final itemBodyTextColor = theme_colors.textColor; // From your theme

    // Use the themed order colors
    final Color currentOrderGreen = theme_colors.orderGreen;
    final Color currentOrderYellow = theme_colors.orderYellow;
    final Color currentOrderRed = theme_colors.orderRed;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9C4), // Exact light yellow from waiter_app
      appBar: AppBar(
         automaticallyImplyLeading: false,
         backgroundColor: appBarBackgroundColor, // Use themed background for AppBar
         elevation: 0, // Remove shadow to match image
         titleSpacing: 12.0, // Adjust spacing if needed
         title: FadedScaleAnimation(
           child: RichText(
               text: TextSpan(children: <TextSpan>[
             TextSpan(
                 text: '', // Hardcoded name, consider using AppConfig
                 style: Theme.of(context)
                     .textTheme
                     .titleMedium! // Use theme's titleMedium
                     .copyWith(
                        letterSpacing: 1,
                        fontWeight: FontWeight.bold,
                        color: appBarTitleColor // Ensure contrast
                      )
                 ),
             TextSpan(
                 text: 'KITCHEN',
                 style: Theme.of(context).textTheme.titleMedium!.copyWith(
                     color: Theme.of(context).primaryColor, // Use primary color for accent
                     letterSpacing: 1,
                     fontWeight: FontWeight.bold)),
           ])),
           fadeDuration: const Duration(milliseconds: 400),
           scaleDuration: const Duration(milliseconds: 400),
         ),
         actions: [
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), // Adjust padding
             child: FadedScaleAnimation(
               // Use CustomButton for the "Past Orders" action
               child: CustomButton(
                   padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10), // Adjust padding for button size
                   leading: Icon(
                     Icons.history,
                     color: Colors.white, // Icon color on red button
                     size: 16,
                   ),
                   // Ensure title is a Text widget for styling
                   title: Text(
                     'Past Orders', // Use space if needed '  Past Orders'
                     style: Theme.of(context)
                         .textTheme
                         .bodyLarge! // bodyLarge is white text per theme
                         .copyWith(fontWeight: FontWeight.bold, fontSize: 14), // Adjust font size
                   ),
                   onTap: () {
                       try {
                           // Use named route defined in routes.dart
                           Navigator.pushNamed(context, PageRoutes.pastOrders);
                       } catch (e) {
                          log('Error navigating to Past Orders: $e. Ensure route "${PageRoutes.pastOrders}" is set up.');
                       }
                   }),
               fadeDuration: const Duration(milliseconds: 400),
               scaleDuration: const Duration(milliseconds: 400),
             ),
           ),
           Padding(
             padding: const EdgeInsets.only(right: 16.0),
             child: Icon(
               socketService.isConnected ? Icons.wifi : Icons.wifi_off,
               color: socketService.isConnected ? Colors.green : Colors.red,
             ),
           ),
           IconButton(
             icon: Icon(Icons.refresh),
             onPressed: _isLoading ? null : _fetchInitialOrders, 
             tooltip: 'Refresh Orders',
           ),
         ],
      ),
      body: Stack( // Body is now a Stack
        children: <Widget>[
          Positioned.fill( // Bubble background as the first layer
            child: CustomPaint(
              painter: BubbleBackgroundPainter(), // Uses default white bubbles
            ),
          ),
          // Original body content starts here, ensure its main container is transparent
          FadedSlideAnimation(
            beginOffset: const Offset(0.0, 0.3),
            endOffset: Offset.zero,
            slideCurve: Curves.linearToEaseOut,
            child: Container(
              // This container wraps your main content, make it transparent
              color: Colors.transparent, 
              child: _isLoading && orders.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text('Error: $_error'))
                      : orders.isEmpty
                          ? Center( /* ... No orders display ... */ )
                          : SingleChildScrollView( 
                              padding: const EdgeInsets.all(10.0), 
                              child: StaggeredGrid.count(
                                  crossAxisCount: 4, 
                                  mainAxisSpacing: 10.0, 
                                  crossAxisSpacing: 10.0, 
                                  children: List.generate(orders.length, (int index) {
                                    final order = orders[index];
                                    final currentDeliveredCount = order.items.where((i) => i.isDelivered).length;
                                    final allItemsDelivered = currentDeliveredCount == order.items.length;

                                    return _buildOrderCard(
                                      context,
                                      order, 
                                      allItemsDelivered, 
                                      headerTextColor, 
                                      itemStrikeThroughColor ?? Colors.grey, 
                                      itemBodyTextColor,
                                      currentOrderGreen,
                                      currentOrderYellow,
                                      currentOrderRed,
                                    );
                                  }),
                                ),
                            ), 
            ), 
          ), // End of FadedSlideAnimation
        ], // End of Stack children
      ), // End of Stack (body)
    );
  }

  // Modify _buildOrderCard to accept context for actions
  Widget _buildOrderCard(
      BuildContext context, // Add context
      Order order,
      bool allItemsDelivered, 
      Color headerTextColor,
      Color itemStrikeThroughColor,
      Color itemBodyTextColor, 
      Color colorGreen,
      Color colorYellow,
      Color colorRed
    ) {
    final elapsed = DateTime.now().difference(order.createdAt);
    final formattedTime = _formatDuration(elapsed);
    final headerColor = _getHeaderColorForElapsedTime(elapsed);
    final headerTextStyle = Theme.of(context).textTheme.bodyLarge!.copyWith(color: headerTextColor, fontSize: 14, fontWeight: FontWeight.bold);
    final headerSubTextStyle = Theme.of(context).textTheme.bodyLarge!.copyWith(
          color: headerTextColor.withOpacity(0.85), fontSize: 10);
    final itemTextStyle = Theme.of(context).textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.normal, fontSize: 14, color: itemBodyTextColor); // Use body color
    final itemStrikeStyle = itemTextStyle.copyWith(
          decoration: TextDecoration.lineThrough, color: itemStrikeThroughColor);
    final itemQuantityStyle = itemTextStyle.copyWith(fontWeight: FontWeight.bold);
    final itemQuantityStrikeStyle = itemQuantityStyle.copyWith(
          decoration: TextDecoration.lineThrough, color: itemStrikeThroughColor);
    final instructionTextStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: itemBodyTextColor.withOpacity(0.8), fontWeight: FontWeight.w300, fontSize: 12);
     final instructionStrikeStyle = instructionTextStyle.copyWith(
          decoration: TextDecoration.lineThrough, color: itemStrikeThroughColor.withOpacity(0.8));

    final bool isUpdating = _updatingOrders.contains(order.id);

    return ClipPath(
      clipper: CustomClipPath(),
      child: FadedScaleAnimation(
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: headerColor,
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.orderType, style: headerTextStyle, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(order.orderNumber, style: headerSubTextStyle),
                        ],
                      ),
                    ),
                    Flexible(
                      child: Text(formattedTime, style: headerTextStyle.copyWith(fontSize: 18)),
                    ),
                  ],
                ),
              ),
              ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  itemCount: order.items.length,
                  itemBuilder: (itemContext, itemIndex) {
                    final item = order.items[itemIndex];
                    return InkWell(
                      onTap: () => _markItemDelivered(context, order.id, item.productId, itemIndex),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: Text(
                                    '${item.quantity} ',
                                    style: item.isDelivered ? itemQuantityStrikeStyle : itemQuantityStyle
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: item.isDelivered ? itemStrikeStyle : itemTextStyle
                                  )
                                ),
                                if (item.isDelivered) // Show checkmark
                                   Icon(Icons.check_circle, color: colorGreen, size: 18)
                              ],
                            ),
                            if (item.specialInstructions.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 20.0, top: 4.0), // Indent instructions slightly
                                child: Text(
                                  'Note: ${item.specialInstructions}',
                                  style: item.isDelivered ? instructionStrikeStyle : instructionTextStyle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }
                ),
          ],
          ),
        ),
      ),
    );
  }
} 
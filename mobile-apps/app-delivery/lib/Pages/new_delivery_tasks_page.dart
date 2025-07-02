import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hungerz_delivery/Config/app_config.dart';
import 'package:hungerz_delivery/Pages/delivery_map_page.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Your color definitions (assuming these are available)
Color kMainColor = Color(0xfffbaf03);
Color kDisabledColor = Color(0xff616161);
Color kWhiteColor = Colors.white;
Color kLightTextColor = Colors.grey;
Color kCardBackgroundColor = Color(0xfff8f9fd);
Color kTransparentColor = Colors.transparent;
Color kMainTextColor = Color(0xff000000);
Color kIconColor = Color(0xffc4c8c1);
Color kHintColor = Color(0xff999e93);
Color kTextColor = Color(0xff6a6c74);
Color secondaryColor = Color(0xff45BD9C);

// API Base URL (ensure this is correct)
const String _apiBaseUrl = AppConfig.baseUrl;

// Placeholder for actual order data model
class DeliveryTask {
  final String orderId;
  final String orderNumber;
  final String customerName;
  final String customerAddress;
  final String customerPhone;
  final LatLng? customerLocation;
  final List<String> itemsSummary;
  final String orderStatus;
  final DateTime orderTime;
  final double? deliveryFee;

  DeliveryTask({
    required this.orderId,
    required this.orderNumber,
    required this.customerName,
    required this.customerAddress,
    required this.customerPhone,
    this.customerLocation,
    required this.itemsSummary,
    required this.orderStatus,
    required this.orderTime,
    this.deliveryFee,
  });

  DeliveryTask copyWith({
    String? orderId,
    String? orderNumber,
    String? customerName,
    String? customerAddress,
    String? customerPhone,
    LatLng? customerLocation,
    List<String>? itemsSummary,
    String? orderStatus,
    DateTime? orderTime,
    double? deliveryFee,
  }) {
    return DeliveryTask(
      orderId: orderId ?? this.orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      customerAddress: customerAddress ?? this.customerAddress,
      customerPhone: customerPhone ?? this.customerPhone,
      customerLocation: customerLocation ?? this.customerLocation,
      itemsSummary: itemsSummary ?? this.itemsSummary,
      orderStatus: orderStatus ?? this.orderStatus,
      orderTime: orderTime ?? this.orderTime,
      deliveryFee: deliveryFee ?? this.deliveryFee,
    );
  }

  factory DeliveryTask.fromPayload(Map<String, dynamic> payload) {
    List<String> items = (payload['items'] as List?)
            ?.map((item) => "${item['quantity']}x ${item['name']}")
            .toList() ??
        ['Items N/A'];
    
    Map<String, dynamic>? customerDetails = payload['customerDetails'] as Map<String, dynamic>?;
    Map<String, dynamic>? deliveryAddress = payload['deliveryAddress'] as Map<String, dynamic>?;

    LatLng? parsedCustomerLocation;
    if (deliveryAddress != null && deliveryAddress['latitude'] != null && deliveryAddress['longitude'] != null) {
      try {
        parsedCustomerLocation = LatLng(
          (deliveryAddress['latitude'] as num).toDouble(),
          (deliveryAddress['longitude'] as num).toDouble(),
        );
      } catch (e) {
        print("Error parsing customer location: $e");
      }
    }

    return DeliveryTask(
      orderId: payload['orderId'] ?? 'N/A',
      orderNumber: payload['orderNumber'] ?? 'N/A',
      customerName: customerDetails?['name'] ?? 'Customer N/A',
      customerAddress: deliveryAddress?['address'] ?? 'Amphitheatre Pkwy, Mountain View, CA',
      customerPhone: customerDetails?['phoneNumber'] ?? 'Phone N/A',
      customerLocation: parsedCustomerLocation,
      itemsSummary: items,
      orderStatus: "Order Upcoming",
      orderTime: payload['createdAt'] != null ? DateTime.tryParse(payload['createdAt']) ?? DateTime.now() : DateTime.now(),
      deliveryFee: (payload['deliveryFee'] as num?)?.toDouble(),
    );
  }
}

final ValueNotifier<List<DeliveryTask>> activeDeliveryTasksNotifier =
    ValueNotifier<List<DeliveryTask>>([]);

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void receiveNewDeliveryTask(Map<String, dynamic> payload) {
  final task = DeliveryTask.fromPayload(payload);
  final currentTasks = List<DeliveryTask>.from(activeDeliveryTasksNotifier.value);
  if (!currentTasks.any((t) => t.orderId == task.orderId)) {
    currentTasks.insert(0, task);
    activeDeliveryTasksNotifier.value = currentTasks;
    print("Task added to notifier. Page should update if listening.");
  }
}

class NewDeliveryTasksPage extends StatefulWidget {
  const NewDeliveryTasksPage({Key? key}) : super(key: key);

  static const String routeName = '/new_delivery_tasks';

  @override
  State<NewDeliveryTasksPage> createState() => _NewDeliveryTasksPageState();
}

class _NewDeliveryTasksPageState extends State<NewDeliveryTasksPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCardBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: kMainColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                "Delivery Tasks",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      kMainColor,
                      kMainColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -20,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -30,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ValueListenableBuilder<List<DeliveryTask>>(
            valueListenable: activeDeliveryTasksNotifier,
            builder: (context, tasks, child) {
              if (tasks.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: DeliveryTaskCard(task: tasks[index]),
                      );
                    },
                    childCount: tasks.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.delivery_dining,
              size: 64,
              color: kMainColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No Active Deliveries",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: kMainTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "New delivery tasks will appear here",
            style: TextStyle(
              fontSize: 16,
              color: kTextColor,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: kMainColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, color: kMainColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  "Stay online to receive orders",
                  style: TextStyle(
                    color: kMainColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DeliveryTaskCard extends StatefulWidget {
  final DeliveryTask task;
  const DeliveryTaskCard({Key? key, required this.task}) : super(key: key);

  @override
  State<DeliveryTaskCard> createState() => _DeliveryTaskCardState();
}

class _DeliveryTaskCardState extends State<DeliveryTaskCard> {
  String _displayAddress = '';
  late DeliveryTask _task; // Make task mutable

  @override
  void initState() {
    super.initState();
    _task = widget.task; // Initialize with the passed task
    _displayAddress = _task.customerAddress;
    if (_task.customerLocation != null) {
      _fetchAddressFromCoordinates(_task.customerLocation!);
    }
  }

  Future<void> _fetchAddressFromCoordinates(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isNotEmpty) {
        final Placemark p = placemarks.first;
        final newAddress = "${p.street}, ${p.locality}, ${p.postalCode}, ${p.country}"
            .replaceAll("null, ", "")
            .replaceAll(", null", "");
        if (mounted && newAddress.isNotEmpty && newAddress != _displayAddress) {
          setState(() {
            _displayAddress = newAddress;
          });
        }
      }
    } catch (e) {
      print("Error fetching address from coordinates: $e");
    }
  }

  Color _getStatusColor() {
    switch (_task.orderStatus) {
      case "Order Upcoming":
        return secondaryColor;
      case "Order OnTheWay":
        return kMainColor;
      case "Order Delivered":
        return Colors.green; // Color for delivered orders
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (_task.orderStatus) {
      case "Order Upcoming":
        return Icons.schedule;
      case "Order OnTheWay":
        return Icons.delivery_dining;
      case "Order Delivered":
        return Icons.check_circle_outline; // Icon for delivered orders
      default:
        return Icons.circle;
    }
  }

  // --- API Call Helper Functions ---
  Future<bool> _callAcceptTaskApi(String orderId) async {
    final uri = Uri.parse('$_apiBaseUrl/orders/$orderId/accept-task');
    print("Calling Accept Task API: $uri for orderId: $orderId");
    try {
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        print("Order $orderId task accepted successfully via API.");
        final responseBody = json.decode(response.body);
        print("API Response for accept task: $responseBody");
        return true;
      } else {
        print("API Error accepting task $orderId: ${response.statusCode} - ${response.body}");
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('API Error accepting task: ${response.statusCode}. Expected ready_for_pickup.'), backgroundColor: Colors.red),
          );
        }
        return false;
      }
    } catch (e) {
      print("Error calling accept task API for $orderId: $e");
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to accept task: ${e.toString()}'), backgroundColor: Colors.red),
          );
       }
      return false;
    }
  }

  Future<bool> _callConfirmDeliveryApi(String orderId) async {
    final uri = Uri.parse('$_apiBaseUrl/orders/$orderId/confirm-delivery');
    print("Calling Confirm Delivery API: $uri for orderId: $orderId");
    try {
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        print("Order $orderId delivery confirmed successfully via API.");
         final responseBody = json.decode(response.body);
        print("API Response for confirm delivery: $responseBody");
        return true;
      } else {
        print("API Error confirming delivery $orderId: ${response.statusCode} - ${response.body}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('API Error confirming delivery: ${response.statusCode}. Expected accepted.'), backgroundColor: Colors.red),
          );
        }
        return false;
      }
    } catch (e) {
      print("Error calling confirm delivery API for $orderId: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to confirm delivery: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
      return false;
    }
  }
  // --- End API Call Helper Functions ---

  void _updateTaskInNotifier(DeliveryTask updatedTask) {
    final currentTasks = List<DeliveryTask>.from(activeDeliveryTasksNotifier.value);
    final taskIndex = currentTasks.indexWhere((t) => t.orderId == updatedTask.orderId);
    if (taskIndex != -1) {
      currentTasks[taskIndex] = updatedTask;
      activeDeliveryTasksNotifier.value = currentTasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    double cardOpacity = 1.0;
    if (_task.orderStatus == "Order OnTheWay") {
      cardOpacity = 0.8;
    } else if (_task.orderStatus == "Order Delivered") {
      cardOpacity = 0.65;
    }

    return Opacity(
      opacity: cardOpacity,
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getStatusColor().withOpacity(0.1),
                  _getStatusColor().withOpacity(0.05),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getStatusIcon(),
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            _task.orderStatus,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                            "Order #${_task.orderNumber}",
                          style: TextStyle(
                            color: kTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                        "${_task.orderTime.day}/${_task.orderTime.month}/${_task.orderTime.year}",
                      style: TextStyle(
                        color: kTextColor,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                        onTap: () => _showOrderDetailsDialog(context, _task),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: kMainColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Details",
                          style: TextStyle(
                            color: kMainColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Customer Info Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kMainColor, kMainColor.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              _task.customerName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: kMainTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 16, color: kTextColor),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _displayAddress,
                                  style: TextStyle(
                                    color: kTextColor,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.phone, size: 16, color: kTextColor),
                              const SizedBox(width: 4),
                              Text(
                                  _task.customerPhone,
                                style: TextStyle(
                                  color: kTextColor,
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

                const SizedBox(height: 16),

                // Items Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kCardBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.restaurant_menu, size: 16, color: kTextColor),
                          const SizedBox(width: 8),
                          Text(
                            "Order Items",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: kMainTextColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                        ..._task.itemsSummary.take(3).map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              "• $item",
                              style: TextStyle(
                                color: kTextColor,
                                fontSize: 13,
                              ),
                            ),
                          )),
                        if (_task.itemsSummary.length > 3)
                        Text(
                            "+ ${_task.itemsSummary.length - 3} more items",
                          style: TextStyle(
                            color: kMainColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Map Button
                  if (_task.orderStatus == "Order Upcoming" || _task.orderStatus == "Order OnTheWay")
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kMainColor, kMainColor.withOpacity(0.8)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: kMainColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.map_outlined, color: Colors.white),
                      label: Text(
                          _task.orderStatus == "Order OnTheWay"
                            ? "Show Live Map" 
                            : "View on Map & Accept",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                        onPressed: () async {
                          if (_task.orderStatus == "Order Upcoming") {
                            print("[NewDeliveryTasksPage] 'View on Map & Accept' button pressed. Order: ${_task.orderId}");
                            
                            // Call API to accept task
                            bool accepted = await _callAcceptTaskApi(_task.orderId);

                            if (accepted && mounted) {
                              setState(() {
                                _task = _task.copyWith(orderStatus: "Order OnTheWay");
                              });
                              _updateTaskInNotifier(_task);

                              FirebaseAnalytics.instance.logEvent(
                                name: 'delivery_started_via_map',
                                parameters: {
                                  'delivery_fee': _task.deliveryFee ?? 0.0,
                                  'order_id': _task.orderId,
                                },
                              );
                              
                              if (_task.customerLocation != null) {
                                print("[NewDeliveryTasksPage] Customer location IS NOT NULL for order: ${_task.orderId}. Proceeding to navigate.");
                          Navigator.pushNamed(
                            context,
                            DeliveryMapPage.routeName,
                                  arguments: _task, 
                          );
                        } else {
                                print("[NewDeliveryTasksPage] Customer location IS NULL for order: ${_task.orderId}. Cannot navigate to map. Showing SnackBar.");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Customer location not available for this task."),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                              }
                            } else if (!accepted && mounted) {
                               print("Failed to accept task via API for order ${_task.orderId} when 'View on Map & Accept' was pressed.");
                            }
                          } else if (_task.orderStatus == "Order OnTheWay") {
                             // If already "OnTheWay", just navigate to map
                             print("[NewDeliveryTasksPage] 'Show Live Map' button pressed for order: ${_task.orderId}");
                             if (_task.customerLocation != null) {
                                Navigator.pushNamed(
                                  context,
                                  DeliveryMapPage.routeName,
                                  arguments: _task, 
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text("Customer location not available for this task."),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.close, size: 18, color: Colors.red),
                          label: Text(
                            "Reject",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () {
                            // Handle reject logic
                              // Potentially update task status to "Rejected" and log to Firestore/Analytics
                              // Example:
                              // setState(() {
                              //   _task = _task.copyWith(orderStatus: "Order Rejected");
                              // });
                              // _updateTaskInNotifier(_task);
                              // _updateFirestoreDeliveryStatus("rejected");
                              // FirebaseAnalytics.instance.logEvent(name: 'delivery_rejected', parameters: {'order_id': _task.orderId});

                              // For now, just remove it from the active list as an example of rejection
                              final currentTasks = List<DeliveryTask>.from(activeDeliveryTasksNotifier.value);
                              currentTasks.removeWhere((t) => t.orderId == _task.orderId);
                              activeDeliveryTasksNotifier.value = currentTasks;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Order ${_task.orderNumber} rejected."),
                                  backgroundColor: Colors.red,
                                ),
                              );
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.05),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [secondaryColor, secondaryColor.withOpacity(0.8)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton.icon(
                          icon: Icon(
                              _task.orderStatus == "Order Upcoming"
                                ? Icons.check 
                                  : (_task.orderStatus == "Order OnTheWay" ? Icons.local_shipping : Icons.done_all), // Changed icon for OnTheWay
                            size: 18,
                            color: Colors.white,
                          ),
                          label: Text(
                              _task.orderStatus == "Order Upcoming"
                                ? "Accept Task" 
                                  : (_task.orderStatus == "Order OnTheWay"
                                    ? "Confirm Delivery" 
                                      : "Delivered"), // Changed text for Delivered
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                            onPressed: _task.orderStatus == "Order Delivered" ? null : () async { // Disable button if delivered
                              if (_task.orderStatus == "Order Upcoming") {
                                // Accept Task Logic via API
                                bool accepted = await _callAcceptTaskApi(_task.orderId);
                                if (accepted && mounted) {
                                  FirebaseAnalytics.instance.logEvent(
                                    name: 'delivery_accepted', 
                                    parameters: {
                                      'delivery_fee': _task.deliveryFee ?? 0.0,
                                      'order_id': _task.orderId,
                                      'accepted_via': 'accept_button'
                                    },
                                  );
                                  setState(() {
                                    _task = _task.copyWith(orderStatus: "Order OnTheWay");
                                  });
                                  _updateTaskInNotifier(_task);
                                  print("Delivery accepted (via Accept Task button) using API: ${_task.orderId}");
                                } else if (!accepted && mounted) {
                                   print("Failed to accept task via API for order ${_task.orderId} (Accept Task Button).");
                                }
                              } else if (_task.orderStatus == "Order OnTheWay") {
                                // Confirm Delivery Logic via API
                                bool confirmed = await _callConfirmDeliveryApi(_task.orderId);
                                if (confirmed && mounted) {
                                  FirebaseAnalytics.instance.logEvent(
                                    name: 'delivery_confirmed',
                                    parameters: {
                                      'delivery_fee': _task.deliveryFee ?? 0.0,
                                      'order_id': _task.orderId,
                                    },
                                  );
                                  setState(() {
                                    _task = _task.copyWith(orderStatus: "Order Delivered");
                                  });
                                  _updateTaskInNotifier(_task);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Order ${_task.orderNumber} confirmed as delivered via API!"),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else if (!confirmed && mounted) {
                                  print("Failed to confirm delivery via API for order ${_task.orderId}.");
                                }
                              }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  void _showOrderDetailsDialog(BuildContext context, DeliveryTask task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  kCardBackgroundColor,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kMainColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.receipt_long, color: kMainColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Order #${task.orderNumber}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: kMainTextColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: kTextColor),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                _buildDetailRow(Icons.person, 'Customer', task.customerName),
                _buildDetailRow(Icons.phone, 'Phone', task.customerPhone),
                _buildDetailRow(Icons.location_on, 'Address', task.customerAddress),
                
                if (task.customerLocation != null) 
                  _buildDetailRow(Icons.gps_fixed, 'Coordinates', 
                      '(${task.customerLocation!.latitude.toStringAsFixed(5)}, ${task.customerLocation!.longitude.toStringAsFixed(5)})'),
                
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kMainColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.restaurant_menu, color: kMainColor, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Order Items',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: kMainTextColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...task.itemsSummary.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: kMainColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      color: kTextColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kMainColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: kTextColor),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: kMainTextColor,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: kTextColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
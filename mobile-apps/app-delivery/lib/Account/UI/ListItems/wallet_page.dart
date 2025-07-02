import 'package:flutter/material.dart';
import 'package:hungerz_delivery/Account/UI/account_page.dart';
import 'package:hungerz_delivery/Config/app_config.dart';
import 'package:hungerz_delivery/Routes/routes.dart';
import 'package:hungerz_delivery/Themes/colors.dart';
import 'package:hungerz_delivery/Themes/style.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// API Base URL
const String _apiBaseUrl = AppConfig.baseUrl;

// Model for a transaction/delivered order
class WalletTransaction {
  final String storeName;
  final String itemsSummary;
  final DateTime dateTime;
  final double amount;

  WalletTransaction({
    required this.storeName,
    required this.itemsSummary,
    required this.dateTime,
    required this.amount,
  });

  factory WalletTransaction.fromOrder(Map<String, dynamic> order) {
    String summary = "Order";
    if (order.containsKey('items') && order['items'] is List) {
      summary = "${(order['items'] as List).length} items";
    }
    
    return WalletTransaction(
      storeName: order['customerName'] as String? ?? order['userName'] as String? ?? 'N/A',
      itemsSummary: summary,
      dateTime: order['deliveredAt'] != null 
                ? DateTime.tryParse(order['deliveredAt'] as String) ?? DateTime.tryParse(order['updatedAt'] as String) ?? DateTime.now()
                : DateTime.tryParse(order['updatedAt'] as String) ?? DateTime.now(),
      amount: (order['deliveryFee'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class WalletPage extends StatefulWidget {
  @override
  _WalletPageState createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Account(),
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black87),
        title: Text(
          "My Wallet",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: Colors.black54),
            onPressed: () {
              // Navigate to transaction history
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: Wallet(),
    );
  }
}

class Wallet extends StatefulWidget {
  @override
  _WalletState createState() => _WalletState();
}

class _WalletState extends State<Wallet> with TickerProviderStateMixin {
  bool _isLoading = true;
  double _availableBalance = 0.0;
  List<WalletTransaction> _recentTransactions = [];
  String? _error;
  late AnimationController _balanceAnimationController;
  late Animation<double> _balanceAnimation;

  @override
  void initState() {
    super.initState();
    _balanceAnimationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _balanceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _balanceAnimationController, curve: Curves.easeOut),
    );
    _fetchWalletData();
  }

  @override
  void dispose() {
    _balanceAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchWalletData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final uri = Uri.parse('$_apiBaseUrl/orders/delivered');
      print("Fetching DELIVERED orders for Wallet from API: $uri");
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decodedBody = json.decode(response.body);
        final List<dynamic> ordersData = (decodedBody is Map && decodedBody.containsKey('orders') && decodedBody['orders'] is List)
            ? decodedBody['orders']
            : (decodedBody is List ? decodedBody : []);

        double totalBalance = 0;
        List<WalletTransaction> transactions = [];

        for (var orderData in ordersData) {
          if (orderData is Map<String, dynamic>) {
            totalBalance += (orderData['deliveryFee'] as num?)?.toDouble() ?? 0.0;
            transactions.add(WalletTransaction.fromOrder(orderData));
          }
        }
        
        transactions.sort((a, b) => b.dateTime.compareTo(a.dateTime));

        if (mounted) {
          setState(() {
            _availableBalance = totalBalance;
            _recentTransactions = transactions;
            _isLoading = false;
          });
          _balanceAnimationController.forward();
        }
      } else {
        print("API Error fetching wallet data: ${response.statusCode} - ${response.body}");
        if (mounted) {
          setState(() {
            _error = "Failed to load wallet data: ${response.statusCode}";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching wallet data: $e");
      if (mounted) {
        setState(() {
          _error = "Error: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchWalletData,
      color: kMainColor,
      child: CustomScrollView(
        slivers: [
          // Balance Card Section
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.all(16),
              child: _buildBalanceCard(),
            ),
          ),
          
          // Quick Actions Section
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildQuickActions(),
            ),
          ),
          
          // Transactions Header
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                  Text(
                    "Recent Transactions",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (_recentTransactions.length > 5)
                    TextButton(
                      onPressed: () {
                        // Navigate to full transaction history
                      },
                      child: Text(
                        "See All",
                        style: TextStyle(
                          color: kMainColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Transactions List
          _buildTransactionsList(),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kMainColor,
            kMainColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kMainColor.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Available Balance",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
              child: Text(
                  "WALLET",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          AnimatedBuilder(
            animation: _balanceAnimation,
            builder: (context, child) {
              return Text(
                _isLoading 
                  ? 'Loading...' 
                  : 'DA ${(_availableBalance * _balanceAnimation.value).toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              );
            },
          ),
          SizedBox(height: 8),
          Text(
            "From ${_recentTransactions.length} completed deliveries",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.send_to_mobile,
            label: "Send to Bank",
            onTap: () => Navigator.pushNamed(context, PageRoutes.addToBank),
            isPrimary: true,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.analytics_outlined,
            label: "Analytics",
            onTap: () {
              // Navigate to analytics
            },
            isPrimary: false,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isPrimary ? kMainColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: isPrimary ? kMainColor.withOpacity(0.2) : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.white : Colors.black54,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_isLoading) {
      return SliverToBoxAdapter(
        child: Container(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(
              color: kMainColor,
              strokeWidth: 3,
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return SliverToBoxAdapter(
        child: Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 32),
              SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Colors.red[700], fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchWalletData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (_recentTransactions.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                "No Transactions Yet",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Your delivery earnings will appear here",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= _recentTransactions.length) return null;
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _buildTransactionTile(_recentTransactions[index]),
          );
        },
        childCount: _recentTransactions.length > 10 ? 10 : _recentTransactions.length,
      ),
    );
  }

  Widget _buildTransactionTile(WalletTransaction transaction) {
    final DateFormat timeFormatter = DateFormat('HH:mm');
    final DateFormat dateFormatter = DateFormat('dd MMM');
    final bool isToday = DateUtils.isSameDay(transaction.dateTime, DateTime.now());
    final bool isYesterday = DateUtils.isSameDay(
      transaction.dateTime, 
      DateTime.now().subtract(Duration(days: 1))
    );
    
    String dateText;
    if (isToday) {
      dateText = 'Today, ${timeFormatter.format(transaction.dateTime)}';
    } else if (isYesterday) {
      dateText = 'Yesterday, ${timeFormatter.format(transaction.dateTime)}';
    } else {
      dateText = '${dateFormatter.format(transaction.dateTime)}, ${timeFormatter.format(transaction.dateTime)}';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kMainColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.delivery_dining,
              color: kMainColor,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.storeName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${transaction.itemsSummary} • $dateText',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+DA ${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.green[600],
                ),
              ),
              SizedBox(height: 2),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Completed',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
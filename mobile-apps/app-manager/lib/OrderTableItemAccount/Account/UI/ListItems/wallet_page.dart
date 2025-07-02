import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungerz_store/Routes/routes.dart';
import 'package:hungerz_store/Themes/colors.dart';
import 'package:hungerz_store/Themes/style.dart';
import 'package:hungerz_store/cubits/orders_cubit.dart';
import 'package:hungerz_store/models/order_model.dart';
import 'package:intl/intl.dart';
import 'package:hungerz_store/OrderTableItemAccount/Account/UI/ListItems/addtobank_page.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;

class WalletPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          "Wallet",
          style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            size: 30,
            color: Theme.of(context).secondaryHeaderColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Wallet(),
    );
  }
}

class Wallet extends StatefulWidget {
  @override
  _WalletState createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  @override
  void initState() {
    super.initState();
    context.read<OrdersCubit>().fetchAllOrdersData();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersCubit, OrdersState>(
      builder: (context, state) {
        if (state is OrdersLoading || state is OrdersInitial) {
          return Center(
            child: CircularProgressIndicator(color: kMainColor),
          );
        }
        if (state is OrdersError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                SizedBox(height: 16),
                  Text(
                  'Error: ${state.message}',
                  style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
          );
        }
        if (state is OrdersLoaded) {
          final orders = [...state.newOrders, ...state.pastOrders];

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
          children: [
                  Image.asset(
                    'assets/images/empty_wallet.png', // Add this image to your assets
                    height: 120,
                    width: 120,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your transaction history will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          // Calculate available balance as the sum of all order totals
          final availableBalance = orders.fold<double>(
              0.0, (sum, order) => sum + (order.totalAmount ?? 0.0));

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildBalanceCard(context, availableBalance),
              ),
              SliverToBoxAdapter(
                child: _buildActionHeader(context),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final order = orders[index];
                    return _buildTransactionItem(order: order);
                  },
                  childCount: orders.length,
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
            ],
          );
        }
        return Container();
      },
    );
  }

  Widget _buildBalanceCard(BuildContext context, double balance) {
    return Container(
      margin: EdgeInsets.all(16),
      child: Card(
        elevation: 6,
        shadowColor: kMainColor.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                kMainColor,
                kMainColor.withOpacity(0.8),
              ],
            ),
          ),
          padding: EdgeInsets.all(24),
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
                      fontSize: 14,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white.withOpacity(0.9),
                    size: 28,
                  ),
                ],
              ),
              SizedBox(height: 20),
                  Text(
                '${balance.toStringAsFixed(2)} DA',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddToBank(amountToAdd: balance),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: kMainColor,
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "TRANSFER TO BANK",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recent Transactions",
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
          ),
          SizedBox(height: 8),
          Divider(),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({required Order order}) {
    final formattedDate = order.createdAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt!)
        : 'Date N/A';

    String itemDetails = '';
    if (order.items != null && order.items.isNotEmpty) {
      itemDetails =
          order.items.map((item) => '${item.quantity}x ${item.name}').join(', ');
    } else {
      itemDetails = 'No items';
    }

    // Additional details
    final subtotal = order.subtotal != null
        ? '${order.subtotal!.toStringAsFixed(2)} DA'
        : 'N/A';
    final deliveryFee = order.deliveryFee != null
        ? '${order.deliveryFee!.toStringAsFixed(2)} DA'
        : 'N/A';
    final total =
        order.totalAmount != null ? '${order.totalAmount!.toStringAsFixed(2)} DA' : 'N/A';
    final orderType = order.orderType ?? 'N/A';
    final paymentStatus =
        order.paymentStatus != null ? order.paymentStatus.toUpperCase() : 'N/A';
    final paymentMethod = order.paymentMethod ?? 'N/A';
    final readyAt = order.readyAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(order.readyAt!)
        : 'N/A';
    final orderTime = order.createdAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt!)
        : 'N/A';
    final userFullName = order.userName ?? 'N/A';
    final userMobile = order.userMobileNumber ?? 'N/A';
    
    // Order number display logic
    final orderNumber = order.orderNumber ?? 
      (order.id != null && (order.id.isNotEmpty) 
        ? order.id.substring(order.id.length - 6).toUpperCase() 
        : 'N/A');

    print('Order ${order.id} readyAt: ${order.readyAt}');

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kMainColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.receipt,
                color: kMainColor,
                size: 22,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order $orderNumber',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              total,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: kMainColor,
              ),
            ),
          ],
        ),
        children: [
          _buildDetailRow('Customer Name', userFullName),
          _buildDetailRow('Customer Mobile', userMobile),
          _buildDetailRow('Items', itemDetails),
          _buildDetailRow('Subtotal', subtotal),
          _buildDetailRow('Delivery Fee', deliveryFee),
          _buildDetailRow('Payment Method', paymentMethod),
          _buildDetailRow('Payment Status', 
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: paymentStatus == 'PAID' 
                        ? Colors.green 
                        : paymentStatus == 'PENDING' 
                            ? Colors.orange 
                            : Colors.red,
                  ),
                ),
                SizedBox(width: 6),
                Text(paymentStatus),
              ],
            )
          ),
          _buildDetailRow('Order Type', orderType),
          _buildDetailRow('Order Time', orderTime),
          _buildDetailRow('Ready At', readyAt),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
          child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: value is Widget 
                ? value 
                : Text(
                    value.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
              ),
            ],
          ),
    );
  }
}
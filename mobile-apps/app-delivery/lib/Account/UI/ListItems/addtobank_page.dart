import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hungerz_delivery/Components/bottom_bar.dart';
import 'package:hungerz_delivery/Config/app_config.dart';
import 'package:hungerz_delivery/Themes/colors.dart';
import 'package:hungerz_delivery/Themes/style.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class AddToBank extends StatelessWidget {
  final double availableBalance;
  final String? stripeAccountId; // Stripe Connect account ID
  final bool isStripeConnected;

  AddToBank({
    Key? key, 
    required this.availableBalance,
    this.stripeAccountId,
    this.isStripeConnected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: Colors.black87,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Withdraw to Bank",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: AddToBankForm(
        availableBalance: availableBalance,
        stripeAccountId: stripeAccountId,
        isStripeConnected: isStripeConnected,
      ),
    );
  }
}

class AddToBankForm extends StatefulWidget {
  final double availableBalance;
  final String? stripeAccountId;
  final bool isStripeConnected;

  AddToBankForm({
    required this.availableBalance,
    this.stripeAccountId,
    required this.isStripeConnected,
  });

  @override
  _AddToBankFormState createState() => _AddToBankFormState();
}

class _AddToBankFormState extends State<AddToBankForm>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;
  bool _showQuickAmounts = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final String _apiBaseUrl = AppConfig.baseUrl;
  final List<double> _quickAmounts = [50, 100, 250, 500];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  Future<void> _connectStripeAccount() async {
    setState(() => _isLoading = true);
    
    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      final String authToken = await FirebaseAuth.instance.currentUser?.getIdToken() ?? "";

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/stripe/connect-account'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        final String accountLinkUrl = responseBody['accountLinkUrl'];
        
        // Open the Stripe Connect onboarding URL
        // You'll need to implement web view or external URL opening
        _showSuccessSnackBar('Redirecting to Stripe account setup...');
      } else {
        _showErrorSnackBar('Failed to create Stripe Connect account');
      }
    } catch (e) {
      _showErrorSnackBar('Error connecting to Stripe: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initiateStripePayout() async {
    if (!_formKey.currentState!.validate()) return;
    if (!widget.isStripeConnected) {
      _showErrorSnackBar('Please connect your Stripe account first');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final double amount = double.tryParse(_amountController.text) ?? 0.0;
      final int amountInCents = (amount * 100).toInt();
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      final String authToken = await FirebaseAuth.instance.currentUser?.getIdToken() ?? "";

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/stripe/create-payout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'amount': amountInCents,
          'currency': 'usd',
          'stripeAccountId': widget.stripeAccountId,
          'description': 'Driver earnings withdrawal',
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        _showSuccessDialog(amount, responseBody['estimatedArrival'] ?? '2-5 business days');
      } else {
        final responseBody = json.decode(response.body);
        _showErrorSnackBar(responseBody['message'] ?? 'Payout failed');
      }
    } catch (e) {
      _showErrorSnackBar('Network error: Please try again');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(double amount, String estimatedArrival) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: Colors.green[600], size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Withdrawal Initiated!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'DA ${amount.toStringAsFixed(2)} has been sent to your bank account.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Expected arrival: $estimatedArrival',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _setQuickAmount(double amount) {
    _amountController.text = amount.toString();
    setState(() => _showQuickAmounts = false);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Form(
            key: _formKey,
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBalanceCard(),
                const SizedBox(height: 32),
                
                if (!widget.isStripeConnected) ...[
                  _buildStripeConnectCard(),
                  const SizedBox(height: 24),
                ] else ...[
                  _buildAmountSection(),
                  const SizedBox(height: 24),
                  _buildWithdrawButton(),
                ],
                
                const SizedBox(height: 24),
                _buildInfoCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kMainColor, kMainColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kMainColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Available Balance",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'DA ${widget.availableBalance.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStripeConnectCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.account_balance, size: 48, color: Colors.orange[600]),
          const SizedBox(height: 16),
          const Text(
            'Connect Your Bank Account',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'To withdraw funds, you need to connect your bank account through Stripe.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.link, size: 20),
              label: Text(_isLoading ? 'Connecting...' : 'Connect with Stripe'),
              onPressed: _isLoading ? null : _connectStripeAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
                  ),
                ],
              ),
    );
  }

  Widget _buildAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Withdrawal Amount",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        
        if (_showQuickAmounts) _buildQuickAmounts(),
        
        const SizedBox(height: 16),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          onTap: () => setState(() => _showQuickAmounts = false),
          decoration: InputDecoration(
            labelText: "Enter amount (DA)",
            labelStyle: TextStyle(color: Colors.grey[600]),
            prefixIcon: Icon(Icons.attach_money, color: kMainColor),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: kMainColor, width: 2),
            ),
            hintText: "0.00",
            contentPadding: const EdgeInsets.all(20),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an amount';
            }
            final double? amount = double.tryParse(value);
            if (amount == null) {
              return 'Please enter a valid number';
            }
            if (amount <= 0) {
              return 'Amount must be greater than zero';
            }
            if (amount > widget.availableBalance) {
              return 'Amount exceeds available balance';
            }
            if (amount < 1) {
              return 'Minimum withdrawal amount is DA 1.00';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildQuickAmounts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick amounts",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _quickAmounts
              .where((amount) => amount <= widget.availableBalance)
              .map((amount) => _buildQuickAmountChip(amount))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildQuickAmountChip(double amount) {
    return GestureDetector(
      onTap: () => _setQuickAmount(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: kMainColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          'DA ${amount.toInt()}',
          style: TextStyle(
            color: kMainColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildWithdrawButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.send_rounded, size: 20),
        label: Text(
          _isLoading ? 'Processing...' : 'Withdraw to Bank',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        onPressed: _isLoading ? null : _initiateStripePayout,
        style: ElevatedButton.styleFrom(
          backgroundColor: kMainColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: kMainColor.withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Withdrawal Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Processing time', '2-5 business days'),
          _buildInfoRow('Minimum amount', 'DA 1.00'),
          _buildInfoRow('Transfer method', 'Bank transfer via Stripe'),
          const SizedBox(height: 8),
          Text(
            'Funds are processed securely through Stripe and sent directly to your connected bank account.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
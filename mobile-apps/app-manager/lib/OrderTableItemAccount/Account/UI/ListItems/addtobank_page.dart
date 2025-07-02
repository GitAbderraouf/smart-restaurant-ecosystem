import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:hungerz_store/Components/bottom_bar.dart';
import 'package:hungerz_store/Components/textfield.dart';
import 'package:hungerz_store/Components/entry_field.dart';

import 'package:hungerz_store/Themes/colors.dart';
import 'package:hungerz_store/Themes/style.dart';
import 'package:hungerz_store/cubits/payment_cubit.dart';
import 'package:hungerz_store/cubits/payment_state.dart';
import 'package:hungerz_store/services/payment_service.dart';

class AddToBank extends StatelessWidget {
  final double? amountToAdd;

  const AddToBank({Key? key, this.amountToAdd}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PaymentCubit(PaymentService()),
      child: Scaffold(
        backgroundColor: const Color(0xfff8fafb),
        appBar: AppBar(
          title: Text(
            "Add Credit/Debit Card",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: Theme.of(context).secondaryHeaderColor,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Add(amountToAdd: amountToAdd),
      ),
    );
  }
}

class Add extends StatefulWidget {
  final double? amountToAdd;

  const Add({Key? key, this.amountToAdd}) : super(key: key);

  @override
  _AddState createState() => _AddState();
}

class _AddState extends State<Add> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expDateController = TextEditingController();
  final _cvvController = TextEditingController();

  bool _isLoading = false;
  String? _clientSecretForConfirmation;
  double? _amountForConfirmation;

  @override
  void initState() {
    super.initState();
    if (widget.amountToAdd != null && widget.amountToAdd! > 0) {
      _amountController.text = widget.amountToAdd!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _cardNumberController.dispose();
    _expDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _handlePayment() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }
    if (_nameController.text.isEmpty ||
        _cardNumberController.text.isEmpty ||
        _expDateController.text.isEmpty ||
        _cvvController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all card details.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _amountForConfirmation = amount;
    });
    context.read<PaymentCubit>().createPaymentIntent(amount);
  }

  Future<void> _confirmStripePayment(String clientSecret) async {
    try {
      final expiryParts = _expDateController.text.split('/');
      final expiryMonth = int.tryParse(expiryParts[0]);
      final expiryYear = expiryParts.length > 1 ? int.tryParse(expiryParts[1]) : null;

      if (expiryMonth == null || expiryYear == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid expiration date format. Use MM/YY')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final billingDetails = stripe.BillingDetails(
        name: _nameController.text,
      );

      final paymentMethod = await stripe.Stripe.instance.createPaymentMethod(
        params: stripe.PaymentMethodParams.card(
          paymentMethodData: stripe.PaymentMethodData(
            billingDetails: billingDetails,
          ),
        ),
      );

      final stripe.PaymentIntent paymentIntent = await stripe.Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: stripe.PaymentMethodParams.cardFromMethodId(
          paymentMethodData: stripe.PaymentMethodDataCardFromMethod(
            paymentMethodId: paymentMethod.id,
          ),
        ),
      );

      if (paymentIntent.status == stripe.PaymentIntentsStatus.Succeeded) {
        if (_amountForConfirmation != null) {
          context.read<PaymentCubit>().confirmPayment(
                paymentIntentId: paymentIntent.id,
                amount: _amountForConfirmation!,
              );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Amount for confirmation not found.')),
          );
          setState(() => _isLoading = false);
        }
      } else if (paymentIntent.status == stripe.PaymentIntentsStatus.RequiresPaymentMethod) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment failed: Invalid card details or insufficient funds.')),
        );
        setState(() => _isLoading = false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment was not successful. Status: ${paymentIntent.status}')),
        );
        setState(() => _isLoading = false);
      }
    } on stripe.StripeException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stripe error: ${e.error.message ?? "Unknown Stripe error"}')),
      );
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error confirming payment: ${e.toString()}')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xff1a1d29),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xffe8ecef),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xff1a1d29),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardBrandIcons() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xff1a1f36),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Center(
            child: Text(
              'VISA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 32,
          height: 20,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xffeb001b), Color(0xfff79e1b)],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Center(
            child: Text(
              'MC',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 32,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xff0079be),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Center(
            child: Text(
              'AMEX',
              style: TextStyle(
                color: Colors.white,
                fontSize: 6,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentCubit, PaymentState>(
      listener: (context, state) {
        if (state is PaymentIntentCreated) {
          _clientSecretForConfirmation = state.clientSecret;
          _amountForConfirmation = state.amount;
          _confirmStripePayment(state.clientSecret);
        } else if (state is PaymentIntentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating payment intent: ${state.error}')),
          );
          setState(() => _isLoading = false);
        } else if (state is PaymentConfirmationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${state.message}. New Balance: ${state.newBalance}')),
          );
          setState(() => _isLoading = false);
          Navigator.pop(context);
        } else if (state is PaymentConfirmationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error confirming payment: ${state.error}')),
          );
          setState(() => _isLoading = false);
        }
      },
      child: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: kMainColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.account_balance_wallet,
                                color: kMainColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Add to Wallet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff1a1d29),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildModernTextField(
                          controller: _amountController,
                          label: "Amount",
                          hint: "Enter amount to add",
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Card Details Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xff6366f1).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.credit_card,
                                color: Color(0xff6366f1),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Card Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff1a1d29),
                              ),
                            ),
                            const Spacer(),
                            _buildCardBrandIcons(),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        _buildModernTextField(
                          controller: _nameController,
                          label: "Cardholder Name",
                          hint: "Enter full name",
                        ),
                        
                        const SizedBox(height: 20),
                        
                        _buildModernTextField(
                          controller: _cardNumberController,
                          label: "Card Number",
                          hint: "1234 5678 9012 3456",
                          keyboardType: TextInputType.number,
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(
                              Icons.credit_card,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernTextField(
                                controller: _expDateController,
                                label: "Expiration Date",
                                hint: "MM/YY",
                                keyboardType: TextInputType.datetime,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildModernTextField(
                                controller: _cvvController,
                                label: "CVV",
                                hint: "123",
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                suffixIcon: Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Icon(
                                    Icons.help_outline,
                                    color: Colors.grey.shade400,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 120), // Space for bottom button
                ],
              ),
            ),
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(kMainColor),
                ),
              ),
            ),
          
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Container(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handlePayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kMainColor,
                      disabledBackgroundColor: Colors.grey.shade300,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Add to Wallet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
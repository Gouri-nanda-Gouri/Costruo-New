import 'package:costruo_user/main.dart';
import 'package:costruo_user/success.dart';
import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';

class PaymentGatewayScreen extends StatefulWidget {
  final int id;
  final int amt;
  final String type;
  const PaymentGatewayScreen({super.key, required this.id, required this.amt, required this.type});

  @override
  _PaymentGatewayScreenState createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  Future<void> updatePaymentStatus() async {
    try {
      await supabase
          .from('tbl_payment')
          .update({'payment_status': 1})
          .eq('workquote_id', widget.id)
          .eq('payment_amount', widget.amt);
          
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => PaymentSuccessPage())
      );
    } catch (e) {
      print(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating payment status: $e'))
        );
      }
    }
  }

  Future<void> checkout() async {
    try {
      await supabase
          .from('tbl_workquote')
          .update({'work_remark': 9})
          .eq('workquote_id', widget.id);
      await supabase.from('tbl_payment').insert({
        'payment_amount': widget.amt,
        'workquote_id': widget.id,
        'payment_status': 1,
        'payment_name': 'Advance'
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PaymentSuccessPage()),
      );
    } catch (e) {
      print(e);
    }
  }

  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Gateway'),
        backgroundColor: const Color.fromARGB(255, 130, 130, 130),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 130, 130, 130), Color.fromARGB(255, 209, 209, 209)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              CreditCardWidget(
                cardNumber: cardNumber,
                expiryDate: expiryDate,
                cardHolderName: cardHolderName,
                cvvCode: cvvCode,
                showBackView: isCvvFocused,
                onCreditCardWidgetChange: (creditCardBrand) {},
                isHolderNameVisible: true,
                enableFloatingCard: true,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      CreditCardForm(
                        cardNumber: cardNumber,
                        expiryDate: expiryDate,
                        cardHolderName: cardHolderName,
                        cvvCode: cvvCode,
                        isHolderNameVisible: true,
                        onCreditCardModelChange: (creditCardModel) {
                          setState(() {
                            cardNumber = creditCardModel.cardNumber;
                            expiryDate = creditCardModel.expiryDate;
                            cardHolderName = creditCardModel.cardHolderName;
                            cvvCode = creditCardModel.cvvCode;
                            isCvvFocused = creditCardModel.isCvvFocused;
                          });
                        },
                        formKey: formKey,
                        cardNumberValidator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'This field is required';
                          }
                          if (value.length != 19) {
                            return 'Invalid card number';
                          }
                          return null;
                        },
                        expiryDateValidator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'This field is required';
                          }

                          // Check if the input matches the MM/YY format
                          if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                            return 'Invalid expiry date format';
                          }

                          // Split the input into month and year
                          final List<String> parts = value.split('/');
                          final int month = int.tryParse(parts[0]) ?? 0;
                          final int year = int.tryParse(parts[1]) ?? 0;

                          // Get the current date
                          final DateTime now = DateTime.now();
                          final int currentYear =
                              now.year % 100; // Get last two digits of the year
                          final int currentMonth = now.month;

                          // Validate the month and year
                          if (month < 1 || month > 12) {
                            return 'Invalid month';
                          }

                          // Check if the year is in the past
                          if (year < currentYear ||
                              (year == currentYear && month < currentMonth)) {
                            return 'Card has expired';
                          }

                          return null; // Valid expiry date
                        },
                        cvvValidator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'This field is required';
                          }
                          if (value.length < 3) {
                            return 'Invalid CVV';
                          }
                          return null;
                        },
                        cardHolderValidator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'This field is required';
                          }
                          if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
                            return 'Invalid cardholder name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 216, 216, 216),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                        ),
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            // Use updatePaymentStatus instead of checkout for pending payments
                            if(widget.type == "Adv"){
                              checkout();
                            }
                            else{
                            updatePaymentStatus();
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please fill in all fields correctly!')),
                            );
                          }
                        },
                        child: const Text(
                          'Pay Now',
                          style: TextStyle(fontSize: 18, color: Colors.blueAccent),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

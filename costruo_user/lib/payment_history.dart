import 'package:costruo_user/payment.dart';
import 'package:flutter/material.dart';
import 'package:costruo_user/main.dart';
import 'package:intl/intl.dart';

class PaymentHistoryPage extends StatefulWidget {
  final int workquoteId;
  final double totalBudget;

  const PaymentHistoryPage({
    super.key, 
    required this.workquoteId,
    required this.totalBudget,
  });

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  List<Map<String, dynamic>> payments = [];
  bool isLoading = true;
  double totalPaid = 0;
  
  @override
  void initState() {
    super.initState();
    fetchPayments();
  }

  Future<void> fetchPayments() async {
    try {
      final data = await supabase
          .from('tbl_payment')
          .select('*')
          .eq('workquote_id', widget.workquoteId)
          .order('created_at', ascending: false);

      setState(() {
        payments = List<Map<String, dynamic>>.from(data);
        totalPaid = payments.fold(
          0, 
          (sum, payment) => sum + (payment['payment_amount'] ?? 0)
        );
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching payments: $e')),
        );
        setState(() => isLoading = false);
      }
    }
  }

  String getPaymentStatusText(int status) {
    switch (status) {
      case 1:
        return 'Completed';
      case 0:
        return 'Pending';
      case 2:
        return 'Failed';
      default:
        return 'Unknown';
    }
  }

  Color getPaymentStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.green;
      case 0:
        return Colors.orange;
      case 2:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPaymentItem(Map<String, dynamic> payment) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            title: Text(
              payment['payment_name'] ?? 'Payment',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(
                    DateTime.parse(payment['created_at'].toString()),
                  ),
                ),
                if (payment['payment_status'] == 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentGatewayScreen(
                              type: 'Pending',
                              id: widget.workquoteId,
                              amt: payment['payment_amount'].toInt(),
                            ),
                          ),
                        ).then((_) => fetchPayments()); // Refresh after payment
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text('Pay Now'),
                    ),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${payment['payment_amount']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  getPaymentStatusText(payment['payment_status']),
                  style: TextStyle(
                    color: getPaymentStatusColor(payment['payment_status']),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remainingAmount = widget.totalBudget - totalPaid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: const Color.fromARGB(255, 130, 130, 130),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Payment Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormat('dd MMM yyyy').format(DateTime.now()),
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      _buildSummaryRow('Total Budget', widget.totalBudget),
                      _buildSummaryRow('Total Paid', totalPaid),
                      _buildSummaryRow('Remaining', remainingAmount),
                    ],
                  ),
                ),
                Expanded(
                  child: payments.isEmpty
                      ? const Center(
                          child: Text(
                            'No payment history available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: payments.length,
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (context, index) => _buildPaymentItem(payments[index]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: label == 'Remaining' 
                  ? amount > 0 ? Colors.red : Colors.green
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

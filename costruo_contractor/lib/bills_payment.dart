import 'package:flutter/material.dart';
import 'package:costruo_contractor/main.dart' as main_supabase;
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

class BillsPayment extends StatefulWidget {
  final int workquoteId;
  final double totalBudget;

  const BillsPayment({
    super.key, 
    required this.workquoteId,
    required this.totalBudget,
  });

  @override
  State<BillsPayment> createState() => _BillsPaymentState();
}

class _BillsPaymentState extends State<BillsPayment> {
  List<Map<String, dynamic>> payments = [];
  bool isLoading = true;
  double totalPaid = 0;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _remarkController = TextEditingController();
  final _billImageController = TextEditingController();
  PlatformFile? pickedImage;

  @override
  void initState() {
    super.initState();
    fetchPayments();
  }

  // Handle bill image pick
  Future<void> handleImagePick() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        pickedImage = result.files.first;
        _billImageController.text = result.files.first.name;
      });
    }
  }

  // Upload bill image to Supabase storage
  Future<String?> uploadBillImage() async {
    if (pickedImage == null) return null;

    try {
      final now = DateTime.now();
      final formattedDate = DateFormat('dd-MM-yy-HH-mm-ss').format(now);
      final fileExtension = pickedImage!.name.split('.').last;
      final fileName = 'bill-${widget.workquoteId}-$formattedDate.$fileExtension';

      await main_supabase.supabase.storage.from('bills').uploadBinary(
            fileName,
            pickedImage!.bytes!,
          );

      final publicUrl = main_supabase.supabase.storage
          .from('bills')
          .getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      print("Error uploading bill image: $e");
      return null;
    }
  }

  Future<void> fetchPayments() async {
    try {
      final data = await main_supabase.supabase
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

  Future<void> addNewPayment() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => isLoading = true);
      
      // Upload bill image if selected
      String? billImageUrl;
      if (pickedImage != null) {
        billImageUrl = await uploadBillImage();
      }
      
      await main_supabase.supabase.from('tbl_payment').insert({
        'payment_amount': double.parse(_amountController.text),
        'workquote_id': widget.workquoteId,
        'payment_status': 0, // Pending status
        'payment_name': _remarkController.text,
        'payment_bill': billImageUrl, // Add bill image URL
      });

      _amountController.clear();
      _remarkController.clear();
      _billImageController.clear();
      setState(() => pickedImage = null);
      
      await fetchPayments();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment request added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding payment: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
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

  // Show bill image in full screen
  void _showBillImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Flexible(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Modified payment form to include bill image
  Widget _buildPaymentForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '₹',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an amount';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _remarkController,
            decoration: const InputDecoration(
              labelText: 'Payment Description',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a description';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: handleImagePick,
            child: AbsorbPointer(
              child: TextFormField(
                controller: _billImageController,
                decoration: const InputDecoration(
                  labelText: 'Attach Bill Image',
                  suffixIcon: Icon(Icons.attach_file),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              addNewPayment();
            },
            child: const Text('Add Payment Request'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Modified payment history item to show bill image
  Widget _buildPaymentHistoryItem(Map<String, dynamic> payment) {
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
            subtitle: Text(
              DateFormat('dd MMM yyyy, hh:mm a').format(
                DateTime.parse(payment['created_at'].toString()),
              ),
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
          if (payment['bill_image'] != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => _showBillImage(payment['bill_image']),
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(payment['bill_image']),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
        title: const Text('Bills & Payments'),
        backgroundColor: const Color.fromARGB(255, 130, 130, 130),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Payment Summary Card
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

                // Add New Payment Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                            left: 16,
                            right: 16,
                            top: 16,
                          ),
                          child: _buildPaymentForm(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

                // Payment History List
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
                          itemBuilder: (context, index) => _buildPaymentHistoryItem(payments[index]),
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

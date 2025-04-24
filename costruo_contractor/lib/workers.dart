import 'package:costruo_contractor/main.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'dart:convert';

class ManageWorkers extends StatefulWidget {
  const ManageWorkers({super.key});

  @override
  State<ManageWorkers> createState() => _ManageWorkersState();
}

class _ManageWorkersState extends State<ManageWorkers> {
  List<Map<String, dynamic>> workers = [];
  List<Map<String, dynamic>> typelist = [];
  List<Map<String, dynamic>> salaryRecords = [];
  bool isLoading = true;
  String? errorMessage;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchWorkers();
    fetchTypes();
    fetchSalaryRecords();
  }

  Future<void> fetchWorkers() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await supabase
          .from('tbl_worker')
          .select('''
            id,
            worker_name,
            worker_email,
            worker_contact,
            worker_photo,
            type_id,
            tbl_type(type_name)
          ''')
          .order('worker_name', ascending: true);

      setState(() {
        workers = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching workers: $e';
      });
    }
  }

  Future<void> fetchTypes() async {
    try {
      final response = await supabase.from("tbl_type").select();
      setState(() {
        typelist = response;
      });
    } catch (e) {
      print("Error fetching types: $e");
    }
  }

  Future<void> fetchSalaryRecords() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final response = await supabase
          .from('tbl_salary')
          .select('worker_id, salary_date, salary_amount, salary_status')
          .gte('salary_date', startOfMonth.toIso8601String())
          .lte('salary_date', endOfMonth.toIso8601String());

      setState(() {
        salaryRecords = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error fetching salary records: $e');
    }
  }

  bool hasBeenPaidThisMonth(String workerId) {
    return salaryRecords.any((record) =>
        record['worker_id'] == workerId && record['salary_status'] == 1);
  }

  Future<void> deleteWorker(String workerId, String? photoUrl) async {
    try {
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this worker?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (shouldDelete != true) return;

      if (photoUrl != null && photoUrl.isNotEmpty) {
        final photoPath = photoUrl.split('/').last;
        await supabase.storage.from('worker').remove([photoPath]);
      }

      await supabase.from('tbl_worker').delete().eq('id', workerId);
      await supabase.auth.admin.deleteUser(workerId);

      await fetchWorkers();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Worker deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting worker: $e')),
      );
    }
  }

  void showPaymentDialog(String workerId, String workerName) {
    showDialog(
      context: context,
      builder: (context) => SalaryPaymentDialog(
        workerId: workerId,
        workerName: workerName,
        onPaymentSuccess: () async {
          await fetchSalaryRecords();
          setState(() {});
        },
      ),
    );
  }

  void showRegistrationDialog() {
    showDialog(
      context: context,
      builder: (context) => RegistrationDialog(
        typelist: typelist,
        onRegisterSuccess: fetchWorkers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Manage Workers',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Worker'),
              onPressed: showRegistrationDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.blue, size: 28),
              onPressed: () async {
                await fetchWorkers();
                await fetchSalaryRecords();
              },
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.3,
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search workers...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
          ),
          Expanded(
            child: _buildWorkersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkersList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchWorkers,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredWorkers = workers.where((worker) {
      final name = worker['worker_name']?.toString().toLowerCase() ?? '';
      final email = worker['worker_email']?.toString().toLowerCase() ?? '';
      final type = worker['tbl_type']?['type_name']?.toString().toLowerCase() ?? '';
      return name.contains(searchQuery) ||
             email.contains(searchQuery) ||
             type.contains(searchQuery);
    }).toList();

    if (filteredWorkers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              searchQuery.isEmpty ? 'No workers added yet' : 'No workers found',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        childAspectRatio: 0.75,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: filteredWorkers.length,
      itemBuilder: (context, index) {
        final worker = filteredWorkers[index];
        return _buildWorkerCard(worker);
      },
    );
  }

  Widget _buildWorkerCard(Map<String, dynamic> worker) {
    final bool canPaySalary = !hasBeenPaidThisMonth(worker['id']);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _showWorkerDetails(worker),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: worker['worker_photo'] != null
                        ? NetworkImage(worker['worker_photo'])
                        : null,
                    child: worker['worker_photo'] == null
                        ? Text(
                            worker['worker_name'][0].toUpperCase(),
                            style: const TextStyle(fontSize: 24),
                          )
                        : null,
                  ),
                  Positioned(
                    right: -8,
                    top: -8,
                    child: PopupMenuButton(
                      icon: const Icon(Icons.more_vert, size: 20),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const ListTile(
                            leading: Icon(Icons.edit, color: Colors.blue, size: 20),
                            title: Text('Edit', style: TextStyle(fontSize: 14)),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onTap: () => _editWorker(worker),
                        ),
                        PopupMenuItem(
                          child: const ListTile(
                            leading: Icon(Icons.delete, color: Colors.red, size: 20),
                            title: Text('Delete', style: TextStyle(fontSize: 14)),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onTap: () => deleteWorker(worker['id'], worker['worker_photo']),
                        ),
                        if (canPaySalary)
                          PopupMenuItem(
                            child: const ListTile(
                              leading: Icon(Icons.payment, color: Colors.green, size: 20),
                              title: Text('Pay Salary', style: TextStyle(fontSize: 14)),
                              contentPadding: EdgeInsets.zero,
                            ),
                            onTap: () => showPaymentDialog(worker['id'], worker['worker_name']),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                worker['worker_name'] ?? 'N/A',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                worker['tbl_type']?['type_name'] ?? 'N/A',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                worker['worker_email'] ?? 'N/A',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWorkerDetails(Map<String, dynamic> worker) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Worker Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage: worker['worker_photo'] != null
                    ? NetworkImage(worker['worker_photo'])
                    : null,
                child: worker['worker_photo'] == null
                    ? Text(
                        worker['worker_name'][0].toUpperCase(),
                        style: const TextStyle(fontSize: 40),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                worker['worker_name'] ?? 'N/A',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                worker['tbl_type']?['type_name'] ?? 'N/A',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.email),
                title: Text(worker['worker_email'] ?? 'N/A'),
                contentPadding: EdgeInsets.zero,
              ),
              ListTile(
                leading: const Icon(Icons.phone),
                title: Text(worker['worker_contact'] ?? 'N/A'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editWorker(Map<String, dynamic> worker) {
    // Implement edit worker functionality
  }
}

class SalaryPaymentDialog extends StatefulWidget {
  final String workerId;
  final String workerName;
  final VoidCallback onPaymentSuccess;

  const SalaryPaymentDialog({
    super.key,
    required this.workerId,
    required this.workerName,
    required this.onPaymentSuccess,
  });

  @override
  State<SalaryPaymentDialog> createState() => _SalaryPaymentDialogState();
}

class _SalaryPaymentDialogState extends State<SalaryPaymentDialog> {
  TextEditingController amountController = TextEditingController();
  bool isPaying = false;

  void navigateToPaymentGateway() {
    final amountText = amountController.text;
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the salary amount")),
      );
      return;
    }

    final amount = int.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid salary amount")),
      );
      return;
    }

    Navigator.of(context).pop(); // Close the dialog
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentGatewayScreen(
          workerId: widget.workerId,
          workerName: widget.workerName,
          amount: amount,
          onPaymentSuccess: widget.onPaymentSuccess,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF5F5F5),
      title: Text(
        'Pay Salary to ${widget.workerName}',
        style: const TextStyle(color: Color(0xFF333333), fontFamily: 'serif'),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Color(0xFF333333)),
              decoration: InputDecoration(
                label: const Text("Salary Amount"),
                labelStyle: const TextStyle(color: Color(0xFF666666)),
                filled: true,
                fillColor: const Color(0xFFE8ECEF),
                prefixIcon: const Icon(Icons.money, color: Color(0xFF333333)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Payment for ${DateFormat('MMMM yyyy').format(DateTime.now())}',
              style: const TextStyle(color: Color(0xFF666666)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Color(0xFF666666))),
        ),
        ElevatedButton(
          onPressed: isPaying ? null : navigateToPaymentGateway,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: const Color(0xFF007BFF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          ),
          child: isPaying
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  "Proceed to Payment",
                  style: TextStyle(fontSize: 16, fontFamily: 'serif'),
                ),
        ),
      ],
    );
  }
}
class PaymentGatewayScreen extends StatefulWidget {
  final String workerId;
  final String workerName;
  final int amount;
  final VoidCallback onPaymentSuccess;

  const PaymentGatewayScreen({
    Key? key,
    required this.workerId,
    required this.workerName,
    required this.amount,
    required this.onPaymentSuccess,
  }) : super(key: key);

  @override
  _PaymentGatewayScreenState createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  
  // Controllers for form fields
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cardHolderNameController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  
  bool isProcessing = false;
  String? errorMessage;

  // Format card number with spaces
  String _formatCardNumber(String input) {
    input = input.replaceAll(' ', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < input.length; i++) {
      buffer.write(input[i]);
      if ((i + 1) % 4 == 0 && i != input.length - 1) {
        buffer.write(' ');
      }
    }
    
    return buffer.toString();
  }

  // Format expiry date with slash
  String _formatExpiryDate(String input) {
    input = input.replaceAll('/', '');
    if (input.length > 2) {
      return '${input.substring(0, 2)}/${input.substring(2)}';
    }
    return input;
  }

  @override
  void initState() {
    super.initState();
    
    // Add listeners to format input as user types
    _cardNumberController.addListener(() {
      final text = _cardNumberController.text;
      _cardNumberController.value = _cardNumberController.value.copyWith(
        text: _formatCardNumber(text),
        selection: TextSelection.collapsed(offset: _formatCardNumber(text).length),
      );
    });
    
    _expiryDateController.addListener(() {
      final text = _expiryDateController.text;
      _expiryDateController.value = _expiryDateController.value.copyWith(
        text: _formatExpiryDate(text),
        selection: TextSelection.collapsed(offset: _formatExpiryDate(text).length),
      );
    });
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cardHolderNameController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isProcessing = true;
      errorMessage = null;
    });

    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));
      
      // In a real app, you would integrate with your payment gateway here
      // For demo purposes, we'll simulate a successful payment
      await supabase.from('tbl_salary').insert({
        'worker_id': widget.workerId,
        'salary_date': DateTime.now().toIso8601String(),
        'salary_amount': widget.amount,
        'salary_status': 1,
      });

      widget.onPaymentSuccess();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful')),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Payment failed: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Payment Gateway',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.4,
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.payment_rounded,
                            color: Color(0xFF1976D2),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Salary Payment',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'For ${widget.workerName}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Amount Display
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFAED581), width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Amount to Pay:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          Text(
                            currencyFormatter.format(widget.amount),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Payment Form
                    Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Card Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Card Number Field
                          TextFormField(
                            controller: _cardNumberController,
                            decoration: InputDecoration(
                              labelText: 'Card Number',
                              hintText: '1234 5678 9012 3456',
                              prefixIcon: const Icon(Icons.credit_card, color: Color(0xFF666666)),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(19),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter card number';
                              }
                              
                              final cardNumber = value.replaceAll(' ', '');
                              if (cardNumber.length < 16) {
                                return 'Card number must be 16 digits';
                              }
                              
                              // Luhn algorithm validation could be added here
                              
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // Card Holder Name
                          TextFormField(
                            controller: _cardHolderNameController,
                            decoration: InputDecoration(
                              labelText: 'Card Holder Name',
                              hintText: 'John Doe',
                              prefixIcon: const Icon(Icons.person, color: Color(0xFF666666)),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                              ),
                            ),
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter card holder name';
                              }
                              if (value.length < 3) {
                                return 'Name is too short';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // Expiry Date and CVV
                          Row(
                            children: [
                              // Expiry Date
                              Expanded(
                                child: TextFormField(
                                  controller: _expiryDateController,
                                  decoration: InputDecoration(
                                    labelText: 'Expiry Date',
                                    hintText: 'MM/YY',
                                    prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF666666)),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    
                                    final cleanValue = value.replaceAll('/', '');
                                    if (cleanValue.length < 4) {
                                      return 'Invalid format';
                                    }
                                    
                                    final month = int.tryParse(cleanValue.substring(0, 2)) ?? 0;
                                    final year = int.tryParse(cleanValue.substring(2, 4)) ?? 0;
                                    
                                    if (month < 1 || month > 12) {
                                      return 'Invalid month';
                                    }
                                    
                                    final now = DateTime.now();
                                    final currentYear = now.year % 100;
                                    final currentMonth = now.month;
                                    
                                    if (year < currentYear || (year == currentYear && month < currentMonth)) {
                                      return 'Card expired';
                                    }
                                    
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // CVV
                              Expanded(
                                child: TextFormField(
                                  controller: _cvvController,
                                  decoration: InputDecoration(
                                    labelText: 'CVV',
                                    hintText: '123',
                                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF666666)),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    if (value.length < 3 || value.length > 4) {
                                      return 'Invalid CVV';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Error Message
                    if (errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFEF9A9A)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 32),
                    
                    // Payment Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isProcessing ? null : _processPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: isProcessing
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Pay Now',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Security Notice
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.lock, size: 16, color: Color(0xFF666666)),
                          SizedBox(width: 8),
                          Text(
                            'Secure Payment',
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class RegistrationDialog extends StatefulWidget {
  final List<Map<String, dynamic>> typelist;
  final VoidCallback onRegisterSuccess;

  const RegistrationDialog({
    super.key,
    required this.typelist,
    required this.onRegisterSuccess,
  });

  @override
  State<RegistrationDialog> createState() => _RegistrationDialogState();
}

class _RegistrationDialogState extends State<RegistrationDialog> {
  bool password = true;
  bool cpassword = true;
  PlatformFile? pickedImage;
  File? _profileImage;

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController contactController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController cpasswordController = TextEditingController();

  String _selectedType = "";
  bool isRegistering = false;

  Future<void> handleImagePick() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          pickedImage = result.files.first;
          _profileImage = File(pickedImage!.path!);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<String?> photoUpload(String uid) async {
    if (pickedImage == null || pickedImage!.bytes == null) return null;

    try {
      final filePath = "$uid-${pickedImage!.name}";
      await supabase.storage
          .from('worker')
          .uploadBinary(filePath, pickedImage!.bytes!);
      final String photoUrl =
          supabase.storage.from('worker').getPublicUrl(filePath);
      return photoUrl;
    } catch (e) {
      throw 'Error uploading image: $e';
    }
  }

  Future<void> register() async {
    try {
      final name = nameController.text;
      final email = emailController.text;
      final contact = contactController.text;
      final password = passwordController.text;
      final type = _selectedType;
      final cpassword = cpasswordController.text;

      if (name.isEmpty ||
          email.isEmpty ||
          contact.isEmpty ||
          password.isEmpty ||
          type.isEmpty ||
          cpassword.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please fill all the fields")));
        return;
      }

      if (pickedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please upload a profile image")));
        return;
      }

      if (password != cpassword) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Password and Confirm Password do not match")));
        return;
      }

      if (_selectedType.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please select a skill type")));
        return;
      }

      if (password.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Password must be at least 6 characters long")));
        return;
      }

      setState(() {
        isRegistering = true;
      });

      final auth = await supabase.auth.signUp(
        password: passwordController.text,
        email: emailController.text,
      );
      String uid = auth.user!.id;

      String? profileImageUrl = await photoUpload(uid);

      await supabase.from("tbl_worker").insert({
        "id": uid,
        "worker_name": name,
        "worker_email": email,
        "worker_contact": contact,
        "worker_password": password,
        "type_id": int.parse(type),
        "worker_photo": profileImageUrl,
      });

      Navigator.of(context).pop();

      widget.onRegisterSuccess();

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Worker registered successfully")));
    } catch (e) {
      setState(() {
        isRegistering = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registration failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF5F5F5),
      title: const Text(
        'Register New Worker',
        style: TextStyle(color: Color(0xFF333333), fontFamily: 'serif'),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: handleImagePick,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage:
                    _profileImage != null ? FileImage(_profileImage!) : null,
                child: _profileImage == null
                    ? const Icon(Icons.camera_alt,
                        color: Color(0xFF666666), size: 40)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Profile Photo",
              style: TextStyle(
                color: Color(0xFF666666),
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: nameController,
              style: const TextStyle(color: Color(0xFF333333)),
              decoration: InputDecoration(
                label: const Text("Full Name"),
                labelStyle: const TextStyle(color: Color(0xFF666666)),
                filled: true,
                fillColor: const Color(0xFFE8ECEF),
                prefixIcon:
                    const Icon(Icons.person_outline, color: Color(0xFF333333)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Color(0xFF333333)),
              decoration: InputDecoration(
                label: const Text("Email"),
                labelStyle: const TextStyle(color: Color(0xFF666666)),
                filled: true,
                fillColor: const Color(0xFFE8ECEF),
                prefixIcon: const Icon(Icons.alternate_email_outlined,
                    color: Color(0xFF333333)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: contactController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Color(0xFF333333)),
              decoration: InputDecoration(
                label: const Text("Contact Number"),
                labelStyle: const TextStyle(color: Color(0xFF666666)),
                filled: true,
                fillColor: const Color(0xFFE8ECEF),
                prefixIcon: const Icon(Icons.phone_enabled_outlined,
                    color: Color(0xFF333333)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField(
              style: const TextStyle(color: Color(0xFF333333)),
              decoration: const InputDecoration(
                labelText: 'Skill Type',
                labelStyle: TextStyle(color: Color(0xFF666666)),
                filled: true,
                fillColor: Color(0xFFE8ECEF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
              value: _selectedType.isEmpty ? null : _selectedType,
              items: widget.typelist.map((type) {
                return DropdownMenuItem(
                  value: type['id'].toString(),
                  child: Text(type['type_name'],
                      style: const TextStyle(color: Color(0xFF333333))),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value.toString();
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              style: const TextStyle(color: Color(0xFF333333)),
              obscureText: password,
              keyboardType: TextInputType.visiblePassword,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      password = !password;
                    });
                  },
                  icon: Icon(
                    password ? Icons.visibility : Icons.visibility_off,
                    color: const Color(0xFF333333),
                  ),
                ),
                label: const Text("Password"),
                labelStyle: const TextStyle(color: Color(0xFF666666)),
                filled: true,
                fillColor: const Color(0xFFE8ECEF),
                prefixIcon:
                    const Icon(Icons.lock_outlined, color: Color(0xFF333333)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: cpasswordController,
              style: const TextStyle(color: Color(0xFF333333)),
              obscureText: cpassword,
              keyboardType: TextInputType.visiblePassword,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      cpassword = !cpassword;
                    });
                  },
                  icon: Icon(
                    cpassword ? Icons.visibility : Icons.visibility_off,
                    color: const Color(0xFF333333),
                  ),
                ),
                label: const Text("Confirm Password"),
                labelStyle: const TextStyle(color: Color(0xFF666666)),
                filled: true,
                fillColor: const Color(0xFFE8ECEF),
                prefixIcon:
                    const Icon(Icons.lock_outlined, color: Color(0xFF333333)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isRegistering ? null : register,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: const Color(0xFF007BFF),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: isRegistering
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Register",
                      style: TextStyle(fontSize: 16, fontFamily: 'serif'),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Color(0xFF666666))),
        ),
      ],
    );
  }
}
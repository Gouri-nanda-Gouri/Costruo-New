import 'package:costruo_user/enquirydetail.dart';
import 'package:costruo_user/main.dart';
import 'package:costruo_user/payment.dart';
import 'package:costruo_user/work_progress.dart';
import 'package:flutter/material.dart';
import 'package:costruo_user/main.dart' as main_supabase;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';
import 'package:costruo_user/payment_history.dart';

class EnquiriesPage extends StatefulWidget {
  const EnquiriesPage({super.key});

  @override
  State<EnquiriesPage> createState() => _EnquiriesPageState();
}

class _EnquiriesPageState extends State<EnquiriesPage> {
  List<Map<String, dynamic>> enquiries = [];

  @override
  void initState() {
    super.initState();
    fetchEnquiries();
  }

  Future<void> fetchEnquiries() async {
    try {
      final data = await main_supabase.supabase
          .from('tbl_enquiry')
          .select('*, tbl_work(*,tbl_contractor(*))')
          .eq('user_id', supabase.auth.currentUser!.id);

      setState(() {
        enquiries = List<Map<String, dynamic>>.from(data);
      });
      print(enquiries);
    } catch (e) {
      print("Error fetching enquiries: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Search Enquiries',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (query) {
              setState(() {
                enquiries = enquiries.where((enquiry) {
                  final location =
                      enquiry['enquiry_location']?.toLowerCase() ?? '';
                  final contact =
                      enquiry['enquiry_contact']?.toLowerCase() ?? '';
                  final detail = enquiry['enquiry_detail']?.toLowerCase() ?? '';
                  return location.contains(query.toLowerCase()) ||
                      contact.contains(query.toLowerCase()) ||
                      detail.contains(query.toLowerCase());
                }).toList();
              });
            },
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: enquiries.length,
              itemBuilder: (context, index) {
                final enquiry = enquiries[index];
                final contractorName = enquiry['tbl_work']?['tbl_contractor']
                        ?['contractor_name'] ??
                    'Unknown Contractor';
                final status = enquiry['enquiry_status'] ?? 0;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: enquiry['enquiry_image'] != null
                        ? CircleAvatar(
                            backgroundImage:
                                NetworkImage(enquiry['enquiry_image']),
                          )
                        : const CircleAvatar(child: Icon(Icons.image)),
                    title: Text(
                      contractorName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location: ${enquiry['enquiry_location']} - ${enquiry['enquiry_detail']}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (status == 1)
                          Text(
                            'Status: Accepted - Visiting: ${enquiry['visiting_date'] ?? 'TBD'}',
                            style: const TextStyle(color: Colors.green),
                          )
                        else if (status == 3)
                          const Text(
                            'Status: Visited',
                            style: TextStyle(color: Colors.blue),
                          )
                        else if (status == 0)
                          const Text(
                            'Status: Pending',
                            style: TextStyle(color: Colors.orange),
                          )
                        else if (status == 4)
                          const Text(
                            'Status: Work Inprogress',
                            style: TextStyle(color: Colors.green),
                          )
                        else if (status == 5)
                          const Text(
                            'Status: Architect Assigned',
                            style: TextStyle(color: Colors.blue),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EnquiryDetailPage(
                            enquiry: enquiry,
                            contractorName: contractorName,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EnquiryDetailPage extends StatefulWidget {
  final Map<String, dynamic> enquiry;
  final String contractorName;

  const EnquiryDetailPage({
    super.key,
    required this.enquiry,
    required this.contractorName,
  });

  @override
  State<EnquiryDetailPage> createState() => _EnquiryDetailPageState();
}

class _EnquiryDetailPageState extends State<EnquiryDetailPage> {
  String? drawingUrl;
  File? localPdfFile;
  bool isLoading = false;
  String? errorMessage;
  String workRemark = '';
  Map<String, dynamic>? workquoteData;

  void navigateDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkProgressPage(
          workquoteId: workquoteData!['workquote_id'],
          enquiryId: widget.enquiry['id'],
        ),
      ),
    );
  }

  void viewPaymentHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentHistoryPage(
          workquoteId: workquoteData!['workquote_id'],
          totalBudget: double.parse(workquoteData!['workquote_budget'].toString()),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchDrawing();
  }

  Future<void> fetchDrawing() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('tbl_workquote')
          .select('*')
          .eq('enquiry_id', widget.enquiry['id'])
          .order('workquote_id', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        setState(() {
          workquoteData = response;
          drawingUrl = response['workquote_drawing'];
          workRemark = response['work_remark']?.toString() ?? '';
        });
        print("Remark: ${response['work_remark']}");
        if (drawingUrl != null) {
          await downloadAndOpenPDF();
        }
      }
    } catch (e) {
      setState(() => errorMessage = 'Error fetching drawing: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> downloadAndOpenPDF() async {
    if (drawingUrl == null) return;

    try {
      final response = await http.get(Uri.parse(drawingUrl!));
      final bytes = response.bodyBytes;
      final tempDir = await getTemporaryDirectory();
      localPdfFile = File('${tempDir.path}/drawing.pdf');
      await localPdfFile!.writeAsBytes(bytes);
    } catch (e) {
      setState(() => errorMessage = 'Error downloading PDF: $e');
    }
  }

  Future<void> acceptDrawing() async {
    try {
      await supabase.from('tbl_workquote').update({'work_remark': '7'}).eq(
          'workquote_id', workquoteData!['workquote_id']);

      setState(() => workRemark = '7');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Drawing accepted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting drawing: $e')),
      );
    }
  }

  Future<void> requestDrawingRevision() async {
    final TextEditingController reasonController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Drawing Revision'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Enter reason for revision',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (result == true && reasonController.text.isNotEmpty) {
      try {
        await supabase.from('tbl_workquote').update({
          'work_remark': '8',
          'refresh_reason': reasonController.text,
        }).eq('workquote_id', workquoteData!['workquote_id']);

        setState(() => workRemark = '8');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Revision requested successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error requesting revision: $e')),
        );
      }
    }
  }

  // Add this method to calculate 25% of the budget
  double calculateAdvancePayment() {
    if (workquoteData != null && workquoteData!['workquote_budget'] != null) {
      double totalBudget = double.parse(workquoteData!['workquote_budget'].toString());
      return totalBudget * 0.25;
    }
    return 0.0;
  }

  // Add this method to handle payment
  Future<void> initiateAdvancePayment() async {
    double paymentAmount = calculateAdvancePayment();
    
    // Show confirmation dialog
    bool? proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Budget: ₹${workquoteData!['workquote_budget']}'),
            const SizedBox(height: 8),
            Text('Advance Payment (25%): ₹$paymentAmount'),
            const SizedBox(height: 16),
            const Text('Would you like to proceed with the payment?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );

    if (proceed == true) {
      // TODO: Implement your payment gateway integration here
      // For now, we'll just show a success message
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentGatewayScreen(
          type: 'Adv',
          id: workquoteData!['workquote_id'],
          amt: paymentAmount.toInt(),
        )));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.enquiry['enquiry_status'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Enquiry Details"),
        actions: [
          if (int.parse(workRemark) >= 9) // Only show when payment is made
            FutureBuilder<List<Map<String, dynamic>>>(
              future: supabase
                  .from('tbl_payment')
                  .select()
                  .eq('workquote_id', workquoteData!['workquote_id'])
                  .eq('payment_status', 0),
              builder: (context, snapshot) {
                final pendingCount = snapshot.data?.length ?? 0;
                
                return Stack(
                  children: [
                    TextButton(
                      onPressed: viewPaymentHistory,
                      child: const Text(
                        'Payments',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    if (pendingCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            pendingCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Existing enquiry image
              if (widget.enquiry['enquiry_image'] != null)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(widget.enquiry['enquiry_image']),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                const SizedBox(
                    height: 200, child: Center(child: Text("No Image"))),

              const SizedBox(height: 16),

              // Basic enquiry details
              Text(
                "Contractor: ${widget.contractorName}",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Contact: ${widget.enquiry['enquiry_contact'] ?? 'No Contact Info'}",
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                "Location: ${widget.enquiry['enquiry_location'] ?? 'No Location'}",
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                "Details: ${widget.enquiry['enquiry_detail'] ?? 'No Details'}",
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),

              // Drawing section
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (localPdfFile != null) ...[
                const Text(
                  "Drawing Preview:",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 400,
                  child: PDFView(
                    filePath: localPdfFile!.path,
                    enableSwipe: true,
                    swipeHorizontal: true,
                    autoSpacing: false,
                    pageFling: false,
                    onError: (error) {
                      print(error.toString());
                    },
                    onPageError: (page, error) {
                      print('$page: ${error.toString()}');
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Add payment section when status is 6
                if (int.parse(workRemark) >= 7) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Payment Details",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            if (int.parse(workRemark) > 9)  // Only show payment history button if status > 9
                              TextButton.icon(
                                onPressed: viewPaymentHistory,
                                icon: const Icon(Icons.history),
                                label: const Text('View History'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total Budget: ₹${workquoteData?['workquote_budget'] ?? 0}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Advance Payment (25%): ₹${calculateAdvancePayment()}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (int.parse(workRemark) < 9) // Only show Pay Now button if status is less than 9
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: initiateAdvancePayment,
                              icon: const Icon(Icons.payment),
                              label: const Text('Pay Advance Amount'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                // Drawing actions
                if (workRemark == '6')
                  Column(
                    children: [
                      const Text(
                        "Drawing Submitted - Pending Review",
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: acceptDrawing,
                            icon: const Icon(Icons.check),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            label: const Text('Accept Drawing'),
                          ),
                          ElevatedButton.icon(
                            onPressed: requestDrawingRevision,
                            icon: const Icon(Icons.refresh),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            label: const Text('Request Revision'),
                          ),
                        ],
                      ),
                    ],
                  )
                else if (workRemark == '7')
                  const Text(
                    "Drawing Approved",
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else if (workRemark == '8')
                  const Text(
                    "Drawing Revision Requested",
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],

              // Status section
              const SizedBox(height: 16),
              if (status == 1)
                Text(
                  "Status: Accepted\nVisiting Day: ${widget.enquiry['visiting_date'] ?? 'To Be Determined'}",
                  style: const TextStyle(fontSize: 18, color: Colors.green),
                )
              else if (status == 3)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Status: Visited",
                      style: TextStyle(fontSize: 18, color: Colors.blue),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuoteSummaryPage(
                              qid: workquoteData!['workquote_id'],
                              eid: widget.enquiry['id'],
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white),
                      child: const Text('View Quote'),
                    ),
                  ],
                )
              else if (status == 0)
                const Text(
                  "Status: Pending",
                  style: TextStyle(fontSize: 18, color: Colors.orange),
                )
              else if (status == 4)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Status: Work In Progress",
                      style: TextStyle(fontSize: 18, color: Colors.green),
                    ),
                    ElevatedButton(
                      onPressed: () => navigateDetails(context),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white),
                      child: const Text('View Progress'),
                    ),
                  ],
                )
              else if (status == 5)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Status: Architect Assigned",
                      style: TextStyle(fontSize: 18, color: Colors.blue),
                    ),
                    ElevatedButton(
                      onPressed: () => navigateDetails(context),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white),
                      child: const Text('View Progress'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

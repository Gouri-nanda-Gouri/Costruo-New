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
import 'package:costruo_user/complaint_page.dart'; // Import ComplaintPage
import 'package:costruo_user/feedback_page.dart'; // Import FeedbackPage

class EnquiriesPage extends StatefulWidget {
  const EnquiriesPage({super.key});

  @override
  State<EnquiriesPage> createState() => _EnquiriesPageState();
}

class _EnquiriesPageState extends State<EnquiriesPage> {
  List<Map<String, dynamic>> enquiries = [];
  List<Map<String, dynamic>> filteredEnquiries = []; // For search results
  final TextEditingController searchController = TextEditingController();

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
        filteredEnquiries = enquiries; // Initialize with all enquiries
      });
      print('Enquiries: $enquiries');
    } catch (e) {
      print("Error fetching enquiries: $e");
    }
  }

  void filterEnquiries(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredEnquiries = enquiries;
      });
      return;
    }

    setState(() {
      filteredEnquiries = enquiries.where((enquiry) {
        final location = enquiry['enquiry_location']?.toLowerCase() ?? '';
        final contact = enquiry['enquiry_contact']?.toLowerCase() ?? '';
        final detail = enquiry['enquiry_detail']?.toLowerCase() ?? '';
        return location.contains(query.toLowerCase()) ||
            contact.contains(query.toLowerCase()) ||
            detail.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: searchController,
            decoration: const InputDecoration(
              labelText: 'Search Enquiries',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: filterEnquiries,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: filteredEnquiries.isEmpty
                ? const Center(child: Text('No enquiries found'))
                : ListView.builder(
                    itemCount: filteredEnquiries.length,
                    itemBuilder: (context, index) {
                      final enquiry = filteredEnquiries[index];
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
                                  'Status: Completed',
                                  style: TextStyle(color: Colors.blue),
                                ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EnquiryDetailPage(
                                  enquiryId: enquiry['id'],
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
  final int enquiryId;
  final String contractorName;

  const EnquiryDetailPage({
    super.key,
    required this.enquiryId,
    required this.contractorName,
  });

  @override
  State<EnquiryDetailPage> createState() => _EnquiryDetailPageState();
}

class _EnquiryDetailPageState extends State<EnquiryDetailPage> {
  Map<String, dynamic>? enquiryData;
  String? drawingUrl;
  File? localPdfFile;
  bool isLoading = false;
  String? errorMessage;
  String workRemark = '';
  Map<String, dynamic>? workquoteData;

  @override
  void initState() {
    super.initState();
    fetchEnquiryData();
    fetchDrawing();
  }

  Future<void> fetchEnquiryData() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('tbl_enquiry')
          .select('*, tbl_work(*,tbl_contractor(*))')
          .eq('id', widget.enquiryId)
          .single();

      setState(() {
        enquiryData = response;
      });
      print('Enquiry data: $response');
    } catch (e) {
      setState(() => errorMessage = 'Error fetching enquiry: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchDrawing() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('tbl_workquote')
          .select('*')
          .eq('enquiry_id', widget.enquiryId)
          .order('workquote_id', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        setState(() {
          workquoteData = response;
          drawingUrl = response['workquote_drawing'];
          workRemark = response['work_remark']?.toString() ?? '';
        });
        print('Workquote data: $response');
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
      await supabase
          .from('tbl_workquote')
          .update({'work_remark': '7'})
          .eq('workquote_id', workquoteData!['workquote_id']);

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

  double calculateAdvancePayment() {
    if (workquoteData != null && workquoteData!['workquote_budget'] != null) {
      final budget = workquoteData!['workquote_budget'].toString();
      final parsedBudget = double.tryParse(budget) ?? 0.0;
      print('Budget value: $budget, Parsed budget: $parsedBudget');
      return parsedBudget * 0.25;
    }
    return 0.0;
  }

  Future<void> initiateAdvancePayment() async {
    if (workquoteData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No work quote data available')),
      );
      return;
    }

    final paymentAmount = calculateAdvancePayment();

    bool? proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Total Budget: ₹${workquoteData?['workquote_budget'] ?? 'Not available'}'),
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
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentGatewayScreen(
              type: 'Adv',
              id: workquoteData!['workquote_id'],
              amt: paymentAmount.toInt(),
            ),
          ),
        );
      }
    }
  }

  void viewPaymentHistory() {
    if (workquoteData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No work quote data available')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentHistoryPage(
          workquoteId: workquoteData!['workquote_id'],
          totalBudget:
              double.tryParse(workquoteData!['workquote_budget']?.toString() ?? '') ??
                  0.0,
        ),
      ),
    );
  }

  void navigateDetails(BuildContext context) {
    if (workquoteData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No work quote data available')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkProgressPage(
          workquoteId: workquoteData!['workquote_id'],
          enquiryId: widget.enquiryId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Enquiry Details"),
        actions: [
          if (workRemark.isNotEmpty && int.parse(workRemark) >= 9)
            FutureBuilder<List<Map<String, dynamic>>>(
              future: supabase
                  .from('tbl_payment')
                  .select()
                  .eq('workquote_id', workquoteData?['workquote_id'] ?? 0)
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : enquiryData == null
              ? Center(child: Text(errorMessage ?? 'Failed to load enquiry'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (enquiryData!['enquiry_image'] != null)
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: NetworkImage(enquiryData!['enquiry_image']),
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          const SizedBox(
                            height: 200,
                            child: Center(child: Text("No Image")),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          "Contractor: ${widget.contractorName}",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Contact: ${enquiryData!['enquiry_contact'] ?? 'No Contact Info'}",
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Location: ${enquiryData!['enquiry_location'] ?? 'No Location'}",
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Details: ${enquiryData!['enquiry_detail'] ?? 'No Details'}",
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 16),
                        if (errorMessage != null)
                          Text(
                            errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        if (localPdfFile != null) ...[
                          const Text(
                            "Drawing Preview:",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
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
                          if (workRemark.isNotEmpty && int.parse(workRemark) >= 7) ...[
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Payment Details",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      if (workRemark.isNotEmpty &&
                                          int.parse(workRemark) > 9)
                                        TextButton.icon(
                                          onPressed: viewPaymentHistory,
                                          icon: const Icon(Icons.history),
                                          label: const Text('View History'),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Total Budget: ₹${workquoteData?['workquote_budget'] ?? 'Not available'}',
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
                                  if (workRemark.isNotEmpty &&
                                      int.parse(workRemark) < 9)
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: initiateAdvancePayment,
                                        icon: const Icon(Icons.payment),
                                        label: const Text('Pay Advance Amount'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
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
                            )
                          else if (workRemark == '10')
                            const Text(
                              "Work Completed",
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                        const SizedBox(height: 16),
                        if (enquiryData!['enquiry_status'] == 1)
                          Text(
                            "Status: Accepted\nVisiting Day: ${enquiryData!['visiting_date'] ?? 'To Be Determined'}",
                            style: const TextStyle(
                                fontSize: 18, color: Colors.green),
                          )
                        else if (enquiryData!['enquiry_status'] == 3)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Status: Visited",
                                style: TextStyle(
                                    fontSize: 18, color: Colors.blue),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  if (workquoteData == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'No work quote data available')),
                                    );
                                    return;
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => QuoteSummaryPage(
                                        qid: workquoteData!['workquote_id'],
                                        eid: widget.enquiryId,
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
                        else if (enquiryData!['enquiry_status'] == 0)
                          const Text(
                            "Status: Pending",
                            style: TextStyle(
                                fontSize: 18, color: Colors.orange),
                          )
                        else if (enquiryData!['enquiry_status'] == 4)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Status: Work In Progress",
                                style: TextStyle(
                                    fontSize: 18, color: Colors.green),
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
                        else if (enquiryData!['enquiry_status'] == 5)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Status: Completed",
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
                              if (workRemark == '10') ...[
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ComplaintPage(
                                              contractorId: enquiryData!['tbl_work']['tbl_contractor']['id'],
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Submit Complaint'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => FeedbackPage(
                                              contractorId: enquiryData!['tbl_work']['tbl_contractor']['id'],
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueAccent,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Provide Feedback'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
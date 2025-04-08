import 'package:flutter/material.dart';
import 'package:costruo_user/main.dart' as main_supabase;
import 'package:url_launcher/url_launcher.dart';

class QuoteSummaryPage extends StatefulWidget {
  final int qid;
  const QuoteSummaryPage({super.key, required this.qid});

  @override
  State<QuoteSummaryPage> createState() => _QuoteSummaryPageState();
}

class _QuoteSummaryPageState extends State<QuoteSummaryPage> {
  String pdfUrl = 'Loading...';
  String days = 'Loading...';
  String budget = 'Loading...';
  String workRemark = ''; // Add variable to store work_remark status
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchWorkQuote();
  }

  Future<void> fetchWorkQuote() async {
    try {
      print("Fetching work quote for workquote_id: ${widget.qid}");

      if (main_supabase.supabase == null) {
        throw Exception("Supabase client not initialized in main.dart");
      }

      final currentUser = main_supabase.supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception("No authenticated user found");
      }
      print("Authenticated user ID: ${currentUser.id}");

      final data = await main_supabase.supabase
          .from('tbl_workquote')
          .select(
              'workquote_id,workquote_file, workquote_budget, workquote_days, work_remark, tbl_enquiry(*, tbl_work(*, tbl_contractor(*)))')
          .eq('workquote_id', widget.qid)
          .maybeSingle();

      print("Raw data from Supabase: $data");

      if (mounted) {
        setState(() {
          if (data != null) {
            pdfUrl = data['workquote_file']?.toString() ?? 'No PDF available';
            days = data['workquote_days']?.toString() ?? 'Not specified';
            budget = data['workquote_budget']?.toString() ?? 'Not specified';
            workRemark =
                data['work_remark']?.toString() ?? ''; // Store the status
            errorMessage = '';
          } else {
            pdfUrl = 'No quote found';
            days = 'N/A';
            budget = 'N/A';
            errorMessage = 'No quote data available for ID: ${widget.qid}';
          }
          isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print("Error fetching work quote: $e");
      print("Stack trace: $stackTrace");
      if (mounted) {
        setState(() {
          pdfUrl = 'Error loading quote';
          days = 'N/A';
          budget = 'N/A';
          errorMessage = 'Error: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _launchPDF(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      print("Attempting to launch URL: $url");
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print("PDF launched successfully");
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print("Error launching PDF: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open PDF: $e')),
        );
      }
    }
  }

  Future<void> accepted() async {
    try {
      await main_supabase.supabase
          .from('tbl_workquote')
          .update({'work_remark': '4'}).eq('workquote_id', widget.qid);
      if (mounted) {
        setState(() {
          workRemark = '4'; // Update local status
        });
      }
    } catch (e) {
      print("Error accepting quote: $e");
    }
  }

  Future<void> rejected() async {
    try {
      await main_supabase.supabase
          .from('tbl_workquote')
          .update({'work_remark': '5'}).eq('workquote_id', widget.qid);
    } catch (e) {
      print("Error rejecting quote: $e");
    }
  }

  Future<void> refresh() async {
    TextEditingController reasonController = TextEditingController();

    // Show dialog and wait for user response
    bool? shouldRefresh = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Refresh Quote'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a reason for refreshing:'),
              const SizedBox(height: 10),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter reason here',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), // Cancel
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (reasonController.text.trim().isNotEmpty) {
                  Navigator.pop(context, true); // Proceed with refresh
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a reason')),
                  );
                }
              },
              child: const Text('Refresh'),
            ),
          ],
        );
      },
    );

    // If user confirmed and provided a reason, proceed with refresh
    if (shouldRefresh == true) {
      try {
        await main_supabase.supabase.from('tbl_workquote').update({
          'work_remark': '6',
          'refresh_reason':
              reasonController.text.trim(), // Add reason to database
        }).eq('workquote_id', widget.qid);

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        print("Error refreshing quote: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error refreshing quote: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quotation Summary',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 2,
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          errorMessage,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    GestureDetector(
                      onTap: () {
                        if (Uri.tryParse(pdfUrl)?.hasScheme == true) {
                          _launchPDF(pdfUrl);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No valid PDF URL')),
                          );
                        }
                      },
                      child: Container(
                        height: 400,
                        margin: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: const Color(0xFF1976D2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.picture_as_pdf,
                                size: 60,
                                color: Color(0xFF1976D2),
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Text(
                                  pdfUrl,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 24,
                                  color: Color(0xFF1976D2),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Days: $days',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                const Icon(
                                  Icons.attach_money,
                                  size: 24,
                                  color: Color(0xFF1976D2),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Amount: $budget',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (workRemark != '4') ...[
                              // Only show buttons if not accepted
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      accepted();
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    onPressed: () {
                                      rejected();
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    onPressed:
                                        refresh, // Just use the function name directly
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.refresh,
                                            color: Colors.white),
                                       
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
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

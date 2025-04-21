import 'package:costruo_user/login.dart';
import 'package:flutter/material.dart';
import 'package:costruo_user/main.dart' as main_supabase;
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class QuoteSummaryPage extends StatefulWidget {
  final int qid;
  final int eid;
  const QuoteSummaryPage({super.key, required this.qid, required this.eid});

  @override
  State<QuoteSummaryPage> createState() => _QuoteSummaryPageState();
}

class _QuoteSummaryPageState extends State<QuoteSummaryPage> {
  String pdfUrl = 'Loading...';
  String drawingUrl = '';
  String days = 'Loading...';
  String budget = 'Loading...';
  String workRemark = '';
  bool isLoading = true;
  String errorMessage = '';
  File? localPdfFile;

  @override
  void initState() {
    super.initState();
    fetchWorkQuote();
  }

  Future<void> downloadAndOpenPDF() async {
    if (drawingUrl.isEmpty) return;

    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(drawingUrl));
      final bytes = response.bodyBytes;
      final tempDir = await getTemporaryDirectory();
      localPdfFile = File('${tempDir.path}/drawing.pdf');
      await localPdfFile!.writeAsBytes(bytes);
      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error downloading PDF: $e';
      });
    }
  }

  Future<void> fetchWorkQuote() async {
    try {
      final data = await main_supabase.supabase
          .from('tbl_workquote')
          .select('workquote_id, workquote_file, workquote_drawing, workquote_budget, workquote_days, work_remark, tbl_enquiry(*)')
          .eq('workquote_id', widget.qid)
          .maybeSingle();

      if (mounted) {
        setState(() {
          if (data != null) {
            pdfUrl = data['workquote_file']?.toString() ?? 'No PDF available';
            drawingUrl = data['workquote_drawing']?.toString() ?? '';
            days = data['workquote_days']?.toString() ?? 'Not specified';
            budget = data['workquote_budget']?.toString() ?? 'Not specified';
            workRemark = data['work_remark']?.toString() ?? '';
            errorMessage = '';
          } else {
            errorMessage = 'No quote data available';
          }
          isLoading = false;
        });
        if (drawingUrl.isNotEmpty) {
          await downloadAndOpenPDF();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
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
      await supabase.from('tbl_enquiry').update({'enquiry_status': 4}).eq('id', widget.eid);
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

  Future<void> acceptDrawing() async {
    try {
      await main_supabase.supabase
          .from('tbl_workquote')
          .update({'work_remark': '7'})
          .eq('workquote_id', widget.qid);
      if (mounted) {
        setState(() {
          workRemark = '7';
        });
      }
    } catch (e) {
      print("Error accepting drawing: $e");
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
        await main_supabase.supabase
            .from('tbl_workquote')
            .update({
              'work_remark': '8',
              'refresh_reason': reasonController.text,
            })
            .eq('workquote_id', widget.qid);
        
        if (mounted) {
          setState(() => workRemark = '8');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Revision requested successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error requesting revision: $e')),
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
                          style: const TextStyle(color: Colors.red, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    // PDF Viewer
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
                    // Quote Details
                    Container(
                      margin: const EdgeInsets.all(16.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Budget: ₹$budget',
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 8),
                          Text('Estimated Days: $days',
                              style: const TextStyle(fontSize: 18)),
                          if (workRemark != 4) ...[
                            // Only show buttons if not accepted
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    accepted();
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(Icons.check),
                                  label: const Text('Accept'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    rejected();
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(Icons.close),
                                  label: const Text('Reject'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: refresh,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Refresh'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (workRemark == '6') Column(
                      children: [
                        const Text("Drawing Submitted - Pending Review",
                            style: TextStyle(color: Colors.orange)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: acceptDrawing,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: const Text('Accept Drawing'),
                            ),
                            ElevatedButton(
                              onPressed: requestDrawingRevision,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                              child: const Text('Request Revision'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (workRemark == '7')
                      const Text("Drawing Approved",
                          style: TextStyle(color: Colors.green)),
                    if (workRemark == '8')
                      const Text("Drawing Revision Requested",
                          style: TextStyle(color: Colors.orange)),
                  ],
                ),
              ),
      ),
    );
  }
}

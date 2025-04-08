import 'package:costruo_contractor/homepage.dart';
import 'package:costruo_contractor/main.dart' as main_supabase;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class Agreement extends StatefulWidget {
  final int enquiryId;
  final String uid;
  const Agreement({super.key, required this.enquiryId, required this.uid});

  @override
  AgreementState createState() => AgreementState();
}

class AgreementState extends State<Agreement> {
  PlatformFile? pickedPdf;
  String? _errorMessage;
  bool _isLoading = false;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _workingDaysController = TextEditingController();
  final TextEditingController _pdfController = TextEditingController();
  String? refreshReason;
  String? workRemark;

  // Color palette
  static const Color primaryColor = Colors.blue;
  static const Color accentColor = Colors.green;
  static const Color backgroundGradientStart = Colors.white;
  static const Color backgroundGradientEnd = Color(0xFFE3F2FD);

  @override
  void initState() {
    super.initState();
    _checkWorkRemark();
  }

  Future<void> _checkWorkRemark() async {
    try {
      final response = await main_supabase.supabase
          .from('tbl_workquote')
          .select('work_remark, refresh_reason')
          .eq('enquiry_id', widget.enquiryId)
          .maybeSingle();

      if (mounted && response != null) {
        setState(() {
          workRemark = response['work_remark']?.toString();
          refreshReason = response['refresh_reason'] as String?;
        });

        if (workRemark == '6' && refreshReason != null) {
          _showRefreshDialog();
        }
      }
    } catch (e) {
      print("Error checking work remark: $e");
      setState(() {
        _errorMessage = "Error loading work remark: $e";
      });
    }
  }

  Future<void> _showRefreshDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('User Request'),
          content: Text('The user thinks: $refreshReason'),
          actions: [
            TextButton(
              onPressed: () async {
                await _handleReject();
                Navigator.pop(context);
              },
              child: const Text('Reject'),
            ),
            TextButton(
              onPressed: () async {
                await _handleAccept();
                Navigator.pop(context);
              },
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleAccept() async {
    try {
      await main_supabase.supabase
          .from('tbl_workquote')
          .update({'work_remark': '3'})
          .eq('enquiry_id', widget.enquiryId);
      if (mounted) {
        setState(() {
          workRemark = '3';
        });
      }
    } catch (e) {
      print("Error accepting refresh: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting request: $e')),
        );
      }
    }
  }

  Future<void> _handleReject() async {
    try {
      await main_supabase.supabase
          .from('tbl_workquote')
          .update({'work_remark': '5'})
          .eq('enquiry_id', widget.enquiryId);
      if (mounted) {
        setState(() {
          workRemark = '5';
        });
      }
    } catch (e) {
      print("Error rejecting refresh: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting request: $e')),
        );
      }
    }
  }

  Future<void> handleProofPick() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.first.bytes != null) {
        setState(() {
          pickedPdf = result.files.first;
          _pdfController.text = pickedPdf!.name;
          _errorMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("PDF Selected!"),
            backgroundColor: accentColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error selecting PDF: $e";
      });
    }
  }

  Future<String?> proofUpload() async {
    try {
      final bucketName = 'agreement';
      final filePath =
          "${DateTime.now().millisecondsSinceEpoch.toString()}-${pickedPdf!.name}";
      await main_supabase.supabase.storage.from(bucketName).uploadBinary(
            filePath,
            pickedPdf!.bytes!,
          );
      final publicUrl = main_supabase.supabase.storage
          .from(bucketName)
          .getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      print("Error uploading PDF: $e");
      setState(() {
        _errorMessage = "Error uploading PDF: $e";
      });
      return null;
    }
  }

  Future<void> insertData(String workquoteFileUrl) async {
    try {
      await main_supabase.supabase.from('tbl_workquote').insert({
        'workquote_budget': _amountController.text,
        'workquote_days': _workingDaysController.text,
        'workquote_file': workquoteFileUrl,
        'contractor_id': main_supabase.supabase.auth.currentUser!.id,
        'enquiry_id': widget.enquiryId,
        'user_id': widget.uid,
      });
    } catch (e) {
      print("Error inserting data: $e");
      setState(() {
        _errorMessage = "Error saving data: $e";
      });
      throw e;
    }
  }

  Future<void> statusEnquiry() async {
    try {
      await main_supabase.supabase.from('tbl_enquiry').update({
        'enquiry_status': 3,
      }).eq('id', widget.enquiryId);
    } catch (e) {
      print("Error updating enquiry status: $e");
      setState(() {
        _errorMessage = "Error updating enquiry status: $e";
      });
    }
  }

  Future<void> _submitForm() async {
    if (_amountController.text.isEmpty ||
        _workingDaysController.text.isEmpty ||
        pickedPdf == null) {
      setState(() {
        _errorMessage = "Please fill all fields and upload a PDF.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String? workquoteFileUrl = await proofUpload();
      if (workquoteFileUrl == null) {
        throw Exception("Failed to upload PDF.");
      }

      await insertData(workquoteFileUrl);
      await statusEnquiry();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Agreement Submitted Successfully!"),
          backgroundColor: accentColor,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Homepage()),
      );
    } catch (e) {
      print("Error submitting form: $e");
      setState(() {
        _errorMessage = "Error submitting form: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [backgroundGradientStart, backgroundGradientEnd],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Upload Agreement',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Upload House Building Agreement',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Please upload a PDF of your house building agreement',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: handleProofPick,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: pickedPdf != null
                              ? accentColor
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.picture_as_pdf,
                            size: 50,
                            color: pickedPdf != null
                                ? accentColor
                                : Colors.grey[400],
                          ),
                          const SizedBox(height: 15),
                          Text(
                            pickedPdf != null
                                ? pickedPdf!.name
                                : 'Tap to Select PDF',
                            style: TextStyle(
                              fontSize: 18,
                              color: pickedPdf != null
                                  ? Colors.black87
                                  : Colors.grey[500],
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Max file size: 10MB',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter Amount',
                      labelText: 'Amount',
                      prefixIcon:
                          const Icon(Icons.attach_money, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide:
                            const BorderSide(color: primaryColor, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _workingDaysController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Total Working Days',
                      labelText: 'Total Working Days',
                      prefixIcon: const Icon(Icons.calendar_month_outlined,
                          color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide:
                            const BorderSide(color: primaryColor, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildButton(
                    onPressed: _submitForm,
                    label: _isLoading ? 'Submitting...' : 'Submit',
                    color: primaryColor,
                    icon: _isLoading ? null : Icons.send,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required VoidCallback onPressed,
    required String label,
    required Color color,
    IconData? icon,
    bool isLoading = false,
  }) {
    return AnimatedScale(
      scale: isLoading ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(icon ?? Icons.check, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
          shadowColor: Colors.black26,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _workingDaysController.dispose();
    _pdfController.dispose();
    super.dispose();
  }
}
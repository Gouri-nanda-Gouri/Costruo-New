import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:costruo_worker/main.dart';
import 'dart:io';

class DrawingSubmissionPage extends StatefulWidget {
  final int workquoteId;
  final int workRemark;

  const DrawingSubmissionPage({
    super.key, 
    required this.workquoteId,
    required this.workRemark,
  });

  @override
  _DrawingSubmissionPageState createState() => _DrawingSubmissionPageState();
}

class _DrawingSubmissionPageState extends State<DrawingSubmissionPage> {
  PlatformFile? pickedDrawing;
  bool isLoading = false;
  String? errorMessage;

  Future<void> _pickDrawing() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          pickedDrawing = result.files.first;
          errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error selecting PDF: $e";
      });
    }
  }

  Future<void> _submitDrawing() async {
    if (pickedDrawing == null || pickedDrawing!.path == null) {
      setState(() {
        errorMessage = "Please select a PDF drawing first";
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}-${pickedDrawing!.name}';
      final file = File(pickedDrawing!.path!);
      
      // Upload the PDF file
      await supabase.storage.from('drawings').upload(
        fileName,
        file,
      );

      // Get the public URL
      final drawingUrl = supabase.storage.from('drawings').getPublicUrl(fileName);

      // Update the database
      await supabase.from('tbl_workquote').update({
        'workquote_drawing': drawingUrl,
        'work_remark': widget.workRemark == 8 ? 6 : 6,
      }).eq('workquote_id', widget.workquoteId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Drawing submitted successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print("Error submitting drawing: $e");
      setState(() {
        errorMessage = "Error submitting drawing: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.workRemark == 8 ? "Revise Drawing" : "Submit Drawing",
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.picture_as_pdf,
                        size: 50,
                        color: pickedDrawing != null ? Colors.blue : Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        pickedDrawing != null ? pickedDrawing!.name : "No PDF selected",
                        style: TextStyle(
                          color: pickedDrawing != null ? Colors.white : Colors.grey[400],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ElevatedButton.icon(
              onPressed: _pickDrawing,
              icon: const Icon(Icons.upload_file),
              label: const Text("Select PDF Drawing"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : _submitDrawing,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.all(16),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit Drawing"),
            ),
          ],
        ),
      ),
    );
  }
}






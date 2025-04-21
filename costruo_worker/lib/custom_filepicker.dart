import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class CustomFilePicker {
  /// Picks an image from either gallery or camera based on the parameters
  /// Returns a PlatformFile object that can be used for display and upload
  static Future<PlatformFile?> pickImage({
    required BuildContext context,
    bool allowCamera = true,
  }) async {
    if (allowCamera) {
      // This will be handled by the _showImageSourceDialog in the parent widget
      // We'll just handle the file picking part here
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1000,
      );

      if (image != null) {
        // Convert XFile to PlatformFile
        final File file = File(image.path);
        final String fileName = image.name;
        final int fileSize = await file.length();
        
        return PlatformFile(
          name: fileName,
          size: fileSize,
          path: image.path,
        );
      }
      return null;
    } else {
      // Use FilePicker for gallery
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first;
      }
      return null;
    }
  }

  /// Uploads a file to Supabase storage bucket
  /// Returns the public URL of the uploaded file or null if upload failed
  static Future<String?> uploadToSupabase({
    required SupabaseClient supabase,
    required String bucketName,
    required String filePath,
    required PlatformFile file,
  }) async {
    try {
      if (file.path == null) return null;
      
      final File fileToUpload = File(file.path!);
      
      // Upload the file to Supabase storage
      await supabase
          .storage
          .from(bucketName)
          .upload(filePath, fileToUpload);
      
      // Get the public URL
      final String publicUrl = supabase
          .storage
          .from(bucketName)
          .getPublicUrl(filePath);
      
      return publicUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }
  
  /// Shows a loading dialog during file operations
  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Processing...",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// Convenience method to handle errors
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
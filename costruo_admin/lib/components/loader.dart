import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class Loader {
  static void showLoader(BuildContext context) {
    showDialog(
      barrierColor: Colors.black.withOpacity(0.5), // Semi-transparent background
      context: context,
      barrierDismissible:
          false, // Prevent dismissing the dialog by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoadingAnimationWidget.beat(
                  color: Colors.blue,
                  size: 60,
                ),
                const SizedBox(height: 15),
                const Text(
                  "Loading...",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void hideLoader(BuildContext context) {
    Navigator.pop(context); // Close the dialog
  }
}

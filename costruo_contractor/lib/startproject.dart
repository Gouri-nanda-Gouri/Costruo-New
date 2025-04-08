import 'package:flutter/material.dart';
import 'package:costruo_contractor/main.dart' as main_supabase;

class StartProjectPage extends StatelessWidget {
  final Map<String, dynamic> enquiry;

  const StartProjectPage({super.key, required this.enquiry});

  Future<void> _startProject(BuildContext context) async {
    try {
      if (enquiry['id'] == null) {
        throw Exception("Enquiry ID is null");
      }

      // Update the enquiry status to 5 (indicating the project has started)
      final updateData = {
        'enquiry_status': 5,
        'start_date': DateTime.now().toIso8601String(), // Record the start date
      };

      final response = await main_supabase.supabase
          .from('tbl_enquiry')
          .update(updateData)
          .match({'id': enquiry['id']});

      print("Project start response: $response");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Project Started Successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // Return to the previous page
    } catch (e) {
      print("Error starting project: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error starting project: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Start Project",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEnquiryImage(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Accepted by the User",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Let's Start the Project!",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        icon: Icons.person,
                        label: "User",
                        value: enquiry['tbl_user'] != null
                            ? (enquiry['tbl_user'] as Map<String, dynamic>)['user_name']
                                    ?.toString() ??
                                'Unknown'
                            : 'Unknown',
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.location_on,
                        label: "Location",
                        value: enquiry['enquiry_location']?.toString() ?? 'No Location',
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.description,
                        label: "Details",
                        value: enquiry['enquiry_detail']?.toString() ?? 'No Details',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ElevatedButton.icon(
                onPressed: () => _startProject(context),
                icon: const Icon(Icons.play_arrow),
                label: const Text("Start Project"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEnquiryImage() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        image: enquiry['enquiry_image'] != null
            ? DecorationImage(
                image: NetworkImage(enquiry['enquiry_image'] as String),
                fit: BoxFit.cover,
              )
            : null,
        color: enquiry['enquiry_image'] == null ? Colors.grey[300] : null,
      ),
      child: enquiry['enquiry_image'] == null
          ? const Center(
              child: Icon(
                Icons.image_not_supported,
                size: 80,
                color: Colors.grey,
              ),
            )
          : null,
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
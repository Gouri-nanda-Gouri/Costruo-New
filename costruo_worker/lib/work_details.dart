import 'package:costruo_worker/main.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

class WorkDetails extends StatefulWidget {
  final int id;
  const WorkDetails({super.key, required this.id});

  @override
  State<WorkDetails> createState() => _WorkDetailsState();
}

class _WorkDetailsState extends State<WorkDetails> {
  Map<String, dynamic>? workDetails;
  List<Map<String, dynamic>> workUpdates = [];
  bool isLoading = true;
  final TextEditingController updateController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _fetchWorkDetails();
    _fetchWorkUpdates();
  }

  Future<void> _fetchWorkDetails() async {
    try {
      final response = await supabase
          .from('tbl_workquote')
          .select('''
            *,
            tbl_enquiry (
              enquiry_detail,
              enquiry_location,
              enquiry_contact,
              tbl_user (
                user_name,
                user_contact
              ),
              tbl_work (
                work_title,
                work_desc,
                work_budget,
                work_gallery
              )
            )
          ''')
          .eq('workquote_id', widget.id)
          .single();

      setState(() {
        workDetails = response;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching work details: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchWorkUpdates() async {
    try {
      final updates = await supabase
          .from('tbl_updates')
          .select()
          .eq('workquote_id', widget.id)
          .order('created_at', ascending: false);

      setState(() {
        workUpdates = List<Map<String, dynamic>>.from(updates);
      });
    } catch (e) {
      print('Error fetching updates: $e');
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<String?> _uploadImage(XFile image) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
      final bytes = await image.readAsBytes();
      
      await supabase.storage
          .from('updates')
          .uploadBinary(fileName, bytes);
          
      return supabase.storage.from('updates').getPublicUrl(fileName);
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _submitUpdate() async {
    if (updateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter update details')),
      );
      return;
    }

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);
      }

      await supabase.from('tbl_updates').insert({
        'workquote_id': widget.id,
        'update_detail': updateController.text.trim(),
        'update_image': imageUrl,
      });

      updateController.clear();
      setState(() => _selectedImage = null);
      _fetchWorkUpdates();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Update submitted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting update: $e')),
      );
    }
  }

  String _formatDate(String dateTime) {
    return DateFormat('MMM dd, yyyy • HH:mm').format(DateTime.parse(dateTime).toLocal());
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final enquiry = workDetails?['tbl_enquiry'];
    final work = enquiry?['tbl_work'];

    return Scaffold(
      appBar: AppBar(
        title: Text(work?['work_title'] ?? 'Work Details'),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Site Image
            if (work?['work_gallery'] != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(work!['work_gallery']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // Site Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: Colors.grey[900],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Site Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Client Name: ${enquiry?['tbl_user']?['user_name'] ?? 'N/A'}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Contact: ${enquiry?['tbl_user']?['user_contact'] ?? enquiry?['enquiry_contact'] ?? 'N/A'}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Location: ${enquiry?['enquiry_location'] ?? 'N/A'}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Description: ${enquiry?['enquiry_detail'] ?? 'N/A'}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Budget: ${work?['work_budget'] ?? 'N/A'}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Add Update Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: Colors.grey[900],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add Update',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: updateController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Enter update details...',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image),
                            label: const Text('Add Image'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_selectedImage != null)
                            const Icon(Icons.check_circle, color: Colors.green),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: _submitUpdate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Submit Update'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Updates List
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: Colors.grey[900],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Updates',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (workUpdates.isEmpty)
                        const Center(
                          child: Text(
                            'No updates yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: workUpdates.length,
                          itemBuilder: (context, index) {
                            final update = workUpdates[index];
                            return Card(
                              color: Colors.grey[800],
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatDate(update['created_at']),
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      update['update_detail'],
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    if (update['update_image'] != null) ...[
                                      const SizedBox(height: 8),
                                      Image.network(
                                        update['update_image'],
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ],
                                    if (update['update_reply'] != null) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[700],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Row(
                                              children: [
                                                Icon(
                                                  Icons.reply,
                                                  size: 16,
                                                  color: Colors.white70,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Client Reply:',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              update['update_reply'],
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

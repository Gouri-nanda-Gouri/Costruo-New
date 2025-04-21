import 'dart:io';

import 'package:costruo_user/login.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

class WorkDetailPage extends StatefulWidget {
  final String image;
  final String title;
  final String description;
  final String budget;
  final String loctn;
  final int workId;
  final Map<String,dynamic> contractor;

  const WorkDetailPage({
    super.key,
    required this.image,
    required this.title,
    required this.description,
    required this.budget,
    required this.loctn,
    required this.workId, required this.contractor,
  });

  @override
  State<WorkDetailPage> createState() => _WorkDetailPageState();
}

class _WorkDetailPageState extends State<WorkDetailPage> {
  List<Map<String, dynamic>> districtlist = [];
  List<Map<String, dynamic>> placelist = [];
  String _selectedDist = "";
  String _selectedPlc = "";
  bool isLoading = false; // Add loading state

  TextEditingController detailsController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  TextEditingController contactController = TextEditingController();

  File? _image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchdistrict();
  }
  

  Future<void> fetchdistrict() async {
    try {
      final response = await supabase.from("tbl_district").select();
      setState(() {
        districtlist = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print("Error fetching district: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching districts: $e')),
      );
    }
  }

  Future<void> fetchplace(String districtId) async {
    try {
      final data = await supabase
          .from("tbl_place")
          .select()
          .eq('district_id', districtId);
          print(data);
      setState(() {
        placelist = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      print("Error fetching places: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching places: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image, String userId) async {
    try {
      String formattedDate =
          DateFormat('dd-MM-yyyy-HH-mm-ss').format(DateTime.now());
      String fileExtension = path.extension(image.path);
      String fileName = 'enquery-$formattedDate$fileExtension';
      await supabase.storage.from('enquery').upload(fileName, image);
      final imageUrl = supabase.storage.from('enquery').getPublicUrl(fileName);
      print("Image uploaded successfully: $imageUrl");
      return imageUrl;
    } catch (e) {
      print('Image upload failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e')),
      );
      return null;
    }
  }

  Future<void> insert() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Check if user is authenticated
      if (supabase.auth.currentUser == null) {
        throw Exception("User is not authenticated. Please log in.");
      }

      final userId = supabase.auth.currentUser!.id;
      print("Authenticated user ID: $userId");

      // Validate fields
      String contact = contactController.text.trim();
      String details = detailsController.text.trim();
      String location = locationController.text.trim();

      if (contact.isEmpty ||
          details.isEmpty ||
          location.isEmpty ||
          _selectedDist.isEmpty ||
          _selectedPlc.isEmpty) {
        throw Exception("Please fill all fields");
      }

      // Upload image if selected
      String? photoUrl;
      if (_image != null) {
        photoUrl = await _uploadImage(_image!, userId);
        if (photoUrl == null) {
          throw Exception("Failed to upload image");
        }
      }

      // Prepare data for insertion
      final enquiryData = {
        'enquiry_contact': contact,
        'enquiry_detail': details,
        'enquiry_location': location,
        'enquiry_place': _selectedPlc,
        'enquiry_image': photoUrl,
        'user_id': userId,
        'work_id': widget.workId,
      };

      print("Inserting enquiry data: $enquiryData");
      print("Work ID: ${widget.workId}");
      // Insert into tbl_enquiry
      final response = await supabase.from('tbl_enquiry').insert(enquiryData);
      print("Insert response: $response");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enquiry sent successfully')),
      );

      // Clear form
      contactController.clear();
      detailsController.clear();
      locationController.clear();
      setState(() {
        _image = null;
        _selectedDist = "";
        _selectedPlc = "";
      });
      Navigator.pop(context);
    } catch (e, stacktrace) {
      print("Error inserting data: $e");
      print("Stacktrace: $stacktrace");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting enquiry: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  

  void _showEnquiryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Send Enquiry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField(
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: Colors.black,
                  decoration: const InputDecoration(
                    hintText: 'District',
                    hintStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Color(0xFF2C2C2C),
                  ),
                  value: _selectedDist.isEmpty ? null : _selectedDist,
                  items: districtlist.map((district) {
                    return DropdownMenuItem(
                      value: district['id'].toString(),
                      child: Text(
                        district['district_name'],
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDist = value.toString();
                      _selectedPlc = "";
                      placelist = [];
                      fetchplace(value.toString());
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField(
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: Colors.black,
                  decoration: const InputDecoration(
                    hintText: 'Place',
                    hintStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Color(0xFF2C2C2C),
                  ),
                  value: _selectedPlc.isEmpty ? null : _selectedPlc,
                  items: placelist.map((place) {
                    return DropdownMenuItem(
                      value: place['id'].toString(),
                      child: Text(
                        place['place_name'],
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPlc = value.toString();
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: contactController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    label: Text("Contact"),
                    labelStyle: TextStyle(
                      color: Color.fromARGB(255, 156, 154, 154),
                    ),
                    filled: true,
                    fillColor: Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: detailsController,
                  keyboardType: TextInputType.streetAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    label: Text("Details"),
                    labelStyle: TextStyle(
                      color: Color.fromARGB(255, 156, 154, 154),
                    ),
                    filled: true,
                    fillColor: Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: locationController,
                  keyboardType: TextInputType.text,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    label: Text("Location"),
                    labelStyle: TextStyle(
                      color: Color.fromARGB(255, 156, 154, 154),
                    ),
                    filled: true,
                    fillColor: Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickImage,
                  child: AbsorbPointer(
                    child: TextFormField(
                      style: const TextStyle(color: Colors.white),
                      controller: TextEditingController(
                          text: _image != null
                              ? path.basename(_image!.path)
                              : "Select an image"),
                      decoration: InputDecoration(
                        labelText: "Image",
                        labelStyle: const TextStyle(
                          color: Color.fromARGB(255, 156, 154, 154),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),
                        hintText: _image == null
                            ? "Select an image"
                            : path.basename(_image!.path),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                      insert();
                    },
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  image: DecorationImage(
                    image: NetworkImage(widget.image),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Contractor: ${widget.contractor['contractor_name'] ?? 'Unknown'}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(widget.description, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text('Budget: ${widget.budget}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text('Location: ${widget.loctn}', style: const TextStyle(fontSize: 16)),
              const SizedBox(
                height: 10,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    _showEnquiryDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: const Color.fromARGB(255, 48, 52, 50),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Contact"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

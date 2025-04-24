import 'package:costruo_contractor/main.dart'; // Ensure you have Supabase client configured here
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CompletedWork extends StatefulWidget {
  const CompletedWork({super.key});

  @override
  State<CompletedWork> createState() => _CompletedWorkState();
}

class _CompletedWorkState extends State<CompletedWork> {
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController budgetController = TextEditingController();
  TextEditingController durationController = TextEditingController();
  TextEditingController imageController = TextEditingController();
  TextEditingController locationController = TextEditingController();

  List<Map<String, dynamic>> wData = []; // Holds the fetched data
  PlatformFile? pickedImage;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
  try {
    final user = supabase.auth.currentUser; // Get logged-in contractor
    if (user == null) {
      print("No user logged in");
      return;
    }

    final data = await supabase
        .from('tbl_work')
        .select()
        .eq('contractor_id', user.id).eq("work_status", 1); // Filter work by logged-in contractor

    setState(() {
      wData = data;
    });
  } catch (e) {
    print("Error fetching data: $e");
  }
}


  Future<void> handleImagePick() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
    );
    if (result != null) {
      setState(() {
        pickedImage = result.files.first;
        imageController.text = pickedImage!.name;
      });
    }
  }

  Future<String?> uploadImage() async {
    if (pickedImage == null) return null;

    try {
      final now = DateTime.now();
      final formattedDate = DateFormat('dd-MM-yy-HH-mm-ss').format(now);
      final fileExtension = pickedImage!.name.split('.').last;
      final fileName = '$formattedDate.$fileExtension';

      await supabase.storage.from('work').uploadBinary(
            fileName,
            pickedImage!.bytes!,
          );

      final publicUrl = supabase.storage.from('work').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

 Future<void> insertData() async {
  try {
    final user = supabase.auth.currentUser;
    if (user == null) {
      print("No user logged in");
      return;
    }

    String title = titleController.text;
    String desc = descriptionController.text;
    String loct = locationController.text;
    String budget = budgetController.text;
    String dur = durationController.text;

    String? photoUrl = await uploadImage();

    await supabase.from('tbl_work').insert({
      'contractor_id': user.id, // Store logged-in contractor's ID
      'work_gallery': photoUrl,
      'work_title': title,
      'work_desc': desc,
      'work_location': loct,
      'work_budget': budget,
      'work_duration': dur,
    });

    Navigator.pop(context);
    fetchData(); // Refresh the list after adding work
  } catch (e) {
    print("Error inserting data: $e");
  }
}

  // void showAddWorkDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         backgroundColor: Colors.black,
  //         title: const Text('Add Work', style: TextStyle(color: Colors.white)),
  //         content: SizedBox(
  //           width: 800,
  //           child: ListView(
  //             shrinkWrap: true,
  //             children: [
  //               buildTextField('Enter title', titleController),
  //               buildTextField('Enter description', descriptionController),
  //               GestureDetector(
  //                 onTap: handleImagePick,
  //                 child: AbsorbPointer(
  //                   child: buildTextField('Select Image', imageController),
  //                 ),
  //               ),
  //               buildTextField('Enter Location', locationController),
  //               buildTextField('Enter Budget', budgetController),
  //               buildTextField('Enter Duration', durationController),
  //             ],
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //               onPressed: () => Navigator.pop(context),
  //               child: const Text('Cancel')),
  //           TextButton(onPressed: () => insertData(), child: const Text('Add')),
  //         ],
  //       );
  //     },
  //   );
  // }

  // Widget buildTextField(String label, TextEditingController controller) {
  //   return TextField(
  //     controller: controller,
  //     style: const TextStyle(color: Colors.white),
  //     decoration: InputDecoration(
  //       labelText: label,
  //       labelStyle: const TextStyle(color: Colors.white),
  //       filled: true,
  //       fillColor: const Color(0xFF2C2C2C),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Completed Work', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        // actions: [
        //   TextButton(
        //     onPressed: () => showAddWorkDialog(context),
        //     child:
        //         const Text('Add Work', style: TextStyle(color: Colors.white)),
        //   ),
        // ],
      ),
      body:  wData.isEmpty
    ? const Center(
        child: Text(
          "No Works Found",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      )
    : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: wData.length,
              itemBuilder: (context, index) {
                final work = wData[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkDetailPage(
                          title: work['work_title'] ?? 'No Title',
                          description: work['work_desc'] ?? 'No Description',
                          budget: work['work_budget'] ?? 'No Description',
                          loctn: work['work_location'] ?? 'No Description',
                          image: work['work_gallery'] ?? '',
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            image: DecorationImage(
                              image: NetworkImage(work['work_gallery'] ?? ''),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          work['work_title'] ?? 'No Title',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class WorkDetailPage extends StatelessWidget {
  final String image;
  final String title;
  final String description;
  final String budget;
  final String loctn;

  const WorkDetailPage({
    super.key,
    required this.image,
    required this.title,
    required this.description,
    required this.budget,
    required this.loctn,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: NetworkImage(image),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(title,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Budget: $budget', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Location: $loctn', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}


import 'package:costruo_contractor/main.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class ManageWorkers extends StatefulWidget {
  const ManageWorkers({super.key});

  @override
  State<ManageWorkers> createState() => _ManageWorkersState();
}

class _ManageWorkersState extends State<ManageWorkers> {
  List<Map<String, dynamic>> workers = [];
  List<Map<String, dynamic>> typelist = [];
  bool isLoading = true;
  String? errorMessage;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchWorkers();
    fetchTypes();
  }

  // Fetch workers from Supabase
  Future<void> fetchWorkers() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await supabase
          .from('tbl_worker')
          .select('''
            id,
            worker_name,
            worker_email,
            worker_contact,
            worker_photo,
            type_id,
            tbl_type(type_name)
          ''')
          .order('worker_name', ascending: true);

      setState(() {
        workers = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching workers: $e';
      });
    }
  }

  // Fetch skill types for dropdown
  Future<void> fetchTypes() async {
    try {
      final response = await supabase.from("tbl_type").select();
      setState(() {
        typelist = response;
      });
    } catch (e) {
      print("Error fetching types: $e");
    }
  }

  // Delete a worker
  Future<void> deleteWorker(String workerId, String? photoUrl) async {
    try {
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this worker?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (shouldDelete != true) return;

      if (photoUrl != null && photoUrl.isNotEmpty) {
        final photoPath = photoUrl.split('/').last;
        await supabase.storage.from('worker').remove([photoPath]);
      }

      await supabase.from('tbl_worker').delete().eq('id', workerId);
      await supabase.auth.admin.deleteUser(workerId);

      await fetchWorkers();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Worker deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting worker: $e')),
      );
    }
  }

  // Show registration dialog
  void showRegistrationDialog() {
    showDialog(
      context: context,
      builder: (context) => RegistrationDialog(
        typelist: typelist,
        onRegisterSuccess: fetchWorkers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Manage Workers',
          style: TextStyle(
            color: Color(0xFF333333), 
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Worker'),
              onPressed: showRegistrationDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.blue, size: 28),
              onPressed: fetchWorkers,
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            width: MediaQuery.of(context).size.width * 0.3, // 30% of screen width
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search workers...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
          ),

          // Workers Grid
          Expanded(
            child: _buildWorkersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkersList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchWorkers,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredWorkers = workers.where((worker) {
      final name = worker['worker_name']?.toString().toLowerCase() ?? '';
      final email = worker['worker_email']?.toString().toLowerCase() ?? '';
      final type = worker['tbl_type']?['type_name']?.toString().toLowerCase() ?? '';
      return name.contains(searchQuery) || 
             email.contains(searchQuery) || 
             type.contains(searchQuery);
    }).toList();

    if (filteredWorkers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              searchQuery.isEmpty ? 'No workers added yet' : 'No workers found',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        childAspectRatio: 0.75,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: filteredWorkers.length,
      itemBuilder: (context, index) {
        final worker = filteredWorkers[index];
        return _buildWorkerCard(worker);
      },
    );
  }

  Widget _buildWorkerCard(Map<String, dynamic> worker) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _showWorkerDetails(worker),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: worker['worker_photo'] != null
                        ? NetworkImage(worker['worker_photo'])
                        : null,
                    child: worker['worker_photo'] == null
                        ? Text(
                            worker['worker_name'][0].toUpperCase(),
                            style: const TextStyle(fontSize: 24),
                          )
                        : null,
                  ),
                  Positioned(
                    right: -8,
                    top: -8,
                    child: PopupMenuButton(
                      icon: const Icon(Icons.more_vert, size: 20),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: ListTile(
                            leading: const Icon(Icons.edit, color: Colors.blue, size: 20),
                            title: const Text('Edit', style: TextStyle(fontSize: 14)),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onTap: () => _editWorker(worker),
                        ),
                        PopupMenuItem(
                          child: ListTile(
                            leading: const Icon(Icons.delete, color: Colors.red, size: 20),
                            title: const Text('Delete', style: TextStyle(fontSize: 14)),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onTap: () => deleteWorker(worker['id'], worker['worker_photo']),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                worker['worker_name'] ?? 'N/A',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                worker['tbl_type']?['type_name'] ?? 'N/A',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                worker['worker_email'] ?? 'N/A',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWorkerDetails(Map<String, dynamic> worker) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Worker Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage: worker['worker_photo'] != null
                    ? NetworkImage(worker['worker_photo'])
                    : null,
                child: worker['worker_photo'] == null
                    ? Text(
                        worker['worker_name'][0].toUpperCase(),
                        style: const TextStyle(fontSize: 40),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                worker['worker_name'] ?? 'N/A',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                worker['tbl_type']?['type_name'] ?? 'N/A',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.email),
                title: Text(worker['worker_email'] ?? 'N/A'),
                contentPadding: EdgeInsets.zero,
              ),
              ListTile(
                leading: const Icon(Icons.phone),
                title: Text(worker['worker_contact'] ?? 'N/A'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editWorker(Map<String, dynamic> worker) {
    // Implement edit worker functionality
    // You can reuse the RegistrationDialog with modifications
  }
}

// Registration Dialog Widget
class RegistrationDialog extends StatefulWidget {
  final List<Map<String, dynamic>> typelist;
  final VoidCallback onRegisterSuccess;

  const RegistrationDialog({
    super.key,
    required this.typelist,
    required this.onRegisterSuccess,
  });

  @override
  State<RegistrationDialog> createState() => _RegistrationDialogState();
}

class _RegistrationDialogState extends State<RegistrationDialog> {
  bool password = true;
  bool cpassword = true;
  PlatformFile? pickedImage;
  File? _profileImage;

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController contactController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController cpasswordController = TextEditingController();

  String _selectedType = "";
  bool isRegistering = false;

  // Handle image picking
  Future<void> handleImagePick() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          pickedImage = result.files.first;
          _profileImage = File(pickedImage!.path!);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  // Upload image to Supabase storage
  Future<String?> photoUpload(String uid) async {
    if (pickedImage == null || pickedImage!.bytes == null) return null;

    try {
      final filePath = "$uid-${pickedImage!.name}";
      await supabase.storage
          .from('worker')
          .uploadBinary(filePath, pickedImage!.bytes!);
      final String photoUrl =
          supabase.storage.from('worker').getPublicUrl(filePath);
      return photoUrl;
    } catch (e) {
      throw 'Error uploading image: $e';
    }
  }

  // Register worker
  Future<void> register() async {
    try {
      final name = nameController.text;
      final email = emailController.text;
      final contact = contactController.text;
      final password = passwordController.text;
      final type = _selectedType;
      final cpassword = cpasswordController.text;

      // Input validation
      if (name.isEmpty ||
          email.isEmpty ||
          contact.isEmpty ||
          password.isEmpty ||
          type.isEmpty ||
          cpassword.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please fill all the fields")));
        return;
      }

      if (pickedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please upload a profile image")));
        return;
      }

      if (password != cpassword) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Password and Confirm Password do not match")));
        return;
      }

      if (_selectedType.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please select a skill type")));
        return;
      }

      if (password.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Password must be at least 6 characters long")));
        return;
      }

      setState(() {
        isRegistering = true;
      });

      // Sign up with Supabase auth
      final auth = await supabase.auth.signUp(
        password: passwordController.text,
        email: emailController.text,
      );
      String uid = auth.user!.id;

      // Upload photo and get URL
      String? profileImageUrl = await photoUpload(uid);

      // Insert worker data
      await supabase.from("tbl_worker").insert({
        "id": uid,
        "worker_name": name,
        "worker_email": email,
        "worker_contact": contact,
        "worker_password": password,
        "type_id": int.parse(type),
        "worker_photo": profileImageUrl,
      });

      // Close dialog
      Navigator.of(context).pop();

      // Refresh worker list
      widget.onRegisterSuccess();

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Worker registered successfully")));
    } catch (e) {
      setState(() {
        isRegistering = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registration failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF5F5F5),
      title: const Text(
        'Register New Worker',
        style: TextStyle(color: Color(0xFF333333), fontFamily: 'serif'),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Profile Photo Upload
            GestureDetector(
              onTap: handleImagePick,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage:
                    _profileImage != null ? FileImage(_profileImage!) : null,
                child: _profileImage == null
                    ? const Icon(Icons.camera_alt,
                        color: Color(0xFF666666), size: 40)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Profile Photo",
              style: TextStyle(
                color: Color(0xFF666666),
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(height: 16),

            // Name Field
            TextFormField(
              controller: nameController,
              style: const TextStyle(color: Color(0xFF333333)),
              decoration: InputDecoration(
                label: const Text("Full Name"),
                labelStyle: const TextStyle(color: Color(0xFF666666)),
                filled: true,
                fillColor: const Color(0xFFE8ECEF),
                prefixIcon:
                    const Icon(Icons.person_outline, color: Color(0xFF333333)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
              ),
            ),
            const SizedBox(height: 16),

            // Email Field
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Color(0xFF333333)),
              decoration: InputDecoration(
                label: const Text("Email"),
                labelStyle: const TextStyle(color: Color(0xFF666666)),
                filled: true,
                fillColor: const Color(0xFFE8ECEF),
                prefixIcon: const Icon(Icons.alternate_email_outlined,
                    color: Color(0xFF333333)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
              ),
            ),
            const SizedBox(height: 16),

            // Contact Field
            TextFormField(
              controller: contactController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Color(0xFF333333)),
              decoration: InputDecoration(
                label: const Text("Contact Number"),
                labelStyle: const TextStyle(color: Color(0xFF666666)),
                filled: true,
                fillColor: const Color(0xFFE8ECEF),
                prefixIcon: const Icon(Icons.phone_enabled_outlined,
                    color: Color(0xFF333333)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
              ),
            ),
            const SizedBox(height: 16),

            // Skill Type Dropdown
            DropdownButtonFormField(
              style: const TextStyle(color: Color(0xFF333333)),
              decoration: const InputDecoration(
                labelText: 'Skill Type',
                labelStyle: TextStyle(color: Color(0xFF666666)),
                filled: true,
                fillColor: Color(0xFFE8ECEF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
              value: _selectedType.isEmpty ? null : _selectedType,
              items: widget.typelist.map((type) {
                return DropdownMenuItem(
                  value: type['id'].toString(),
                  child: Text(type['type_name'],
                      style: const TextStyle(color: Color(0xFF333333))),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value.toString();
                });
              },
            ),
            const SizedBox(height: 16),

            // Password Field
            TextFormField(
              controller: passwordController,
              style: const TextStyle(color: Color(0xFF333333)),
              obscureText: password,
              keyboardType: TextInputType.visiblePassword,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      password = !password;
                    });
                  },
                  icon: Icon(
                    password ? Icons.visibility : Icons.visibility_off,
                    color: const Color(0xFF333333),
                  ),
                ),
                label: const Text("Password"),
                labelStyle: const TextStyle(color: Color(0xFF666666)),
                filled: true,
                fillColor: const Color(0xFFE8ECEF),
                prefixIcon:
                    const Icon(Icons.lock_outlined, color: Color(0xFF333333)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
              ),
            ),
            const SizedBox(height: 16),

            // Confirm Password Field
            TextFormField(
              controller: cpasswordController,
              style: const TextStyle(color: Color(0xFF333333)),
              obscureText: cpassword,
              keyboardType: TextInputType.visiblePassword,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      cpassword = !cpassword;
                    });
                  },
                  icon: Icon(
                    cpassword ? Icons.visibility : Icons.visibility_off,
                    color: const Color(0xFF333333),
                  ),
                ),
                label: const Text("Confirm Password"),
                labelStyle: const TextStyle(color: Color(0xFF666666)),
                filled: true,
                fillColor: const Color(0xFFE8ECEF),
                prefixIcon:
                    const Icon(Icons.lock_outlined, color: Color(0xFF333333)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
              ),
            ),
            const SizedBox(height: 20),

            // Register Button
            ElevatedButton(
              onPressed: isRegistering ? null : register,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: const Color(0xFF007BFF),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: isRegistering
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Register",
                      style: TextStyle(fontSize: 16, fontFamily: 'serif'),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Color(0xFF666666))),
        ),
      ],
    );
  }
}

import 'package:costruo_worker/custom_filepicker.dart';
import 'package:costruo_worker/login.dart';
import 'package:costruo_worker/main.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  bool password = true;
  bool cpassword = true;
  PlatformFile? pickedImage;
  File? _profileImage;

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController contactController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController cpasswordController = TextEditingController();
  TextEditingController photoController = TextEditingController();

  List<Map<String, dynamic>> typelist = [];
  String _selectedType = "";

  @override
  void initState() {
    super.initState();
    fetchTypes();
  }

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

  // Show dialog to choose image source
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text("Select Image Source", 
            style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text("Gallery", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  handleImagePick(camera: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text("Camera", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  handleImagePick(camera: true);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Handle File Upload Process
  Future<void> handleImagePick({bool camera = false}) async {
    final pickedFile = await CustomFilePicker.pickImage(
      context: context,
      allowCamera: camera,
    );
    
    if (pickedFile != null) {
      setState(() {
        pickedImage = pickedFile;
        photoController.text = pickedFile.name;
        _profileImage = File(pickedFile.path!);
      });
    }
  }

  // Upload image to Supabase storage
  Future<String?> photoUpload(String uid) async {
    if (pickedImage == null) return null;
    
    return CustomFilePicker.uploadToSupabase(
      supabase: supabase,
      bucketName: 'worker',
      filePath: "$uid-${pickedImage!.name}",
      file: pickedImage!,
    );
  }

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
            const SnackBar(content: Text("Please upload your profile image")));
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

      // Loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

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

      // Close loading dialog
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration successful!")));
      
      // Navigate to login screen
      Navigator.pushReplacement(context, 
        MaterialPageRoute(
          builder: (context) => const Login(),
        ),
      );
      
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registration failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Worker Registration",
          style: TextStyle(color: Colors.white, fontFamily: 'serif'),
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Getting Started",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFFFFF),
                        fontFamily: 'serif',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      "Create your professional worker profile",
                      style: TextStyle(
                        fontSize: 16,
                        color: Color.fromARGB(255, 156, 154, 154),
                        fontFamily: 'serif',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Profile Photo Upload
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : null,
                        child: _profileImage == null
                            ? const Icon(Icons.camera_alt, color: Colors.white, size: 40)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Profile Photo",
                      style: TextStyle(
                        color: Color.fromARGB(255, 156, 154, 154),
                        fontFamily: 'serif',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name Field
                    TextFormField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        label: const Text("Full Name"),
                        labelStyle: const TextStyle(
                          color: Color.fromARGB(255, 156, 154, 154),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),
                        prefixIcon: const Icon(Icons.person_outline,
                            color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
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
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        label: const Text("Email"),
                        labelStyle: const TextStyle(
                          color: Color.fromARGB(255, 156, 154, 154),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),
                        prefixIcon: const Icon(Icons.alternate_email_outlined,
                            color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
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
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        label: const Text("Contact Number"),
                        labelStyle: const TextStyle(
                          color: Color.fromARGB(255, 156, 154, 154),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),
                        prefixIcon: const Icon(Icons.phone_enabled_outlined,
                            color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Skill Type Dropdown
                    DropdownButtonFormField(
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Skill Type',
                        labelStyle: TextStyle(
                            color: Color.fromARGB(255, 156, 154, 154)),
                        filled: true,
                        fillColor: Color(0xFF2C2C2C),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      value: _selectedType.isEmpty ? null : _selectedType,
                      items: typelist.map((type) {
                        return DropdownMenuItem(
                          value: type['id'].toString(),
                          child: Text(type['type_name'],
                              style: const TextStyle(color: Colors.black)),
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
                      style: const TextStyle(color: Colors.white),
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
                            color: Colors.white,
                          ),
                        ),
                        label: const Text("Password"),
                        labelStyle: const TextStyle(
                          color: Color.fromARGB(255, 156, 154, 154),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),
                        prefixIcon: const Icon(Icons.lock_outlined,
                            color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password Field
                    TextFormField(
                      controller: cpasswordController,
                      style: const TextStyle(color: Colors.white),
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
                            color: Colors.white,
                          ),
                        ),
                        label: const Text("Confirm Password"),
                        labelStyle: const TextStyle(
                          color: Color.fromARGB(255, 156, 154, 154),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),
                        prefixIcon: const Icon(Icons.lock_outlined,
                            color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Register Button
                    ElevatedButton(
                      onPressed: register,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        backgroundColor: Colors.white,
                        foregroundColor: const Color.fromARGB(255, 48, 52, 50),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                      ),
                      child: const Text(
                        "Register",
                        style: TextStyle(fontSize: 16, fontFamily: 'serif'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:costruo_contractor/login.dart';
import 'package:costruo_contractor/main.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  List<Map<String, dynamic>> districtlist = [];
  List<Map<String, dynamic>> placelist = [];
  bool password = true;
  bool cpassword = true;

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController contactController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController photoController = TextEditingController();
  TextEditingController licenseController = TextEditingController();
  TextEditingController cpasswordController = TextEditingController();

  String _selectedDist = "";
  String _selectedPlc = "";
  @override
  void initState() {
    super.initState();
    fetchdistrict();
  }

  PlatformFile? pickedImage;
  PlatformFile? pickedProof;

  // Handle File Upload Process
  Future<void> handleImagePick() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false, // Only single file upload
    );
    if (result != null) {
      setState(() {
        pickedImage = result.files.first;
        photoController.text=result.files.first.name;
      });
    }
  }

  Future<void> handleProofPick() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false, // Only single file upload
    );
    if (result != null) {
      setState(() {
        pickedProof = result.files.first;
        licenseController.text=result.files.first.name;
      });
    }
  }

  Future<String?> photoUpload(String uid) async {
    try {
      final bucketName = 'contractor'; // Replace with your bucket name
      final filePath = "$uid-${pickedImage!.name}";
      await supabase.storage.from(bucketName).uploadBinary(
            filePath,
            pickedImage!.bytes!, // Use file.bytes for Flutter Web
          );
      final publicUrl =
          supabase.storage.from(bucketName).getPublicUrl(filePath);
      // await updateImage(uid, publicUrl);
      return publicUrl;
    } catch (e) {
      print("Error photo upload: $e");
      return null;
    }
  }

  Future<String?> proofUpload(String uid) async {
    try {
      final bucketName = 'contractor'; // Replace with your bucket name
      final filePath = "$uid-${pickedProof!.name}";
      await supabase.storage.from(bucketName).uploadBinary(
            filePath,
            pickedProof!.bytes!, // Use file.bytes for Flutter Web
          );
      final publicUrl =
          supabase.storage.from(bucketName).getPublicUrl(filePath);
      // await updateImage(uid, publicUrl);
      return publicUrl;
    } catch (e) {
      print("Error photo upload: $e");
      return null;
    }
  }

  Future<void> register() async {
    try {
      final auth = await supabase.auth.signUp(password:passwordController.text, email: emailController.text );
      String uid = auth.user!.id;
      insertData(uid);
    } catch (e) {
      print("Error Authentication: $e");
    } 
  }

  Future<void> insertData(String uid) async {
    try {
      String name = nameController.text;
      String email = emailController.text;
      String contact = contactController.text;
      String address = addressController.text;
      String password = passwordController.text;

      await supabase.from('tbl_contractor').insert({
        'id' :uid,
        'contractor_name': name,
        'contractor_email': email,
        'contractor_contact': contact,
        'contractor_address': address,
        'contractor_password': password,
        'place_id':_selectedPlc,
      });
      await fileUpload(uid);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Login(),));
    } catch (e) {
      print("Error:$e");
    }
  }

  Future<void> fileUpload(String uid) async {
    try {
      String? photoUrl = await photoUpload(uid);
      String? proofUrl = await proofUpload(uid);
      await supabase.from('tbl_contractor').update({
        'contractor_license':proofUrl,
        'contractor_photo':photoUrl,
      }).eq('id', uid);
    } catch (e) {
      print("Error:$e");
    }
  }

  Future<void> fetchdistrict() async {
    try {
      final response = await supabase.from("tbl_district").select();
      print(response);
      setState(() {
        districtlist = response;
      });
    } catch (e) {
      print("Error fetching district: $e");
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
        placelist = data;
      });
    } catch (e) {
      print("Error fetching places: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(color: Color.fromARGB(255, 99, 95, 95)),
        //decoration: BoxDecoration(image: DecorationImage(image: AssetImage("assets/h9.jpg",),fit: BoxFit.cover),),//stack vacha pole image varaan.like cosmos
        child: Center(
          child: Container(
            alignment: Alignment.center,
            width: 500,
            height: 700,
            decoration: BoxDecoration(
              color:
                  const Color(0xFF0D0D0D), // Background color for the container
              borderRadius: BorderRadius.circular(15), // Rounded corners
            ),
            child: Form(
                child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 18.0, horizontal: 40),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/logo.png', // Path to your logo
                        height: 50, // Adjust the height of the logo
                        width: 50, // Adjust width if necessary
                      ),
                      const Text(
                        " Welcome to Costruo",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'serif', // Use the serif font family
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Text(
                        "Begin by creating an account",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 156, 154, 154),
                          fontFamily: 'serif', // Use the serif font family
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      TextFormField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          label: const Text("Name"),
                          labelStyle: const TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2C),
                          prefixIcon: IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.person_outline,
                                  color: Colors.white)),
                          border: const OutlineInputBorder(),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      TextFormField(
                        controller: emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          label: const Text("Email"),
                          labelStyle: const TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2C),
                          prefixIcon: IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.alternate_email_outlined,
                                  color: Colors.white)),
                          border: const OutlineInputBorder(),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      TextFormField(
                        controller: contactController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          label: const Text("Contact"),
                          labelStyle: const TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2C),
                          prefixIcon: IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.phone_enabled_outlined,
                                color: Colors.white,
                              )),
                          border: const OutlineInputBorder(),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      TextFormField(
                        controller: addressController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          label: const Text("Address"),
                          labelStyle: const TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2C),
                          prefixIcon: IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.home_outlined,
                                  color: Colors.white)),
                          border: const OutlineInputBorder(),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      DropdownButtonFormField(
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'District',
                          hintStyle: TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: Color(0xFF2C2C2C),
                        ),
                        value: _selectedDist.isEmpty ? null : _selectedDist,
                        items: districtlist.map((district) {
                          return DropdownMenuItem(
                            value: district['id'].toString(),
                            child: Text(district['district_name'],
                                style: const TextStyle(color: Colors.black)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDist = value.toString();
                            _selectedPlc = ""; // Reset place selection
                            fetchplace(value
                                .toString()); // Fetch places based on district
                          });
                        },
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      DropdownButtonFormField(
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Place',
                          hintStyle: TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: Color(0xFF2C2C2C),
                        ),
                        value: _selectedPlc.isEmpty ? null : _selectedPlc,
                        items: placelist.map((place) {
                          return DropdownMenuItem(
                            value: place['id'].toString(),
                            child: Text(place['place_name'],
                                style: const TextStyle(color: Colors.black)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPlc = value.toString();
                          });
                        },
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      TextFormField(
                        mouseCursor: MouseCursor.defer,
                        onTap: () {
                          handleImagePick();
                        },
                        readOnly: true,
                        autofocus: false,
                        controller: photoController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Photo",
                          hintStyle: const TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2C),
                          suffixIcon: IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: Colors.white)),
                          border: const OutlineInputBorder(),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      TextFormField(
                        mouseCursor: MouseCursor.defer,
                        onTap: () { handleProofPick();},
                        readOnly: true,
                        controller: licenseController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "License",
                          hintStyle: const TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2C),
                          suffixIcon: IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: Colors.white)),
                          border: const OutlineInputBorder(),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ), // Add space between fields
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
                                password
                                    ? Icons.remove_red_eye
                                    : Icons.remove_red_eye_outlined,
                                color: Colors.white,
                              )),
                          label: const Text("Password"),
                          labelStyle: const TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2C),
                          prefixIcon: IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.lock_outlined,
                                color: Colors.white,
                              )),
                          border: const OutlineInputBorder(),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                      ),
                      const SizedBox(height: 10),
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
                                password
                                    ? Icons.remove_red_eye
                                    : Icons.remove_red_eye_outlined,
                                color: Colors.white,
                              )),
                          label: const Text(" Confirm Password"),
                          labelStyle: const TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2C),
                          prefixIcon: IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.lock_outlined,
                                color: Colors.white,
                              )),
                          border: const OutlineInputBorder(),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                      ),

                      const SizedBox(height: 10),
                      ElevatedButton(
                          onPressed: () {
                           register();
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor:
                                const Color.fromARGB(255, 48, 52, 50),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Sign Up"))
                    ],
                  ),
                ),
              ),
            )),
          ),
        ),
      ),
    );
  }
}

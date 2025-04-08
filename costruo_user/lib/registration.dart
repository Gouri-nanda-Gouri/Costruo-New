import 'package:costruo_user/main.dart';
import 'package:flutter/material.dart';

class Reg extends StatefulWidget {
  const Reg({super.key});

  @override
  State<Reg> createState() => _RegState();
}

class _RegState extends State<Reg> {
  bool password = true;
  bool cpassword = true;

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController contactController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController cpasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Future<void> register() async {
    try {
      await supabase.auth.signUp(
          password: passwordController.text, email: emailController.text);
          insertData();
          print("Success");
    } catch (e) {
      print("Error1: $e");
    }
  }

  Future<void> insertData() async {
    try {
      String name = nameController.text;
      String email = emailController.text;
      String contact = contactController.text;
       String password = passwordController.text;

      final response = await supabase.from('tbl_user').insert({
        'user_name': name,
        'user_email': email,
        'user_contact': contact,
        'user_password': password,
      });
      print('Insertion successful: $response');
    } catch (e) {
      print("Error:$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        // title: Text("Sign Up"),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/h1.jpg', // Use your image path
              fit: BoxFit.cover,
            ),
          ),

          // Registration Form
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(
                    0xFF0D0D0D), // Semi-transparent white background
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Getting Started",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFFFFF),
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
                        labelStyle: const TextStyle(
                          color: Color.fromARGB(255, 156, 154, 154),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),
                        prefixIcon: IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.person_outline,
                                color: Colors.white)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              20), // Adjust curvature here
                          borderSide: BorderSide.none, // Removes default border
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
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
                        prefixIcon: IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.alternate_email_outlined,
                                color: Colors.white)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              20), // Adjust curvature here
                          borderSide: BorderSide.none, // Removes default border
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    TextFormField(
                      controller: contactController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        label: const Text("Contact"),
                        labelStyle: const TextStyle(
                          color: Color.fromARGB(255, 156, 154, 154),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),
                        prefixIcon: IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.phone_enabled_outlined,
                              color: Colors.white,
                            )),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              20), // Adjust curvature here
                          borderSide: BorderSide.none, // Removes default border
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    
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
                        labelStyle: const TextStyle(
                          color: Color.fromARGB(255, 156, 154, 154),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),
                        prefixIcon: IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.lock_outlined,
                              color: Colors.white,
                            )),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              20), // Adjust curvature here
                          borderSide: BorderSide.none, // Removes default border
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
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
                        labelStyle: const TextStyle(
                          color: Color.fromARGB(255, 156, 154, 154),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),
                        prefixIcon: IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.lock_outlined,
                              color: Colors.white,
                            )),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              20), // Adjust curvature here
                          borderSide: BorderSide.none, // Removes default border
                        ),
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
                            borderRadius: BorderRadius.circular(20),
                          ),
                          backgroundColor: Colors.white,
                          foregroundColor:
                              const Color.fromARGB(255, 48, 52, 50),
                        ),
                        child: const Text("Continue"))
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

import 'package:costruo_worker/home.dart';
import 'package:costruo_worker/main.dart';
import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool password = true;

  Future<void> signIn() async {
    try {
      // First authenticate with Supabase Auth
      final authResponse = await supabase.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (authResponse.session == null) {
        showError("Authentication failed");
        return;
      }

      // Then fetch worker details
      final workerResponse = await supabase
          .from('tbl_worker')
          .select()
          .eq('worker_email', emailController.text.trim())
          .single();

      print("Worker login successful: ${workerResponse['worker_email']}");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WorkerHomePage()),
      );
        } catch (e) {
      print("Login error: $e");
      showError("Invalid credentials");
    }
  }


  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(color: Colors.white))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF000000),
      body: Center(
        child: Container(
          alignment: Alignment.center,
          width: 500,
          height: 500,
          decoration: BoxDecoration(
            color: Color(0xFF000000),
            borderRadius:
                BorderRadius.circular(20), // Add curve to the container
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 40),
            child: Form(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    //   Image.asset(
                    //   'assets/logo.png', // Path to your logo
                    //   height: 50, // Adjust the height of the logo
                    //   width: 50, // Adjust width if necessary
                    // ),
                    const Text(
                      "Log in",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'serif', // Use the serif font family
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      "or create an account",
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
                      controller: emailController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        label: const Text("Email"),
                        labelStyle: const TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),
                        prefixIcon: const Icon(
                          Icons.alternate_email_rounded,
                          color: Colors.white,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    TextFormField(
                      //controller: passwordController,
                      style: const TextStyle(color: Colors.white),
                      controller: passwordController,
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
                        label: Text("Password"),
                        labelStyle: const TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Color(0xFF2C2C2C),
                        prefixIcon: IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.lock_outlined,
                              color: Colors.white,
                            )),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              20), // Adjust curvature here
                          borderSide: BorderSide.none,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    ElevatedButton(
                        onPressed: () {
                          signIn();
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          backgroundColor: Colors.white,
                          foregroundColor:
                              const Color.fromARGB(255, 48, 52, 50),
                        ),
                        child: const Text("Enter"))
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

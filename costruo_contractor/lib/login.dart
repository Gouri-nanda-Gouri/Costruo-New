import 'package:costruo_contractor/dashboard.dart';
import 'package:costruo_contractor/main.dart';
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
      await supabase.auth.signInWithPassword(password: passwordController.text, email: emailController.text);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>  Homepage(),));
      print("Success");
    } catch (e) {
      print("Error:$e");
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          alignment: Alignment.center,
          width: 500,
          height: 500,
          decoration: BoxDecoration(
            color: const Color(0xFF000000),
            borderRadius: BorderRadius.circular(20), // Add curve to the container
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 40),
            child: Form(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/logo.png', // Path to your logo
                    height: 50, // Adjust the height of the logo
                    width: 50, // Adjust width if necessary
                  ),
                  const Text(
                    "Welcome to Costruo",
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
                    controller: emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      label: const Text("Email"),
                      labelStyle: const TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2C),
                      prefixIcon: const Icon(Icons.alternate_email_rounded,color: Colors.white,),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15), // Add curve to the textfield
                      ),
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
                          labelStyle: const TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2C),
                          prefixIcon: IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.lock_outlined,
                                color: Colors.white,
                              )),
                          border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15), // Add curve to the textfield
                      ),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                      ),
                        const SizedBox(
                    height: 16,
                  ),
                  const Text(
                    "Already have a account?Sign in",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 156, 154, 154),
                      fontFamily: 'serif', // Use the serif font family
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
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor:
                                const Color.fromARGB(255, 48, 52, 50),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Log in"))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

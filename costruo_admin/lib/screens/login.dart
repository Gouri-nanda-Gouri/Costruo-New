import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Costruo"),
      ),
      body: Center(
        // Center aligns the container within the screen
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: 16.0), // Adjust horizontal padding
          child: Row(
             mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Container(
              //   alignment: Alignment.center,
              //   color: const Color(0xFF18795B),
              //   height: 400,
              //   width: 400,
              // ),
              Container(
                alignment: Alignment.center,
                height: 400,
                width: 400,
                color: const Color(0xFF18795B),
                child: Padding(
                  padding: EdgeInsets.all(16.0), // Inner padding for form content
                  child: Form(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Shrink to fit content
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch, // Stretch buttons
                        children: [
                          Image.asset(
                            'assets/logo.png', // Path to your logo
                            height: 50, // Adjust the height of the logo
                            width: 50, // Adjust width if necessary
                          ),
                          Text(
                            "Log in",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'serif', // Use the serif font family
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            "or create an account",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 156, 154, 154),
                              fontFamily: 'serif', // Use the serif font family
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20),
                          TextFormField(
                            decoration: InputDecoration(
                              label: Text('Email'),
                              labelStyle: TextStyle(color: Color(0xFFC0C0C0)),
                              filled: true,
                              fillColor: Color(0xFF2C2C2C),
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 16), // Add space between fields
                          TextFormField(
                            decoration: InputDecoration(
                              label: Text('Password'),
                              labelStyle: TextStyle(color: Color(0xFFC0C0C0)),
                              filled: true,
                              fillColor: Color(0xFF2C2C2C),
                              suffixIcon: Icon(Icons.remove_red_eye),
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true, // Hide password text
                          ),
                          SizedBox(height: 16), // Add space before button
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: Color.fromARGB(255, 48, 52, 50),
                          foregroundColor: Colors.white,
                            ),
                            child: Text(
                              "Login",
                            ),
                          ),
                          Text(
                            "Forgot Pass?",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 156, 154, 154),
                              fontFamily: 'serif', // Use the serif font family
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

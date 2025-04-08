import 'package:flutter/material.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegState();
}

class _RegState extends State<Registration> {
  bool password = true;
  TextEditingController name = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController contact = TextEditingController();
  TextEditingController address = TextEditingController();
  TextEditingController passwords = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // appBar: AppBar(
      //   title: Text("Sign Up"),
      //   backgroundColor: Colors.black,
      // ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          child: Form(
              child: Center(
            child: Container(
              alignment: Alignment.center,
              width: 500,
              height: 700,
              decoration: BoxDecoration(
                color: const Color(0xFF18795B), // Background color for the container
                borderRadius: BorderRadius.circular(15), // Rounded corners
              ),
              child: SingleChildScrollView(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/logo.png', // Path to your logo
                        height: 150, // Adjust the size of the logo
                        width: 150, // Adjust width if necessary
                      ),
                      Text(
                        "Sign in",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'serif', // Use the serif font family
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        "or Already have an account",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 156, 154, 154),
                          fontFamily: 'serif', // Use the serif font family
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      Container(
                        width: 400, // Set the width of the text boxes
                        child: TextFormField(
                          controller: name,
                          decoration: InputDecoration(
                            label: Text('Username'),
                            labelStyle: TextStyle(color: Colors.white),
                            filled: true,
                            fillColor: Color(0xFF2C2C2C),
                            prefixIcon: IconButton(
                                onPressed: () {},
                                icon: Icon(Icons.person_outline)),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        width: 400, // Set the width of the text boxes
                        child: TextFormField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            label: Text('Email'),
                            labelStyle: TextStyle(color: Colors.white),
                            filled: true,
                            fillColor: Color(0xFF2C2C2C),
                            prefixIcon: IconButton(
                                onPressed: () {},
                                icon: Icon(Icons.alternate_email_outlined)),
                            border: OutlineInputBorder(),
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        width: 400, // Set the width of the text boxes
                        child: TextFormField(
                          controller: contact,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            label: Text('Contact'),
                            labelStyle: TextStyle(color: Colors.white),
                            filled: true,
                            fillColor: Color(0xFF2C2C2C),
                            prefixIcon: IconButton(
                                onPressed: () {},
                                icon: Icon(Icons.phone_enabled_outlined)),
                            border: OutlineInputBorder(),
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        width: 400, // Set the width of the text boxes
                        child: TextFormField(
                          controller: address,
                          keyboardType: TextInputType.streetAddress,
                          maxLines: null,
                          minLines: 2,
                          decoration: InputDecoration(
                            label: Text("Address"),
                            labelStyle: TextStyle(color: Colors.white),
                            filled: true,
                            fillColor: Color(0xFF2C2C2C),
                            prefixIcon: IconButton(
                                onPressed: () {},
                                icon: Icon(Icons.home_outlined)),
                            border: OutlineInputBorder(),
                            
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        width: 400, // Set the width of the text boxes
                        child: TextFormField(
                          controller: passwords,
                          obscureText: password,
                          keyboardType: TextInputType.visiblePassword,
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    password = !password;
                                  });
                                },
                                icon: Icon(password
                                    ? Icons.remove_red_eye
                                    : Icons.remove_red_eye_outlined)),
                            label: Text("Password"),
                            labelStyle: TextStyle(color: Colors.white),
                            filled: true,
                            fillColor: Color(0xFF2C2C2C),
                            prefixIcon: IconButton(
                                onPressed: () {},
                                icon: Icon(Icons.lock_outlined)),
                            border: OutlineInputBorder(),
                            
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: Color.fromARGB(255, 48, 52, 50),
                          foregroundColor: Colors.white,
                        ),
                        child: Text("SignUp"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )),
        ),
      ),
    );
  }
}
import 'package:costruo_contractor/login.dart';
import 'package:costruo_contractor/registration.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3EBD2),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Navigation Bar
              Container(
                height: 60,
                color: const Color(0xFFE3EBD2),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: ['Home', 'Projects', 'About']
                            .map((title) => TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      fontFamily: 'serif',
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const Login()),
                            ),
                            child: const Text(
                              "Login",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'serif'),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const Registration()),
                            ),
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'serif'),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.5),

              const SizedBox(height: 30),

              // Header Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: const Text(
                            "BUILD BEYOND LIMITS",
                            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'serif'),
                          ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.3),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextButton(
                            onPressed: () {},
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text(
                                "Discuss Project",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'serif'),
                              ),
                            ),
                          ),
                        ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.3),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            'With Costruo, construction is faster, smarter, and more efficient.',
                            style: GoogleFonts.lato(textStyle: const TextStyle(color: Colors.black, fontSize: 15)),
                          ).animate().fadeIn(duration: 800.ms).scale(),
                        ),
                        const SizedBox(width: 150),
                        Expanded(
                          flex: 3,
                          child: const Text(
                            "BUILD BEYOND LIMITS",
                            style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'serif'),
                          ).animate().fadeIn(duration: 1000.ms).slideX(begin: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      height: 400,
                      width: double.infinity,
                      child: Image.asset('assets/h6.jpg', fit: BoxFit.cover),
                    ).animate().fadeIn(duration: 1200.ms).scale(),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // About Section
              Column(
                children: [
                  Text('//About', style: GoogleFonts.lato(textStyle: const TextStyle(color: Colors.black, fontSize: 25)))
                      .animate()
                      .fadeIn()
                      .slideY(),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 300,
                    child: Text(
                      'Costruo integrates technology with modern design to bring your vision to life.',
                      style: GoogleFonts.lato(textStyle: const TextStyle(color: Colors.black, fontSize: 15)),
                    ),
                  ).animate().fadeIn().scale(),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Learn More",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'serif'),
                    ),
                  ).animate().fadeIn(),
                ],
              ),

              const SizedBox(height: 30),

              // Features Section (with your original layout & animations)
              buildFeaturesSection(),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFeaturesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('//Features', style: GoogleFonts.lato(fontSize: 25, color: Colors.black)).animate().fadeIn(duration: 600.ms),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildFeatureColumn(title: 'Time-Efficient Execution', description: 'Automated workflows and real-time updates ensure faster project completion.')
                  .animate()
                  .slideX(begin: -1, end: 0, duration: 600.ms)
                  .fadeIn(),
              const SizedBox(width: 50),
              buildFeatureColumn(title: 'Seamless Collaboration', description: 'Direct communication between users, workers, and contractors reduces delays.')
                  .animate()
                  .slideY(begin: 1, end: 0, duration: 600.ms)
                  .fadeIn(),
              const SizedBox(width: 50),
              buildFeatureColumn(title: 'Smart Budgeting', description: 'Built-in expense tracking helps manage finances and control costs.')
                  .animate()
                  .slideX(begin: 1, end: 0, duration: 600.ms)
                  .fadeIn(),
              const SizedBox(width: 50),
              buildFeatureColumn(title: 'Reliable Workforce', description: 'Connects users with verified professionals ensuring quality work.')
                  .animate()
                  .slideY(begin: -1, end: 0, duration: 600.ms)
                  .fadeIn(),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildFeatureColumn({required String title, required String description}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(width: 300, child: Text(description, style: GoogleFonts.lato(fontSize: 15, color: Colors.black87))),
      ],
    );
  }
}

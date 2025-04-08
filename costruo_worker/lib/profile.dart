import 'package:costruo_worker/login.dart';
import 'package:costruo_worker/main.dart'; // Assuming supabase is defined here
import 'package:flutter/material.dart';

class WorkerProfile extends StatefulWidget {
  const WorkerProfile({super.key});

  @override
  State<WorkerProfile> createState() => _WorkerProfileState();
}

class _WorkerProfileState extends State<WorkerProfile> {
  Map<String, dynamic>? workerData;
  String? skillTypeName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWorkerProfile();
  }

  Future<void> fetchWorkerProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
        );
        return;
      }

      final workerResponse = await supabase
          .from('tbl_worker')
          .select()
          .eq('id', user.id)
          .single();

      final typeResponse = await supabase
          .from('tbl_type')
          .select('type_name')
          .eq('id', workerResponse['type_id'])
          .single();

      setState(() {
        workerData = workerResponse;
        skillTypeName = typeResponse['type_name'];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading profile: $e")),
      );
    }
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error signing out: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Worker Profile",
          style: TextStyle(color: Colors.white, fontFamily: 'serif'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _signOut,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : workerData == null
              ? const Center(
                  child: Text(
                    "Profile not found",
                    style: TextStyle(color: Colors.white, fontFamily: 'serif'),
                  ),
                )
              : Center(
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
                          // Profile Image
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[800],
                            backgroundImage: workerData!['worker_photo'] != null
                                ? NetworkImage(workerData!['worker_photo'])
                                : null,
                            child: workerData!['worker_photo'] == null
                                ? const Icon(Icons.person,
                                    color: Colors.white, size: 60)
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Worker Name
                          Text(
                            workerData!['worker_name'],
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'serif',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),

                          // Skill Type
                          Text(
                            skillTypeName ?? "Unknown Skill",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(255, 156, 154, 154),
                              fontFamily: 'serif',
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Contact Information Card
                          Card(
                            color: const Color(0xFF2C2C2C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Contact Information",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'serif',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.email_outlined,
                                          color: Colors.white),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          workerData!['worker_email'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'serif',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone_outlined,
                                          color: Colors.white),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          workerData!['worker_contact'].toString(), // Convert to String
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'serif',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Edit Profile Button
                          ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Edit Profile not implemented yet"),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              backgroundColor: Colors.white,
                              foregroundColor:
                                  const Color.fromARGB(255, 48, 52, 50),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 15),
                            ),
                            child: const Text(
                              "Edit Profile",
                              style: TextStyle(fontSize: 16, fontFamily: 'serif'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
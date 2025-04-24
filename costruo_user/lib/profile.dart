import 'package:costruo_user/enquery.dart';
import 'package:flutter/material.dart';
import 'package:costruo_user/login.dart'; // Import the LoginPage

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  List<dynamic> userData = []; // Store fetched user data

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final data = await supabase.from('tbl_user').select();
      setState(() {
        userData = data;
      });
    } catch (e) {
      print("Error in fetching data: $e");
    }
  }

  Future<void> _logout() async {
    try {
      await supabase.auth.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    } catch (e) {
      print("Error during logout: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: userData.isEmpty
          ? const Center(child: CircularProgressIndicator()) // Show loader while fetching data
          : ListView(
              padding: const EdgeInsets.all(10),
              children: [
                // Profile information
                for (var user in userData)
                  Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.black,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        user['user_name'] ?? 'No Name',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Email: ${user['user_email'] ?? 'No Email'}"),
                          Text("Contact: ${user['user_contact'] ?? 'No Contact'}"),
                        ],
                      ),
                    ),
                  ),
                // Navigation to Enquiries Page
                const SizedBox(height: 20),
                ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EnquiriesPage(),
                      ),
                    );
                  },
                  title: const Text(
                    "View Your Enquiries",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.black,
                  ),
                ),
                // Navigation to View Complaints Page
                ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ViewComplaintsPage(),
                      ),
                    );
                  },
                  title: const Text(
                    "View Your Complaints",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.black,
                  ),
                ),
                // Logout Option
                ListTile(
                  onTap: _logout,
                  title: const Text(
                    "Logout",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Colors.red,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.logout,
                    size: 16,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
    );
  }
}

class ViewComplaintsPage extends StatefulWidget {
  const ViewComplaintsPage({super.key});

  @override
  _ViewComplaintsPageState createState() => _ViewComplaintsPageState();
}

class _ViewComplaintsPageState extends State<ViewComplaintsPage> {
  List<Map<String, dynamic>> complaints = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await supabase
          .from('tbl_complaint')
          .select()
          .eq('user_id', supabase.auth.currentUser!.id);

      setState(() {
        complaints = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching complaints: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Complaints'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : complaints.isEmpty
              ? Center(
                  child: errorMessage != null
                      ? Text(errorMessage!, style: const TextStyle(color: Colors.red))
                      : const Text('No complaints found'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    final complaint = complaints[index];
                    final status = complaint['complaint_status'] == 0 ? 'Pending' : 'Resolved';
                    final reply = complaint['complaint_reply'];

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              complaint['complaint_title'] ?? 'Untitled Complaint',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Date: ${complaint['complaint_date'] ?? 'Unknown'}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Details: ${complaint['complaint_content'] ?? 'No details provided'}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Status: $status',
                              style: TextStyle(
                                fontSize: 16,
                                color: status == 'Pending' ? Colors.orange : Colors.green,
                              ),
                            ),
                            if (reply != null && reply.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Reply:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reply,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
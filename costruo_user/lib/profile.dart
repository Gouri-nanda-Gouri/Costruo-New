import 'package:costruo_user/enquery.dart';
import 'package:costruo_user/main.dart'; // Assuming// Import the Enquiries Page
import 'package:flutter/material.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  List<dynamic> userData = []; // Store fetched data

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text("Profile"),
      // ),
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
                // Simple button or ListTile for navigation
                const SizedBox(height: 20),
                ListTile(
                  onTap: () {
                    // Navigate to the Enquiries Page when the ListTile is tapped
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EnquiriesPage(), // EnquiriesPage is the page you want to navigate to
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
              ],
            ),
    );
  }
}

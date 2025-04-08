import 'package:costruo_worker/profile.dart';
import 'package:flutter/material.dart';

class WorkerHomePage extends StatefulWidget {
  const WorkerHomePage({Key? key}) : super(key: key);

  @override
  _WorkerHomePageState createState() => _WorkerHomePageState();
}

class _WorkerHomePageState extends State<WorkerHomePage> {
  // Worker profile information
  final String workerName = "John Doe";
  final String jobTitle = "Electrician";
  final int experience = 5;
  final double rating = 4.5;
  final String profileImage = "https://example.com/profile.jpg";

  // Navigation state
  int _currentIndex = 0;

  // List of jobs - could be updated dynamically
  final List<Map<String, String>> availableJobs = [
    {
      "title": "Wiring Work",
      "location": "Downtown",
      "pay": "₹5000",
      "distance": "3.2 km",
      "urgency": "High",
      "time": "Today, 2:00 PM",
    },
    {
      "title": "Lighting Installation",
      "location": "Uptown",
      "pay": "₹7000",
      "distance": "5.7 km",
      "urgency": "Medium",
      "time": "Tomorrow, 10:00 AM",
    },
    {
      "title": "Circuit Repair",
      "location": "Midtown",
      "pay": "₹3500",
      "distance": "1.8 km",
      "urgency": "Low",
      "time": "Wednesday, 4:00 PM",
    },
  ];

  // Stats could be updated based on user activity
  final Map<String, dynamic> stats = {
    "completed": 32,
    "inProgress": 2,
    "monthlyEarnings": "₹48,000",
  };

  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
    // You would typically navigate to different screens here
  }

  void _viewJobDetails(int index) {
    // Show job details, possibly in a modal or navigate to details page
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: Text(
          availableJobs[index]["title"] ?? "",
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'serif',
          ),
        ),
        content: const Text(
          "This would show full job details",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'serif',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            child: const Text(
              "Close",
              style: TextStyle(fontFamily: 'serif'),
            ),
          ),
        ],
      ),
    );
  }

  void _acceptJob(int index) {
    // Logic for accepting a job
    setState(() {
      // Example: Move job from available to in-progress
      stats["inProgress"] = (stats["inProgress"] as int) + 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Job accepted: ${availableJobs[index]["title"]}",
          style: const TextStyle(fontFamily: 'serif'),
        ),
        backgroundColor: const Color(0xFF2C2C2C),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        title: const Text(
          "Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontFamily: 'serif',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              setState(() {
                // Handle notifications
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              // Handle logout
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: NetworkImage(profileImage),
                        child: profileImage.isEmpty
                            ? const Icon(Icons.person, size: 40, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Hello, $workerName!",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'serif',
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              jobTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 156, 154, 154),
                                fontFamily: 'serif',
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _buildInfoChip(
                                    Icons.star, "$rating", Colors.amber),
                                const SizedBox(width: 10),
                                _buildInfoChip(Icons.work, "$experience years",
                                    Colors.blue),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      _buildQuickActionButton(
                        context,
                        Icons.search,
                        "Find Jobs",
                        Colors.white,
                        () {
                          setState(() {
                            _currentIndex = 1; // Switch to Jobs tab
                          });
                        },
                      ),
                      const SizedBox(width: 10),
                      _buildQuickActionButton(
                        context,
                        Icons.history,
                        "Profile",
                        Colors.white,
                        () {
                          // Navigate to WorkerProfile page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const WorkerProfile()),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      _buildQuickActionButton(
                        context,
                        Icons.payment,
                        "Earnings",
                        Colors.white,
                        () {
                          setState(() {
                            _currentIndex = 2; // Switch to Earnings tab
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Stats Summary Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                        "Jobs Completed", "${stats['completed']}", Colors.green),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildStatCard(
                        "In Progress", "${stats['inProgress']}", Colors.orange),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildStatCard(
                        "This Month", stats['monthlyEarnings'], Colors.blue),
                  ),
                ],
              ),
            ),

            // Available Jobs Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Available Jobs",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'serif',
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _currentIndex = 1; // Switch to Jobs tab
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          "View All",
                          style: TextStyle(fontFamily: 'serif'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(availableJobs.length, (index) {
                    return Column(
                      children: [
                        JobCard(
                          title: availableJobs[index]["title"] ?? "",
                          location: availableJobs[index]["location"] ?? "",
                          pay: availableJobs[index]["pay"] ?? "",
                          distance: availableJobs[index]["distance"] ?? "",
                          urgency: availableJobs[index]["urgency"] ?? "",
                          time: availableJobs[index]["time"] ?? "",
                          onViewDetails: () => _viewJobDetails(index),
                          onAccept: () => _acceptJob(index),
                        ),
                        const SizedBox(height: 15),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            elevation: 0,
            backgroundColor: const Color(0xFF0D0D0D),
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.work_outline), label: "Jobs"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.payment), label: "Earnings"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline), label: "Profile"),
            ],
            currentIndex: _currentIndex,
            onTap: _changeTab,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontFamily: 'serif',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: const Color(0xFF0D0D0D), size: 16),
        label: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF0D0D0D),
            fontFamily: 'serif',
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontFamily: 'serif',
            ),
          ),
        ],
      ),
    );
  }
}

class JobCard extends StatelessWidget {
  final String title;
  final String location;
  final String pay;
  final String distance;
  final String urgency;
  final String time;
  final VoidCallback onViewDetails;
  final VoidCallback onAccept;

  const JobCard({
    Key? key,
    required this.title,
    required this.location,
    required this.pay,
    required this.distance,
    required this.urgency,
    required this.time,
    required this.onViewDetails,
    required this.onAccept,
  }) : super(key: key);

  Color _getUrgencyColor() {
    switch (urgency.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'serif',
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getUrgencyColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    urgency,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getUrgencyColor(),
                      fontWeight: FontWeight.w500,
                      fontFamily: 'serif',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(width: 15),
                const Icon(Icons.directions_car_outlined,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  distance,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontFamily: 'serif',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontFamily: 'serif',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  pay,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    fontFamily: 'serif',
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: onViewDetails,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Details",
                        style: TextStyle(fontFamily: 'serif'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0D0D0D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Accept",
                        style: TextStyle(fontFamily: 'serif'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:costruo_contractor/assign.dart';
import 'package:costruo_contractor/enq.dart';
import 'package:costruo_contractor/main.dart';
import 'package:costruo_contractor/mywork.dart';
import 'package:costruo_contractor/ongoing.dart';
import 'package:flutter/material.dart';

class Homepage extends StatefulWidget {
  @override
  HomepageState createState() => HomepageState();
}

class HomepageState extends State<Homepage> {
  int _selectedPage = 0; // 0 = Dashboard, 1 = Projects
  
  // Project lists
  List<Map<String, dynamic>> newProjects = [
    {"title": "Smart Home Design", "client": "Johnson Family", "deadline": "Apr 15"},
    {"title": "Modern Office Renovation", "client": "TechSpace Inc.", "deadline": "May 2"},
  ];

  List<Map<String, dynamic>> ongoingProjects = [
    {"title": "Luxury Villa", "progress": 0.75, "client": "Robert Williams", "deadline": "Apr 10"},
    {"title": "Commercial Complex", "progress": 0.50, "client": "MetroBiz Corp", "deadline": "Jun 22"},
  ];

  List<Map<String, dynamic>> completedProjects = [
    {"title": "Apartment Building", "client": "Urban Housing LLC", "completedDate": "Feb 25"},
    {"title": "Shopping Mall", "client": "Retail Ventures", "completedDate": "Jan 15"},
  ];

  // Active workers for today
  List<Map<String, dynamic>> workers = [
    {"name": "John Doe", "profession": "Electrician", "rating": 4.8, "avatar": "assets/avatars/john.png"},
    {"name": "Sarah Smith", "profession": "Plumber", "rating": 4.5, "avatar": "assets/avatars/sarah.png"},
    {"name": "Miguel Cortez", "profession": "Carpenter", "rating": 4.7, "avatar": "assets/avatars/miguel.png"},
    {"name": "Lisa Chen", "profession": "Interior Designer", "rating": 4.9, "avatar": "assets/avatars/lisa.png"},
  ];

  // Dashboard statistics
  Map<String, dynamic> stats = {
    "activeProjects": 6,
    "pendingTasks": 12,
    "teamMembers": 8,
    "monthlyEarnings": 24500
  };

  void _showProjectsPage() {
    setState(() {
      _selectedPage = 1;
    });
  }

  void _showDashboardPage() {
    setState(() {
      _selectedPage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text('Costruo', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Badge(
              label: Text('3'),
              child: Icon(Icons.notifications_outlined),
            ),
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const EnquiriesPage()));
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CircleAvatar(
              backgroundColor: Colors.green[100],
              child: Text('JD', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800])),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _selectedPage == 0 ? _buildDashboard() : _buildProjectsPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedPage,
        onTap: (index) {
          setState(() {
            _selectedPage = index;
          });
        },
        selectedItemColor: Colors.green[800],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business_outlined),
            activeIcon: Icon(Icons.business),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Team',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[800],
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AssignWorker()));
        },
      ),
    );
  }
  List<dynamic> cData = [];

  Future<void> fetchData() async {
    try {
      final data = await supabase.from('tbl_contractor').select().limit(1);
      setState(() {
        cData = data;
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[800]!, Colors.green[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Text('JD', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[800])),
                ),
                const SizedBox(height: 10),
                 Text(
              "Hello ${cData.isNotEmpty ? cData[0]['contractor_name'] ?? 'Guest' : 'Loading...'}",
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'serif',
              ),
            ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: _showDashboardPage,
          ),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('All Projects'),
            onTap: _showProjectsPage,
          ),
          ExpansionTile(
            leading: const Icon(Icons.folder),
            title: const Text('Project Status'),
            children: [
              ListTile(
                leading: const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.add_box, size: 20),
                ),
                title: const Text('New'),
                onTap: () {
                  // Handle navigation to "New" projects page
                },
              ),
              ListTile(
                leading: const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.loop, size: 20),
                ),
                title: const Text('Ongoing'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkQuotesPage()));
                },
              ),
              ListTile(
                leading: const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.check_circle, size: 20),
                ),
                title: const Text('Completed'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const Mywork()));
                },
              ),
            ],
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Team Members'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Tasks'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Reports'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome card with quick stats
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Welcome back, John!', 
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Here\'s what\'s happening today',
                    style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statCard('Active\nProjects', stats['activeProjects'].toString(), Colors.blue[700]!),
                      _statCard('Pending\nTasks', stats['pendingTasks'].toString(), Colors.orange[700]!),
                      _statCard('Team\nMembers', stats['teamMembers'].toString(), Colors.purple[700]!),
                      _statCard('Monthly\nEarnings', '\$${stats['monthlyEarnings']}', Colors.green[700]!),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Ongoing projects section
          _sectionTitle("Ongoing Projects", 
            trailing: TextButton(
              child: Text('See All', style: TextStyle(color: Colors.green[800])),
              onPressed: _showProjectsPage,
            )
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: ongoingProjects.length,
              itemBuilder: (context, index) {
                return _buildProjectCard(
                  ongoingProjects[index]["title"],
                  ongoingProjects[index]["progress"],
                  ongoingProjects[index]["client"],
                  ongoingProjects[index]["deadline"],
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          
          // Today's team section
          _sectionTitle("Today's Team", 
            trailing: TextButton(
              child: Text('Manage', style: TextStyle(color: Colors.green[800])),
              onPressed: () {},
            )
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: workers.length,
              itemBuilder: (context, index) {
                return _buildWorkerCard(workers[index]);
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Recent activities
          _sectionTitle("Recent Activities"),
          const SizedBox(height: 12),
          _buildActivityList(),
        ],
      ),
    );
  }

  Widget _buildProjectsPage() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: Colors.green[800],
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.green[800],
              tabs: [
                Tab(text: "New (${newProjects.length})"),
                Tab(text: "Ongoing (${ongoingProjects.length})"),
                Tab(text: "Completed (${completedProjects.length})"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildProjectsList(newProjects, isNew: true),
                _buildProjectsList(ongoingProjects),
                _buildProjectsList(completedProjects, isCompleted: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsList(List<Map<String, dynamic>> projectList, {bool isNew = false, bool isCompleted = false}) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projectList.length,
      itemBuilder: (context, index) {
        final project = projectList[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        project["title"],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isNew ? Colors.blue[50] : isCompleted ? Colors.green[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isNew ? "New" : isCompleted ? "Completed" : "${(project["progress"] * 100).toInt()}%",
                        style: TextStyle(
                          color: isNew ? Colors.blue[700] : isCompleted ? Colors.green[700] : Colors.orange[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      project["client"] ?? "Unknown Client",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      isCompleted ? Icons.event_available : Icons.event,
                      size: 16,
                      color: Colors.grey[600]
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCompleted ? "Completed: ${project["completedDate"]}" : "Due: ${project["deadline"]}",
                      style: TextStyle(
                        color: isCompleted ? Colors.grey[700] : 
                               project["deadline"] == "Apr 10" ? Colors.red[700] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                
                if (!isNew && !isCompleted) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: project["progress"],
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      project["progress"] < 0.3 ? Colors.red[400]! :
                      project["progress"] < 0.7 ? Colors.orange[400]! : Colors.green[400]!
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
                
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {},
                      child: Text(isCompleted ? 'View Report' : isNew ? 'Start Project' : 'Update'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Container(
      width: 75,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              title.contains('Projects') ? Icons.business :
              title.contains('Tasks') ? Icons.check_circle_outline :
              title.contains('Team') ? Icons.people_outline :
              Icons.monetization_on_outlined,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.2),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildProjectCard(String title, double progress, String client, String deadline) {
    final isUrgent = deadline == "Apr 10";
    
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${(progress * 100).toInt()}%",
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress < 0.3 ? Colors.red[400]! :
                  progress < 0.7 ? Colors.orange[400]! : Colors.green[400]!
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      client,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.event, size: 16, color: isUrgent ? Colors.red[600] : Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    "Due: $deadline",
                    style: TextStyle(
                      color: isUrgent ? Colors.red[700] : Colors.grey[700],
                      fontSize: 13,
                      fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Update'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    minimumSize: const Size(100, 36),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkerCard(Map<String, dynamic> worker) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: Colors.green[100],
                radius: 28,
                child: Text(
                  worker["name"].toString().split(' ').map((e) => e[0]).join(''),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[800]),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                worker["name"],
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              Text(
                worker["profession"],
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    worker["rating"].toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityList() {
    List<Map<String, dynamic>> activities = [
      {"title": "New material delivery", "time": "3:30 PM", "type": "delivery"},
      {"title": "Team meeting scheduled", "time": "Tomorrow, 9:00 AM", "type": "meeting"},
      {"title": "Project milestone reached", "time": "Today, 11:20 AM", "type": "milestone"},
    ];
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: activities.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: activity["type"] == "delivery" ? Colors.blue[50] :
                       activity["type"] == "meeting" ? Colors.purple[50] : Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                activity["type"] == "delivery" ? Icons.local_shipping :
                activity["type"] == "meeting" ? Icons.people : Icons.flag,
                color: activity["type"] == "delivery" ? Colors.blue[700] :
                       activity["type"] == "meeting" ? Colors.purple[700] : Colors.green[700],
                size: 20,
              ),
            ),
            title: Text(activity["title"]),
            subtitle: Text(activity["time"]),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          );
        },
      ),
    );
  }

  Widget _buildAddProjectSheet() {
    return Container(
      height: 600,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Add New Project',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Form fields would go here
          const TextField(
            decoration: InputDecoration(
              labelText: 'Project Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Client Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Deadline',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
            ),
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          
          const Spacer(),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Create Project'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
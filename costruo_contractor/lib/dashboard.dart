import 'package:costruo_contractor/completed_projects.dart';
import 'package:costruo_contractor/enq.dart';
import 'package:costruo_contractor/login.dart';
import 'package:costruo_contractor/main.dart';
import 'package:costruo_contractor/ongoing.dart';
import 'package:costruo_contractor/workers.dart';
import 'package:flutter/material.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  HomepageState createState() => HomepageState();
}

class HomepageState extends State<Homepage> {
  // Data structures to hold database information
  List<Map<String, dynamic>> ongoingProjects = [];
  List<Map<String, dynamic>> activeWorkers = [];
  Map<String, dynamic> stats = {
    "activeProjects": 0,
    "pendingTasks": 0,
    "teamMembers": 0,
    "monthlyEarnings": 0
  };
  Map<String, dynamic> contractorData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await fetchContractorData();  // Wait for contractor data first
    await fetchDashboardData();   // Then fetch dashboard data
  }

  Future<void> fetchContractorData() async {
    try {
      final response = await supabase
          .from('tbl_contractor')
          .select('contractor_name, contractor_photo')
          .eq('id', supabase.auth.currentUser!.id)
          .single();
      
      if (mounted) {
        setState(() {
          contractorData = response;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching contractor data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> fetchDashboardData() async {
    try {
      final contractorId = supabase.auth.currentUser!.id;
      
      // Fetch ongoing projects
      final projectsResponse = await supabase
          .from('tbl_workquote')
          .select('''
            *,
            tbl_enquiry (
              enquiry_detail,
              enquiry_location,
              tbl_user (
                user_name
              )
            )
          ''')
          .eq('contractor_id', contractorId)
          .neq('work_remark', 10)  // Not completed
          .order('created_at', ascending: false);

      // Fetch all workers
      final workersResponse = await supabase
          .from('tbl_worker')
          .select('''
            worker_name,
            worker_photo,
            tbl_type (
              type_name
            )
          ''')
          .eq('contractor_id', contractorId);

      // Calculate statistics
      final activeProjectsCount = projectsResponse.length;
      
      // Get pending tasks count
      final pendingTasksResponse = await supabase
          .from('tbl_workquote')
          .select()
          .eq('contractor_id', contractorId)
          .eq('work_remark', 3);
      
      // Get team members count
      final teamMembersResponse = await supabase
          .from('tbl_worker')
          .select('id')
          .eq('contractor_id', contractorId);

      // Calculate monthly earnings
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      
      final earningsResponse = await supabase
          .from('tbl_payment')
          .select('''
            payment_amount,
            tbl_workquote!inner (
              contractor_id
            )
          ''')
          .eq('tbl_workquote.contractor_id', contractorId)
          .gte('created_at', startOfMonth.toIso8601String())
          .lte('created_at', endOfMonth.toIso8601String());

      double monthlyEarnings = 0;
      for (var payment in earningsResponse) {
        monthlyEarnings += (payment['payment_amount'] as num).toDouble();
      }

      setState(() {
        ongoingProjects = List<Map<String, dynamic>>.from(projectsResponse);
        activeWorkers = List<Map<String, dynamic>>.from(workersResponse);
        stats = {
          "activeProjects": activeProjectsCount,
          "pendingTasks": pendingTasksResponse.length,
          "teamMembers": teamMembersResponse.length,
          "monthlyEarnings": monthlyEarnings
        };
        isLoading = false;
      });

    } catch (e) {
      print('Error fetching dashboard data: $e');
      setState(() => isLoading = false);
    }
  }

  void _showDashboardPage() {
    setState(() {
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
      body: _buildDashboard(),
    );
  }
  List<Map<String,dynamic>> cData = [];

  Future<void> fetchData() async {
    try {
      final data = await supabase.from('tbl_contractor').select().eq('id', supabase.auth.currentUser!.id).single;
      setState(() {
        cData = data as List<Map<String, dynamic>>;
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
                  backgroundImage: contractorData['contractor_photo'] != null
                    ? NetworkImage(contractorData['contractor_photo'])
                    : null,
                  child: contractorData['contractor_photo'] == null
                    ? Text(
                        contractorData['contractor_name']?.substring(0, 1).toUpperCase() ?? 'C',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800]
                        ),
                      )
                    : null,
                ),
                const SizedBox(height: 10),
                Text(
                  "Hello ${contractorData['contractor_name'] ?? 'Contractor'}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
          // ListTile(
          //   leading: const Icon(Icons.business),
          //   title: const Text('All Projects'),
          //   onTap: _showProjectsPage,
          // ),
          ExpansionTile(
            leading: const Icon(Icons.folder),
            title: const Text('Projects'),
            children: [
              ListTile(
                leading: const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.add_box, size: 20),
                ),
                title: const Text('New'),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const EnquiriesPage()));
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
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CompletedProjects()));
                },
              ),
            ],
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Team Members'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageWorkers(),));
            },
          ),
         
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Reports'),
            onTap: () {},
          ),
          // const Divider(),
          // ListTile(
          //   leading: const Icon(Icons.settings),
          //   title: const Text('Settings'),
          //   onTap: () {},
          // ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await supabase.auth.signOut();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const Login(),), (context) => false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoading 
                      ? 'Loading...'
                      : 'Welcome back, ${contractorData['contractor_name'] ?? 'Contractor'}!',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Here's what's happening today",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statCard('Active\nProjects', stats['activeProjects'].toString(), Colors.blue[700]!),
                      _statCard('Pending\nTasks', stats['pendingTasks'].toString(), Colors.orange[700]!),
                      _statCard('Team\nMembers', stats['teamMembers'].toString(), Colors.purple[700]!),
                      _statCard('Monthly\nEarnings', '\$${stats['monthlyEarnings'].toStringAsFixed(2)}', Colors.green[700]!),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          _sectionTitle("Ongoing Projects", 
            trailing: TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkQuotesPage()));
              },
              child: Text('See All', style: TextStyle(color: Colors.green[800])),
            )
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ongoingProjects.isEmpty
              ? Center(
                  child: Text('No ongoing projects',
                    style: TextStyle(color: Colors.grey[600]))
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: ongoingProjects.length,
                  itemBuilder: (context, index) {
                    final project = ongoingProjects[index];
                    return _buildProjectCard(
                      project['tbl_enquiry']['enquiry_detail'] ?? 'Untitled Project',
                      project['tbl_enquiry']['tbl_user']['user_name'] ?? 'Unknown Client',
                      project['tbl_enquiry']['enquiry_location'] ?? 'No location',
                    );
                  },
                ),
          ),

          const SizedBox(height: 24),
          
          _sectionTitle("My Workers", 
            trailing: TextButton(
              child: Text('Manage', style: TextStyle(color: Colors.green[800])),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageWorkers(),));
              },
            )
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: activeWorkers.isEmpty
              ? Center(
                  child: Text('No workers added yet',
                    style: TextStyle(color: Colors.grey[600]))
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: activeWorkers.length,
                  itemBuilder: (context, index) {
                    final worker = activeWorkers[index];
                    return _buildWorkerCard({
                      "name": worker['worker_name'],
                      "profession": worker['tbl_type']['type_name'],
                      "avatar": worker['worker_photo'],
                    });
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return SizedBox(
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

  Widget _buildProjectCard(String title, String client, String location) {
    return Card(
      margin: const EdgeInsets.only(right: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(client,
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(location,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerCard(Map<String, dynamic> worker) {
    return Card(
      margin: const EdgeInsets.only(right: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: worker['avatar'] != null
                ? NetworkImage(worker['avatar'])
                : null,
              child: worker['avatar'] == null
                ? Text(worker['name'][0],
                    style: const TextStyle(fontSize: 24))
                : null,
            ),
            const SizedBox(height: 8),
            Text(worker['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(worker['profession'],
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  
}

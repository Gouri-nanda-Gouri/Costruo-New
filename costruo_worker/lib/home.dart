import 'package:costruo_worker/drawing_submission.dart';
import 'package:costruo_worker/profile.dart';
import 'package:costruo_worker/work_details.dart';
import 'package:flutter/material.dart';
import 'package:costruo_worker/main.dart';
import 'package:costruo_worker/login.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class WorkerHomePage extends StatefulWidget {
  const WorkerHomePage({Key? key}) : super(key: key);

  @override
  _WorkerHomePageState createState() => _WorkerHomePageState();
}

class _WorkerHomePageState extends State<WorkerHomePage> {
  Map<String, dynamic> workerData = {};
  List<Map<String, dynamic>> assignedWorks = [];
  List<Map<String, dynamic>> completedWorks = [];
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  String errorMessage = '';

  // Work summary metrics
  int totalAssignments = 0;
  int ongoingProjects = 0;
  double totalSalary = 0.0; // Changed from drawingSubmissions to totalSalary
  double averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadWorkerData();
    _loadAssignedWorks();
    _loadCompletedWorks();
    _loadNotifications();
    _loadWorkSummary();
  }

  Future<void> _loadWorkerData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
        );
        return;
      }

      final response = await supabase
          .from('tbl_worker')
          .select('''
            *,
            tbl_type (
              type_name
            )
          ''')
          .eq('id', user.id)
          .single();

      setState(() {
        workerData = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading worker data: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadAssignedWorks() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('tbl_assign')
          .select('''
            *,
            tbl_workquote (
              *,
              tbl_enquiry (
                enquiry_location,
                enquiry_detail,
                enquiry_status,
                visiting_date
              )
            )
          ''')
          .eq('worker_id', user.id)
          .eq('assign_status', 0)
          .order('created_at', ascending: false);

      setState(() {
        assignedWorks = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading assigned works: $e');
    }
  }

  Future<void> _loadCompletedWorks() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('tbl_assign')
          .select('''
            *,
            tbl_workquote (
              *,
              tbl_enquiry (
                enquiry_location,
                enquiry_detail,
                enquiry_status
              )
            )
          ''')
          .eq('worker_id', user.id)
          .eq('assign_status', 1)
          .order('created_at', ascending: false)
          .limit(5);

      setState(() {
        completedWorks = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading completed works: $e');
    }
  }

  Future<void> _loadNotifications() async {
    setState(() {
      notifications = [
        {
          'id': 1,
          'title': 'New Assignment',
          'message': 'You have been assigned to a new project in Vyttila',
          'created_at': DateTime.now().subtract(const Duration(hours: 2)).toString(),
        },
        {
          'id': 2,
          'title': 'Drawing Revision',
          'message': 'Your drawing submission for Keezhillam needs revision',
          'created_at': DateTime.now().subtract(const Duration(days: 1)).toString(),
        },
      ];
    });
  }

  Future<void> _loadWorkSummary() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Load total assignments
      final assignmentsResponse = await supabase
          .from('tbl_assign')
          .select('id')
          .eq('worker_id', user.id);

      // Load ongoing projects
      final ongoingResponse = await supabase
          .from('tbl_assign')
          .select('id')
          .eq('worker_id', user.id)
          .eq('assign_status', 0);

      // Load total salary
      final salaryResponse = await supabase
          .from('tbl_salary')
          .select('salary_amount')
          .eq('worker_id', user.id)
          .eq('salary_status', 1);

      setState(() {
        totalAssignments = assignmentsResponse.length;
        ongoingProjects = ongoingResponse.length;
        totalSalary = salaryResponse.fold(0.0, (sum, item) => sum + (item['salary_amount'] as num).toDouble());
        averageRating = 0.0; // No tbl_ratings table provided
      });
    } catch (e) {
      print('Error loading work summary: $e');
      setState(() {
        totalAssignments = 15;
        ongoingProjects = 4;
        totalSalary = 0.0;
        averageRating = 0.0;
      });
    }
  }

  List<Map<String, dynamic>> _getUpcomingDeadlines() {
    List<Map<String, dynamic>> deadlines = [];

    for (var work in assignedWorks) {
      final enquiry = work['tbl_workquote']?['tbl_enquiry'];
      final visitingDate = enquiry?['visiting_date'];

      if (visitingDate != null) {
        DateTime? deadlineDate = DateTime.tryParse(visitingDate);
        if (deadlineDate != null && deadlineDate.isAfter(DateTime.now())) {
          deadlines.add({
            'id': work['id'],
            'location': enquiry?['enquiry_location'] ?? 'Unknown',
            'detail': enquiry?['enquiry_detail'] ?? 'No details',
            'deadline': deadlineDate,
          });
        }
      }
    }

    deadlines.sort((a, b) => (a['deadline'] as DateTime).compareTo(b['deadline'] as DateTime));
    return deadlines.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Worker Dashboard",
          style: TextStyle(color: Colors.white, fontFamily: 'serif'),
        ),
        actions: [
          Badge(
            label: Text(notifications.length.toString()),
            isLabelVisible: notifications.isNotEmpty,
            child: IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: _showNotifications,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WorkerProfile()),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await _loadWorkerData();
                    await _loadAssignedWorks();
                    await _loadCompletedWorks();
                    await _loadNotifications();
                    await _loadWorkSummary();
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWorkerInfoCard(),
                        const SizedBox(height: 24),
                        _buildWorkSummarySection(),
                        const SizedBox(height: 24),
                        _buildUpcomingDeadlinesSection(),
                        const SizedBox(height: 24),
                        _buildQuickActionsSection(),
                        const SizedBox(height: 24),
                        _buildAssignedWorksSection(),
                        const SizedBox(height: 24),
                        _buildRecentCompletedWorksSection(),
                        const SizedBox(height: 24),
                        _buildSafetyTipCard(),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.support),
        onPressed: () {
          // Implement support page navigation
        },
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.black87,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade800, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: workerData['worker_photo'] != null
                      ? NetworkImage(workerData['worker_photo'])
                      : null,
                  child: workerData['worker_photo'] == null
                      ? Text(
                          workerData['worker_name']?[0] ?? 'W',
                          style: const TextStyle(fontSize: 24),
                        )
                      : null,
                ),
                const SizedBox(height: 10),
                Text(
                  workerData['worker_name'] ?? 'Worker',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  workerData['tbl_type']?['type_name'] ?? 'Worker Type',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.white),
            title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
            selected: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment, color: Colors.white),
            title: const Text('All Assignments', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              // Implement all assignments page
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.white),
            title: const Text('Completed Works', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              // Implement completed works page
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today, color: Colors.white),
            title: const Text('Calendar', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              // Implement calendar page
            },
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.white),
            title: const Text('My Profile', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WorkerProfile()),
              );
            },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.help, color: Colors.white),
            title: const Text('Help & Support', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              // Implement support page
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text('Logout', style: TextStyle(color: Colors.white)),
            onTap: () async {
              await supabase.auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Login()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade900, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade900.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: workerData['worker_photo'] != null
                    ? NetworkImage(workerData['worker_photo'])
                    : null,
                child: workerData['worker_photo'] == null
                    ? Text(
                        workerData['worker_name']?[0] ?? 'W',
                        style: const TextStyle(fontSize: 24),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workerData['worker_name'] ?? 'Worker',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      workerData['tbl_type']?['type_name'] ?? 'Worker Type',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                '$averageRating/5.0',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Rating',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Work Summary",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'serif',
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                "Total Assignments",
                totalAssignments.toString(),
                Icons.assignment,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                "Ongoing Projects",
                ongoingProjects.toString(),
                Icons.build,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SalaryDetailsPage()),
                  );
                },
                child: _buildSummaryCard(
                  "Total Salary",
                  '₹${totalSalary.toStringAsFixed(2)}',
                  Icons.payment,
                  Colors.orange,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                "Completion Rate",
                "${((completedWorks.length / (completedWorks.length + assignedWorks.length)) * 100).toStringAsFixed(0)}%",
                Icons.check_circle,
                Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingDeadlinesSection() {
    final deadlines = _getUpcomingDeadlines();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Upcoming Deadlines",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'serif',
              ),
            ),
            TextButton(
              onPressed: () {
                // Implement calendar page navigation
              },
              child: const Text(
                "View Calendar",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (deadlines.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text(
                "No upcoming deadlines",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: deadlines.length,
            itemBuilder: (context, index) {
              final deadline = deadlines[index];
              final daysLeft = deadline['deadline'].difference(DateTime.now()).inDays;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: daysLeft < 2 ? Colors.red.withOpacity(0.2) : Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: daysLeft < 2 ? Colors.red.withOpacity(0.5) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: daysLeft < 2 ? Colors.red.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: daysLeft < 2 ? Colors.red : Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deadline['location'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              deadline['detail'],
                              style: const TextStyle(color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            DateFormat('MMM d').format(deadline['deadline']),
                            style: const TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            daysLeft < 2 ? "Due soon!" : "$daysLeft days left",
                            style: TextStyle(
                              color: daysLeft < 2 ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Actions",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'serif',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildQuickActionButton(
              "Submit\nDrawing",
              Icons.draw,
              Colors.blue,
              _showDrawingSubmissionOptions,
            ),
            _buildQuickActionButton(
              "View\nCalendar",
              Icons.calendar_today,
              Colors.orange,
              () {
                // Implement calendar page navigation
              },
            ),
            _buildQuickActionButton(
              "My\nProfile",
              Icons.person,
              Colors.purple,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WorkerProfile()),
                );
              },
            ),
            _buildQuickActionButton(
              "Support",
              Icons.help,
              Colors.green,
              () {
                // Implement support page navigation
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 70,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignedWorksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Assigned Works",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'serif',
              ),
            ),
            TextButton(
              onPressed: () {
                // Implement all assigned works page
              },
              child: const Text(
                "View All",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (assignedWorks.isEmpty)
          const Center(
            child: Text(
              "No works assigned yet",
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: assignedWorks.length > 3 ? 3 : assignedWorks.length,
            itemBuilder: (context, index) {
              final work = assignedWorks[index];
              final enquiry = work['tbl_workquote']?['tbl_enquiry'];
              final enquiryStatus = enquiry?['enquiry_status'] ?? 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: Colors.white10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WorkDetails(id: work['tbl_workquote']['workquote_id']),
                          ),
                        );
                      },
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getStatusColor(enquiryStatus).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getStatusIcon(enquiryStatus),
                          color: _getStatusColor(enquiryStatus),
                        ),
                      ),
                      title: Text(
                        'Site: ${enquiry?['enquiry_location'] ?? 'N/A'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            enquiry?['enquiry_detail'] ?? 'No details',
                            style: const TextStyle(color: Colors.grey),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _getPriorityChip(enquiryStatus),
                          const SizedBox(height: 4),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        if (assignedWorks.length > 3)
          Center(
            child: TextButton(
              onPressed: () {
                // Implement all assigned works page
              },
              child: const Text('Show More', style: TextStyle(color: Colors.blue)),
            ),
          ),
      ],
    );
  }

  Widget _buildRecentCompletedWorksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recent Completed Works",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'serif',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (completedWorks.isEmpty)
          const Center(
            child: Text(
              "No completed works yet",
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: completedWorks.length,
            itemBuilder: (context, index) {
              final work = completedWorks[index];
              final enquiry = work['tbl_workquote']?['tbl_enquiry'];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.black45,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                  title: Text(
                    enquiry?['enquiry_location'] ?? 'N/A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Completed on: ${work['assign_date'] != null ? DateFormat('MMM d, yyyy').format(DateTime.parse(work['assign_date'])) : 'Unknown'}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkDetails(id: work['tbl_workquote']['workquote_id']),
                      ),
                    );
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSafetyTipCard() {
    final List<Map<String, String>> safetyTips = [
      {
        'title': 'Always Wear PPE',
        'description': 'Make sure to wear appropriate personal protective equipment for every task.',
      },
      {
        'title': 'Report Hazards',
        'description': 'If you notice any safety hazards on site, report them immediately.',
      },
      {
        'title': 'Stay Hydrated',
        'description': 'Drink plenty of water throughout the day, especially in hot weather.',
      },
      {
        'title': 'Follow Safety Protocols',
        'description': 'Always adhere to established safety procedures for each task.',
      },
      {
        'title': 'Take Regular Breaks',
        'description': 'Fatigue can lead to accidents. Take scheduled breaks to stay alert.',
      },
    ];

    final Random random = Random();
    final tip = safetyTips[random.nextInt(safetyTips.length)];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade800, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                "Safety Tip of the Day",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tip['title']!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tip['description']!,
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    switch (status) {
      case 0:
        return Colors.blue; // Pending
      case 1:
        return Colors.orange; // In Progress
      case 3:
        return Colors.red; // Urgent
      case 4:
        return Colors.green; // Approved
      case 5:
        return Colors.purple; // Completed
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(dynamic status) {
    switch (status) {
      case 0:
        return Icons.assignment; // Pending
      case 1:
        return Icons.build; // In Progress
      case 3:
        return Icons.priority_high; // Urgent
      case 4:
        return Icons.check_circle; // Approved
      case 5:
        return Icons.done_all; // Completed
      default:
        return Icons.help_outline;
    }
  }

  Widget _getPriorityChip(int status) {
    String label;
    Color color;

    switch (status) {
      case 3:
        label = 'Urgent';
        color = Colors.red;
        break;
      case 1:
        label = 'In Progress';
        color = Colors.orange;
        break;
      case 0:
        label = 'Pending';
        color = Colors.blue;
        break;
      default:
        label = 'Normal';
        color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  "Notifications",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (notifications.isEmpty)
                const Center(
                  child: Text(
                    "No new notifications",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.notifications,
                          color: Colors.blue,
                        ),
                      ),
                      title: Text(
                        notification['title'] ?? 'Notification',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification['message'] ?? '',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification['created_at'] != null
                                ? _getTimeAgo(DateTime.parse(notification['created_at']))
                                : '',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  void _showDrawingSubmissionOptions() {
    if (assignedWorks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No assigned works available for drawing submission'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  "Select Work for Drawing Submission",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: assignedWorks.length,
                itemBuilder: (context, index) {
                  final work = assignedWorks[index];
                  final enquiry = work['tbl_workquote']?['tbl_enquiry'];

                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.draw,
                        color: Colors.blue,
                      ),
                    ),
                    title: Text(
                      enquiry?['enquiry_location'] ?? 'N/A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      enquiry?['enquiry_detail'] ?? 'No details',
                      style: const TextStyle(color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DrawingSubmissionPage(
                            workRemark: work['tbl_workquote']['work_remark'],
                            workquoteId: work['tbl_workquote']['workquote_id'],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class SalaryDetailsPage extends StatefulWidget {
  const SalaryDetailsPage({Key? key}) : super(key: key);

  @override
  _SalaryDetailsPageState createState() => _SalaryDetailsPageState();
}

class _SalaryDetailsPageState extends State<SalaryDetailsPage> {
  List<Map<String, dynamic>> salaryHistory = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSalaryHistory();
  }

  Future<void> _loadSalaryHistory() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
        );
        return;
      }

      final response = await supabase
          .from('tbl_salary')
          .select()
          .eq('worker_id', user.id)
          .eq('salary_status', 1)
          .order('salary_date', ascending: false);

      setState(() {
        salaryHistory = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading salary history: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Salary Report",
          style: TextStyle(color: Colors.white, fontFamily: 'serif'),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Salary History",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (salaryHistory.isEmpty)
                        const Center(
                          child: Text(
                            "No salary records found",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: salaryHistory.length,
                          itemBuilder: (context, index) {
                            final salary = salaryHistory[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: Colors.white10,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  '₹${salary['salary_amount'].toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  DateFormat('MMM d, yyyy HH:mm:ss')
                                      .format(DateTime.parse(salary['salary_date'])),
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
    );
  }
}
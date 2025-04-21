import 'package:costruo_worker/drawing_submission.dart';
import 'package:costruo_worker/profile.dart';
import 'package:costruo_worker/work_details.dart';
import 'package:flutter/material.dart';
import 'package:costruo_worker/main.dart';
import 'package:costruo_worker/login.dart';

class WorkerHomePage extends StatefulWidget {
  const WorkerHomePage({Key? key}) : super(key: key);

  @override
  _WorkerHomePageState createState() => _WorkerHomePageState();
}

class _WorkerHomePageState extends State<WorkerHomePage> {
  Map<String, dynamic> workerData = {};
  List<Map<String, dynamic>> assignedWorks = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadWorkerData();
    _loadAssignedWorks();
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
                enquiry_status
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
                      // Worker Info Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
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
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Assigned Works Section
                      const Text(
                        "Assigned Works",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(height: 16),
                      
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
                          itemCount: assignedWorks.length,
                          itemBuilder: (context, index) {
                            final work = assignedWorks[index];
                            final enquiry = work['tbl_workquote']?['tbl_enquiry'];
                            final int workRemark = work['tbl_workquote']?['work_remark'] ?? 0;
                            print('Remark: ${work['tbl_workquote']}');
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              color: Colors.white10,
                              child: Column(
                                children: [
                                  ListTile(
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => WorkDetails(id: work['tbl_workquote']['workquote_id'],),));
                                    },
                                    title: Text(
                                      'Site Location: ${enquiry?['enquiry_location'] ?? 'N/A'}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 8),
                                        Text(
                                          'Site Details: ${enquiry?['enquiry_detail'] ?? 'N/A'}',
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Assignment: ${work['assign_remark'] ?? 'N/A'}',
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Status: ${_getStatusText(enquiry?['enquiry_status'])}',
                                          style: TextStyle(
                                            color: _getStatusColor(enquiry?['enquiry_status']),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (workRemark == 5 || workRemark == 8)
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => DrawingSubmissionPage(
                                                workquoteId: work['tbl_workquote']['workquote_id'],
                                                workRemark: workRemark,
                                              ),
                                            ),
                                          );
                                          if (result == true) {
                                            _loadAssignedWorks(); // Refresh the list
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                        ),
                                        child: Text(
                                          workRemark == 8 ? 'Revise Drawing' : 'Submit Drawing',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
    );
  }

  String _getStatusText(int? status) {
    switch (status) {
      case 4:
        return 'Work In Progress';
      case 5:
        return 'Drawing Required';
      default:
        return 'Unknown Status';
    }
  }

  Color _getStatusColor(int? status) {
    switch (status) {
      case 4:
        return Colors.green;
      case 5:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

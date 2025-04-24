import 'package:flutter/material.dart';
import '../main.dart';

class ViewComplaintsAdminPage extends StatefulWidget {
  const ViewComplaintsAdminPage({super.key});

  @override
  _ViewComplaintsAdminPageState createState() => _ViewComplaintsAdminPageState();
}

class _ViewComplaintsAdminPageState extends State<ViewComplaintsAdminPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> complaints = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    try {
      final response = await supabase.from('tbl_complaint').select();
      setState(() {
        complaints = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print("Error fetching complaints: $e");
    }
  }

  Future<void> sendReply(String complaintId, String currentReply) async {
    final TextEditingController replyController = TextEditingController(text: currentReply);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Reply'),
        content: TextField(
          controller: replyController,
          decoration: const InputDecoration(
            hintText: 'Enter your reply',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (result == true && replyController.text.trim().isNotEmpty) {
      try {
        await supabase.from('tbl_complaint').update({
          'complaint_reply': replyController.text.trim(),
          'complaint_status': 1,
        }).eq('id', complaintId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply sent successfully')),
        );
        fetchComplaints(); // Refresh the list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending reply: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> filterComplaints(int status) {
    return complaints.where((c) => c['complaint_status'] == status).toList();
  }

  Widget buildComplaintTable(List<Map<String, dynamic>> complaintList, int status) {
    return complaintList.isEmpty
        ? const Center(child: Text('No complaints found'))
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('SNO')),
                DataColumn(label: Text('Title')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Content')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Reply')),
                DataColumn(label: Text('Actions')),
              ],
              rows: complaintList.asMap().entries.map((entry) {
                int index = entry.key + 1;
                var complaint = entry.value;
                final complaintStatus = complaint['complaint_status'] == 0 ? 'Pending' : 'Resolved';
                final reply = complaint['complaint_reply'] ?? '';
                final isReplied = complaint['complaint_status'] == 1;

                return DataRow(cells: [
                  DataCell(Text(index.toString())),
                  DataCell(Text(complaint['complaint_title'] ?? 'Untitled')),
                  DataCell(Text(complaint['complaint_date'] ?? 'Unknown')),
                  DataCell(Text(complaint['complaint_content'] ?? 'No details')),
                  DataCell(Text(
                    complaintStatus,
                    style: TextStyle(
                      color: complaintStatus == 'Pending' ? Colors.orange : Colors.green,
                    ),
                  )),
                  DataCell(Text(reply.isEmpty ? 'No reply' : reply)),
                  DataCell(
                    Row(
                      children: [
                        if (status == 0) ...[
                          IconButton(
                            icon: const Icon(Icons.reply, color: Colors.green),
                            onPressed: () => sendReply(complaint['id'].toString(), reply),
                          ),
                        ] else if (status == 1) ...[
                          const Text('Replied', style: TextStyle(color: Colors.grey)),
                        ],
                      ],
                    ),
                  ),
                ]);
              }).toList(),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Pending Complaints"),
            Tab(text: "Resolved Complaints"),
          ],
        ),
        SizedBox(
          height: 500,
          child: TabBarView(
            viewportFraction: 1,
            controller: _tabController,
            children: [
              buildComplaintTable(filterComplaints(0), 0),
              buildComplaintTable(filterComplaints(1), 1),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
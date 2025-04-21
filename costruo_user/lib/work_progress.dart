import 'package:flutter/material.dart';
import 'package:costruo_user/main.dart' as main_supabase;
import 'package:intl/intl.dart';

class WorkProgressPage extends StatefulWidget {
  final int workquoteId;
  final int enquiryId;

  const WorkProgressPage({
    super.key,
    required this.workquoteId,
    required this.enquiryId,
  });

  @override
  State<WorkProgressPage> createState() => _WorkProgressPageState();
}

class _WorkProgressPageState extends State<WorkProgressPage> {
  List<Map<String, dynamic>> assignedWorkers = [];
  List<Map<String, dynamic>> workUpdates = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchWorkProgress();
    _fetchWorkUpdates();
  }

  Future<void> _fetchWorkProgress() async {
    try {
      final workers = await main_supabase.supabase
          .from('tbl_assign')
          .select('''
            assign_remark,
            created_at,
            tbl_worker (
              worker_name,
              worker_contact,
              worker_photo
            )
          ''')
          .eq('workquote_id', widget.workquoteId);

      if (mounted) {
        setState(() {
          assignedWorkers = List<Map<String, dynamic>>.from(workers);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error loading work progress: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchWorkUpdates() async {
    try {
      final updates = await main_supabase.supabase
          .from('tbl_updates')
          .select()
          .eq('workquote_id', widget.workquoteId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          workUpdates = List<Map<String, dynamic>>.from(updates);
        });
      }
    } catch (e) {
      print('Error fetching work updates: $e');
    }
  }

  Future<void> _submitReply(String updateId, String reply) async {
    try {
      await main_supabase.supabase
          .from('tbl_updates')
          .update({'update_reply': reply})
          .eq('id', updateId);

      _fetchWorkUpdates(); // Refresh updates after reply
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply submitted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting reply: $e')),
        );
      }
    }
  }

  void _showReplyDialog(String updateId) {
    final TextEditingController replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Reply'),
        content: TextField(
          controller: replyController,
          decoration: const InputDecoration(
            hintText: 'Enter your reply...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (replyController.text.trim().isNotEmpty) {
                _submitReply(updateId, replyController.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateTime) {
    try {
      final date = DateTime.parse(dateTime).toLocal();
      return DateFormat('MMMM dd, yyyy • HH:mm').format(date);
    } catch (e) {
      return 'Date unavailable';
    }
  }

  Widget _buildWorkUpdatesSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Work Updates',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1976D2),
            ),
          ),
          const SizedBox(height: 16),
          if (workUpdates.isEmpty)
            const Center(
              child: Text(
                'No work updates available',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: workUpdates.length,
              itemBuilder: (context, index) {
                final update = workUpdates[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(
                          _formatDate(update['created_at']),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            if (update['update_detail'] != null)
                              Text(
                                update['update_detail'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            if (update['update_image'] != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Image.network(
                                  update['update_image'],
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (update['update_reply'] != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.grey[100],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your Reply:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(update['update_reply']),
                            ],
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: ElevatedButton.icon(
                            onPressed: () => _showReplyDialog(update['id'].toString()),
                            icon: const Icon(Icons.reply),
                            label: const Text('Add Reply'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Progress'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Assigned Workers Section
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Assigned Workers',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (assignedWorkers.isEmpty)
                              const Text(
                                'No workers assigned yet',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: assignedWorkers.length,
                                itemBuilder: (context, index) {
                                  final worker = assignedWorkers[index];
                                  final workerData = worker['tbl_worker'];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundImage: workerData['worker_photo'] != null
                                            ? NetworkImage(workerData['worker_photo'])
                                            : null,
                                        child: workerData['worker_photo'] == null
                                            ? Text(workerData['worker_name'][0].toUpperCase())
                                            : null,
                                      ),
                                      title: Text(workerData['worker_name']),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Contact: ${workerData['worker_contact']}'),
                                          Text('Role: ${worker['assign_remark']}'),
                                          Text('Since: ${_formatDate(worker['created_at'])}'),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      _buildWorkUpdatesSection(),
                    ],
                  ),
                ),
    );
  }
}

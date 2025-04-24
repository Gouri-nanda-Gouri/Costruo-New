import 'package:costruo_contractor/bills_payment.dart';
import 'package:costruo_contractor/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:file_picker/file_picker.dart';

class WorkQuoteDetailPage extends StatefulWidget {
  final Map<String, dynamic> quote;

  const WorkQuoteDetailPage({super.key, required this.quote});

  static const Color primaryColor = Color(0xFF1976D2);
  static const Color accentColor = Color(0xFF4CAF50);
  static const Color backgroundGradientStart = Colors.white;
  static const Color backgroundGradientEnd = Color(0xFFE3F2FD);

  @override
  State<WorkQuoteDetailPage> createState() => _WorkQuoteDetailPageState();
}

class _WorkQuoteDetailPageState extends State<WorkQuoteDetailPage> {
  String clientName = '';
  String clientContact = '';
  List<Map<String, dynamic>> workUpdates = [];
  bool isLoadingUpdates = true;

  @override
  void initState() {
    super.initState();
    fetchClientDetails();
    _fetchWorker();
    fetchWorkUpdates();
  }

  Future<void> fetchClientDetails() async {
    try {
      final response = await supabase
          .from('tbl_user')
          .select('user_name, user_contact')
          .eq('id', widget.quote['user_id'])
          .single();
      
      setState(() {
        clientName = response['user_name'] ?? 'Unknown Client';
        clientContact = response['user_contact'] ?? 'No contact';
      });
    } catch (e) {
      print('Error fetching client details: $e');
    }
  }

  Future<void> fetchWorkUpdates() async {
    try {
      final response = await supabase
          .from('tbl_updates')
          .select()
          .eq('workquote_id', widget.quote['workquote_id'])
          .order('created_at', ascending: false);

      setState(() {
        workUpdates = List<Map<String, dynamic>>.from(response);
        isLoadingUpdates = false;
      });
    } catch (e) {
      print('Error fetching work updates: $e');
      setState(() => isLoadingUpdates = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quote #${widget.quote['enquiry_id']} Details'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          widget.quote['work_remark'] >= 9 ? OutlinedButton.icon(
            icon: const Icon(Icons.credit_card),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BillsPayment(
                    workquoteId: widget.quote['workquote_id'],
                    totalBudget: double.parse(widget.quote['workquote_budget'].toString()),
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
            ),
            label: const Text('Bill & Payment'),
          ) : const SizedBox(),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              WorkQuoteDetailPage.backgroundGradientStart,
              WorkQuoteDetailPage.backgroundGradientEnd
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Client Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.person,
                        'Name',
                        clientName,
                        Colors.blue.shade700,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.phone,
                        'Contact',
                        clientContact,
                        Colors.green.shade700,
                      ),
                    ],
                  ),
                ),
              ),
              _buildStatusCard(),
              const SizedBox(height: 16),
              _buildQuoteInfoCard(),
              const SizedBox(height: 16),
              _buildFileCard(),
              const SizedBox(height: 16),
              _buildWorkUpdatesSection(),
              const SizedBox(height: 16),
              _workerInfo(),
              const SizedBox(height: 16),
              if (widget.quote['work_remark'] == 9)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      const Divider(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () => _completeProject(context),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text(
                            'Mark Project as Complete',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completeProject(BuildContext context) async {
  try {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Complete Project'),
          content: const Text(
            'Are you sure you want to mark this project as complete?\n\nThis action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Complete Project'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return; // Exit if user cancels
    }

    // Fetch work_id from tbl_work via tbl_enquiry
    final workResponse = await supabase
        .from('tbl_workquote')
        .select('tbl_enquiry!inner(*, tbl_work!inner(work_id))')
        .eq('workquote_id', widget.quote['workquote_id'])
        .maybeSingle();

    if (workResponse == null) {
      throw Exception('No workquote found for workquote_id: ${widget.quote['workquote_id']}');
    }

    final workId = workResponse['tbl_enquiry']?['tbl_work']?['work_id'] as int?;
    if (workId == null) {
      throw Exception('Work ID not found in enquiry or work data');
    }
    print('Work ID: $workId');

    final enqid = workResponse['tbl_enquiry']?['enquiry_id'] as int?;
    if (enqid == null) {
      throw Exception('Work ID not found in enquiry or work data');
    }
    print('Enq ID: $enqid');

    // Perform updates
    await Future.wait([
      supabase
          .from('tbl_workquote')
          .update({'work_remark': '10'})
          .eq('workquote_id', widget.quote['workquote_id']),
      supabase
          .from('tbl_assign')
          .update({'assign_status': 1})
          .eq('workquote_id', widget.quote['workquote_id']),
      supabase
          .from('tbl_work')
          .update({'work_status': 1})
          .eq('work_id', workId),

        supabase
          .from('tbl_enquiry')
          .update({'enquiry_status': 5})
          .eq('enquiry_id', enqid),
    ]);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Project marked as complete!'),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate back
    Navigator.pop(context);
  } catch (e, stacktrace) {
    print('Error completing project: $e');
    print(stacktrace);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error completing project: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  List<Map<String, dynamic>> workers = [];

  Future<void> _fetchWorker() async {
    try {
      final response = await supabase
          .from('tbl_assign')
          .select(
              "assign_remark,created_at,assign_status, tbl_worker(worker_name,worker_contact)")
          .eq('workquote_id', widget.quote['workquote_id']);
      setState(() {
        workers = response;
      });
    } catch (e) {
      print("Workers infor error: $e");
    }
  }

  Widget _workerInfo() {
    return Card(
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
                const Text(
                  'Assigned Workers',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (widget.quote['work_remark'] != 10) // Only show if not completed
                  ElevatedButton.icon(
                    onPressed: showWorkersDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Assign Workers'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WorkQuoteDetailPage.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (workers.isEmpty)
              const Text(
                'No workers assigned yet',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: workers.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final worker = workers[index];
                  final workerData = worker['tbl_worker'];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: WorkQuoteDetailPage.primaryColor,
                      child: Text(
                        workerData['worker_name'][0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      workerData['worker_name'],
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(workerData['worker_contact']),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('Assigned: ${_formatDate(worker['created_at'])}'),
                          ],
                        ),
                      ],
                    ),
                    trailing: _buildStatusChip(worker['assign_status']),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(int status) {
    String label;
    Color color;

    switch (status) {
      case 0:
        label = 'Active';
        color = Colors.green;
        break;
      case 1:
        label = 'Completed';
        color = Colors.blue;
        break;
      default:
        label = 'Pending';
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    int statusInt = widget.quote['work_remark'] ?? 0;
    String text;
    Color color;
    IconData icon;

    switch (statusInt) {
      case 3:
        text = 'Accepted';
        color = WorkQuoteDetailPage.accentColor;
        icon = Icons.check_circle;
        break;
      case 4:
        text = 'Work In Progress';
        color = Colors.green;
        icon = Icons.engineering;
        break;
      case 5:
        text = 'Architect Assigned';
        color = Colors.blue;
        icon = Icons.architecture;
        break;
      case 6:
        text = 'Revision Requested';
        color = Colors.orange;
        icon = Icons.refresh;
        break;
      case 7:
        text = 'Quote Generated';
        color = Colors.purple;
        icon = Icons.description;
        break;
      case 8:
        text = 'Revision Requested';
        color = Colors.orange;
        icon = Icons.refresh;
        break;
      case 9:
        text = 'Payment Completed';
        color = Colors.green;
        icon = Icons.payment;
        break;
      case 10:
        text = 'Work Completed';
        color = Colors.green;
        icon = Icons.check_circle;  // Changed icon
        break;
      default:
        text = 'Submitted';
        color = Colors.blueGrey;
        icon = Icons.send;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(
          'Status',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quote Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.attach_money, 'Budget',
                '${widget.quote['workquote_budget']}', Colors.amber.shade700),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.calendar_today, 'Timeline',
                '${widget.quote['workquote_days']} days', Colors.blue.shade700),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.date_range, 'Submitted',
                _formatDate(widget.quote['created_at']), Colors.grey.shade700),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quotation File',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.insert_drive_file, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getFileName(widget.quote['workquote_file']),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // Add file download/view logic here
              },
              icon: const Icon(Icons.download),
              label: const Text('Download File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: WorkQuoteDetailPage.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  String _getFileName(String path) {
    final parts = path.split('/');
    return parts.isNotEmpty ? parts.last : 'Quote Document';
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
    // Don't show the section if project is completed
    if (widget.quote['work_remark'] == 10) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Work Updates',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddUpdateDialog,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Add Update'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WorkQuoteDetailPage.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (isLoadingUpdates)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (workUpdates.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.engineering_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No work updates yet',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: workUpdates.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final update = workUpdates[index];
                return _buildUpdateItem(update);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildUpdateItem(Map<String, dynamic> update) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.update, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                timeago.format(DateTime.parse(update['created_at'])),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (update['update_detail'] != null && update['update_detail'].isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              update['update_detail'],
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (update['update_image'] != null)
            GestureDetector(
              onTap: () => _showFullImage(update['update_image']),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(update['update_image']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          if (update['update_reply'] != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.comment, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'Client Reply',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(update['update_reply']),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showAddUpdateDialog() async {
    final TextEditingController detailController = TextEditingController();
    PlatformFile? selectedFile;
    bool isUploading = false;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Work Update'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: detailController,
                    decoration: const InputDecoration(
                      labelText: 'Update Details',
                      hintText: 'Enter work update details',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  if (selectedFile != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Selected image: ${selectedFile!.name}',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isUploading
                              ? null
                              : () async {
                                  FilePickerResult? result =
                                      await FilePicker.platform.pickFiles(
                                    type: FileType.image,
                                    allowMultiple: false,
                                  );
                                  if (result != null) {
                                    setState(() {
                                      selectedFile = result.files.first;
                                    });
                                  }
                                },
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Select Image'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: WorkQuoteDetailPage.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isUploading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isUploading || selectedFile == null
                      ? null
                      : () async {
                          setState(() {
                            isUploading = true;
                          });

                          try {
                            // Upload image to Supabase Storage
                            final fileName =
                                '${DateTime.now().millisecondsSinceEpoch}_${selectedFile!.name}';

                            await supabase.storage.from('updates').uploadBinary(
                                  fileName,
                                  selectedFile!.bytes!,
                                );

                            // Get the public URL of the uploaded image
                            final imageUrl = supabase.storage
                                .from('updates')
                                .getPublicUrl(fileName);

                            // Add the update to the database
                            await supabase.from('tbl_updates').insert({
                              'workquote_id': widget.quote['workquote_id'],
                              'update_image': imageUrl,
                              'update_detail': detailController.text.trim(),
                              'created_at': DateTime.now().toIso8601String(),
                            });

                            // Refresh the updates list
                            fetchWorkUpdates();

                            if (!mounted) return;
                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Update added successfully'),
                                backgroundColor: WorkQuoteDetailPage.accentColor,
                              ),
                            );
                          } catch (e) {
                            setState(() {
                              isUploading = false;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error adding update: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WorkQuoteDetailPage.primaryColor,
                  ),
                  child: isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> showWorkersDialog() async {
    List<Map<String, dynamic>> workers = [];
    final remarkController = TextEditingController(text: 'Newly assigned');
    
    try {
      final response = await supabase
          .from('tbl_worker')
          .select('''
            id,
            worker_name,
            worker_photo,
            type_id (
              type_name
            )
          ''');
      workers = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching workers: $e');
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available Workers',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: remarkController,
                    decoration: InputDecoration(
                      labelText: 'Assignment Remark',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ),
                Expanded(
                  child: workers.isEmpty
                      ? const Center(
                          child: Text(
                            'No workers available',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: workers.length,
                          itemBuilder: (context, index) {
                            final worker = workers[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: worker['worker_photo'] != null
                                      ? NetworkImage(worker['worker_photo'])
                                      : null,
                                  child: worker['worker_photo'] == null
                                      ? Text(
                                          worker['worker_name'][0].toUpperCase(),
                                          style: const TextStyle(color: Colors.white),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  worker['worker_name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  worker['type_id']['type_name'] ?? 'No type specified',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      // Start a transaction
                                      
                                      
                                      // Insert worker assignment (without assign_status)
                                      await supabase.from('tbl_assign').insert({
                                        'worker_id': worker['id'],
                                        'workquote_id': widget.quote['workquote_id'],
                                        'assign_remark': remarkController.text.trim()
                                      });

                                      // Update work_remark if current status is 4
                                      if (widget.quote['work_remark'] == 4) {
                                        await supabase
                                            .from('tbl_workquote')
                                            .update({'work_remark': 5})
                                            .eq('workquote_id', widget.quote['workquote_id']);
                                            
                                        // Update local state
                                        widget.quote['work_remark'] = 5;
                                      }

                                     
                                      
                                      if (!mounted) return;
                                      Navigator.of(context).pop();
                                      _fetchWorker(); // Refresh the workers list
                                      setState(() {}); // Refresh the status card
                                      
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Worker assigned successfully'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } catch (e) {
                                      
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error assigning worker: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: WorkQuoteDetailPage.primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Assign'),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

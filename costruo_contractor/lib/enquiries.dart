import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WorkQuoteDetailPage extends StatelessWidget {
  final Map<String, dynamic> quote;

  const WorkQuoteDetailPage({super.key, required this.quote});

  static const Color primaryColor = Color(0xFF1976D2);
  static const Color accentColor = Color(0xFF4CAF50);
  static const Color backgroundGradientStart = Colors.white;
  static const Color backgroundGradientEnd = Color(0xFFE3F2FD);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quote #${quote['enquiry_id']} Details'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [backgroundGradientStart, backgroundGradientEnd],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(),
              const SizedBox(height: 16),
              _buildQuoteInfoCard(),
              const SizedBox(height: 16),
              _buildFileCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    String statusStr = quote['work_remark']?.toString() ?? '';
    String text;
    Color color;
    IconData icon;

    switch (statusStr) {
      case '3':
        text = 'Accepted';
        color = accentColor;
        icon = Icons.check_circle;
        break;
      case '5':
        text = 'Rejected';
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case '6':
        text = 'Pending Review';
        color = Colors.orange;
        icon = Icons.access_time;
        break;
      default:
        text = 'Submitted';
        color = Colors.blueGrey;
        icon = Icons.send;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                Text(
                  text,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
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
            _buildInfoRow(Icons.attach_money, 'Budget', '${quote['workquote_budget']}', Colors.amber.shade700),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.calendar_today, 'Timeline', '${quote['workquote_days']} days', Colors.blue.shade700),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.date_range, 'Submitted', _formatDate(quote['created_at']), Colors.grey.shade700),
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
                    _getFileName(quote['workquote_file']),
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
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
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
}
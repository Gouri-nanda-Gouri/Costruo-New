import 'package:costruo_contractor/enquiries.dart';
import 'package:costruo_contractor/main.dart' as main_supabase;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WorkQuotesPage extends StatefulWidget {
  const WorkQuotesPage({super.key});

  @override
  State<WorkQuotesPage> createState() => _WorkQuotesPageState();
}

class _WorkQuotesPageState extends State<WorkQuotesPage> {
  List<Map<String, dynamic>> workQuotes = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Enhanced color palette
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color accentColor = Color(0xFF4CAF50);
  static const Color backgroundGradientStart = Colors.white;
  static const Color backgroundGradientEnd = Color(0xFFE3F2FD);
  static const Color cardShadowColor = Color(0x1A000000);

  @override
  void initState() {
    super.initState();
    _fetchWorkQuotes();
  }

  Future<void> _fetchWorkQuotes() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final contractorId = main_supabase.supabase.auth.currentUser!.id;
      
      final response = await main_supabase.supabase
          .from('tbl_workquote')
          .select()
          .eq('contractor_id', contractorId)
          .neq('work_remark', 10)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          workQuotes = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error loading work quotes: $e";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ongoing Projects',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
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
        child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _fetchWorkQuotes,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : workQuotes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/empty_quotes.png',
                        height: 120,
                        width: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, obj, st) => const Icon(
                          Icons.assignment_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No work quotes submitted yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your submitted quotes will appear here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchWorkQuotes,
                  color: primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: workQuotes.length,
                    itemBuilder: (context, index) {
                      final quote = workQuotes[index];
                      return _buildQuoteCard(quote);
                    },
                  ),
                ),
      ),
    );
  }

  Widget _buildQuoteCard(Map<String, dynamic> quote) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: cardShadowColor,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkQuoteDetailPage(quote: quote),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Enquiry #${quote['enquiry_id']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      _buildStatusBadge(quote['work_remark']),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          Icons.attach_money,
                          'Budget',
                          '${quote['workquote_budget']}',
                          Colors.amber.shade700,
                        ),
                        const Divider(height: 16),
                        _buildInfoRow(
                          Icons.calendar_today,
                          'Timeline',
                          '${quote['workquote_days']} days',
                          Colors.blue.shade700,
                        ),
                        const Divider(height: 16),
                        _buildInfoRow(
                          Icons.insert_drive_file_outlined,
                          'Quotation',
                          _getFileName(quote['workquote_file']),
                          Colors.green.shade700,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(quote['created_at']),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
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

  Widget _buildStatusBadge(dynamic status) {
    String statusStr = status?.toString() ?? '';
    
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateTime) {
    try {
      final date = DateTime.parse(dateTime).toLocal();
      return DateFormat('MMM dd, yyyy • HH:mm').format(date);
    } catch (e) {
      return 'Date unavailable';
    }
  }
}
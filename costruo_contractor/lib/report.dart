import 'package:costruo_contractor/main.dart';
import 'package:flutter/material.dart';
import 'package:costruo_contractor/main.dart' as main_supabase;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as html;

class Report extends StatefulWidget {
  const Report({super.key});

  @override
  State<Report> createState() => _ReportState();
}

class _ReportState extends State<Report> {
  DateTime? startDate;
  DateTime? endDate;
  bool isLoading = false;
  List<Map<String, dynamic>> reportData = [];
  final currencyFormatter = NumberFormat("#,##0.00", "en_US");

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            colorScheme: const ColorScheme.light(primary: Colors.blue),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  Future<void> generateReport() async {
    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start and end dates')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await main_supabase.supabase
          .from('tbl_workquote')
          .select('''
            *,
            tbl_enquiry (
              enquiry_detail,
              user_id
            ),
            tbl_payment (
              payment_amount,
              payment_status,
              created_at
            )
          ''')
          .gte('created_at', startDate!.toIso8601String())
          .lte('created_at', endDate!.toIso8601String())
          .eq('contractor_id', supabase.auth.currentUser!.id);

      setState(() {
        reportData = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: $e')),
      );
    }
  }

  Future<void> downloadPDF() async {
    final pdf = pw.Document();

    // Calculate totals
    double totalBudget = 0;
    double totalReceived = 0;
    int totalProjects = reportData.length;
    int completedProjects = reportData.where((p) => p['work_remark'] == 10).length;

    for (var project in reportData) {
      totalBudget += double.parse(project['workquote_budget'].toString());
      var payments = List<Map<String, dynamic>>.from(project['tbl_payment']);
      totalReceived += payments
          .where((p) => p['payment_status'] == 'approved')
          .fold(0.0, (sum, payment) => sum + double.parse(payment['payment_amount'].toString()));
    }

    // Add content to PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Work Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Period: ${DateFormat('MMM dd, yyyy').format(startDate!)} - ${DateFormat('MMM dd, yyyy').format(endDate!)}'),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildPDFSummaryItem('Total Projects', totalProjects.toString()),
                _buildPDFSummaryItem('Completed', completedProjects.toString()),
                _buildPDFSummaryItem('Total Budget', '\$${currencyFormatter.format(totalBudget)}'),
                _buildPDFSummaryItem('Received', '\$${currencyFormatter.format(totalReceived)}'),
              ],
            ),
          ),
          pw.SizedBox(height: 30),
          pw.Table.fromTextArray(
            headers: ['Project', 'Budget', 'Status', 'Payments Received'],
            data: reportData.map((project) {
              var payments = List<Map<String, dynamic>>.from(project['tbl_payment']);
              double receivedAmount = payments
                  .where((p) => p['payment_status'] == 'approved')
                  .fold(0.0, (sum, payment) => sum + double.parse(payment['payment_amount'].toString()));
              
              return [
                project['tbl_enquiry']['enquiry_detail'],
                '\$${currencyFormatter.format(double.parse(project['workquote_budget'].toString()))}',
                _getStatusText(project['work_remark']),
                '\$${currencyFormatter.format(receivedAmount)}',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    // Save and download PDF
    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement()
      ..href = url
      ..style.display = 'none'
      ..download = 'work_report_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.pdf';
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  pw.Widget _buildPDFSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  String _getStatusText(int remark) {
    switch (remark) {
      case 10:
        return 'Completed';
      case 9:
        return 'In Progress';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Report'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Date Range',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectDate(context, true),
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Start Date',
                                      border: OutlineInputBorder(),
                                    ),
                                    child: Text(
                                      startDate != null
                                          ? DateFormat('MMM dd, yyyy').format(startDate!)
                                          : 'Select Start Date',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _selectDate(context, false),
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'End Date',
                                      border: OutlineInputBorder(),
                                    ),
                                    child: Text(
                                      endDate != null
                                          ? DateFormat('MMM dd, yyyy').format(endDate!)
                                          : 'Select End Date',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: generateReport,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Generate Report'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              if (reportData.isNotEmpty)
                                ElevatedButton.icon(
                                  onPressed: downloadPDF,
                                  icon: const Icon(Icons.download),
                                  label: const Text('Download PDF'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (reportData.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Project Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Project')),
                            DataColumn(label: Text('Budget')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Payments Received')),
                            DataColumn(label: Text('Start Date')),
                          ],
                          rows: reportData.map((project) {
                            var payments = List<Map<String, dynamic>>.from(project['tbl_payment']);
                            double receivedAmount = payments
                                .where((p) => p['payment_status'] == 'approved')
                                .fold(0.0, (sum, payment) => sum + double.parse(payment['payment_amount'].toString()));
                            
                            return DataRow(
                              cells: [
                                DataCell(Text(project['tbl_enquiry']['enquiry_detail'])),
                                DataCell(Text('\$${currencyFormatter.format(double.parse(project['workquote_budget'].toString()))}')),
                                DataCell(Text(_getStatusText(project['work_remark']))),
                                DataCell(Text('\$${currencyFormatter.format(receivedAmount)}')),
                                DataCell(Text(DateFormat('MMM dd, yyyy').format(DateTime.parse(project['created_at'])))),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (startDate != null && endDate != null)
              const Center(
                child: Text(
                  'No projects found for the selected date range',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

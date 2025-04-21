import 'package:flutter/material.dart';
import 'package:costruo_contractor/main.dart' as main_supabase;

// Assuming Agreement page is in a separate file or defined elsewhere
// If not, you can add the Agreement class here (as provided earlier)
import 'package:costruo_contractor/agreement.dart'; // Import the Agreement page

class EnquiriesPage extends StatefulWidget {
  const EnquiriesPage({super.key});

  @override
  State<EnquiriesPage> createState() => _EnquiriesPageState();
}

class _EnquiriesPageState extends State<EnquiriesPage> {
  List<Map<String, dynamic>> enquiries = [];
  List<Map<String, dynamic>> filteredEnquiries = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchEnquiries();
  }

  Future<void> fetchEnquiries() async {
    try {
      final data = await main_supabase.supabase
          .from('tbl_enquiry')
          .select('*, tbl_user(user_name)');

      setState(() {
        enquiries = (data as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        filteredEnquiries = enquiries;
      });
    } catch (e) {
      _showErrorSnackBar("Error fetching enquiries: $e");
    }
  }

  void _filterEnquiries(String query) {
    setState(() {
      filteredEnquiries = enquiries.where((enquiry) {
        final location = enquiry['enquiry_location']?.toString().toLowerCase() ?? '';
        final contact = enquiry['enquiry_contact']?.toString().toLowerCase() ?? '';
        final detail = enquiry['enquiry_detail']?.toString().toLowerCase() ?? '';
        final userName = enquiry['tbl_user'] != null
            ? (enquiry['tbl_user'] as Map<String, dynamic>)['user_name']
                ?.toString()
                .toLowerCase() ?? ''
            : '';

        return location.contains(query.toLowerCase()) ||
            contact.contains(query.toLowerCase()) ||
            detail.contains(query.toLowerCase()) ||
            userName.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Enquiries",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Enquiries',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filterEnquiries,
            ),
          ),
          Expanded(
            child: filteredEnquiries.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredEnquiries.length,
                    itemBuilder: (context, index) {
                      final enquiry = filteredEnquiries[index];
                      return _buildEnquiryCard(enquiry);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Enquiries Found',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnquiryCard(Map<String, dynamic> enquiry) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: enquiry['enquiry_image'] != null
              ? NetworkImage(enquiry['enquiry_image'] as String)
              : null,
          child: enquiry['enquiry_image'] == null
              ? const Icon(Icons.person_outline)
              : null,
        ),
        title: Text(
          enquiry['tbl_user'] != null
              ? (enquiry['tbl_user'] as Map<String, dynamic>)['user_name']?.toString() ?? 'Unknown User'
              : 'Unknown User',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              enquiry['enquiry_location']?.toString() ?? 'No Location',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              enquiry['enquiry_detail']?.toString() ?? 'No Details',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[800]),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Check if the enquiry is accepted and has a visiting date
          if (enquiry['enquiry_status'] == 1 && enquiry['visiting_date'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VisitDetailsPage(enquiry: enquiry),
              ),
            ).then((_) => fetchEnquiries());
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EnquiryDetailPage(enquiry: enquiry),
              ),
            ).then((_) => fetchEnquiries());
          }
        },
      ),
    );
  }
}

class EnquiryDetailPage extends StatelessWidget {
  final Map<String, dynamic> enquiry;

  const EnquiryDetailPage({super.key, required this.enquiry});

  Future<void> _acceptEnquiry(BuildContext context, DateTime? visitingDate) async {
    try {
      if (enquiry['id'] == null) {
        throw Exception("Enquiry ID is null");
      }

      print("Updating enquiry with ID: ${enquiry['id']} to status 1");
      final updateData = {
        'enquiry_status': 1,
        if (visitingDate != null) 'visiting_date': visitingDate.toIso8601String(),
      };

      final response = await main_supabase.supabase
          .from('tbl_enquiry')
          .update(updateData)
          .match({'id': enquiry['id']});

      print("Update response: $response");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enquiry Accepted!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print("Error accepting enquiry: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error accepting enquiry: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectEnquiry(BuildContext context) async {
    try {
      if (enquiry['id'] == null) {
        throw Exception("Enquiry ID is null");
      }

      print("Updating enquiry with ID: ${enquiry['id']} to status 0");
      final response = await main_supabase.supabase
          .from('tbl_enquiry')
          .update({'enquiry_status': 0})
          .match({'id': enquiry['id']});

      print("Update response: $response");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enquiry Rejected!"),
          backgroundColor: Colors.red,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print("Error rejecting enquiry: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error rejecting enquiry: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Enquiry Details",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEnquiryImage(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        icon: Icons.person,
                        label: "User",
                        value: enquiry['tbl_user'] != null
                            ? (enquiry['tbl_user'] as Map<String, dynamic>)['user_name']?.toString() ?? 'Unknown'
                            : 'Unknown',
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.phone,
                        label: "Contact",
                        value: enquiry['enquiry_contact']?.toString() ?? 'No Contact Info',
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.location_on,
                        label: "Location",
                        value: enquiry['enquiry_location']?.toString() ?? 'No Location',
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.description,
                        label: "Details",
                        value: enquiry['enquiry_detail']?.toString() ?? 'No Details',
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.info,
                        label: "Status",
                        value: enquiry['enquiry_status']?.toString() ?? 'Unknown',
                      ),
                    ],
                  ),
                ),
              ),
            ),
           enquiry['enquiry_status'] == 0 ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final selectedDate = await _showScheduleMeetingDialog(context);
                        if (selectedDate != null) {
                          await _acceptEnquiry(context, selectedDate);
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text("Accept"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectEnquiry(context),
                      icon: const Icon(Icons.close),
                      label: const Text("Reject"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ) : const SizedBox(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEnquiryImage() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        image: enquiry['enquiry_image'] != null
            ? DecorationImage(
                image: NetworkImage(enquiry['enquiry_image'] as String),
                fit: BoxFit.cover,
              )
            : null,
        color: enquiry['enquiry_image'] == null ? Colors.grey[300] : null,
      ),
      child: enquiry['enquiry_image'] == null
          ? const Center(
              child: Icon(
                Icons.image_not_supported,
                size: 80,
                color: Colors.grey,
              ),
            )
          : null,
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class VisitDetailsPage extends StatelessWidget {
  final Map<String, dynamic> enquiry;

  const VisitDetailsPage({super.key, required this.enquiry});

  @override
  Widget build(BuildContext context) {
    // Parse the visiting_date from the enquiry
    final visitingDate = DateTime.tryParse(enquiry['visiting_date']?.toString() ?? '');
    final formattedDate = visitingDate != null
        ? "${visitingDate.day}/${visitingDate.month}/${visitingDate.year}"
        : 'Unknown Date';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Visit Details",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEnquiryImage(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        icon: Icons.calendar_today,
                        label: "Visiting Date",
                        value: formattedDate,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.location_on,
                        label: "Location",
                        value: enquiry['enquiry_location']?.toString() ?? 'No Location',
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.description,
                        label: "Details",
                        value: enquiry['enquiry_detail']?.toString() ?? 'No Details',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // "Next" Button to navigate to the Agreement page
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>  Agreement(enquiryId: enquiry['id'],uid: enquiry['user_id'],), // Navigate to Agreement page
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text("Next"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEnquiryImage() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        image: enquiry['enquiry_image'] != null
            ? DecorationImage(
                image: NetworkImage(enquiry['enquiry_image'] as String),
                fit: BoxFit.cover,
              )
            : null,
        color: enquiry['enquiry_image'] == null ? Colors.grey[300] : null,
      ),
      child: enquiry['enquiry_image'] == null
          ? const Center(
              child: Icon(
                Icons.image_not_supported,
                size: 80,
                color: Colors.grey,
              ),
            )
          : null,
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<DateTime?> _showScheduleMeetingDialog(BuildContext context) async {
  DateTime? selectedDate;

  return showDialog<DateTime?>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            title: const Text(
              "Schedule Meeting",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.blue),
                  title: Text(
                    selectedDate == null
                        ? "Select Date"
                        : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                    style: TextStyle(
                      color: selectedDate == null ? Colors.grey : Colors.black,
                    ),
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.light().copyWith(
                            primaryColor: Colors.blue,
                            hintColor: Colors.blueAccent,
                            colorScheme: const ColorScheme.light(
                              primary: Colors.blue,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (pickedDate != null) {
                      setState(() {
                        selectedDate = pickedDate;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, null); // Return null if canceled
                },
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedDate != null) {
                    Navigator.pop(context, selectedDate); // Return the selected date
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Meeting Scheduled on ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please select a date."),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Confirm"),
              ),
            ],
          );
        },
      );
    },
  );
}
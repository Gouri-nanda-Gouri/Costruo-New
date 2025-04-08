import 'package:costruo_user/enquirydetail.dart';
import 'package:costruo_user/main.dart';
import 'package:flutter/material.dart';
import 'package:costruo_user/main.dart' as main_supabase;

class EnquiriesPage extends StatefulWidget {
  const EnquiriesPage({super.key});

  @override
  State<EnquiriesPage> createState() => _EnquiriesPageState();
}

class _EnquiriesPageState extends State<EnquiriesPage> {
  List<Map<String, dynamic>> enquiries = [];

  @override
  void initState() {
    super.initState();
    fetchEnquiries();
  }

  Future<void> fetchEnquiries() async {
    try {
      final data = await main_supabase.supabase
          .from('tbl_enquiry')
          .select('*, tbl_work(*,tbl_contractor(*))')
          .eq('user_id', supabase.auth.currentUser!.id);

      setState(() {
        enquiries = List<Map<String, dynamic>>.from(data);
      });
      print(enquiries);
    } catch (e) {
      print("Error fetching enquiries: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Enquiries"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Search Enquiries',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (query) {
                setState(() {
                  enquiries = enquiries.where((enquiry) {
                    final location =
                        enquiry['enquiry_location']?.toLowerCase() ?? '';
                    final contact =
                        enquiry['enquiry_contact']?.toLowerCase() ?? '';
                    final detail =
                        enquiry['enquiry_detail']?.toLowerCase() ?? '';
                    return location.contains(query.toLowerCase()) ||
                        contact.contains(query.toLowerCase()) ||
                        detail.contains(query.toLowerCase());
                  }).toList();
                });
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: enquiries.length,
                itemBuilder: (context, index) {
                  final enquiry = enquiries[index];
                  final contractorName = enquiry['tbl_work']?['tbl_contractor']
                          ?['contractor_name'] ??
                      'Unknown Contractor';
                  final status = enquiry['enquiry_status'] ?? 0;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: enquiry['enquiry_image'] != null
                          ? CircleAvatar(
                              backgroundImage:
                                  NetworkImage(enquiry['enquiry_image']),
                            )
                          : const CircleAvatar(child: Icon(Icons.image)),
                      title: Text(
                        contractorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location: ${enquiry['enquiry_location']} - ${enquiry['enquiry_detail']}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (status == 1)
                            Text(
                              'Status: Accepted - Visiting: ${enquiry['visiting_date'] ?? 'TBD'}',
                              style: const TextStyle(color: Colors.green),
                            )
                          else if (status == 3)
                            const Text(
                              'Status: Visited',
                              style: TextStyle(color: Colors.blue),
                            )
                          else
                            const Text(
                              'Status: Pending',
                              style: TextStyle(color: Colors.orange),
                            ),
                        ],
                      ),                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EnquiryDetailPage(
                              enquiry: enquiry,
                              contractorName: contractorName,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EnquiryDetailPage extends StatelessWidget {
  final Map<String, dynamic> enquiry;
  final String contractorName;

  const EnquiryDetailPage({
    super.key,
    required this.enquiry,
    required this.contractorName,
  });

  Future<void> navigateDetails(BuildContext context) async {
    try {
      final response = await supabase.from('tbl_workquote').select().eq('enquiry_id', enquiry['id']).maybeSingle().order('workquote_id',ascending: false).limit(1);
      if(response!.isNotEmpty){
      Navigator.push(context, MaterialPageRoute(builder:(context) => QuoteSummaryPage(qid: response!['workquote_id'],),));

      }
      else{
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Waiting for Contractor to upload the Quotation")));
      }
    } catch (e) {
      print("Error nvi: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = enquiry['enquiry_status'] ?? 0;
    

    return Scaffold(
      appBar: AppBar(title: const Text("Enquiry Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (enquiry['enquiry_image'] != null)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(enquiry['enquiry_image']),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                const SizedBox(
                    height: 200, child: Center(child: Text("No Image"))),
              const SizedBox(height: 16),
              Text(
                "Contractor: $contractorName",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Contact: ${enquiry['enquiry_contact'] ?? 'No Contact Info'}",
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                "Location: ${enquiry['enquiry_location'] ?? 'No Location'}",
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                "Details: ${enquiry['enquiry_detail'] ?? 'No Details'}",
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              if (status == 1)
                Text(
                  "Status: Accepted\nVisiting Day: ${enquiry['visiting_date'] ?? 'To Be Determined'}",
                  style: const TextStyle(fontSize: 18, color: Colors.green),
                )
              else if (status == 3)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Status: Visited",
                      style: TextStyle(fontSize: 18, color: Colors.blue),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        navigateDetails(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue,foregroundColor: Colors.white),
                      child: const Text('Next'),
                    ),
                  ],
                )
              else
                const Text(
                  "Status: Pending",
                  style: TextStyle(fontSize: 18, color: Colors.orange),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

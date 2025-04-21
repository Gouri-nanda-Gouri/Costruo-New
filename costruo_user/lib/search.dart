import 'package:costruo_user/workdetails.dart';
import 'package:flutter/material.dart';
import 'package:costruo_user/main.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  List<Map<String, dynamic>> wData = [];

  Future<void> fetchData() async {
    try {
      final data = await supabase.from('tbl_work').select("*,tbl_contractor(*)");
      setState(() {
        wData = data;
      });
    } catch (e, stacktrace) {
      print("⚠️ Error fetching data: $e");
      print(stacktrace);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: const Text("Search")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextFormField(
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                label: const Text(
                  "Search Contractors",
                  style: TextStyle(color: Colors.black),
                ),
                suffixIcon:
                    const Icon(Icons.search_rounded, color: Colors.black),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.black, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: wData.length,
              itemBuilder: (context, index) {
                final work = wData[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkDetailPage(
                          title: work['work_title'] ?? 'No Title',
                          description: work['work_desc'] ?? 'No Description',
                          budget: work['work_budget']?.toString() ?? 'N/A',
                          loctn: work['work_location'] ?? 'Unknown',
                          image: work['work_gallery'] ?? '',
                          workId: work['work_id'] ?? 0,
                          contractor: work['tbl_contractor'],
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            image: DecorationImage(
                              image: NetworkImage(work['work_gallery'] ?? ''),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          work['work_title'] ?? 'No Title',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


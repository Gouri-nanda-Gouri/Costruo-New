import 'package:costruo_admin/components/page_loader.dart';
import 'package:costruo_admin/main.dart';
import 'package:flutter/material.dart';

class Place extends StatefulWidget {
  const Place({super.key});

  @override
  State<Place> createState() => _PlaceState();
}

class _PlaceState extends State<Place> {
  TextEditingController placeController = TextEditingController();
  List<Map<String, dynamic>> districtlist = [];
  bool _isLoading = true;
  String _selectedDist = "";

  @override
  void initState() {
    super.initState();
    fetchdistrict();
    fetchplace();
  }

  Future<void> fetchdistrict() async {
    try {
      final response = await supabase.from("tbl_district").select();
      print(response);
      setState(() {
        districtlist = response;
      });
    } catch (e) {}
  }

  List<Map<String, dynamic>> plcData = [];

  int eid = 0;

  Future<void> insert() async {
    try {
      String place = placeController.text;
      await supabase
          .from('tbl_place')
          .insert({'place_name': place, 'district_id': _selectedDist});
      print("Place Inserted Successfully");
      fetchplace();  // Refresh the data after inserting
    } catch (e) {
      print("Error:$e");
    }
  }

  Future<void> fetchplace() async {
    try {
      final data = await supabase.from("tbl_place").select();
      setState(() {
        plcData = data;
        _isLoading = false;
      });
    } catch (e) {
      print("Error in selecting $e");
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const PageLoader()
        : Form(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField(
                          decoration: InputDecoration(
                            hintText: 'District',
                            hintStyle: TextStyle(color: Colors.white),
                            filled: true,
                            fillColor: Color.fromARGB(255, 177, 172, 172),
                          ),
                          items: districtlist.map((dist) {
                            return DropdownMenuItem(
                              value: dist['id'].toString(),
                              child: Text(dist['district_name']),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedDist = value!;
                            });
                          }),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: placeController,
                        decoration: InputDecoration(
                          hintText: 'Place',
                          hintStyle: TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: Color.fromARGB(255, 177, 172, 172),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    ElevatedButton(
                        onPressed: () {
                          insert();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal, // Background color
                          foregroundColor: Colors.white, // Text color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text("Submit")),
                  ],
                ),
                SizedBox(height: 20),
                DataTable(
                  columns: [
                    DataColumn(label: Text('SNO')),
                    DataColumn(label: Text('District')),
                    DataColumn(label: Text('Place')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: plcData.asMap().entries.map((entry) {
                    int index = entry.key + 1;
                    var data = entry.value;
                    return DataRow(cells: [
                      DataCell(Text(index.toString())),
                      DataCell(Text(districtlist.firstWhere((dist) => dist['id'] == data['district_id'], orElse: () => {'district_name': 'Unknown'})['district_name'])),
                      DataCell(Text(data['place_name'])),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              // Add edit functionality here
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              // Add delete functionality here
                              deletePlace(data['id']);
                            },
                          ),
                        ],
                      )),
                    ]);
                  }).toList(),
                ),
              ],
            ),
          );
  }

  Future<void> deletePlace(int id) async {
    try {
      await supabase.from('tbl_place').delete().eq('id', id);
      print("Place deleted successfully");
      fetchplace();  // Refresh data after deletion
    } catch (e) {
      print("Error in deleting place: $e");
    }
  }
}

import 'package:costruo_admin/components/form_validation.dart';
import 'package:costruo_admin/components/loader.dart';
import 'package:costruo_admin/components/page_loader.dart';
import 'package:costruo_admin/main.dart';
import 'package:flutter/material.dart';

class District extends StatefulWidget {
  const District({super.key});

  @override
  State<District> createState() => _DistrictState();
}

class _DistrictState extends State<District> {

  final _formKey = GlobalKey<FormState>();

  TextEditingController districtController = TextEditingController();

  bool _isLoading = true;

  Future<void> insertData() async {
    Loader.showLoader(context);
    try {
      String district = districtController.text;
      await supabase.from('tbl_district').insert({'district_name': district});
      print("District Inserted Successfull");
      Loader.hideLoader(context);
    } catch (e) {
      Loader.hideLoader(context);
      print("Error adding district: $e");
    }
  }

  List<Map<String, dynamic>> disData = [];
  Future<void> fetchData() async {
    try {
      final data = await supabase.from('tbl_district').select();
      fetchData();
      setState(() {
        disData = data;
      });
      setState(() {
        _isLoading=false;
      });
    } catch (e) {
      setState(() {
        _isLoading=false;
      });
      print("Error in selecting $e");
    }
  }

  Future<void> deletedist(int id) async {
    try {
      await supabase.from('tbl_district').delete().eq('id', id);
      print("Deleted");
      fetchData();
    } catch (e) {
      print("Error in deleting$e");
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchData();
  }

  int eid = 0;

  Future<void> _editdistrict() async {
    try {
      await supabase
          .from("tbl_district")
          .update({'district_name': districtController.text}).eq('id', eid);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Updated")));
    } catch (e) {
      print("Error $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading ? const PageLoader() : Form(
      key: _formKey,
      child: Center(
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color.fromARGB(
                255, 212, 227, 222), // Background color for the container
            borderRadius: BorderRadius.circular(15),
            // Rounded corners
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                validator: (value) => FormValidation.validateTextField(value),
                controller: districtController,
                decoration: InputDecoration(
                  hintText: 'Enter District',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Color.fromARGB(255, 177, 172, 172),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Center(
                child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (eid == 0) {
                          insertData();
                        } else {
                          _editdistrict();
                        }
                      }
                    },
                     style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal, // Background color
                        foregroundColor: Colors.white, // Text color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    child: Text("Submit")),
              ),
               const SizedBox(height: 20),
          const Text(
            "Districts List",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                itemCount: disData.length,
                itemBuilder: (context, index) {
                  final data = disData[index];
                  return ListTile(
                      leading: Text((index + 1).toString(),
                          style: TextStyle(color: Colors.black)),
                      title: Text(data['district_name'],
                          style: TextStyle(color: Colors.black)),
                      trailing: SizedBox(
                        width: 100,
                        child: Row(
                          children: [
                            IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.teal),
                          onPressed: () {
                            setState(() {
                              eid = data['id'];
                              districtController.text = data['district_name'];
                            });
                          },
                        ),
                             IconButton(
                          icon: const Icon(Icons.edit, color: Colors.teal),
                          onPressed: () {
                            setState(() {
                              eid = data['id'];
                              districtController.text = data['district_name'];
                            });
                          },
                        ),
                          ],
                        ),
                      ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

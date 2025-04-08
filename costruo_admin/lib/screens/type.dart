import 'package:costruo_admin/components/form_validation.dart';
import 'package:costruo_admin/main.dart';
import 'package:flutter/material.dart';

class Types extends StatefulWidget {
  const Types({super.key});

  @override
  State<Types> createState() => _TypesState();
}

class _TypesState extends State<Types> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController typeController = TextEditingController();
  Future<void> insert() async {
    try {
      String category = typeController.text;
      print(category);
      await supabase.from('tbl_type').insert({'type_name': category});
      print("Type Inserted");
      fetchdata();
    } catch (e) {
      print("Error inserting type_name:$e");
    }
  }

  List<Map<String, dynamic>> TypeData = [];

  Future<void> fetchdata() async {
    try {
      final data = await supabase.from('tbl_type').select();
      print(data);
      setState(() {
        TypeData = data;
      });
    } catch (e) {
      print("Error inserting type $e");
    }
  }

  Future<void> deletecate(int id) async {
    try {
      await supabase.from('tbl_type').delete().eq('id', id);
      print("Deleted");
    } catch (e) {}
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchdata();
  }

  int eid = 0;
  Future<void> editType() async {
    try {
      await supabase
          .from('tbl_type')
          .update({'type_name': typeController.text}).eq('id', eid);
      print("Deleted");
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
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
              controller: typeController,
              decoration: InputDecoration(
                hintText: 'Enter Type',
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
                        insert();
                      } else {
                        editType();
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
            const Text(
              " Types",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: TypeData.length,
              itemBuilder: (context, index) {
              final data = TypeData[index];
              return ListTile(
                  leading: Text((index + 1).toString(),
                          style: TextStyle(color: Colors.black)),
                      title: Text(data['type_name'],
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
                              typeController.text = data['type_name'];
                            });
                          },
                        ),
                             IconButton(
                          icon: const Icon(Icons.edit, color: Colors.teal),
                          onPressed: () {
                            setState(() {
                              eid = data['id'];
                              typeController.text = data['type_name'];
                            });
                          },
                        ),
                          ],
                        ),
                        )
              );
            },)
          ],
        ),
      ),
    );
  }
}

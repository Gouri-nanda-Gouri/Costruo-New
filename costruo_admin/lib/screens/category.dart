import 'package:costruo_admin/components/form_validation.dart';
import 'package:costruo_admin/main.dart';
import 'package:flutter/material.dart';

class Category extends StatefulWidget {
  const Category({super.key});

  @override
  State<Category> createState() => _CategoryState();
}

class _CategoryState extends State<Category> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController categoryController=TextEditingController();
    Future<void> insert() async {
    try {
      String category = categoryController.text;
      print(category);
      await supabase.from('tbl_category').insert({'category_name': category});
      print("Category Inserted");
      fetchdata();
    } catch (e) {
      print("Error inserting Category:$e");
    }
  }
  
  List<Map<String, dynamic>> catData = [];

  Future<void> fetchdata() async {
    try {
      final data = await supabase.from('tbl_category').select();
      print(data);
      setState(() {
        catData = data;
      });
    } catch (e) {
      print("Error inserting category $e");
    }
  }
  Future<void> deletecate(int id)
  async {
    try {
    await supabase.from('tbl_category').delete().eq('id', id);
    print("Deleted");  
    } catch (e) {
      
    }
  }
    @override

  void initState() {
    // TODO: implement initState
    super.initState();
    fetchdata();
  }
   int eid=0;
  Future<void> editcate()
  async {
    try {
      await supabase.from('tbl_category').update({'category_name':categoryController.text}).eq('id', eid);
    print("Deleted");  
    } catch (e) {
      
    }
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
              controller: categoryController,
              decoration: InputDecoration(
                hintText: 'Enter Category',
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
                        if(eid==0)
                        {
                          insert();
                        }
                        else
                        {
                          editcate();
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
            " Categories",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
           const SizedBox(height: 8),
           ListView.builder(
            shrinkWrap: true,
                itemCount: catData.length,
            itemBuilder: (context, index) {
              final data = catData[index];
             return ListTile(
                 leading: Text((index + 1).toString(),
                          style: TextStyle(color: Colors.black)),
                      title: Text(data['category_name'],
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
                              categoryController.text = data['category_name'];
                            });
                          },
                        ),
                             IconButton(
                          icon: const Icon(Icons.edit, color: Colors.teal),
                          onPressed: () {
                            setState(() {
                              eid = data['id'];
                              categoryController.text = data['category_name'];
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

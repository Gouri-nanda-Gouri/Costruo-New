import 'package:costruo_contractor/main.dart';
import 'package:flutter/material.dart';

class AssignWorker extends StatefulWidget {
  const AssignWorker({super.key});

  @override
  State<AssignWorker> createState() => AssignWorkerState();
}

class AssignWorkerState extends State<AssignWorker> {
  List<Map<String, dynamic>> typelist = [];
  List<Map<String, dynamic>> workers = [];
  String _selectedType = "";

  @override
  void initState() {
    super.initState();
    fetchTypes();
  }

  Future<void> fetchTypes() async {
    try {
      final response = await supabase.from("tbl_type").select();
      setState(() {
        typelist = response;
      });
    } catch (e) {
      print("Error fetching types: $e");
    }
  }

  Future<void> fetchWorkers(String typeId) async {
    try {
      final response = await supabase
          .from("tbl_worker")
          .select('worker_name, worker_photo, tbl_type(type_name)')
          .eq('type_id', typeId);
      setState(() {
        workers = response;
      });
    } catch (e) {
      print("Error fetching workers: $e");
    }
  }

  void assignWorker(String workerName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Assigned $workerName to type[$_selectedType]'),
      ),
    );
  }
  Future<void> assignWork(String workerId) async {
    try {
      final response = await supabase.from("tbl_assign").insert({
        "worker_id": workerId,
        //"type_id": typeId,
      });
      print("Worker assigned successfully: $response");
    } catch (e) {
      print("Error assigning worker: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButtonFormField<String>(
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                labelText: 'Skill Type',
                labelStyle: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(
                    color: Colors.blue[400]!,
                    width: 2,
                  ),
                ),
                errorBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(
                    color: Colors.redAccent,
                    width: 1,
                  ),
                ),
                focusedErrorBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(
                    color: Colors.redAccent,
                    width: 2,
                  ),
                ),
              ),
              value: _selectedType.isEmpty ? null : _selectedType,
              items: typelist.map((type) {
                return DropdownMenuItem<String>(
                  value: type['id'].toString(),
                  child: Text(
                    type['type_name'] ?? 'Unknown Type',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                    fetchWorkers(_selectedType);
                  });
                }
              },
              dropdownColor: Colors.white,
              icon: Icon(
                Icons.arrow_drop_down,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: workers.isEmpty
                  ? const Center(
                      child: Text(
                        'Select a skill type to see workers',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: workers.length,
                      itemBuilder: (context, index) {
                        final worker = workers[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundImage: worker['worker_photo'] != null
                                  ? NetworkImage(worker['worker_photo'])
                                  : const AssetImage('assets/default_avatar.png')
                                      as ImageProvider,
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    worker['worker_name'] ?? 'Unnamed Worker',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    assignWorker(
                                        worker['worker_name'] ?? 'Unnamed Worker');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[400],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 2,
                                    textStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  child: const Text('Assign'),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              worker['tbl_type']?['type_name'] ?? 'No Type',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
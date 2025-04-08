import 'package:flutter/material.dart';
import '../main.dart';

class Contractor extends StatefulWidget {
  const Contractor({super.key});

  @override
  State<Contractor> createState() => _ContractorState();
}

class _ContractorState extends State<Contractor> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchContractors();
  }

  List<Map<String, dynamic>> contractors = [];
  Future<void> fetchContractors() async {
    try {
      final response = await supabase.from("tbl_contractor").select("*,tbl_place(*,tbl_district(*))");
      setState(() {
        contractors = response;
      });
    } catch (e) {
      print("Contractor data failed: $e");
    }
  }

  Future<void> updateStatus(String id, int status) async {
    try {
      await supabase.from("tbl_contractor").update({'contractor_vstatus': status}).eq('id', id);
      fetchContractors();
    } catch (e) {
      print("Error updating status: $e");
    }
  }

  List<Map<String, dynamic>> filterContractors(int status) {
    return contractors.where((c) => c['contractor_vstatus'] == status).toList();
  }

  Widget buildContractorTable(List<Map<String, dynamic>> contractorList, int status) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('SNO')),
        DataColumn(label: Text('Photo')),
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Email')),
        DataColumn(label: Text('Contact')),
        DataColumn(label: Text('Address')),
        DataColumn(label: Text('District')),
        DataColumn(label: Text('Place')),
        DataColumn(label: Text('Actions')),
      ],
      rows: contractorList.asMap().entries.map((entry) {
        int index = entry.key + 1;
        var contractor = entry.value;
        return DataRow(cells: [
          DataCell(Text(index.toString())),
          DataCell(CircleAvatar(
            backgroundImage: NetworkImage(contractor['contractor_photo']),
          )),
          DataCell(Text(contractor['contractor_name'])),
          DataCell(Text(contractor['contractor_email'])),
          DataCell(Text(contractor['contractor_contact'])),
          DataCell(Text(contractor['contractor_address'])),
          DataCell(Text(contractor['tbl_place']['tbl_district']['district_name'])),
          DataCell(Text(contractor['tbl_place']['place_name'])),
          DataCell(Row(
            children: [
              if (status == 0) ...[ // New Contractors
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                  onPressed: () => updateStatus(contractor['id'], 1),
                ),
                IconButton(
                  icon: const Icon(Icons.not_interested_rounded, color: Colors.red),
                  onPressed: () => updateStatus(contractor['id'], 2),
                ),
              ] else if (status == 1) ...[ // Verified Contractors
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: () => updateStatus(contractor['id'], 2),
                ),
              ] else if (status == 2) ...[ // Rejected Contractors
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.green),
                  onPressed: () => updateStatus(contractor['id'], 1),
                ),
              ]
            ],
          )),
        ]);
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "New Contractors"),
            Tab(text: "Verified Contractors"),
            Tab(text: "Rejected Contractors"),
          ],
        ),
        SizedBox(
          height: 500,
          child: TabBarView(
            viewportFraction: 1,
            controller: _tabController,
            children: [
              buildContractorTable(filterContractors(0), 0),
              buildContractorTable(filterContractors(1), 1),
              buildContractorTable(filterContractors(2), 2),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

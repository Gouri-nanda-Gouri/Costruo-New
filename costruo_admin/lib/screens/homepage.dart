import 'package:costruo_admin/components/appbar.dart';
import 'package:costruo_admin/components/sidebar.dart';
import 'package:costruo_admin/screens/category.dart';
import 'package:costruo_admin/screens/contractor.dart';
import 'package:costruo_admin/screens/dashbord.dart';
import 'package:costruo_admin/screens/district.dart';
import 'package:costruo_admin/screens/place.dart';
import 'package:costruo_admin/screens/type.dart';
import 'package:costruo_admin/screens/viewcomplaint.dart';
import 'package:flutter/material.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    Dashbord(),
    District(),
    Place(),
    Category(),
    Types(),
    Contractor(),
    ViewComplaintsAdminPage(),
  ];

  void onSidebarItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
   @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFFFFFFFF),
        body: Row(
          children: [
            Expanded(
                flex: 1,
                child: MySideBar(
                  onItemSelected: onSidebarItemTapped,
                )),
            Expanded(
              flex: 5,
              child: ListView(
                children: [
                  MyAppBar(),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: _pages[_selectedIndex],
                  ),
                ],
              ),
            )
          ],
        ));
  }
}
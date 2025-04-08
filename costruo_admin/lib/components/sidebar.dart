import 'package:flutter/material.dart';

class MySideBar extends StatefulWidget {
  final Function(int) onItemSelected;
  const MySideBar({super.key, required this.onItemSelected});

  @override
  State<MySideBar> createState() => _MySideBarState();
}

class _MySideBarState extends State<MySideBar> {
  final List<String> pages = [
    "Dashboard",
    "District",
    "Place",
    "Category",
    "Type",
    "Contractors"

  ];

  final List<IconData> icons = [
    Icons.home_outlined, 
    Icons.data_saver_on_outlined,
    Icons.data_saver_on_outlined,
    Icons.dashboard_customize_outlined,
     Icons.dashboard_customize_outlined,
     Icons.person_add_alt_1_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:  const Color(0xFF18795B),
    //       gradient: LinearGradient(colors: [
    //    ,
    //     const Color.fromARGB(255, 43, 43, 43)
    //   ], 
    //  )
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                    'assets/logo.png', // Path to your logo
                    height: 200, // Adjust the size of the logo
                    width: 200, // Adjust width if necessary
                  ),
              SizedBox(height: 50),
              ListView.builder(
                  shrinkWrap: true,
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: () {
                        widget.onItemSelected(index);
                      },
                      leading: Icon(icons[index], color: Colors.white),
                      title: Text(pages[index],
                          style: TextStyle(color: Colors.white)),
                    );
                  }),
            ],
          ),
          ListTile(
            leading: Icon(Icons.logout_outlined, color: Colors.white),
            title: Text(
              "Logout",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
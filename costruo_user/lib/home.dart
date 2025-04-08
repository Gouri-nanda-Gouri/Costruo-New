import 'dart:async';
import 'package:costruo_user/main.dart' as main_supabase;
import 'package:costruo_user/profile.dart';
import 'package:costruo_user/search.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  PageController _pageController = PageController(viewportFraction: 0.9);
  int currentPage = 0;

  List<Map<String,dynamic>> bannerImages = [];

  @override
  void initState() {
    super.initState();
    startAutoScroll();
    fetchData();
    fetchwork();
  }

 Future<void> fetchwork() async {
  try {
    final data = await main_supabase.supabase.from('tbl_work').select();
    setState(() {
      bannerImages = List<Map<String, dynamic>>.from(data);
    });
  } catch (e) {
    print("Error fetching data: $e");
  }
}

  void startAutoScroll() {
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (currentPage < bannerImages.length - 1) {
        currentPage++;
      } else {
        currentPage = 0;
      }
      _pageController.animateToPage(
        currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  List<dynamic> userData = [];

  Future<void> fetchData() async {
    try {
      final data = await main_supabase.supabase.from('tbl_user').select().limit(1);
      setState(() {
        userData = data;
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              "Costruo",
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'serif',
              ),
            ),
            const Spacer(),
            Text(
              "Hello ${userData.isNotEmpty ? userData[0]['user_name'] ?? 'Guest' : 'Loading...'}",
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'serif',
              ),
            ),
          ],
        ),
      ),
      body: _getPage(_selectedIndex), // This controls which page is shown
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home",
              backgroundColor: Colors.black),
          BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: "Search",
              backgroundColor: Colors.black),
          BottomNavigationBarItem(
              icon: Icon(Icons.work),
              label: "Projects",
              backgroundColor: Colors.black),
          BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Profile",
              backgroundColor: Colors.black),
        ],
      ),
    );
  }

  /// This method controls the content for each tab
  Widget _getPage(int index) {
  switch (index) {
    case 0: // Home Page
      return Column(
        children: [
          const SizedBox(
            height: 20,
          ),
          SizedBox(
            height: 150,
            child: PageView.builder(
              controller: _pageController,
              itemCount: bannerImages.length, // Correct the count
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Image.network(
                    bannerImages[index]['work_gallery'], // Correctly access the image URL
                    fit: BoxFit.cover,
                  ),
                );
              },
              onPageChanged: (index) {
                setState(() {
                  currentPage = index;
                });
              },
            ),
          ),
          const SizedBox(height: 20),
          const Expanded(
            child: Center(
              child: Text("Home Page Content",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          
        ],
      );

    case 1:
      return  Search();

    case 2:
      return const Center(
        child: Text("Projects Page",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      );

    case 3:
      return const Profile();

    default:
      return const Home();
  }
}
}

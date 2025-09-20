import 'package:flutter/material.dart';
import '../admin/adminDashboard.dart';
import '../admin/studentManagement.dart';
import '../admin/addCurriculum.dart';
import '../admin/quizManagement.dart';
import '../admin/settings.dart';

void main() {
  runApp(MaterialApp(home: AdminNav(initialIndex: 0)));
}

class AdminNav extends StatefulWidget {
  final int initialIndex;
  const AdminNav({super.key, this.initialIndex = 0});

  @override
  State<AdminNav> createState() => _AdminNavState();
}

class _AdminNavState extends State<AdminNav> {
  late int _selectedIndex;

  final List<Widget> _pages = const [
    AdminDashboard(),
    StudentManagementPage(),
    CurriculumPage(),
    QuizManagementPage(),
    AdminSettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.white,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Curriculum',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Quizzes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

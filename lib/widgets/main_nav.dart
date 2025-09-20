import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../providers/auth_provider.dart';
import '../screens/home.dart';
import '../screens/Subject_Screen/subjectsPage.dart';
import '../screens/AITutor/aiTutor.dart';
// import '../screens/Progress.dart';
import '../screens/settings.dart';
import '../screens/Quiz_Screen/quizzes_page.dart';

class MainNav extends ConsumerStatefulWidget {
  final int initialIndex;
  const MainNav({this.initialIndex = 0, super.key});

  @override
  ConsumerState<MainNav> createState() => _MainNavState();
}

class _MainNavState extends ConsumerState<MainNav> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      const DashboardPage(),
      SubjectsPage(),
      const AiTutorPage(),
      const QuizzesPage(), // <-- new global tab at index 3 (adjust order as desired)
      // const ProgressPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: 'Subjects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_outlined),
            activeIcon: Icon(Icons.smart_toy),
            label: 'AI Tutor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz_outlined),
            activeIcon: Icon(Icons.quiz),
            label: 'Quizzes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

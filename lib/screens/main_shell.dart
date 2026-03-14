import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'adopt_screen.dart';
import 'programs_screen.dart';
import 'contact_screen.dart';
import 'parent_feedback_screen.dart';
import 'about_us_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    AdoptScreen(),
    ProgramsScreen(),
    ParentFeedbackScreen(),
    AboutUsScreen(),
    ContactScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.favorite_border),
      activeIcon: Icon(Icons.favorite_rounded),
      label: 'Adopt',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.school_outlined),
      activeIcon: Icon(Icons.school_rounded),
      label: 'Programs',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.forum_outlined),
      activeIcon: Icon(Icons.forum_rounded),
      label: 'Stories',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.info_outline),
      activeIcon: Icon(Icons.info_rounded),
      label: 'About',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.mail_outline),
      activeIcon: Icon(Icons.mail_rounded),
      label: 'Contact',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          items: _navItems,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

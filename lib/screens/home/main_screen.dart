import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:strive_campus/screens/home/home_screen.dart';
import 'package:strive_campus/screens/campus/campus_screen.dart';
import 'package:strive_campus/screens/analytics/analytics_screen.dart';
import 'package:strive_campus/screens/home/profile_screen.dart';
import 'package:strive_campus/screens/aptitude/aptitude_home_screen.dart';
import 'package:strive_campus/screens/technical/technical_home_screen.dart';
import 'package:strive_campus/screens/hr/hr_home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

@override
void initState() {
  super.initState();
  _screens = [
    HomeScreen(onNavigateToTab: _navigateToTab),
    const TechnicalTabScreen(),
    const CampusScreen(),
    const AnalyticsScreen(),
    const ProfileScreen(),
  ];
}

void _navigateToTab(int index) {
  setState(() => _currentIndex = index);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz_outlined),
            activeIcon: Icon(Icons.quiz),
            label: 'Tests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Campus',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class TestsPlaceholder extends StatelessWidget {
  const TestsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: Center(
        child: Text(
          'Tests\nComing soon!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, color: Color(0xFF1A1A2E)),
        ),
      ),
    );
  }
}

class ProfilePlaceholder extends StatelessWidget {
  const ProfilePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: Center(
        child: Text(
          'Profile\nComing soon!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, color: Color(0xFF1A1A2E)),
        ),
      ),
    );
  }
}

class TechnicalTabScreen extends StatefulWidget {
  const TechnicalTabScreen({super.key});

  @override
  State<TechnicalTabScreen> createState() => _TechnicalTabScreenState();
}

class _TechnicalTabScreenState extends State<TechnicalTabScreen> {
  String department = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDept();
  }

  Future<void> _loadDept() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        if (mounted) {
          setState(() {
            department = doc.data()!['department'] ?? '';
            isLoading = false;
          });
        }
        return;
      }
    }
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
      );
    }

    final bool showTech = department != 'Civil Engineering' && department != 'MBA';

    return DefaultTabController(
      length: showTech ? 3 : 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          title: Text(
            'Tests',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: [
              const Tab(text: 'Aptitude'),
              if (showTech) const Tab(text: 'Technical'),
              const Tab(text: 'HR'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const AptitudeHomeScreen(),
            if (showTech) const TechnicalHomeScreen(),
            const HRHomeScreen(),
          ],
        ),
      ),
    );
  }
}

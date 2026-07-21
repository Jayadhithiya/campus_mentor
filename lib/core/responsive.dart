import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart' show themeNotifier;
import '../screens/home/notifications_screen.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.desktop,
  });

  static const double mobileBreakpoint = 800.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isWeb(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= mobileBreakpoint) {
          return desktop;
        }
        return mobile;
      },
    );
  }
}

class WebDesktopShell extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final Widget child;

  const WebDesktopShell({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.child,
  });

  static const List<_NavItem> _navItems = [
    _NavItem('Home', Icons.home_outlined, Icons.home),
    _NavItem('Tests', Icons.quiz_outlined, Icons.quiz),
    _NavItem('Campus', Icons.school_outlined, Icons.school),
    _NavItem('Analytics', Icons.bar_chart_outlined, Icons.bar_chart),
    _NavItem('Profile', Icons.person_outline, Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141428) : const Color(0xFFF5F7FA),
      body: Row(
        children: [
          // Desktop Left Navigation Sidebar
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(
                right: BorderSide(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header / Branding
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'StriveCampus',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: onSurface,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'AI STUDY PARTNER',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Section Label
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Text(
                    'MAIN MENU',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: onSurface.withValues(alpha: 0.4),
                      letterSpacing: 1.0,
                    ),
                  ),
                ),

                // Navigation Items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _navItems.length,
                    itemBuilder: (context, index) {
                      final item = _navItems[index];
                      final isSelected = currentIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => onIndexChanged(index),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryColor.withValues(alpha: 0.12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(
                                        color: primaryColor.withValues(alpha: 0.3),
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? item.activeIcon : item.icon,
                                    size: 22,
                                    color: isSelected
                                        ? primaryColor
                                        : onSurface.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? primaryColor
                                          : onSurface.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  if (isSelected) const Spacer(),
                                  if (isSelected)
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const Divider(height: 1),
                // Footer Controls: Theme Toggle & Account Quick Action
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Theme Switcher Tile
                      InkWell(
                        onTap: () async {
                          final newMode =
                              isDark ? ThemeMode.light : ThemeMode.dark;
                          themeNotifier.value = newMode;
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('isDark', newMode == ThemeMode.dark);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1F1F3D)
                                : const Color(0xFFF0F4F8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isDark ? Icons.dark_mode : Icons.light_mode,
                                size: 20,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                isDark ? 'Dark Theme' : 'Light Theme',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: onSurface,
                                ),
                              ),
                              const Spacer(),
                              Switch(
                                value: isDark,
                                activeThumbColor: primaryColor,
                                onChanged: (val) async {
                                  final newMode =
                                      val ? ThemeMode.dark : ThemeMode.light;
                                  themeNotifier.value = newMode;
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setBool('isDark', val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Workspace Area
          Expanded(
            child: Column(
              children: [
                // Top Web Bar
                Container(
                  height: 68,
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _navItems[currentIndex].label,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                      ),
                      const Spacer(),
                      // Notification Bell
                      IconButton(
                        tooltip: 'Notifications',
                        icon: Icon(
                          Icons.notifications_none_outlined,
                          color: onSurface.withValues(alpha: 0.7),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      // User Profile Avatar Chip
                      StreamBuilder<User?>(
                        stream: FirebaseAuth.instance.userChanges(),
                        builder: (context, snapshot) {
                          final user = snapshot.data;
                          final email = user?.email ?? 'User';
                          final initial = email.isNotEmpty ? email[0].toUpperCase() : 'U';

                          return InkWell(
                            onTap: () => onIndexChanged(4), // Go to Profile
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1F1F3D)
                                    : const Color(0xFFF0F4F8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: primaryColor,
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    email.split('@')[0],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Main Content View with max-width container
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1350),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem(this.label, this.icon, this.activeIcon);
}

import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

class InAppNotificationService {
  static List<Map<String, dynamic>> getBaseNotifications() => [
        {
          'id': '1',
          'title': 'Attendance Warning!',
          'desc': 'DBMS attendance is at 68%. Attend next class!',
          'time': '2 mins ago',
          'icon': Icons.warning_amber_outlined,
          'color': const Color(0xFFF59E0B),
          'bg': const Color(0xFFFEF3C7),
          'read': false,
          'group': 'Today',
        },
        {
          'id': '2',
          'title': 'Assignment Due Tomorrow',
          'desc': 'OS Assignment is due tomorrow at 11:59 PM.',
          'time': '1 hour ago',
          'icon': Icons.assignment_outlined,
          'color': const Color(0xFFEF4444),
          'bg': const Color(0xFFFEE2E2),
          'read': false,
          'group': 'Today',
        },
        {
          'id': '3',
          'title': 'AI Study Tip',
          'desc': 'Practice Binary Trees � it\'s your weak area this week.',
          'time': '3 hours ago',
          'icon': Icons.lightbulb_outline,
          'color': const Color(0xFF45B08C),
          'bg': const Color(0xFFEEEDFE),
          'read': false,
          'group': 'Today',
        },
        {
          'id': '4',
          'title': 'Test Result',
          'desc': 'Great job! You scored 84% in Aptitude today.',
          'time': '5 hours ago',
          'icon': Icons.emoji_events_outlined,
          'color': const Color(0xFF22C55E),
          'bg': const Color(0xFFDCFCE7),
          'read': true,
          'group': 'Today',
        },
        {
          'id': '5',
          'title': 'Streak Reminder',
          'desc': 'Don\'t break your streak! Take a test today.',
          'time': 'Yesterday',
          'icon': Icons.local_fire_department_outlined,
          'color': const Color(0xFFFF6B6B),
          'bg': const Color(0xFFFFF1F1),
          'read': true,
          'group': 'Yesterday',
        },
        {
          'id': '6',
          'title': 'New AI Questions Ready',
          'desc': 'Fresh DSA questions generated for you. Start practicing!',
          'time': 'Yesterday',
          'icon': Icons.auto_awesome_outlined,
          'color': const Color(0xFF7C3AED),
          'bg': const Color(0xFFEDE9FE),
          'read': true,
          'group': 'Yesterday',
        },
      ];
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  int _getWeekNumber(DateTime date) {
    int dayOfYear = int.parse(
        date.difference(DateTime(date.year, 1, 1)).inDays.toString());
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    
    final currentWeek = _getWeekNumber(DateTime.now());
    final savedWeek = prefs.getInt('current_week') ?? currentWeek;
    
    // Automatically reset each week
    if (currentWeek != savedWeek) {
      await prefs.setStringList('read_notification_ids', []);
      await prefs.setStringList('cleared_notification_ids', []);
      await prefs.setInt('current_week', currentWeek);
    }
    
    final readIds = prefs.getStringList('read_notification_ids') ?? [];
    final clearedIds = prefs.getStringList('cleared_notification_ids') ?? [];
    
    final baseNots = InAppNotificationService.getBaseNotifications();
    final filteredNots = baseNots.where((n) => !clearedIds.contains(n['id'])).toList();

    for (var n in filteredNots) {
      if (readIds.contains(n['id'])) {
        n['read'] = true;
      }
    }
    
    setState(() {
      notifications = filteredNots;
    });
  }

  Future<void> _markAllRead() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> readIds = [];
    
    setState(() {
      for (var n in notifications) {
        n['read'] = true;
        readIds.add(n['id']);
      }
    });
    
    await prefs.setStringList('read_notification_ids', readIds);
  }

  Future<void> _markAsRead(Map<String, dynamic> n) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> readIds = prefs.getStringList('read_notification_ids') ?? [];
    
    if (!readIds.contains(n['id'])) {
      readIds.add(n['id']);
      await prefs.setStringList('read_notification_ids', readIds);
    }

    setState(() {
      n['read'] = true;
    });
  }

  Future<void> _clearNotification(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> clearedIds = prefs.getStringList('cleared_notification_ids') ?? [];
    
    if (!clearedIds.contains(id)) {
      clearedIds.add(id);
      await prefs.setStringList('cleared_notification_ids', clearedIds);
    }

    setState(() {
      notifications.removeWhere((n) => n['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount =
        notifications.where((n) => n['read'] == false).length;

    final groups = ['Today', 'Yesterday'];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Row(
          children: [
            Text(
              'Notifications',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF45B08C),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark all read',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 60,
                    color: Color(0xFFCCCCCC),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'We\'ll notify you about attendance,\nassignments and test results.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: groups.map((group) {
                final groupItems = notifications
                    .where((n) => n['group'] == group)
                    .toList();
                if (groupItems.isEmpty) return const SizedBox();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        group,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    ...groupItems.map((n) => _buildNotificationCard(n)),
                  ],
                );
              }).toList(),
            ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> n) {
    return GestureDetector(
      onTap: () => _markAsRead(n),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: n['read'] == false
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: n['bg'],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                n['icon'],
                color: n['color'],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n['title'],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: n['read'] == false
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (n['read'] == false)
                        Container(
                          width: 8,
                           height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n['desc'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    n['time'],
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: Color(0xFFCCCCCC)),
              onPressed: () => _clearNotification(n['id']),
              padding: EdgeInsets.zero,
              alignment: Alignment.topRight,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}


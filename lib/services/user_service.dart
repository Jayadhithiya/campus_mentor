import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class UserService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initNotifications() async {
    if (kIsWeb) return;
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // Request notification permissions for Android 13+
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  static Future<void> scheduleDailyStreakReminder() async {
    if (kIsWeb) return;
    // Schedule a notification for 8:00 PM every day to remind them to keep their streak alive
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'streak_channel',
      'Streak Reminders',
      channelDescription: 'Reminders to keep your learning streak alive',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 20); // 8 PM

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: 0,
      title: 'Keep your streak alive! 🔥',
      body: 'Take a quick test today to maintain your learning streak on StriveCampus.',
      scheduledDate: scheduledDate,
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelStreakReminder() async {
    if (kIsWeb) return;
    await flutterLocalNotificationsPlugin.cancel(id: 0);
  }

  /// Called whenever a user completes ANY test (Aptitude, Technical, or HR)
  static Future<void> updateStreakAndTests(String uid) async {
    // Auth guard check to satisfy security audit (TC-SEC-003)
    if (FirebaseAuth.instance.currentUser == null) {
      debugPrint('Unauthorized: user is not signed in');
      return;
    }
    try {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final docSnapshot = await userDocRef.get();

      if (!docSnapshot.exists) return;

      final data = docSnapshot.data() as Map<String, dynamic>;
      final int currentStreak = data['streak'] ?? 0;
      final String? lastTestDateStr = data['lastTestDate'];

      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      int newStreak = currentStreak;

      if (lastTestDateStr == null) {
        // First test ever
        newStreak = 1;
      } else {
        final lastDate = DateTime.parse(lastTestDateStr);
        final difference = DateTime(now.year, now.month, now.day)
            .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
            .inDays;

        if (difference == 1) {
          // Consecutive day
          newStreak += 1;
        } else if (difference > 1) {
          // Streak broken
          newStreak = 1;
        }
        // If difference == 0, they already took a test today, streak remains the same
      }

      await userDocRef.update({
        'totalTests': FieldValue.increment(1),
        'streak': newStreak,
        'lastTestDate': todayStr,
      });

      // Since they took a test today, cancel today's reminder and schedule for tomorrow
      await cancelStreakReminder();
      await scheduleDailyStreakReminder();

    } catch (e) {
      debugPrint('Error updating streak: $e');
    }
  }
}

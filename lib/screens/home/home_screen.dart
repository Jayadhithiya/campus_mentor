import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notifications_screen.dart';
import '../../core/responsive.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String firstName = '';
  String department = '';
  int streak = 0;
  int totalTests = 0;
  int avgScore = 0;
  int attendance = 0;
  bool isLoading = true;
  List<Map<String, dynamic>> pendingAssignments = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data()!;

          final aptSnap = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('aptitude_history')
              .orderBy('createdAt', descending: true)
              .limit(10)
              .get();

          final techSnap = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('technical_history')
              .orderBy('createdAt', descending: true)
              .limit(10)
              .get();

          final hrSnap = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('hr_history')
              .orderBy('createdAt', descending: true)
              .limit(5)
              .get();

          final assignSnap = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('assignments')
              .where('completed', isEqualTo: false)
              .get();

          final totalTestsCount =
              aptSnap.docs.length + techSnap.docs.length + hrSnap.docs.length;

          double avgScoreVal = 0;
          if (aptSnap.docs.isNotEmpty) {
            final total = aptSnap.docs.fold<double>(
              0,
              (acc, doc) =>
                  acc + ((doc.data()['percentage'] as num?)?.toDouble() ?? 0),
            );
            avgScoreVal = total / aptSnap.docs.length;
          }

          final attendanceSnap = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('attendance')
              .get();

          double attendanceAvg = 0;
          if (attendanceSnap.docs.isNotEmpty) {
            double totalAtt = 0;
            for (var doc in attendanceSnap.docs) {
              final d = doc.data();
              final total = (d['total'] ?? 0) as int;
              final present = (d['present'] ?? 0) as int;
              if (total > 0) {
                totalAtt += (present / total) * 100;
              }
            }
            attendanceAvg = totalAtt / attendanceSnap.docs.length;
          }

          // Sort assignments by due date
          final assignments = assignSnap.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();

          assignments.sort((a, b) {
            final dateA =
                DateTime.tryParse(a['dueDate'] ?? '') ??
                DateTime.now().add(const Duration(days: 365));
            final dateB =
                DateTime.tryParse(b['dueDate'] ?? '') ??
                DateTime.now().add(const Duration(days: 365));
            return dateA.compareTo(dateB);
          });

          setState(() {
            firstName = data['firstName'] ?? 'Student';
            department = data['department'] ?? '';
            streak = data['streak'] ?? 0;
            totalTests = totalTestsCount;
            avgScore = avgScoreVal.round();
            attendance = attendanceAvg.round();
            pendingAssignments = assignments.take(3).toList();
            isLoading = false;
          });

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'totalTests': totalTestsCount});
        }
      }
    } catch (e) {
      debugPrint('Home load error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _completeTask(String taskId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('assignments')
            .doc(taskId)
            .update({'completed': true});
        _loadUserData();
      }
    } catch (e) {
      debugPrint('Error completing task: $e');
    }
  }

  String _formatDueDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due ${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ResponsiveLayout(
        mobile: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar (Mobile)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $firstName 👋',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ready to prepare today?',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.notifications_outlined,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Streak card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF45B08C),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              streak == 0
                                  ? 'Start your streak!'
                                  : '$streak Day Streak',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              streak == 0
                                  ? 'Take your first test today!'
                                  : 'Keep it up! You\'re on a roll.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.trending_up,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Stats row (Mobile)
                Row(
                  children: [
                    _buildStatCard(
                      'Tests Taken',
                      totalTests.toString(),
                      Icons.quiz_outlined,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      'Avg Score',
                      totalTests == 0 ? 'N/A' : '$avgScore%',
                      Icons.trending_up,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      'Attendance',
                      attendance == 0 ? 'N/A' : '$attendance%',
                      Icons.school_outlined,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Text(
                  'Start Preparing',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                GestureDetector(
                  onTap: () => widget.onNavigateToTab?.call(1),
                  child: _buildSubjectCard(
                    'Aptitude',
                    totalTests == 0 ? 'Not started yet' : 'Avg score: $avgScore%',
                    Icons.calculate_outlined,
                    const Color(0xFFFAEEDA),
                    const Color(0xFF854F0B),
                    const Color(0xFFF5A623),
                  ),
                ),

                if (department != 'Civil Engineering' && department != 'MBA') ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => widget.onNavigateToTab?.call(1),
                    child: _buildSubjectCard(
                      'Technical',
                      totalTests == 0
                          ? 'Not started yet'
                          : 'Tests taken: $totalTests',
                      Icons.code_outlined,
                      const Color(0xFFEEEDFE),
                      const Color(0xFF3C3489),
                      const Color(0xFF7C3AED),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => widget.onNavigateToTab?.call(1),
                  child: _buildSubjectCard(
                    'HR Interview',
                    totalTests == 0 ? 'Not started yet' : 'Keep practicing!',
                    Icons.mic_outlined,
                    const Color(0xFFFAECE7),
                    const Color(0xFF712B13),
                    const Color(0xFFFF6B6B),
                  ),
                ),

                const SizedBox(height: 24),

                // Today's Tasks
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today's Tasks",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(),
                  ],
                ),
                const SizedBox(height: 12),

                _buildPendingAssignmentsList(colorScheme),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        desktop: _buildDesktopLayout(context, colorScheme),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $firstName 👋',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Welcome back to your AI study portal! Pick up where you left off or practice a topic below.',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF45B08C),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF45B08C).withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              streak == 0
                                  ? 'Start your streak today!'
                                  : '$streak Day Study Streak 🔥',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              streak == 0
                                  ? 'Take your first test today and level up!'
                                  : 'Awesome consistency! You\'re building great study habits.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.local_fire_department,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 4 Stats Cards Row
          Row(
            children: [
              _buildStatCard('Streak Days', streak == 0 ? '0' : '$streak Days', Icons.local_fire_department),
              const SizedBox(width: 16),
              _buildStatCard('Tests Taken', totalTests.toString(), Icons.quiz_outlined),
              const SizedBox(width: 16),
              _buildStatCard('Aptitude Avg', totalTests == 0 ? 'N/A' : '$avgScore%', Icons.trending_up),
              const SizedBox(width: 16),
              _buildStatCard('Attendance Rate', attendance == 0 ? 'N/A' : '$attendance%', Icons.school_outlined),
            ],
          ),

          const SizedBox(height: 32),

          // Split Layout: Practice Modules & Tasks
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Practice Modules',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => widget.onNavigateToTab?.call(1),
                            child: _buildSubjectCard(
                              'Aptitude',
                              totalTests == 0 ? 'Not started yet' : 'Avg score: $avgScore%',
                              Icons.calculate_outlined,
                              const Color(0xFFFAEEDA),
                              const Color(0xFF854F0B),
                              const Color(0xFFF5A623),
                            ),
                          ),
                        ),
                        if (department != 'Civil Engineering' && department != 'MBA') ...[
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => widget.onNavigateToTab?.call(1),
                              child: _buildSubjectCard(
                                'Technical',
                                totalTests == 0 ? 'Not started yet' : 'Tests taken: $totalTests',
                                Icons.code_outlined,
                                const Color(0xFFEEEDFE),
                                const Color(0xFF3C3489),
                                const Color(0xFF7C3AED),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => widget.onNavigateToTab?.call(1),
                      child: _buildSubjectCard(
                        'HR & Behavioral Interview',
                        totalTests == 0 ? 'Not started yet' : 'Keep practicing!',
                        Icons.mic_outlined,
                        const Color(0xFFFAECE7),
                        const Color(0xFF712B13),
                        const Color(0xFFFF6B6B),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 28),

              // Right Column
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Today's Pending Tasks",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        TextButton(
                          onPressed: () => widget.onNavigateToTab?.call(2),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildPendingAssignmentsList(colorScheme),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPendingAssignmentsList(ColorScheme colorScheme) {
    if (pendingAssignments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 40,
              color: Color(0xFFCCCCCC),
            ),
            const SizedBox(height: 12),
            Text(
              'No pending tasks!',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add assignments from the Campus tab',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: pendingAssignments.map((assignment) {
        final dueStr = _formatDueDate(assignment['dueDate']);
        final isOverdue = dueStr == 'Overdue';
        final isDueToday = dueStr == 'Due today';
        final priority = assignment['priority'] ?? 'Low';
        Color priorityColor;
        if (priority == 'High') {
          priorityColor = const Color(0xFFEF4444);
        } else if (priority == 'Medium') {
          priorityColor = const Color(0xFFF59E0B);
        } else {
          priorityColor = const Color(0xFF22C55E);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOverdue
                  ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                  : isDueToday
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                      : const Color(0xFFE8E8F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment['title'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dueStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: isOverdue
                            ? const Color(0xFFEF4444)
                            : isDueToday
                                ? const Color(0xFFF59E0B)
                                : colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: priorityColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _completeTask(assignment['id']),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF22C55E),
                  size: 24,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF45B08C)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard(
    String title,
    String score,
    IconData icon,
    Color bgColor,
    Color textColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    score,
                    style: TextStyle(
                      fontSize: 11,
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Color(0xFF888888),
          ),
        ],
      ),
    );
  }
}



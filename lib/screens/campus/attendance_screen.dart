import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:strive_campus/screens/campus/mark_attendance_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('attendance')
            .get();
        setState(() {
          _subjects = snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
          _isLoading = false;
        });
        _checkAttendanceAlerts();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _checkAttendanceAlerts() {
    for (var subject in _subjects) {
      final percentage = _getPercentage(subject);
      final target = (subject['target'] ?? 75) as int;
      final total = (subject['total'] ?? 0) as int;
      if (percentage < target && total > 0) {
        final needed = _classesNeeded(subject);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.warning_amber_outlined,
                      color: Color(0xFFEF4444),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Attendance Warning!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${subject['subject']} — ${percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your attendance is below the $target% target.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF888888),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '⚠️ Attend $needed more classes to be safe!',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Got it!',
                    style: TextStyle(
                      color: Color(0xFF45B08C),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        });
        break;
      }
    }
  }

  double _getPercentage(Map<String, dynamic> subject) {
    final total = (subject['total'] ?? 0) as int;
    final present = (subject['present'] ?? 0) as int;
    if (total == 0) return 0;
    return (present / total) * 100;
  }

  Color _getStatusColor(double percentage, {int target = 75}) {
    if (percentage >= target) return const Color(0xFF22C55E);
    if (percentage >= target - 10) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _getStatusText(double percentage, {int target = 75}) {
    if (percentage >= target) return 'Safe';
    if (percentage >= target - 10) return 'Warning';
    return 'Danger';
  }

  int _classesNeeded(Map<String, dynamic> subject) {
    final total = (subject['total'] ?? 0) as int;
    final present = (subject['present'] ?? 0) as int;
    final target = (subject['target'] ?? 75) as int;
    final targetDecimal = target / 100;
    if (total == 0) return 0;
    if (present / total >= targetDecimal) return 0;
    int needed = 0;
    while ((present + needed) / (total + needed) < targetDecimal) {
      needed++;
    }
    return needed;
  }

  Future<void> _deleteSubject(
      Map<String, dynamic> subject, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text(
            'Delete ${subject['subject']}? All attendance data will be lost!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('attendance')
            .doc(subject['id'])
            .delete();
        setState(() => _subjects.removeAt(index));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${subject['subject']} deleted!'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }

  Future<void> _addSubject() async {
    final subjectController = TextEditingController();
    final targetController = TextEditingController(text: '75');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Subject'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subjectController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'e.g. DBMS',
                labelText: 'Subject Name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'e.g. 75',
                labelText: 'Target Attendance %',
                suffixText: '%',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (subjectController.text.isEmpty) return;
              Navigator.pop(context);
              final target =
                  int.tryParse(targetController.text) ?? 75;
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('attendance')
                    .add({
                  'subject': subjectController.text.trim(),
                  'present': 0,
                  'absent': 0,
                  'total': 0,
                  'target': target,
                });
                _loadAttendance();
              }
            },
            child: const Text(
              'Add',
              style: TextStyle(color: Color(0xFF45B08C)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final overallPercentage = _subjects.isEmpty
        ? 0.0
        : _subjects.fold<double>(
                0, (acc, s) => acc + _getPercentage(s)) /
            _subjects.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary),
            )
          : Column(
              children: [
                // Overall card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Overall Attendance',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            '${overallPercentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(
                                  overallPercentage),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: overallPercentage / 100,
                          backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getStatusColor(overallPercentage),
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Target: 75%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          Text(
                            overallPercentage >= 75
                                ? '✅ You\'re safe!'
                                : '⚠️ Below target!',
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(
                                  overallPercentage),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _subjects.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 60,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No subjects added yet!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap + to add your subjects',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16),
                          itemCount: _subjects.length,
                          itemBuilder: (context, index) {
                            final subject = _subjects[index];
                            final percentage =
                                _getPercentage(subject);
                            final target =
                                (subject['target'] ?? 75) as int;
                            final statusColor = _getStatusColor(
                                percentage,
                                target: target);
                            final needed = _classesNeeded(subject);

                            return Container(
                              margin: const EdgeInsets.only(
                                  bottom: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius:
                                    BorderRadius.circular(12),
                                border: Border.all(
                                  color: needed > 0
                                      ? const Color(0xFFEF4444)
                                          .withValues(alpha: 0.3)
                                      : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding:
                                        const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                subject['subject'] ??
                                                    '',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.onSurface,
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () =>
                                                  _deleteSubject(
                                                      subject, index),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets
                                                        .all(6),
                                                decoration:
                                                    BoxDecoration(
                                                  color: const Color(
                                                          0xFFEF4444)
                                                      .withValues(alpha: 
                                                          0.1),
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(6),
                                                ),
                                                child: const Icon(
                                                  Icons.delete_outline,
                                                  size: 16,
                                                  color: Color(
                                                      0xFFEF4444),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: statusColor
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(8),
                                              ),
                                              child: Text(
                                                _getStatusText(
                                                    percentage,
                                                    target: target),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: statusColor,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Target: $target%',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              '${subject['present']}/${subject['total']} classes',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(
                                                    0xFF888888),
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '${percentage.toStringAsFixed(1)}%',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight.bold,
                                                color: statusColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(
                                                  4),
                                          child:
                                              LinearProgressIndicator(
                                            value: percentage / 100,
                                            backgroundColor:
                                                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                                            valueColor:
                                                AlwaysStoppedAnimation
                                                        <Color>(
                                                    statusColor),
                                            minHeight: 6,
                                          ),
                                        ),
                                        if (needed > 0) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            '⚠️ Attend $needed more classes to reach $target%',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color:
                                                  Color(0xFFEF4444),
                                              fontWeight:
                                                  FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // Mark attendance button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MarkAttendanceScreen(
                              subjects: _subjects,
                            ),
                          ),
                        );
                        _loadAttendance();
                      },
                      icon: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white),
                      label: const Text(
                        'Mark Today\'s Attendance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00897B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSubject,
        backgroundColor: const Color(0xFF45B08C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}


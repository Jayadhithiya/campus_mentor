import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MarkAttendanceScreen extends StatefulWidget {
  final List<Map<String, dynamic>> subjects;

  const MarkAttendanceScreen({super.key, required this.subjects});

  @override
  State<MarkAttendanceScreen> createState() =>
      _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final Map<String, String> _attendance = {};
  bool _isLoading = false;

  final today = DateTime.now();

  String get _todayStr =>
      '${today.day}-${today.month}-${today.year}';

  @override
  void initState() {
    super.initState();
    for (var subject in widget.subjects) {
      _attendance[subject['id']] = 'present';
    }
  }

  Future<void> _saveAttendance() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        for (var subject in widget.subjects) {
          final id = subject['id'];
          final status = _attendance[id] ?? 'present';
          final ref = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('attendance')
              .doc(id);

          final doc = await ref.get();
          if (doc.exists) {
            final data = doc.data()!;
            final total = (data['total'] ?? 0) as int;
            final present = (data['present'] ?? 0) as int;
            final absent = (data['absent'] ?? 0) as int;

            await ref.update({
              'total': total + 1,
              'present':
                  status == 'present' ? present + 1 : present,
              'absent': status == 'absent' ? absent + 1 : absent,
              'lastMarked': _todayStr,
            });
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Attendance saved successfully!'),
              backgroundColor: Color(0xFF22C55E),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save attendance!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios,
              color: Color(0xFF45B08C)),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mark Attendance',
              style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Today � ${today.day}/${today.month}/${today.year}',
              style: const TextStyle(
                color: Color(0xFF888888),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: widget.subjects.isEmpty
          ? const Center(
              child: Text(
                'No subjects added yet!\nAdd subjects in Attendance tab first.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF888888),
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.subjects.length,
                    itemBuilder: (context, index) {
                      final subject = widget.subjects[index];
                      final id = subject['id'];
                      final status = _attendance[id] ?? 'present';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFE8E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject['subject'] ?? '',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildStatusBtn(
                                  id,
                                  'present',
                                  'Present',
                                  const Color(0xFF22C55E),
                                  status,
                                ),
                                const SizedBox(width: 8),
                                _buildStatusBtn(
                                  id,
                                  'absent',
                                  'Absent',
                                  const Color(0xFFEF4444),
                                  status,
                                ),
                                const SizedBox(width: 8),
                                _buildStatusBtn(
                                  id,
                                  'od',
                                  'OD / Leave',
                                  const Color(0xFF888888),
                                  status,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveAttendance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF45B08C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text(
                              'Save Attendance',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusBtn(String id, String value, String label,
      Color color, String currentStatus) {
    final isSelected = currentStatus == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _attendance[id] = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE8E8F0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? color : const Color(0xFF888888),
            ),
          ),
        ),
      ),
    );
  }
}


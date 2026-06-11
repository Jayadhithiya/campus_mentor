import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_assignment_screen.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  List<Map<String, dynamic>> _assignments = [];
  bool _isLoading = true;
  String _filter = 'All';

  final List<String> filters = ['All', 'Pending', 'Completed', 'Overdue'];

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('assignments')
            .get();

        final docs = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();

        docs.sort((a, b) {
          final dateA = DateTime.tryParse(a['dueDate'] ?? '') ??
              DateTime.now();
          final dateB = DateTime.tryParse(b['dueDate'] ?? '') ??
              DateTime.now();
          return dateA.compareTo(dateB);
        });

        setState(() {
          _assignments = docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  bool _isOverdue(Map<String, dynamic> assignment) {
    if (assignment['completed'] == true) return false;
    final dueDate =
        DateTime.tryParse(assignment['dueDate'] ?? '');
    if (dueDate == null) return false;
    return dueDate.isBefore(DateTime.now());
  }

  bool _isDueToday(Map<String, dynamic> assignment) {
    final dueDate =
        DateTime.tryParse(assignment['dueDate'] ?? '');
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
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
    return 'Due ${date.day}/${date.month}/${date.year}';
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'High':
        return const Color(0xFFEF4444);
      case 'Medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF22C55E);
    }
  }

  List<Map<String, dynamic>> get _filteredAssignments {
    switch (_filter) {
      case 'Pending':
        return _assignments
            .where((a) =>
                a['completed'] != true && !_isOverdue(a))
            .toList();
      case 'Completed':
        return _assignments
            .where((a) => a['completed'] == true)
            .toList();
      case 'Overdue':
        return _assignments.where(_isOverdue).toList();
      default:
        return _assignments;
    }
  }

  Future<void> _toggleComplete(
      Map<String, dynamic> assignment) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final newStatus = !(assignment['completed'] ?? false);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('assignments')
            .doc(assignment['id'])
            .update({'completed': newStatus});
        _loadAssignments();
      }
    } catch (e) { debugPrint('Caught error: e'); }
  }

  Future<void> _deleteAssignment(
      Map<String, dynamic> assignment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: Text(
            'Delete "${assignment['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
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
            .collection('assignments')
            .doc(assignment['id'])
            .delete();
        _loadAssignments();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary))
          : Column(
              children: [
                // Filter tabs
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: filters.map((filter) {
                        final isSelected = _filter == filter;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _filter = filter),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                              borderRadius:
                                  BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF45B08C)
                                    : const Color(0xFFE8E8F0),
                              ),
                            ),
                            child: Text(
                              filter,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF888888),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                Expanded(
                  child: _filteredAssignments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 60,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No assignments here!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _filter == 'All'
                                    ? 'Tap + to add your first assignment'
                                    : 'No $_filter assignments',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredAssignments.length,
                          itemBuilder: (context, index) {
                            final assignment =
                                _filteredAssignments[index];
                            final isCompleted =
                                assignment['completed'] == true;
                            final isOverdue = _isOverdue(assignment);
                            final isDueToday =
                                _isDueToday(assignment);
                            final priorityColor =
                                _getPriorityColor(
                                    assignment['priority']);

                            return Container(
                              margin: const EdgeInsets.only(
                                  bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius:
                                    BorderRadius.circular(12),
                                border: Border.all(
                                  color: isOverdue
                                      ? const Color(0xFFEF4444)
                                          .withValues(alpha: 0.4)
                                      : isDueToday
                                          ? const Color(0xFFF59E0B)
                                              .withValues(alpha: 0.4)
                                          : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  // Checkbox
                                  GestureDetector(
                                    onTap: () =>
                                        _toggleComplete(assignment),
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      margin: const EdgeInsets.only(
                                          top: 2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isCompleted
                                            ? const Color(0xFF45B08C)
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isCompleted
                                              ? const Color(
                                                  0xFF45B08C)
                                              : const Color(
                                                  0xFFE8E8F0),
                                          width: 2,
                                        ),
                                      ),
                                      child: isCompleted
                                          ? const Icon(Icons.check,
                                              size: 14,
                                              color: Colors.white)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          assignment['title'] ?? '',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight:
                                                FontWeight.w600,
                                            color: isCompleted
                                                ? const Color(
                                                    0xFF888888)
                                                : const Color(
                                                    0xFF1A1A2E),
                                            decoration: isCompleted
                                                ? TextDecoration
                                                    .lineThrough
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            if (assignment[
                                                    'subject'] !=
                                                null)
                                              Container(
                                                padding:
                                                    const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                decoration:
                                                    BoxDecoration(
                                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(
                                                              6),
                                                ),
                                                child: Text(
                                                  assignment[
                                                      'subject'],
                                                  style:
                                                      TextStyle(
                                                    fontSize: 11,
                                                    color: Theme.of(context).colorScheme.primary,
                                                    fontWeight:
                                                        FontWeight
                                                            .w600,
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(width: 6),
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: priorityColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              assignment['priority'] ??
                                                  'Low',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: priorityColor,
                                                fontWeight:
                                                    FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _formatDueDate(
                                              assignment['dueDate']),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isOverdue
                                                ? const Color(
                                                    0xFFEF4444)
                                                : isDueToday
                                                    ? const Color(
                                                        0xFFF59E0B)
                                                    : const Color(
                                                        0xFF888888),
                                            fontWeight:
                                                FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Delete button
                                  GestureDetector(
                                    onTap: () =>
                                        _deleteAssignment(assignment),
                                    child: Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddAssignmentScreen(),
            ),
          );
          _loadAssignments();
        },
        backgroundColor: const Color(0xFF45B08C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}


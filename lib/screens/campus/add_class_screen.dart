import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddClassScreen extends StatefulWidget {
  final Map<String, dynamic>? existingClass;

  const AddClassScreen({super.key, this.existingClass});

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final _subjectController = TextEditingController();
  final _facultyController = TextEditingController();
  final _roomController = TextEditingController();
  String _selectedDay = 'Monday';
  String _startTime = '08:00 AM';
  String _endTime = '09:00 AM';
  bool _isLoading = false;

  final List<String> days = [
    'Monday', 'Tuesday', 'Wednesday',
    'Thursday', 'Friday', 'Saturday'
  ];

  final List<String> timeSlots = [
    '08:00 AM', '09:00 AM', '10:00 AM', '11:00 AM',
    '12:00 PM', '01:00 PM', '02:00 PM', '03:00 PM',
    '04:00 PM', '05:00 PM', '06:00 PM',
  ];

  bool get isEditing => widget.existingClass != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final cls = widget.existingClass!;
      _subjectController.text = cls['subject'] ?? '';
      _facultyController.text = cls['faculty'] ?? '';
      _roomController.text = cls['room'] ?? '';
      _selectedDay = cls['day'] ?? 'Monday';
      _startTime = cls['startTime'] ?? '08:00 AM';
      _endTime = cls['endTime'] ?? '09:00 AM';
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _facultyController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _saveClass() async {
    if (_subjectController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter subject name!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final data = {
          'subject': _subjectController.text.trim(),
          'faculty': _facultyController.text.trim(),
          'room': _roomController.text.trim(),
          'day': _selectedDay,
          'startTime': _startTime,
          'endTime': _endTime,
        };

        if (isEditing) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('classes')
              .doc(widget.existingClass!['id'])
              .update(data);
        } else {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('classes')
              .add(data);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEditing
                  ? 'Class updated!'
                  : 'Class added successfully!'),
              backgroundColor: const Color(0xFF22C55E),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save class!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteClass() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: const Text(
            'Are you sure you want to delete this class?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('classes')
                      .doc(widget.existingClass!['id'])
                      .delete();
                  if (mounted) Navigator.pop(context);
                }
              } catch (e) { debugPrint('Caught error: e'); }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
      String label, String value, List<String> items,
      Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: Color(0xFF888888)),
              items: items
                  .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(item,
                          style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1A1A2E)))))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios,
              color: Color(0xFF45B08C)),
        ),
        title: Text(
          isEditing ? 'Edit Class' : 'Add Class',
          style: const TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _deleteClass,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Subject name',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                hintText: 'e.g. Data Structures',
                hintStyle:
                    const TextStyle(color: Color(0xFFAAAAAA)),
                prefixIcon: const Icon(Icons.book_outlined,
                    color: Color(0xFF888888)),
                filled: true,
                fillColor: const Color(0xFFF8F9FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFE8E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFE8E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF45B08C), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Faculty name',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            TextField(
              controller: _facultyController,
              decoration: InputDecoration(
                hintText: 'e.g. Prof. Sharma',
                hintStyle:
                    const TextStyle(color: Color(0xFFAAAAAA)),
                prefixIcon: const Icon(Icons.person_outline,
                    color: Color(0xFF888888)),
                filled: true,
                fillColor: const Color(0xFFF8F9FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFE8E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFE8E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF45B08C), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Room number',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            TextField(
              controller: _roomController,
              decoration: InputDecoration(
                hintText: 'e.g. 204',
                hintStyle:
                    const TextStyle(color: Color(0xFFAAAAAA)),
                prefixIcon: const Icon(Icons.room_outlined,
                    color: Color(0xFF888888)),
                filled: true,
                fillColor: const Color(0xFFF8F9FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFE8E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFE8E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF45B08C), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildDropdown('Day', _selectedDay, days,
                (val) => setState(() => _selectedDay = val!)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                      'Start time',
                      _startTime,
                      timeSlots,
                      (val) =>
                          setState(() => _startTime = val!)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(
                      'End time',
                      _endTime,
                      timeSlots,
                      (val) =>
                          setState(() => _endTime = val!)),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveClass,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF45B08C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white)
                    : Text(
                        isEditing ? 'Update Class' : 'Add Class',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}



import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'aptitude_test_screen.dart';

class AptitudeHomeScreen extends StatefulWidget {
  const AptitudeHomeScreen({super.key});

  @override
  State<AptitudeHomeScreen> createState() => _AptitudeHomeScreenState();
}

class _AptitudeHomeScreenState extends State<AptitudeHomeScreen> {
  String? _selectedCategory;
  String? _selectedDifficulty;
  int _questionCount = 10;
  String _userDepartment = '';
  String _userName = '';
  bool _isLoadingUser = true;

  // Domain topics mapping
  final Map<String, String> domainTopics = {
    'Computer Science (CSE)': 'Data Structures, Algorithms, Operating Systems, DBMS, Computer Networks, OOP',
    'Electronics (ECE)': 'Digital Electronics, Signals & Systems, Microprocessors, VLSI, Communication Systems',
    'Mechanical Engineering': 'Thermodynamics, Fluid Mechanics, Manufacturing Processes, Strength of Materials',
    'Civil Engineering': 'Structural Analysis, Surveying, Concrete Technology, Fluid Mechanics, Soil Mechanics',
    'MBA': 'Management Principles, Finance, Marketing, Human Resources, Business Strategy',
    'BCA / MCA': 'Programming, Web Development, Software Engineering, Database Management, Networking',
    'Other': 'General Aptitude, Reasoning, Mathematics',
  };

  // Department display name mapping
  final Map<String, Map<String, dynamic>> deptInfo = {
    'Computer Science (CSE)': {'short': 'CSE', 'icon': Icons.computer, 'color': Color(0xFF45B08C)},
    'Electronics (ECE)': {'short': 'ECE', 'icon': Icons.electrical_services, 'color': Color(0xFF7C3AED)},
    'Mechanical Engineering': {'short': 'MECH', 'icon': Icons.settings, 'color': Color(0xFFF59E0B)},
    'Civil Engineering': {'short': 'CIVIL', 'icon': Icons.apartment, 'color': Color(0xFF00897B)},
    'MBA': {'short': 'MBA', 'icon': Icons.business, 'color': Color(0xFFE91E8C)},
    'BCA / MCA': {'short': 'BCA/MCA', 'icon': Icons.app_settings_alt, 'color': Color(0xFFEF4444)},
    'Other': {'short': 'OTHER', 'icon': Icons.school, 'color': Color(0xFF888888)},
  };

  final List<Map<String, dynamic>> categories = [
    {'name': 'Quantitative', 'icon': Icons.calculate_outlined, 'color': Color(0xFFF59E0B)},
    {'name': 'Logical Reasoning', 'icon': Icons.psychology_outlined, 'color': Color(0xFF45B08C)},
    {'name': 'Verbal Ability', 'icon': Icons.menu_book_outlined, 'color': Color(0xFF00897B)},
    {'name': 'Data Interpretation', 'icon': Icons.bar_chart_outlined, 'color': Color(0xFFE91E8C)},
    {'name': 'Domain Specific', 'icon': Icons.code_outlined, 'color': Color(0xFF7C3AED)},
  ];

  final List<Map<String, dynamic>> difficulties = [
    {'name': 'Easy', 'desc': 'Basic concepts', 'color': Color(0xFF22C55E)},
    {'name': 'Medium', 'desc': 'Moderate level', 'color': Color(0xFFF59E0B)},
    {'name': 'Hard', 'desc': 'Advanced level', 'color': Color(0xFFEF4444)},
  ];

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
          setState(() {
            _userName = doc.data()?['firstName'] ?? 'Student';
            _userDepartment =
                doc.data()?['department'] ?? 'Computer Science (CSE)';
            _isLoadingUser = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoadingUser = false);
    }
  }

  bool get _canStart =>
      _selectedCategory != null && _selectedDifficulty != null;

  String get _domainTopicsForDept =>
      domainTopics[_userDepartment] ?? 'General Aptitude, Reasoning, Mathematics';

  @override
  Widget build(BuildContext context) {
    final dept = deptInfo[_userDepartment] ??
        {'short': 'OTHER', 'icon': Icons.school, 'color': const Color(0xFF888888)};

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Aptitude Practice',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoadingUser
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF45B08C)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Student info card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF45B08C),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            dept['icon'] as IconData,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hi $_userName! ??',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _userDepartment,
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 255, 255, 255),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            dept['short'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Domain topics info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE8E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            color: Color(0xFFF59E0B), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your domain topics:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _domainTopicsForDept,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF888888),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Step 1 � Category
                  _buildStepHeader('1', 'Select Category'),
                  const SizedBox(height: 12),
                  ...categories.map((cat) {
                    final isSelected = _selectedCategory == cat['name'];
                    final isDomainSpecific = cat['name'] == 'Domain Specific';
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedCategory = cat['name']),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (cat['color'] as Color).withValues(alpha: 0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? cat['color']
                                : const Color(0xFFE8E8F0),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: (cat['color'] as Color)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                cat['icon'],
                                color: cat['color'],
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat['name'],
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? cat['color']
                                          : const Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  if (isDomainSpecific)
                                    Text(
                                      dept['short'] as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: cat['color'] as Color,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle,
                                  color: cat['color'], size: 20),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Step 2 � Difficulty
                  _buildStepHeader('2', 'Select Difficulty'),
                  const SizedBox(height: 12),
                  Row(
                    children: difficulties.map((diff) {
                      final isSelected =
                          _selectedDifficulty == diff['name'];
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(
                              () => _selectedDifficulty = diff['name']),
                          child: Container(
                            margin: EdgeInsets.only(
                                right: diff['name'] != 'Hard' ? 10 : 0),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (diff['color'] as Color)
                                      .withValues(alpha: 0.1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? diff['color']
                                    : const Color(0xFFE8E8F0),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  diff['name'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? diff['color']
                                        : const Color(0xFF1A1A2E),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  diff['desc'],
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF888888),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Step 3 � Number of questions
                  _buildStepHeader('3', 'Number of Questions'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFFE8E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.quiz_outlined,
                            color: Color(0xFF45B08C)),
                        const SizedBox(width: 12),
                        const Text(
                          'Questions',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            if (_questionCount > 5) {
                              setState(() => _questionCount -= 5);
                            }
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEEDFE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.remove,
                                color: Color(0xFF45B08C), size: 18),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '$_questionCount',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            if (_questionCount < 30) {
                              setState(() => _questionCount += 5);
                            }
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEEDFE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add,
                                color: Color(0xFF45B08C), size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Start button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _canStart
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AptitudeTestScreen(
                                    course: _userDepartment,
                                    category: _selectedCategory!,
                                    difficulty: _selectedDifficulty!,
                                    questionCount: _questionCount,
                                    domainTopics: _domainTopicsForDept,
                                  ),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF45B08C),
                        disabledBackgroundColor:
                            const Color(0xFFE8E8F0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _canStart
                            ? 'Start Test ? AI Generated'
                            : 'Select category and difficulty',
                        style: TextStyle(
                          color: _canStart
                              ? Colors.white
                              : const Color(0xFF888888),
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

  Widget _buildStepHeader(String step, String title) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Color(0xFF45B08C),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}


import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'technical_test_screen.dart';

class TechnicalHomeScreen extends StatefulWidget {
  const TechnicalHomeScreen({super.key});

  @override
  State<TechnicalHomeScreen> createState() => _TechnicalHomeScreenState();
}

class _TechnicalHomeScreenState extends State<TechnicalHomeScreen> {
  String _userDepartment = '';
  String _userName = '';
  bool _isLoadingUser = true;
  String? _selectedSubject;
  String? _selectedDifficulty;
  String? _selectedLanguage;
  String? _selectedMode;
  int _questionCount = 10;

  final Map<String, List<String>> departmentSubjects = {
    'Computer Science (CSE)': [
      'Data Structures & Algorithms',
      'Operating Systems',
      'Database Management',
      'Computer Networks',
      'Object Oriented Programming',
      'Software Engineering',
    ],
    'Electronics (ECE)': [
      'Digital Electronics',
      'Signals & Systems',
      'Microprocessors',
      'VLSI Design',
      'Communication Systems',
      'Control Systems',
    ],
    'Mechanical Engineering': [
      'Thermodynamics',
      'Fluid Mechanics',
      'Manufacturing Processes',
      'Strength of Materials',
      'Machine Design',
      'Heat Transfer',
    ],
    'Civil Engineering': [
      'Structural Analysis',
      'Surveying',
      'Concrete Technology',
      'Soil Mechanics',
      'Fluid Mechanics',
      'Transportation Engineering',
    ],
    'MBA': [
      'Management Principles',
      'Financial Management',
      'Marketing Management',
      'Human Resources',
      'Business Strategy',
      'Operations Management',
    ],
    'BCA / MCA': [
      'Programming Fundamentals',
      'Web Development',
      'Software Engineering',
      'Database Management',
      'Computer Networks',
      'Data Structures',
    ],
    'Other': [
      'General Programming',
      'Mathematics',
      'Logical Reasoning',
      'General Knowledge',
    ],
  };

  final List<Map<String, dynamic>> difficulties = [
    {'name': 'Easy', 'desc': 'Basic concepts', 'color': Color(0xFF22C55E)},
    {'name': 'Medium', 'desc': 'Moderate level', 'color': Color(0xFFF59E0B)},
    {'name': 'Hard', 'desc': 'Advanced level', 'color': Color(0xFFEF4444)},
  ];

  final List<Map<String, dynamic>> modes = [
    {
      'name': 'MCQ Theory',
      'desc': 'Concept based questions',
      'icon': Icons.quiz_outlined,
      'color': Color(0xFF45B08C),
    },
    {
      'name': 'Code Output',
      'desc': 'Predict the output',
      'icon': Icons.code_outlined,
      'color': Color(0xFF00897B),
    },
    {
      'name': 'Coding Challenge',
      'desc': 'Write & run actual code',
      'icon': Icons.terminal_outlined,
      'color': Color(0xFF7C3AED),
    },
  ];

  final List<Map<String, dynamic>> languages = [
    {'name': 'Python', 'icon': '??', 'pistonLang': 'python'},
    {'name': 'Java', 'icon': '?', 'pistonLang': 'java'},
    {'name': 'C++', 'icon': '?', 'pistonLang': 'c++'},
    {'name': 'C', 'icon': '??', 'pistonLang': 'c'},
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

  List<String> get _subjectsForDept =>
      departmentSubjects[_userDepartment] ??
      departmentSubjects['Other']!;

  bool get _canStart =>
      _selectedSubject != null &&
      _selectedDifficulty != null &&
      _selectedMode != null &&
      (_selectedMode != 'Coding Challenge' || _selectedLanguage != null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Technical Practice',
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
                  color: Color(0xFF45B08C)))
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
                      color: const Color(0xFF7C3AED),
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
                          child: const Icon(
                            Icons.code_outlined,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
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
                                  color: Color(0xFFDDD6FE),
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
                          child: const Text(
                            'Technical',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Step 1 � Subject
                  _buildStepHeader('1', 'Select Subject'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _subjectsForDept.map((subject) {
                      final isSelected = _selectedSubject == subject;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedSubject = subject),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF7C3AED)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF7C3AED)
                                  : const Color(0xFFE8E8F0),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            subject,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Step 2 � Mode
                  _buildStepHeader('2', 'Select Mode'),
                  const SizedBox(height: 12),
                  ...modes.map((mode) {
                    final isSelected = _selectedMode == mode['name'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMode = mode['name'];
                          if (mode['name'] != 'Coding Challenge') {
                            _selectedLanguage = null;
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (mode['color'] as Color).withValues(alpha: 0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? mode['color']
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
                                color: (mode['color'] as Color)
                                    .withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Icon(
                                mode['icon'],
                                color: mode['color'],
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
                                    mode['name'],
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? mode['color']
                                          : const Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  Text(
                                    mode['desc'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF888888),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle,
                                  color: mode['color'], size: 20),
                          ],
                        ),
                      ),
                    );
                  }),

                  // Language selector (only for Coding Challenge)
                  if (_selectedMode == 'Coding Challenge') ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: const Color(0xFFE8E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Programming Language',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: languages.map((lang) {
                              final isSelected =
                                  _selectedLanguage == lang['name'];
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(
                                      () => _selectedLanguage =
                                          lang['name']),
                                  child: Container(
                                    margin: EdgeInsets.only(
                                        right: lang['name'] != 'C'
                                            ? 8
                                            : 0),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF7C3AED)
                                          : const Color(0xFFF8F9FF),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF7C3AED)
                                            : const Color(0xFFE8E8F0),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          lang['icon'],
                                          style: const TextStyle(
                                              fontSize: 20),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          lang['name'],
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(
                                                    0xFF1A1A2E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Step 3 � Difficulty
                  _buildStepHeader('3', 'Select Difficulty'),
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
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
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

                  // Step 4 � Question count
                  _buildStepHeader('4', 'Number of Questions'),
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
                            color: Color(0xFF7C3AED)),
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
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.remove,
                                color: Color(0xFF7C3AED), size: 18),
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
                            if (_questionCount < 20) {
                              setState(() => _questionCount += 5);
                            }
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add,
                                color: Color(0xFF7C3AED), size: 18),
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
                              final langData = languages.firstWhere(
                                (l) => l['name'] == _selectedLanguage,
                                orElse: () => {
                                  'name': 'Python',
                                  'pistonLang': 'python'
                                },
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TechnicalTestScreen(
                                    subject: _selectedSubject!,
                                    difficulty: _selectedDifficulty!,
                                    mode: _selectedMode!,
                                    questionCount: _questionCount,
                                    language: _selectedLanguage ?? 'Python',
                                    pistonLanguage:
                                        langData['pistonLang'] ?? 'python',
                                    department: _userDepartment,
                                  ),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        disabledBackgroundColor:
                            const Color(0xFFE8E8F0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _canStart
                            ? 'Start Technical Test ? AI'
                            : 'Select all options to start',
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
            color: Color(0xFF7C3AED),
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


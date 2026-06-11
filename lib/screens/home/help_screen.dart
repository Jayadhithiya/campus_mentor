import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int? _expandedIndex;

  final List<Map<String, dynamic>> faqs = [
    {
      'category': 'Getting Started',
      'question': 'How does the AI interview work?',
      'answer':
          'AI acts as your interviewer and asks HR or technical questions. You type your answers and AI scores you on communication, content and confidence. Feedback is given in your chosen language.',
    },
    {
      'category': 'Getting Started',
      'question': 'How are questions generated?',
      'answer':
          'Claude AI generates fresh questions every session based on your domain, difficulty level and weak areas. Questions are never repeated so every session is unique.',
    },
    {
      'category': 'Getting Started',
      'question': 'Can I change my language anytime?',
      'answer':
          'Yes! Go to Profile → Settings → Language and select Tamil, Hindi or English. The change applies immediately across the whole app.',
    },
    {
      'category': 'Attendance',
      'question': 'Why is attendance showing wrong?',
      'answer':
          'Make sure you mark attendance daily in the Campus tab. Go to Campus → Mark Attendance → select Present, Absent or OD for each class. The percentage updates automatically.',
    },
    {
      'category': 'Attendance',
      'question': 'What is the minimum attendance required?',
      'answer':
          'Most Indian colleges require 75% minimum attendance to be eligible for exams. StriveCampus warns you when you drop below this and tells you how many classes you can safely miss.'
    },
    {
      'category': 'Account',
      'question': 'How do I reset my password?',
      'answer':
          'Go to Login screen → tap Forgot Password → enter your registered email → check your inbox for the reset link. The link expires in 24 hours.',
    },
    {
      'category': 'Account',
      'question': 'Is my data safe?',
      'answer':
          'Yes! All your data is stored securely in Firebase with encryption. We never share your personal information with anyone. Your test scores and attendance are private to your account only.',
    },
    {
      'category': 'AI Features',
      'question': 'Can I use StriveCampus offline?',
      'answer':
          'Basic features like timetable and assignments work offline. AI features like mock interviews, question generation and chatbot require an internet connection.',
    },
    {
      'category': 'AI Features',
      'question': 'How does the AI study planner work?',
      'answer':
          'AI analyses your test history, weak topics and upcoming schedule to create a personalised weekly study plan. It tells you exactly what to practice and when for maximum improvement.',
    },
  ];

  List<Map<String, dynamic>> get filteredFaqs {
    if (_searchQuery.isEmpty) return faqs;
    return faqs
        .where((faq) =>
            faq['question']
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            faq['answer']
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          child: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF45B08C),
          ),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() {
                _searchQuery = val;
                _expandedIndex = null;
              }),
              decoration: InputDecoration(
                hintText: 'Search for help...',
                hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF888888),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            color: Color(0xFF888888)),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
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
          ),

          // FAQ list
          Expanded(
            child: filteredFaqs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 48, color: Color(0xFFCCCCCC)),
                        SizedBox(height: 12),
                        Text(
                          'No results found!',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Try a different search term',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredFaqs.length,
                    itemBuilder: (context, index) {
                      final faq = filteredFaqs[index];
                      final isExpanded = _expandedIndex == index;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isExpanded
                                ? const Color(0xFF45B08C)
                                : const Color(0xFFE8E8F0),
                            width: isExpanded ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _expandedIndex =
                                      isExpanded ? null : index;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        faq['question'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isExpanded
                                              ? const Color(0xFF45B08C)
                                              : const Color(0xFF1A1A2E),
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: isExpanded
                                          ? const Color(0xFF45B08C)
                                          : const Color(0xFF888888),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isExpanded)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                    16, 0, 16, 16),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                        color: Color(0xFFE8E8F0)),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEEDFE),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        faq['category'],
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF45B08C),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      faq['answer'],
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF888888),
                                        height: 1.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Contact support card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8E8F0)),
            ),
            child: Column(
              children: [
                const Text(
                  'Still need help?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'We\'re here to help you. Reach out to us anytime!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF888888),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final Uri emailUri = Uri(
                        scheme: 'mailto',
                        path: 'jayadhithiya@gmail.com',
                        query:
                            'subject=StriveCampus Support&body=Hi, I need help with...',
                      );
                      if (await canLaunchUrl(emailUri)) {
                        await launchUrl(emailUri);
                      }
                    },
                    icon: const Icon(
                      Icons.email_outlined,
                      color: Color(0xFF45B08C),
                    ),
                    label: const Text(
                      'Contact Support',
                      style: TextStyle(
                        color: Color(0xFF45B08C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF45B08C)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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




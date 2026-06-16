import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_keys.dart';
import '../../services/user_service.dart';
import 'aptitude_result_screen.dart';

class AptitudeTestScreen extends StatefulWidget {
  final String course;
final String category;
final String difficulty;
final int questionCount;
final String domainTopics;

const AptitudeTestScreen({
  super.key,
  required this.course,
  required this.category,
  required this.difficulty,
  required this.questionCount,
  required this.domainTopics,
});

  @override
  State<AptitudeTestScreen> createState() => _AptitudeTestScreenState();
}

class _AptitudeTestScreenState extends State<AptitudeTestScreen> {
  List<Map<String, dynamic>> _questions = [];
  int _currentIndex = 0;
  String? _selectedAnswer;
  final Map<int, String> _answers = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  int _timeLeft = 0;
  Timer? _timer;

  static const String _apiKey = ApiKeys.groqKey;
  @override
  void initState() {
    super.initState();
    _generateQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timeLeft = widget.questionCount * 90;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _submitTest();
      }
    });
  }

  String _formatTime() {
    final mins = _timeLeft ~/ 60;
    final secs = _timeLeft % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<List<String>> _getPastQuestions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('aptitude_history')
            .where('category', isEqualTo: widget.category)
            .where('course', isEqualTo: widget.course)
            .limit(3)
            .get();

        List<String> pastQuestions = [];
        for (var doc in snapshot.docs) {
          final questions = doc.data()['questions'] as List? ?? [];
          for (var q in questions) {
            pastQuestions.add(q['question'] ?? '');
          }
        }
        return pastQuestions.take(10).toList();
      }
    } catch (e) { debugPrint('Caught error: e'); }
    return [];
  }

  String _buildPrompt(List<String> pastQuestions) {
  String avoidText = '';
  if (pastQuestions.isNotEmpty) {
    avoidText = '\nAvoid repeating: ${pastQuestions.take(5).join(' | ')}';
  }

  final domainContext = widget.category == 'Domain Specific'
      ? '\nFocus specifically on these topics: ${widget.domainTopics}'
      : '\nMake questions relevant to ${widget.course} students where possible. Key topics: ${widget.domainTopics}';

  return '''Generate ${widget.questionCount} ${widget.difficulty} ${widget.category} MCQ questions for ${widget.course} students.$domainContext$avoidText
  
Output ONLY this JSON, no other text:
[
{"question":"Q1?","options":{"A":"opt1","B":"opt2","C":"opt3","D":"opt4"},"correct":"A","explanation":"reason"},
{"question":"Q2?","options":{"A":"opt1","B":"opt2","C":"opt3","D":"opt4"},"correct":"B","explanation":"reason"}
]''';
  }

  Future<void> _generateQuestions() async {
    setState(() => _isLoading = true);

    final pastQuestions = await _getPastQuestions();

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        debugPrint('Attempt $attempt starting...');

        final response = await http
            .post(
              Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $_apiKey',
              },
              body: jsonEncode({
                'model': 'llama-3.3-70b-versatile',
                'messages': [
                  {
                    'role': 'system',
                    'content':
                        'You are a JSON generator. Output ONLY valid JSON arrays. Never output anything else. No markdown. No explanations. Just raw JSON starting with [ and ending with ].',
                  },
                  {'role': 'user', 'content': _buildPrompt(pastQuestions)},
                ],
                'temperature': 0.3,
                'max_tokens': 4096,
              }),
            )
            .timeout(const Duration(seconds: 40));

        if (response.statusCode == 200) {
          final groqData = jsonDecode(response.body);
          String rawText = groqData['choices'][0]['message']['content'];

          debugPrint('Raw (attempt $attempt): $rawText');

          // Clean response
          rawText = rawText.trim();
          rawText = rawText.replaceAll('```json', '');
          rawText = rawText.replaceAll('```', '');
          rawText = rawText.trim();

          // Extract JSON array
          final startIndex = rawText.indexOf('[');
          final endIndex = rawText.lastIndexOf(']');

          if (startIndex == -1 || endIndex == -1) {
            debugPrint('No JSON array found, retrying...');
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }

          rawText = rawText.substring(startIndex, endIndex + 1);

          try {
            final List<dynamic> parsed = jsonDecode(rawText);
            if (parsed.isNotEmpty) {
              setState(() {
                _questions = parsed
                    .map((q) => q as Map<String, dynamic>)
                    .toList();
                _isLoading = false;
              });
              _startTimer();
              debugPrint('Success! ${_questions.length} questions loaded.');
              return;
            } else {
              debugPrint('Empty array, retrying...');
            }
          } catch (parseError) {
            debugPrint('Parse error: $parseError');
          }
        } else {
          debugPrint('HTTP Error: ${response.statusCode} � ${response.body}');
        }
      } catch (e) {
        debugPrint('Exception attempt $attempt: $e');
      }

      await Future.delayed(const Duration(seconds: 2));
    }

    _showError();
  }

  void _showError() {
    setState(() => _isLoading = false);
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Failed to load questions'),
          content: const Text(
            'Could not generate questions. Please check your internet and try again.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Go Back'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _generateQuestions();
              },
              child: const Text(
                'Retry',
                style: TextStyle(color: Color(0xFF45B08C)),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _selectAnswer(String answer) {
    setState(() => _selectedAnswer = answer);
  }

  void _nextQuestion() {
    if (_selectedAnswer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an answer!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    _answers[_currentIndex] = _selectedAnswer!;

    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = _answers[_currentIndex];
      });
    } else {
      _submitTest();
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      if (_selectedAnswer != null) {
        _answers[_currentIndex] = _selectedAnswer!;
      }
      setState(() {
        _currentIndex--;
        _selectedAnswer = _answers[_currentIndex];
      });
    }
  }

  Future<void> _submitTest() async {
    _timer?.cancel();
    if (_selectedAnswer != null) {
      _answers[_currentIndex] = _selectedAnswer!;
    }

    setState(() => _isSubmitting = true);

    int score = 0;
    List<Map<String, dynamic>> results = [];

    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final userAnswer = _answers[i] ?? '';
      final correct = question['correct'] ?? '';
      final isCorrect = userAnswer == correct;
      if (isCorrect) score++;

      results.add({
        'question': question['question'],
        'options': question['options'],
        'correct': correct,
        'userAnswer': userAnswer,
        'isCorrect': isCorrect,
        'explanation': question['explanation'] ?? '',
      });
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('aptitude_history')
            .add({
              'course': widget.course,
              'category': widget.category,
              'difficulty': widget.difficulty,
              'score': score,
              'total': _questions.length,
              'percentage': ((score / _questions.length) * 100).round(),
              'questions': results,
              'createdAt': DateTime.now().toIso8601String(),
            });

        await UserService.updateStreakAndTests(user.uid);
      }
    } catch (e) { debugPrint('Caught error: e'); }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AptitudeResultScreen(
            score: score,
            total: _questions.length,
            results: results,
            course: widget.course,
            category: widget.category,
            difficulty: widget.difficulty,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FF),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF45B08C)),
              const SizedBox(height: 24),
              const Text(
                'Your questions are getting ready...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.questionCount} ${widget.difficulty} ${widget.category} questions\nfor ${widget.course} students',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
              ),
            ],
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Color(0xFFCCCCCC),
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load questions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _generateQuestions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF45B08C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];
    final options = question['options'] as Map<String, dynamic>;
    final progress = (_currentIndex + 1) / _questions.length;
    final isRed = _timeLeft < 60;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Quit Test?'),
              content: const Text('Your progress will be lost. Are you sure?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Continue Test'),
                ),
                TextButton(
                  onPressed: () {
                    _timer?.cancel();
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Quit',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
          child: const Icon(Icons.close, color: Color(0xFF1A1A2E)),
        ),
        title: Column(
          children: [
            Text(
              '${widget.category} � ${widget.difficulty}',
              style: const TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.course,
              style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isRed ? const Color(0xFFEF4444) : const Color(0xFFEEEDFE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: isRed ? Colors.white : const Color(0xFF45B08C),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isRed ? Colors.white : const Color(0xFF45B08C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFE8E8F0),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF45B08C)),
            minHeight: 4,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEDFE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Q${_currentIndex + 1} of ${_questions.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF45B08C),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    question['question'] ?? '',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...options.entries.map((entry) {
                    final isSelected = _selectedAnswer == entry.key;
                    return GestureDetector(
                      onTap: () => _selectAnswer(entry.key),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEEEDFE)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF45B08C)
                                : const Color(0xFFE8E8F0),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF45B08C)
                                    : const Color(0xFFF8F9FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF888888),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.value.toString(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected
                                      ? const Color(0xFF45B08C)
                                      : const Color(0xFF1A1A2E),
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE8E8F0))),
            ),
            child: Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousQuestion,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE8E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        '? Previous',
                        style: TextStyle(color: Color(0xFF888888)),
                      ),
                    ),
                  ),
                if (_currentIndex > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF45B08C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : Text(
                            _currentIndex == _questions.length - 1
                                ? 'Submit Test'
                                : 'Next ?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
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



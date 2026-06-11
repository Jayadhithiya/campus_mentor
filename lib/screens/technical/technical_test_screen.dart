import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_keys.dart';
import '../../services/user_service.dart';
import 'technical_result_screen.dart';

class TechnicalTestScreen extends StatefulWidget {
  final String subject;
  final String difficulty;
  final String mode;
  final int questionCount;
  final String language;
  final String pistonLanguage;
  final String department;

  const TechnicalTestScreen({
    super.key,
    required this.subject,
    required this.difficulty,
    required this.mode,
    required this.questionCount,
    required this.language,
    required this.pistonLanguage,
    required this.department,
  });

  @override
  State<TechnicalTestScreen> createState() =>
      _TechnicalTestScreenState();
}

class _TechnicalTestScreenState extends State<TechnicalTestScreen> {
  List<Map<String, dynamic>> _questions = [];
  int _currentIndex = 0;
  String? _selectedAnswer;
  //String _userCode = '';
  String _codeOutput = '';
  bool _isRunningCode = false;
  final Map<int, dynamic> _answers = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  int _timeLeft = 0;
  Timer? _timer;
  final TextEditingController _codeController = TextEditingController();

  static const String _groqKey = ApiKeys.groqKey;

  @override
  void initState() {
    super.initState();
    _generateQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timeLeft = widget.questionCount * 120;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
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

  String _buildPrompt() {
    if (widget.mode == 'MCQ Theory') {
      return '''Generate exactly ${widget.questionCount} ${widget.difficulty} difficulty MCQ theory questions on ${widget.subject} for ${widget.department} students.

STRICT RULES:
1. Return ONLY a JSON array
2. No markdown, no backticks
3. Start with [ end with ]
4. Each question has 4 options A B C D
5. One correct answer only

JSON format:
[{"question":"...","options":{"A":"...","B":"...","C":"...","D":"..."},"correct":"A","explanation":"..."}]''';
    } else if (widget.mode == 'Code Output') {
      return '''Generate exactly ${widget.questionCount} ${widget.difficulty} "predict the output" questions on ${widget.subject} using ${widget.language} programming language for ${widget.department} students.

STRICT RULES:
1. Return ONLY a JSON array
2. No markdown, no backticks
3. Start with [ end with ]
4. Show a code snippet and ask what the output will be
5. 4 options A B C D with one correct answer

JSON format:
[{"question":"What is the output of this code?\\n\\ncode_here","options":{"A":"...","B":"...","C":"...","D":"..."},"correct":"A","explanation":"..."}]''';
    } else {
      return '''Generate exactly ${widget.questionCount} ${widget.difficulty} coding challenge problems on ${widget.subject} for ${widget.department} students using ${widget.language}.

STRICT RULES:
1. Return ONLY a JSON array
2. No markdown, no backticks
3. Start with [ end with ]
4. Each problem has a description, starter code, expected output for test case

JSON format:
[{"question":"Problem description here","starterCode":"# Write your solution here\\ndef solution():\\n    pass","testInput":"test input here","expectedOutput":"expected output here","hint":"helpful hint"}]''';
    }
  }

  Future<void> _generateQuestions() async {
    setState(() => _isLoading = true);

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final response = await http.post(
          Uri.parse(
              'https://api.groq.com/openai/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_groqKey',
          },
          body: jsonEncode({
            'model': 'llama-3.3-70b-versatile',
            'messages': [
              {
                'role': 'system',
                'content':
                    'You are a JSON generator. Output ONLY valid JSON arrays. Never output anything else. No markdown. No explanations. Just raw JSON starting with [ and ending with ].',
              },
              {
                'role': 'user',
                'content': _buildPrompt(),
              }
            ],
            'temperature': 0.3,
            'max_tokens': 4096,
          }),
        ).timeout(const Duration(seconds: 40));

        if (response.statusCode == 200) {
          final groqData = jsonDecode(response.body);
          String rawText =
              groqData['choices'][0]['message']['content'];

          rawText = rawText.trim();
          rawText = rawText.replaceAll('```json', '');
          rawText = rawText.replaceAll('```', '');
          rawText = rawText.trim();

          final startIndex = rawText.indexOf('[');
          final endIndex = rawText.lastIndexOf(']');

          if (startIndex != -1 && endIndex != -1) {
            rawText =
                rawText.substring(startIndex, endIndex + 1);
          }

          try {
            final List<dynamic> parsed = jsonDecode(rawText);
            if (parsed.isNotEmpty) {
              setState(() {
                _questions = parsed
                    .map((q) => q as Map<String, dynamic>)
                    .toList();
                _isLoading = false;
              });

              // Set starter code for coding challenge
              if (widget.mode == 'Coding Challenge' &&
                  _questions.isNotEmpty) {
                _codeController.text =
                    _questions[0]['starterCode'] ?? '';
              }

              _startTimer();
              return;
            }
          } catch (e) {
            debugPrint('Parse error attempt $attempt: $e');
          }
        } else {
          debugPrint('Error $attempt: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Exception $attempt: $e');
      }

      await Future.delayed(const Duration(seconds: 2));
    }

    _showError();
  }

Future<void> _runCode() async {
  if (_codeController.text.trim().isEmpty) return;

  setState(() {
    _isRunningCode = true;
    _codeOutput = '';
  });

  try {
    // Map language to correct Piston language and version
    String pistonLang = widget.pistonLanguage;
    String version = '*';

    if (pistonLang == 'python') {
      pistonLang = 'python';
      version = '3.10.0';
    } else if (pistonLang == 'java') {
      pistonLang = 'java';
      version = '15.0.2';
    } else if (pistonLang == 'c++') {
      pistonLang = 'c++';
      version = '10.2.0';
    } else if (pistonLang == 'c') {
      pistonLang = 'c';
      version = '10.2.0';
    }

    final response = await http.post(
      Uri.parse('https://emkc.org/api/v2/piston/execute'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'language': pistonLang,
        'version': version,
        'files': [
          {
            'name': pistonLang == 'java'
                ? 'Main.java'
                : pistonLang == 'c++'
                    ? 'main.cpp'
                    : pistonLang == 'c'
                        ? 'main.c'
                        : 'main.py',
            'content': _codeController.text,
          }
        ],
        'stdin': _questions[_currentIndex]['testInput'] ?? '',
      }),
    ).timeout(const Duration(seconds: 20));

    debugPrint('Piston status: ${response.statusCode}');
    debugPrint('Piston body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final stdout = data['run']['stdout'] ?? '';
      final stderr = data['run']['stderr'] ?? '';
   
      setState(() {
        if (stderr.isNotEmpty && stdout.isEmpty) {
          _codeOutput = 'Error: $stderr';
        } else if (stdout.isNotEmpty) {
          _codeOutput = stdout.trim();
        } else {
          _codeOutput = 'No output produced';
        }
        _isRunningCode = false;
        _answers[_currentIndex] = _codeController.text;
      });
    } else {
      debugPrint('Piston error: ${response.body}');
      setState(() {
        _codeOutput = 'Server error (${response.statusCode}). Try again!';
        _isRunningCode = false;
      });
    }
  } catch (e) {
    debugPrint('Piston exception: $e');
    setState(() {
      _codeOutput = 'Connection failed. Check internet and try again!';
      _isRunningCode = false;
    });
  }
}

  void _showError() {
    if (!mounted) return;
    setState(() => _isLoading = false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Failed to load questions'),
        content: const Text(
            'Could not generate questions. Please check your internet and try again.'),
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
            child: const Text('Retry',
                style: TextStyle(color: Color(0xFF7C3AED))),
          ),
        ],
      ),
    );
  }

  void _selectAnswer(String answer) {
    setState(() => _selectedAnswer = answer);
  }

  void _nextQuestion() {
    if (widget.mode == 'Coding Challenge') {
      _answers[_currentIndex] = _codeController.text;
    } else {
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
    }

    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer =
            _answers[_currentIndex] as String?;
        if (widget.mode == 'Coding Challenge') {
          _codeController.text =
              _answers[_currentIndex] as String? ??
                  _questions[_currentIndex]['starterCode'] ??
                  '';
          _codeOutput = '';
        }
      });
    } else {
      _submitTest();
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      if (widget.mode == 'Coding Challenge') {
        _answers[_currentIndex] = _codeController.text;
      } else if (_selectedAnswer != null) {
        _answers[_currentIndex] = _selectedAnswer!;
      }
      setState(() {
        _currentIndex--;
        _selectedAnswer =
            _answers[_currentIndex] as String?;
        if (widget.mode == 'Coding Challenge') {
          _codeController.text =
              _answers[_currentIndex] as String? ??
                  _questions[_currentIndex]['starterCode'] ??
                  '';
          _codeOutput = '';
        }
      });
    }
  }

  Future<void> _submitTest() async {
    _timer?.cancel();

    if (widget.mode == 'Coding Challenge') {
      _answers[_currentIndex] = _codeController.text;
    } else if (_selectedAnswer != null) {
      _answers[_currentIndex] = _selectedAnswer!;
    }

    setState(() => _isSubmitting = true);

    int score = 0;
    List<Map<String, dynamic>> results = [];

    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final userAnswer = _answers[i]?.toString() ?? '';

      if (widget.mode == 'Coding Challenge') {
        results.add({
          'question': question['question'],
          'starterCode': question['starterCode'] ?? '',
          'userCode': userAnswer,
          'expectedOutput': question['expectedOutput'] ?? '',
          'hint': question['hint'] ?? '',
          'mode': 'coding',
        });
      } else {
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
          'mode': widget.mode,
        });
      }
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('technical_history')
            .add({
          'subject': widget.subject,
          'difficulty': widget.difficulty,
          'mode': widget.mode,
          'score': score,
          'total': widget.mode == 'Coding Challenge'
              ? 0
              : _questions.length,
          'percentage': widget.mode == 'Coding Challenge'
              ? 0
              : ((_questions.isNotEmpty)
                  ? ((score / _questions.length) * 100).round()
                  : 0),
          'results': results,
          'createdAt': DateTime.now().toIso8601String(),
        });

        await UserService.updateStreakAndTests(user.uid);
      }
    } catch (e) { debugPrint('Caught error: e'); }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TechnicalResultScreen(
            score: score,
            total: _questions.length,
            results: results,
            subject: widget.subject,
            difficulty: widget.difficulty,
            mode: widget.mode,
            language: widget.language,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                  color: Color(0xFF7C3AED)),
              const SizedBox(height: 24),
              const Text(
                'AI is generating questions...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.questionCount} ${widget.difficulty} ${widget.mode} questions\non ${widget.subject}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF888888),
                ),
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
              const Icon(Icons.error_outline,
                  size: 60, color: Color(0xFFCCCCCC)),
              const SizedBox(height: 16),
              const Text('Failed to load questions'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _generateQuestions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                ),
                child: const Text('Retry',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];
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
              content: const Text(
                  'Your progress will be lost. Are you sure?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Continue'),
                ),
                TextButton(
                  onPressed: () {
                    _timer?.cancel();
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Quit',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
          child: const Icon(Icons.close,
              color: Color(0xFF1A1A2E)),
        ),
        title: Column(
          children: [
            Text(
              widget.subject,
              style: const TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${widget.mode} � ${widget.difficulty}',
              style: const TextStyle(
                color: Color(0xFF888888),
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isRed
                  ? const Color(0xFFEF4444)
                  : const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.timer_outlined,
                    size: 14,
                    color: isRed
                        ? Colors.white
                        : const Color(0xFF7C3AED)),
                const SizedBox(width: 4),
                Text(
                  _formatTime(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isRed
                        ? Colors.white
                        : const Color(0xFF7C3AED),
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
            valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF7C3AED)),
            minHeight: 4,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question counter + mode badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Q${_currentIndex + 1} of ${_questions.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.mode,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Question text
                  Text(
                    question['question'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // MCQ / Code Output options
                  if (widget.mode != 'Coding Challenge') ...[
                    ...(question['options']
                            as Map<String, dynamic>)
                        .entries
                        .map((entry) {
                      final isSelected =
                          _selectedAnswer == entry.key;
                      return GestureDetector(
                        onTap: () => _selectAnswer(entry.key),
                        child: Container(
                          margin: const EdgeInsets.only(
                              bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFEDE9FE)
                                : Colors.white,
                            borderRadius:
                                BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF7C3AED)
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
                                      ? const Color(0xFF7C3AED)
                                      : const Color(0xFFFFFFFF),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(
                                              0xFF888888),
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
                                        ? const Color(0xFF7C3AED)
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

                  // Coding Challenge
                  if (widget.mode == 'Coding Challenge') ...[
                    // Language badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.language,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Code editor
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          // Editor header
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2D2D3F),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.code,
                                    color: Color(0xFF7C3AED),
                                    size: 16),
                                const SizedBox(width: 8),
                                const Text(
                                  'Code Editor',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    _codeController.text =
                                        question['starterCode'] ??
                                            '';
                                  },
                                  child: const Text(
                                    'Reset',
                                    style: TextStyle(
                                      color: Color(0xFF888888),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Code input
                          TextField(
                            controller: _codeController,
                            maxLines: 12,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontFamily: 'monospace',
                              height: 1.5,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Run button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed:
                            _isRunningCode ? null : _runCode,
                        icon: _isRunningCode
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.play_arrow,
                                color: Colors.white),
                        label: Text(
                          _isRunningCode
                              ? 'Running...'
                              : 'Run Code ?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF22C55E),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                    // Output
                    if (_codeOutput.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _codeOutput
                                  .startsWith('Error')
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _codeOutput
                                    .startsWith('Error')
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF22C55E),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              _codeOutput.startsWith('Error')
                                  ? '? Error'
                                  : '? Output',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _codeOutput
                                        .startsWith('Error')
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF22C55E),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _codeOutput,
                              style: const TextStyle(
                                fontSize: 13,
                                fontFamily: 'monospace',
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Expected output
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFE8E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '?? Expected Output',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF888888),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              question['expectedOutput'] ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                fontFamily: 'monospace',
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Hint
                    if (question['hint'] != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Text('?? ',
                                style: TextStyle(fontSize: 14)),
                            Expanded(
                              child: Text(
                                question['hint'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),

          // Bottom navigation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE8E8F0)),
              ),
            ),
            child: Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousQuestion,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFFE8E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                      ),
                      child: const Text('? Previous',
                          style: TextStyle(
                              color: Color(0xFF888888))),
                    ),
                  ),
                if (_currentIndex > 0)
                  const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed:
                        _isSubmitting ? null : _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)
                        : Text(
                            _currentIndex ==
                                    _questions.length - 1
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

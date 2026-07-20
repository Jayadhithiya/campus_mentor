import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_keys.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../services/user_service.dart';
import 'hr_result_screen.dart';

class HRInterviewScreen extends StatefulWidget {
  final String interviewType;
  final int questionCount;
  final String department;
  final String userName;

  const HRInterviewScreen({
    super.key,
    required this.interviewType,
    required this.questionCount,
    required this.department,
    required this.userName,
  });

  @override
  State<HRInterviewScreen> createState() => _HRInterviewScreenState();
}

class _HRInterviewScreenState extends State<HRInterviewScreen> {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  List<Map<String, dynamic>> _questions = [];
  int _currentIndex = 0;
  final TextEditingController _answerController = TextEditingController();
  final List<Map<String, dynamic>> _answers = [];
  bool _isLoadingQuestions = true;
  bool _isEvaluating = false;
  bool _isSubmitting = false;
  Map<String, dynamic>? _currentFeedback;
  int _timeLeft = 0;
  Timer? _timer;

  static final String _groqKey = ApiKeys.groqKey;

  @override
  void initState() {
    super.initState();
    _generateQuestions();
    _initSpeech();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speech.stop();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (error) => debugPrint('Speech error: $error'),
    );
    setState(() {});
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition not available!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _answerController.text = result.recognizedWords;
            _answerController.selection = TextSelection.fromPosition(
              TextPosition(offset: _answerController.text.length),
            );
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_IN',
      );
    }
  }

  void _startTimer() {
    _timeLeft = widget.questionCount * 180;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _submitInterview();
      }
    });
  }

  String _formatTime() {
    final mins = _timeLeft ~/ 60;
    final secs = _timeLeft % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _buildQuestionsPrompt() {
    String context = '';
    if (widget.interviewType == 'HR Round') {
      context =
          'behavioural, personality, strength/weakness, situational HR questions';
    } else if (widget.interviewType == 'Technical HR') {
      context =
          'mix of technical domain questions for ${widget.department} and HR behavioural questions';
    } else if (widget.interviewType == 'Group Discussion') {
      context =
          'GD topics and discussion questions relevant for ${widget.department} students and current affairs';
    } else {
      context =
          'full mock interview questions mixing technical, HR and situational questions for ${widget.department} students';
    }

    return '''Generate exactly ${widget.questionCount} interview questions for a ${widget.department} student.
Interview type: ${widget.interviewType}
Focus: $context

STRICT RULES:
1. Return ONLY a JSON array
2. No markdown, no backticks
3. Start with [ end with ]

JSON format:
[{"question":"Tell me about yourself?","category":"HR","tips":"Focus on education, skills and career goals"}]''';
  }

  Future<void> _generateQuestions() async {
    setState(() => _isLoadingQuestions = true);

    if (!ApiKeys.isGroqKeyConfigured) {
      if (mounted) {
        setState(() => _isLoadingQuestions = false);
        _showError(
          customMessage: 'Groq API Key is not configured. Please create a `.env` file at the root of the project with `GROQ_KEY=gsk_...` or set it in `lib/core/constants/api_keys.dart`. 🔑'
        );
      }
      return;
    }

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
                    'You are a JSON generator. Output ONLY valid JSON arrays. Never output anything else.',
              },
              {
                'role': 'user',
                'content': _buildQuestionsPrompt(),
              }
            ],
            'temperature': 0.5,
            'max_tokens': 2048,
          }),
        ).timeout(const Duration(seconds: 30));

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
                _isLoadingQuestions = false;
              });
              _startTimer();
              return;
            }
          } catch (e) {
            debugPrint('Parse error: $e');
          }
        } else if (response.statusCode == 401 || response.body.contains('invalid_api_key')) {
          if (mounted) {
            setState(() => _isLoadingQuestions = false);
            _showError(
              customMessage: 'Invalid or unauthorized Groq API key. Please check your configuration in `.env` or `api_keys.dart`. 🔑'
            );
          }
          return;
        }
      } catch (e) {
        debugPrint('Exception: $e');
      }
      await Future.delayed(const Duration(seconds: 2));
    }

    if (mounted) {
      setState(() => _isLoadingQuestions = false);
      _showError();
    }
  }

  Future<void> _evaluateAnswer() async {
    if (_answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please type or speak your answer first!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    }

    setState(() => _isEvaluating = true);

    try {
      final question = _questions[_currentIndex];
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
                  'You are an expert HR interviewer evaluating candidate answers. Return ONLY valid JSON, no markdown.',
            },
            {
              'role': 'user',
              'content':
                  '''Evaluate this interview answer for a ${widget.department} student.

Question: ${question['question']}
Answer: ${_answerController.text}

Return ONLY this JSON:
{"score":8,"feedback":"Your feedback here","strengths":"What was good","improvements":"What to improve","sampleAnswer":"A better answer would be..."}

Score should be 1-10.''',
            }
          ],
          'temperature': 0.3,
          'max_tokens': 1024,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final groqData = jsonDecode(response.body);
        String rawText =
            groqData['choices'][0]['message']['content'];

        rawText = rawText.trim();
        rawText = rawText.replaceAll('```json', '');
        rawText = rawText.replaceAll('```', '');
        rawText = rawText.trim();

        final startIndex = rawText.indexOf('{');
        final endIndex = rawText.lastIndexOf('}');

        if (startIndex != -1 && endIndex != -1) {
          rawText = rawText.substring(startIndex, endIndex + 1);
        }

        try {
          final feedback = jsonDecode(rawText);
          setState(() {
            _currentFeedback = feedback;
            _isEvaluating = false;
          });

          _answers.add({
            'question': question['question'],
            'category': question['category'] ?? 'HR',
            'answer': _answerController.text,
            'score': feedback['score'] ?? 5,
            'feedback': feedback['feedback'] ?? '',
            'strengths': feedback['strengths'] ?? '',
            'improvements': feedback['improvements'] ?? '',
            'sampleAnswer': feedback['sampleAnswer'] ?? '',
          });
        } catch (e) {
          setState(() => _isEvaluating = false);
          _addDefaultFeedback();
        }
      } else if (response.statusCode == 401 || response.body.contains('invalid_api_key')) {
        setState(() => _isEvaluating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid Groq API Key! Please check config. 🔑'),
            backgroundColor: Colors.red,
          ),
        );
        _addDefaultFeedback();
      } else {
        setState(() => _isEvaluating = false);
        _addDefaultFeedback();
      }
    } catch (e) {
      setState(() => _isEvaluating = false);
      _addDefaultFeedback();
    }
  }

  void _addDefaultFeedback() {
    setState(() {
      _currentFeedback = {
        'score': 6,
        'feedback': 'Good attempt! Keep practicing.',
        'strengths': 'You attempted the question.',
        'improvements': 'Be more specific with examples.',
        'sampleAnswer': 'Try to use the STAR method for answers.',
      };
    });
    _answers.add({
      'question': _questions[_currentIndex]['question'],
      'category': _questions[_currentIndex]['category'] ?? 'HR',
      'answer': _answerController.text,
      'score': 6,
      'feedback': 'Good attempt! Keep practicing.',
      'strengths': 'You attempted the question.',
      'improvements': 'Be more specific with examples.',
      'sampleAnswer': 'Try to use the STAR method.',
    });
  }

  void _nextQuestion() {
    if (_currentFeedback == null) {
      _evaluateAnswer();
      return;
    }

    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _answerController.clear();
        _currentFeedback = null;
      });
    } else {
      _submitInterview();
    }
  }

  Future<void> _submitInterview() async {
    _timer?.cancel();

    if (_currentFeedback == null &&
        _answerController.text.isNotEmpty) {
      _addDefaultFeedback();
    }

    setState(() => _isSubmitting = true);

    final totalScore = _answers.isEmpty
        ? 0
        : (_answers.fold<double>(
                    0.0,
                    (acc, a) =>
                        acc + ((a['score'] as num).toDouble())) /
                _answers.length)
            .round();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('hr_history')
            .add({
          'interviewType': widget.interviewType,
          'department': widget.department,
          'totalScore': totalScore,
          'answers': _answers,
          'createdAt': DateTime.now().toIso8601String(),
        });

        await UserService.updateStreakAndTests(user.uid);
      }
    } catch (e) { debugPrint('Caught error: e'); }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HRResultScreen(
            answers: _answers,
            totalScore: totalScore,
            interviewType: widget.interviewType,
            department: widget.department,
            userName: widget.userName,
          ),
        ),
      );
    }
  }

  void _showError({String? customMessage}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Failed to load questions'),
        content:
            Text(customMessage ?? 'Please check internet and try again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Go Back'),
          ),
          if (customMessage == null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _generateQuestions();
              },
              child: const Text('Retry',
                  style: TextStyle(color: Color(0xFFE91E8C))),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingQuestions) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FF),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                  color: Color(0xFFE91E8C)),
              const SizedBox(height: 24),
              const Text(
                'AI is preparing your interview...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.questionCount} ${widget.interviewType} questions\nfor ${widget.department}',
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
                    backgroundColor: const Color(0xFFE91E8C)),
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
              title: const Text('Quit Interview?'),
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
              widget.interviewType,
              style: const TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.department,
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
                  : const Color(0xFFFFE4F3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.timer_outlined,
                    size: 14,
                    color: isRed
                        ? Colors.white
                        : const Color(0xFFE91E8C)),
                const SizedBox(width: 4),
                Text(
                  _formatTime(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isRed
                        ? Colors.white
                        : const Color(0xFFE91E8C),
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
                Color(0xFFE91E8C)),
            minHeight: 4,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question counter
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE4F3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Q${_currentIndex + 1} of ${_questions.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE91E8C),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE4F3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          question['category'] ?? 'HR',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE91E8C),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // AI Interviewer avatar
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE91E8C),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.smart_toy_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F7),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                            border: Border.all(
                                color: const Color(0xFFFFCCE8)),
                          ),
                          child: Text(
                            question['question'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF1A1A2E),
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (question['tips'] != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 52),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Text('?? Tip: ',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF92400E))),
                            Expanded(
                              child: Text(
                                question['tips'],
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Answer input with mic button
                  if (_currentFeedback == null) ...[
                    Row(
                      children: [
                        const Text(
                          'Your Answer:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _toggleListening,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isListening
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFFFFE4F3),
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isListening
                                      ? Icons.mic
                                      : Icons.mic_outlined,
                                  color: _isListening
                                      ? Colors.white
                                      : const Color(0xFFE91E8C),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isListening
                                      ? 'Listening...'
                                      : 'Speak',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _isListening
                                        ? Colors.white
                                        : const Color(0xFFE91E8C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Listening indicator
                    if (_isListening)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444)
                              .withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(Icons.graphic_eq,
                                color: Color(0xFFEF4444),
                                size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Listening... Speak your answer clearly',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                    TextField(
                      controller: _answerController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText:
                            'Type your answer or tap Speak above...\n\nTip: Use specific examples from your experience',
                        hintStyle: const TextStyle(
                            color: Color(0xFFAAAAAA),
                            fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FF),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFFE8E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFFE8E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFFE91E8C),
                              width: 2),
                        ),
                      ),
                    ),
                  ],

                  // Feedback section
                  if (_currentFeedback != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFE8E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Answer:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF888888),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _answerController.text,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFE91E8C)
                                .withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _getScoreColor(
                                        _currentFeedback![
                                            'score']),
                                    width: 3,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${_currentFeedback!['score']}/10',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight:
                                          FontWeight.bold,
                                      color: _getScoreColor(
                                          _currentFeedback![
                                              'score']),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'AI Feedback',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight:
                                            FontWeight.bold,
                                        color: Color(0xFF1A1A2E),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _currentFeedback![
                                              'feedback'] ??
                                          '',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF888888),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(
                              color: Color(0xFFE8E8F0)),
                          const SizedBox(height: 8),
                          _buildFeedbackRow(
                            '? Strengths',
                            _currentFeedback!['strengths'] ??
                                '',
                            const Color(0xFF22C55E),
                          ),
                          const SizedBox(height: 8),
                          _buildFeedbackRow(
                            '?? Improve',
                            _currentFeedback!['improvements'] ??
                                '',
                            const Color(0xFFF59E0B),
                          ),
                          const SizedBox(height: 8),
                          _buildFeedbackRow(
                            '?? Sample Answer',
                            _currentFeedback!['sampleAnswer'] ??
                                '',
                            const Color(0xFF45B08C),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                  top: BorderSide(color: Color(0xFFE8E8F0))),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isEvaluating || _isSubmitting
                    ? null
                    : _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E8C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isEvaluating
                    ? const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'AI is evaluating...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        _currentFeedback == null
                            ? 'Submit Answer ? Get Feedback'
                            : _currentIndex ==
                                    _questions.length - 1
                                ? 'Finish Interview'
                                : 'Next Question ?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
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

  Color _getScoreColor(dynamic score) {
    final s = (score as num).toInt();
    if (s >= 8) return const Color(0xFF22C55E);
    if (s >= 6) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Widget _buildFeedbackRow(
      String label, String content, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF888888),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}



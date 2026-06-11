import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/constants/api_keys.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  String _userName = '';
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _assignments = [];

  static const String _apiKey = ApiKeys.groqKey;

  @override
  void initState() {
    super.initState();
    _loadUserContext();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add({
      'role': 'assistant',
      'text':
          'Hi! I\'m your Campus Assistant 👋\n\nI can help you with:\n• Your attendance status\n• Assignment deadlines\n• Schedule questions\n• Study tips\n\nWhat would you like to know?',
      'time': _getTime(),
    });
  }

  Future<void> _loadUserContext() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          _userName = userDoc.data()?['firstName'] ?? 'Student';
        }

        final attendanceSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('attendance')
            .get();
        _subjects = attendanceSnap.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();

        final assignmentSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('assignments')
            .where('completed', isEqualTo: false)
            .get();
        _assignments = assignmentSnap.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      }
    } catch (e) { debugPrint('Caught error: e'); }
  }

  String _getTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : now.hour;
    final min = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $period';
  }

  String _buildContext() {
    String context =
        'You are a helpful campus assistant for a college student app called StriveCampus.\n';
    context +=
        'Be friendly, concise and helpful. Use emojis occasionally. Keep responses short.\n\n';
    context += 'Student name: $_userName\n\n';

    if (_subjects.isNotEmpty) {
      context += 'Attendance data:\n';
      for (var subject in _subjects) {
        final total = (subject['total'] ?? 0) as int;
        final present = (subject['present'] ?? 0) as int;
        final target = (subject['target'] ?? 75) as int;
        final percentage = total > 0
            ? ((present / total) * 100).toStringAsFixed(1)
            : '0';
        context +=
            '- ${subject['subject']}: $percentage% ($present/$total classes, target: $target%)\n';
      }
    }

    if (_assignments.isNotEmpty) {
      context += '\nPending assignments:\n';
      for (var assignment in _assignments) {
        final dueDate = assignment['dueDate'] != null
            ? DateTime.tryParse(assignment['dueDate'])
            : null;
        final dueDateStr = dueDate != null
            ? '${dueDate.day}/${dueDate.month}/${dueDate.year}'
            : 'No date';
        context +=
            '- ${assignment['title']} (${assignment['subject'] ?? 'No subject'}) due $dueDateStr, priority: ${assignment['priority'] ?? 'Medium'}\n';
      }
    }

    return context;
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'role': 'user',
        'text': text,
        'time': _getTime(),
      });
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final systemContext = _buildContext();

      final response = await http.post(
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
              'content': systemContext,
            },
            {
              'role': 'user',
              'content': text,
            }
          ],
          'temperature': 0.7,
          'max_tokens': 2048,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'];
        setState(() {
          _messages.add({
            'role': 'assistant',
            'text': reply,
            'time': _getTime(),
          });
          _isTyping = false;
        });
      } else {
        debugPrint('Error: ${response.statusCode}');
        debugPrint('Body: ${response.body}');
        _addErrorMessage();
      }
    } catch (e) {
      debugPrint('Exception: $e');
      _addErrorMessage();
    }

    _scrollToBottom();
  }

  void _addErrorMessage() {
    setState(() {
      _messages.add({
        'role': 'assistant',
        'text':
            'Sorry, I couldn\'t connect right now. Please check your internet connection and try again! 🔄',
        'time': _getTime(),
      });
      _isTyping = false;
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
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
          child: const Icon(Icons.arrow_back_ios,
              color: Color(0xFF45B08C)),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF45B08C),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Campus Assistant',
                  style: TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Powered by Groq AI',
                  style: TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  'Am I safe to bunk?',
                  'What\'s due this week?',
                  'My attendance status',
                  'Study tips for exams',
                ].map((chip) {
                  return GestureDetector(
                    onTap: () {
                      _messageController.text = chip;
                      _sendMessage();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEDFE),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF45B08C)
                                .withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        chip,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF45B08C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return _buildTypingIndicator();
                }
                final message = _messages[index];
                final isUser = message['role'] == 'user';
                return _buildMessageBubble(message, isUser);
              },
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask anything...',
                      hintStyle:
                          const TextStyle(color: Color(0xFFAAAAAA)),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                            color: Color(0xFFE8E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                            color: Color(0xFFE8E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                            color: Color(0xFF45B08C), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: Color(0xFF45B08C),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
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

  Widget _buildMessageBubble(
      Map<String, dynamic> message, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF45B08C),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser
                        ? const Color(0xFF45B08C)
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft:
                          Radius.circular(isUser ? 16 : 4),
                      bottomRight:
                          Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: const Color(0xFFE8E8F0)),
                  ),
                  child: isUser
                      ? Text(
                          message['text'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        )
                      : MarkdownBody(
                          data: message['text'],
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1A1A2E),
                              height: 1.4,
                            ),
                            strong: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1A1A2E),
                              fontWeight: FontWeight.bold,
                            ),
                            listBullet: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  message['time'],
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFAAAAAA),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF45B08C),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF45B08C)
                .withValues(alpha: 0.3 + (value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}


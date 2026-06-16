import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/constants/api_keys.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  String _userName = '';
  String _department = '';
  List<Map<String, dynamic>> _aptitudeHistory = [];
  List<Map<String, dynamic>> _technicalHistory = [];
  List<Map<String, dynamic>> _hrHistory = [];
  String _aiPlan = '';
  bool _isLoadingPlan = false;

  static const String _groqKey = ApiKeys.groqKey;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load user info
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          _userName = userDoc.data()?['firstName'] ?? 'Student';
          _department =
              userDoc.data()?['department'] ?? 'Computer Science (CSE)';
        }

        // Load aptitude history
        final aptSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('aptitude_history')
            .orderBy('createdAt', descending: true)
            .limit(10)
            .get();
        _aptitudeHistory = aptSnap.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();

        // Load technical history
        final techSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('technical_history')
            .orderBy('createdAt', descending: true)
            .limit(10)
            .get();
        _technicalHistory = techSnap.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();

        // Load HR history
        final hrSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('hr_history')
            .orderBy('createdAt', descending: true)
            .limit(10)
            .get();
        _hrHistory = hrSnap.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      }
    } catch (e) {
      debugPrint('Analytics load error: $e');
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  double get _aptitudeAvg {
    if (_aptitudeHistory.isEmpty) return 0;
    final total = _aptitudeHistory.fold<double>(
      0,
      (acc, h) => acc + ((h['percentage'] as num?)?.toDouble() ?? 0),
    );
    return total / _aptitudeHistory.length;
  }

  double get _technicalAvg {
    final filtered = _technicalHistory
        .where((h) => h['mode'] != 'Coding Challenge')
        .toList();
    if (filtered.isEmpty) return 0;
    final total = filtered.fold<double>(
      0,
      (acc, h) => acc + ((h['percentage'] as num?)?.toDouble() ?? 0),
    );
    return total / filtered.length;
  }

  double get _hrAvg {
    if (_hrHistory.isEmpty) return 0;
    final total = _hrHistory.fold<double>(
      0,
      (acc, h) => acc + ((h['totalScore'] as num?)?.toDouble() ?? 0) * 10,
    );
    return total / _hrHistory.length;
  }

  int get _totalTests =>
      _aptitudeHistory.length + _technicalHistory.length + _hrHistory.length;

  Future<void> _generateAIPlan() async {
    if (!mounted) return;
    setState(() => _isLoadingPlan = true);

    try {
      final prompt =
          '''
Analyse this student's performance and create a personalised improvement plan.

Student: $_userName
Department: $_department
Aptitude average: ${_aptitudeAvg.toStringAsFixed(1)}%
Technical average: ${_technicalAvg.toStringAsFixed(1)}%
HR Interview average: ${(_hrAvg).toStringAsFixed(1)}%
Total tests taken: $_totalTests

Recent aptitude tests: ${_aptitudeHistory.take(3).map((h) => '${h['category']} ${h['difficulty']}: ${h['percentage']}%').join(', ')}
Recent technical tests: ${_technicalHistory.take(3).map((h) => '${h['subject']} ${h['mode']}: ${h['percentage'] ?? 'Coding'}%').join(', ')}

Create a 1-week study plan with:
1. Top 3 weak areas to focus on
2. Daily study schedule (Monday to Sunday)
3. Specific topics to practice each day
4. Tips to improve weak areas

Keep it concise, practical and motivating for a college student!
''';

      final response = await http
          .post(
            Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_groqKey',
            },
            body: jsonEncode({
              'model': 'llama-3.3-70b-versatile',
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
              'temperature': 0.7,
              'max_tokens': 1024,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          _aiPlan = data['choices'][0]['message']['content'];
          _isLoadingPlan = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _aiPlan = 'Failed to generate plan. Try again!';
          _isLoadingPlan = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiPlan = 'Connection error. Check internet!';
        _isLoadingPlan = false;
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // Header
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hi $_userName! ??',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'Your performance overview',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _loadData,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Icon(
                              Icons.refresh,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Overall stats
                    Row(
                      children: [
                        _buildStatCard(
                          'Total Tests',
                          '$_totalTests',
                          Icons.quiz_outlined,
                          const Color(0xFF45B08C),
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          'Aptitude',
                          '${_aptitudeAvg.toStringAsFixed(0)}%',
                          Icons.calculate_outlined,
                          const Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          'Technical',
                          '${_technicalAvg.toStringAsFixed(0)}%',
                          Icons.code_outlined,
                          const Color(0xFF7C3AED),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        _buildStatCard(
                          'HR Score',
                          '${(_hrAvg / 10).toStringAsFixed(1)}/10',
                          Icons.mic_outlined,
                          const Color(0xFFE91E8C),
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          'Best Aptitude',
                          _aptitudeHistory.isEmpty
                              ? '�'
                              : '${_aptitudeHistory.map((h) => (h['percentage'] as num?)?.toInt() ?? 0).reduce((a, b) => a > b ? a : b)}%',
                          Icons.emoji_events_outlined,
                          const Color(0xFF22C55E),
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          'HR Tests',
                          '${_hrHistory.length}',
                          Icons.record_voice_over_outlined,
                          const Color(0xFF00897B),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Performance bars
                    _buildSectionTitle('Performance Overview', Icons.bar_chart),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          _buildPerformanceBar(
                            'Aptitude',
                            _aptitudeAvg / 100,
                            const Color(0xFFF59E0B),
                            '${_aptitudeAvg.toStringAsFixed(1)}%',
                          ),
                          const SizedBox(height: 16),
                          _buildPerformanceBar(
                            'Technical',
                            _technicalAvg / 100,
                            const Color(0xFF7C3AED),
                            '${_technicalAvg.toStringAsFixed(1)}%',
                          ),
                          const SizedBox(height: 16),
                          _buildPerformanceBar(
                            'HR Interview',
                            _hrAvg / 100,
                            const Color(0xFFE91E8C),
                            '${(_hrAvg / 10).toStringAsFixed(1)}/10',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // AI Improvement Plan
                    _buildSectionTitle('AI Study Plan', Icons.auto_awesome),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_aiPlan.isEmpty && !_isLoadingPlan) ...[
                            Text(
                              'Get your personalised AI study plan!',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'AI will analyse your performance and create a custom 1-week study plan.',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: _totalTests == 0
                                    ? null
                                    : _generateAIPlan,
                                icon: const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: Text(
                                  _totalTests == 0
                                      ? 'Take tests first to get plan'
                                      : 'Generate My Study Plan',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF45B08C),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ] else if (_isLoadingPlan) ...[
                            Center(
                              child: Column(
                                children: [
                                  CircularProgressIndicator(
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'AI is creating your plan...',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: colorScheme.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Your Personalised Study Plan',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _generateAIPlan,
                                  child: Icon(
                                    Icons.refresh,
                                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            MarkdownBody(
                              data: _aiPlan,
                              styleSheet: MarkdownStyleSheet(
                                p: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurface,
                                  height: 1.6,
                                ),
                                strong: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                                h1: TextStyle(
                                  fontSize: 16,
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                                h2: TextStyle(
                                  fontSize: 15,
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                                h3: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                                listBullet: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Recent Aptitude Tests
                    if (_aptitudeHistory.isNotEmpty) ...[
                      _buildSectionTitle(
                        'Recent Aptitude Tests',
                        Icons.calculate_outlined,
                      ),
                      const SizedBox(height: 12),
                      ..._aptitudeHistory
                          .take(5)
                          .map(
                            (test) => _buildTestHistoryCard(
                              test['category'] ?? 'Aptitude',
                              '${test['difficulty']} � ${test['course']}',
                              '${test['percentage']}%',
                              _formatDate(test['createdAt']),
                              const Color(0xFFF59E0B),
                              Icons.calculate_outlined,
                            ),
                          ),
                      const SizedBox(height: 16),
                    ],

                    // Recent Technical Tests
                    if (_technicalHistory.isNotEmpty) ...[
                      _buildSectionTitle(
                        'Recent Technical Tests',
                        Icons.code_outlined,
                      ),
                      const SizedBox(height: 12),
                      ..._technicalHistory
                          .take(5)
                          .map(
                            (test) => _buildTestHistoryCard(
                              test['subject'] ?? 'Technical',
                              '${test['mode']} � ${test['difficulty']}',
                              test['mode'] == 'Coding Challenge'
                                  ? 'Submitted'
                                  : '${test['percentage']}%',
                              _formatDate(test['createdAt']),
                              const Color(0xFF7C3AED),
                              Icons.code_outlined,
                            ),
                          ),
                      const SizedBox(height: 16),
                    ],

                    // Recent HR Tests
                    if (_hrHistory.isNotEmpty) ...[
                      _buildSectionTitle(
                        'Recent HR Interviews',
                        Icons.mic_outlined,
                      ),
                      const SizedBox(height: 12),
                      ..._hrHistory
                          .take(5)
                          .map(
                            (test) => _buildTestHistoryCard(
                              test['interviewType'] ?? 'HR',
                              test['department'] ?? '',
                              '${test['totalScore']}/10',
                              _formatDate(test['createdAt']),
                              const Color(0xFFE91E8C),
                              Icons.mic_outlined,
                            ),
                          ),
                      const SizedBox(height: 16),
                    ],

                    // Empty state
                    if (_totalTests == 0) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.bar_chart_outlined,
                              size: 60,
                              color: Color(0xFFCCCCCC),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tests taken yet!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Take Aptitude, Technical or HR tests\nto see your analytics here!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: colorScheme.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                  fontSize: 10, color: colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceBar(
    String label,
    double value,
    Color color,
    String display,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
            Text(
              display,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildTestHistoryCard(
    String title,
    String subtitle,
    String score,
    String date,
    Color color,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  score,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}



import 'package:flutter/material.dart';
import 'package:strive_campus/screens/hr/hr_home_screen.dart';

class HRResultScreen extends StatefulWidget {
  final List<Map<String, dynamic>> answers;
  final int totalScore;
  final String interviewType;
  final String department;
  final String userName;

  const HRResultScreen({
    super.key,
    required this.answers,
    required this.totalScore,
    required this.interviewType,
    required this.department,
    required this.userName,
  });

  @override
  State<HRResultScreen> createState() => _HRResultScreenState();
}

class _HRResultScreenState extends State<HRResultScreen> {
  bool _showReview = false;

  Color get scoreColor {
    if (widget.totalScore >= 8) return const Color(0xFF22C55E);
    if (widget.totalScore >= 6) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String get scoreMessage {
    if (widget.totalScore >= 8) return 'Outstanding! 🌟';
    if (widget.totalScore >= 6) return 'Good Performance! 👍';
    if (widget.totalScore >= 4) return 'Keep Practicing! 💪';
    return 'Need More Preparation! 📚';
  }

  String get performanceAdvice {
    if (widget.totalScore >= 8) {
      return 'You are interview ready! Focus on polishing your answers.';
    }
    if (widget.totalScore >= 6) {
      return 'Good foundation! Work on giving more specific examples.';
    }
    if (widget.totalScore >= 4) {
      return 'Practice more mock interviews and study common questions.';
    }
    return 'Start with basic HR questions and build your confidence gradually.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Interview Result',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Score card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: scoreColor.withValues(alpha: 0.3), width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    'Hi ${widget.userName}!',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF888888),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scoreMessage,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: scoreColor, width: 6),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Text(
                            '${widget.totalScore}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: scoreColor,
                            ),
                          ),
                          Text(
                            'out of 10',
                            style: TextStyle(
                              fontSize: 11,
                              color: scoreColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(widget.interviewType,
                          Icons.record_voice_over_outlined),
                      _buildInfoChip(widget.department,
                          Icons.school_outlined),
                      _buildInfoChip(
                          '${widget.answers.length} Questions',
                          Icons.quiz_outlined),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Performance advice
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: scoreColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline,
                      color: scoreColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      performanceAdvice,
                      style: TextStyle(
                        fontSize: 13,
                        color: scoreColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Score per question strip
            Container(
              padding: const EdgeInsets.all(16),
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
                    'Question Scores',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(
                      widget.answers.length,
                      (index) {
                        final score =
                            widget.answers[index]['score'] as int;
                        Color color;
                        if (score >= 8) {
                          color = const Color(0xFF22C55E);
                        } else if (score >= 6) {
                          color = const Color(0xFFF59E0B);
                        } else {
                          color = const Color(0xFFEF4444);
                        }
                        return Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(8),
                            border: Border.all(color: color),
                          ),
                          child: Center(
                            child: Text(
                              '$score',
                              style: TextStyle(
                                color: color,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Review toggle
            GestureDetector(
              onTap: () =>
                  setState(() => _showReview = !_showReview),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4F3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.rate_review_outlined,
                        color: Color(0xFFE91E8C), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _showReview
                          ? 'Hide Full Review'
                          : 'View Full Review & Feedback',
                      style: const TextStyle(
                        color: Color(0xFFE91E8C),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _showReview
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(0xFFE91E8C),
                    ),
                  ],
                ),
              ),
            ),

            // Full review
            if (_showReview) ...[
              const SizedBox(height: 12),
              ...List.generate(widget.answers.length, (index) {
                final answer = widget.answers[index];
                final score = answer['score'] as int;
                Color scoreColor;
                if (score >= 8) {
                  scoreColor = const Color(0xFF22C55E);
                } else if (score >= 6) {
                  scoreColor = const Color(0xFFF59E0B);
                } else {
                  scoreColor = const Color(0xFFEF4444);
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: scoreColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE91E8C),
                              borderRadius:
                                  BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Q${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: scoreColor.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Score: $score/10',
                              style: TextStyle(
                                color: scoreColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              answer['category'] ?? 'HR',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF888888),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        answer['question'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          answer['answer'],
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildReviewRow('✅',
                          answer['strengths'] ?? '', const Color(0xFF22C55E)),
                      const SizedBox(height: 6),
                      _buildReviewRow('📈',
                          answer['improvements'] ?? '', const Color(0xFFF59E0B)),
                      const SizedBox(height: 6),
                      _buildReviewRow('💡',
                          answer['sampleAnswer'] ?? '', const Color(0xFF45B08C)),
                    ],
                  ),
                );
              }),
            ],

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const HRHomeScreen(),
                        ),
                        (route) => route.isFirst,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFFE91E8C)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(
                          color: Color(0xFFE91E8C),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.popUntil(
                        context, (route) => route.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E8C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                    ),
                    child: const Text(
                      'Go Home',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4F3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFFE91E8C)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFFE91E8C),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow(
      String emoji, String content, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            content,
            style: TextStyle(
              fontSize: 12,
              color: color,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}


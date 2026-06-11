import 'package:flutter/material.dart';
import 'package:strive_campus/screens/aptitude/aptitude_home_screen.dart';

class AptitudeResultScreen extends StatefulWidget {
  final int score;
  final int total;
  final List<Map<String, dynamic>> results;
  final String course;
  final String category;
  final String difficulty;

  const AptitudeResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.results,
    required this.course,
    required this.category,
    required this.difficulty,
  });

  @override
  State<AptitudeResultScreen> createState() =>
      _AptitudeResultScreenState();
}

class _AptitudeResultScreenState
    extends State<AptitudeResultScreen> {
  bool _showReview = false;

  double get percentage =>
      (widget.score / widget.total) * 100;

  Color get scoreColor {
    if (percentage >= 80) return const Color(0xFF22C55E);
    if (percentage >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String get scoreMessage {
    if (percentage >= 80) return 'Excellent! ??';
    if (percentage >= 60) return 'Good job! ??';
    if (percentage >= 40) return 'Keep practicing! ??';
    return 'Need more practice! ??';
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
          'Test Result',
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
                    scoreMessage,
                    style: const TextStyle(
                      fontSize: 20,
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
                      border: Border.all(
                          color: scoreColor, width: 6),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Text(
                            '${widget.score}/${widget.total}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: scoreColor,
                            ),
                          ),
                          Text(
                            '${percentage.round()}%',
                            style: TextStyle(
                              fontSize: 14,
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
                      _buildInfoChip(
                          widget.category, Icons.quiz_outlined),
                      _buildInfoChip(widget.difficulty,
                          Icons.signal_cellular_alt),
                      _buildInfoChip(
                          widget.course.length > 20
                              ? '${widget.course.substring(0, 20)}...'
                              : widget.course,
                          Icons.school_outlined),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats row
            Row(
              children: [
                _buildStatCard('? Correct',
                    '${widget.score}', const Color(0xFF22C55E)),
                const SizedBox(width: 12),
                _buildStatCard(
                    '? Wrong',
                    '${widget.total - widget.score}',
                    const Color(0xFFEF4444)),
                const SizedBox(width: 12),
                _buildStatCard('?? Score',
                    '${percentage.round()}%', scoreColor),
              ],
            ),

            const SizedBox(height: 16),

            // Answer summary strip
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
                    'Answer Summary',
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
                      widget.results.length,
                      (index) {
                        final isCorrect =
                            widget.results[index]['isCorrect'];
                        return Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFEF4444),
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
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

            // Review answers toggle
            GestureDetector(
              onTap: () =>
                  setState(() => _showReview = !_showReview),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEDFE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.rate_review_outlined,
                        color: Color(0xFF45B08C), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _showReview
                          ? 'Hide Answer Review'
                          : 'View Answer Review',
                      style: const TextStyle(
                        color: Color(0xFF45B08C),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _showReview
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(0xFF45B08C),
                    ),
                  ],
                ),
              ),
            ),

            // Answer review
            if (_showReview) ...[
              const SizedBox(height: 12),
              ...List.generate(widget.results.length, (index) {
                final result = widget.results[index];
                final isCorrect = result['isCorrect'];
                final options = result['options']
                    as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCorrect
                          ? const Color(0xFF22C55E)
                              .withValues(alpha: 0.3)
                          : const Color(0xFFEF4444)
                              .withValues(alpha: 0.3),
                    ),
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
                              color: isCorrect
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFFEF4444),
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
                          Icon(
                            isCorrect
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: isCorrect
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFEF4444),
                            size: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        result['question'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...options.entries.map((entry) {
                        final isCorrectOption =
                            entry.key == result['correct'];
                        final isUserAnswer =
                            entry.key == result['userAnswer'];
                        Color optionColor =
                            const Color(0xFFE8E8F0);
                        if (isCorrectOption) {
                          optionColor =
                              const Color(0xFF22C55E);
                        }
                        if (isUserAnswer && !isCorrect) {
                          optionColor =
                              const Color(0xFFEF4444);
                        }
                        return Container(
                          margin:
                              const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                optionColor.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(8),
                            border: Border.all(
                                color: optionColor,
                                width: isCorrectOption ||
                                        isUserAnswer
                                    ? 1.5
                                    : 1),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${entry.key}.',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: optionColor ==
                                          const Color(
                                              0xFFE8E8F0)
                                      ? const Color(0xFF888888)
                                      : optionColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.value.toString(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: optionColor ==
                                            const Color(
                                                0xFFE8E8F0)
                                        ? const Color(
                                            0xFF888888)
                                        : const Color(
                                            0xFF1A1A2E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (result['explanation'] != null &&
                          result['explanation'].isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text('?? ',
                                  style: TextStyle(
                                      fontSize: 13)),
                              Expanded(
                                child: Text(
                                  result['explanation'],
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
                              const AptitudeHomeScreen(),
                        ),
                        (route) => route.isFirst,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFF45B08C)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(
                          color: Color(0xFF45B08C),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.popUntil(
                          context, (route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF45B08C),
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
        color: const Color(0xFFEEEDFE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF45B08C)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF45B08C),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8E8F0)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF888888),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


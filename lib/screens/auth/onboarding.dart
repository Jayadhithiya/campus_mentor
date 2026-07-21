import 'package:flutter/material.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentPage = 0;
  final PageController _pageController = PageController();

  final List<Map<String, dynamic>> pages = [
    {
      'title': 'Practice interviews with AI in your language',
      'desc':
          'Get HR, technical and aptitude practice sessions powered by AI. Ask questions, get answers in Tamil, Hindi or English.',
      'color': const Color(0xFFF0F0FF),
      'iconColor': const Color(0xFF45B08C),
      'icon': Icons.chat_bubble_outline,
    },
    {
      'title': 'Track attendance, deadlines and marks',
      'desc':
          'Never miss a class or assignment again. StriveCampus tracks your attendance and warns you before it drops.',
      'color': const Color(0xFFFFF0F5),
      'iconColor': const Color(0xFFE91E8C),
      'icon': Icons.calendar_today_outlined,
    },
    {
      'title': 'See exactly where to improve',
      'desc':
          'After every test, AI analyses your performance and gives you a personal improvement plan in your language.',
      'color': const Color(0xFFF0FFF4),
      'iconColor': const Color(0xFF00897B),
      'icon': Icons.insights_outlined,
    },
  ];

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  void _nextPage() {
    if (currentPage < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() => currentPage = index);
                        },
                        itemCount: pages.length,
                        itemBuilder: (context, index) {
                          final page = pages[index];
                          return Column(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Container(
                                  width: double.infinity,
                                  color: page['color'],
                                  child: Center(
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: page['iconColor'],
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (page['iconColor'] as Color)
                                                .withValues(alpha: 0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        page['icon'],
                                        size: 40,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 5,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0,
                                    vertical: 12.0,
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          page['title'],
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1A1A2E),
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          page['desc'],
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF777777),
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              pages.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                width: currentPage == index ? 20 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: currentPage == index
                                      ? pages[currentPage]['iconColor']
                                      : const Color(0xFFDDDDDD),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _nextPage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: pages[currentPage]['iconColor'],
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                currentPage == pages.length - 1
                                    ? 'Get Started'
                                    : 'Next',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (currentPage < pages.length - 1)
                            TextButton(
                              onPressed: _goToLogin,
                              child: const Text(
                                'Skip',
                                style: TextStyle(
                                  color: Color(0xFF888888),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

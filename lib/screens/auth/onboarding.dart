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
      'desc': 'Get HR, technical and aptitude practice sessions powered by AI. Ask questions, get answers in Tamil, Hindi or English.',
      'color': Color(0xFFF0F0FF),
      'iconColor': Color(0xFF45B08C),
      'icon': Icons.chat_bubble_outline,
    },
    {
      'title': 'Track attendance, deadlines and marks',
      'desc': 'Never miss a class or assignment again. StriveCampus tracks your attendance and warns you before it drops.',
      'color': Color(0xFFFFF0F5),
      'iconColor': Color(0xFFE91E8C),
      'icon': Icons.calendar_today_outlined,
    },
    {
      'title': 'See exactly where to improve',
      'desc': 'After every test, AI analyses your performance and gives you a personal improvement plan in your language.',
      'color': Color(0xFFF0FFF4),
      'iconColor': Color(0xFF00897B),
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
      backgroundColor: Colors.white,
      body: SafeArea(
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
                      Container(
                        width: double.infinity,
                        height: 300,
                        color: page['color'],
                        child: Center(
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: page['iconColor'],
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Icon(
                              page['icon'],
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              page['title'],
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A2E),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              page['desc'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF888888),
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pages[currentPage]['iconColor'],
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (currentPage < pages.length - 1)
                    TextButton(
                      onPressed: _goToLogin,
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


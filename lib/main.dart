import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'package:strive_campus/screens/auth/onboarding.dart';
import 'package:strive_campus/screens/home/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strive_campus/services/user_service.dart';

import 'package:flutter/semantics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('dotenv load error: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
    runApp(const _FirebaseErrorApp());
    return;
  }

  try {
    await UserService.initNotifications();
  } catch (e) {
    debugPrint('Notifications init error: $e');
  }

  if (kIsWeb) {
    SemanticsBinding.instance.ensureSemantics();
  }

  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDark') ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  runApp(const StriveCampusApp());
}

class StriveCampusApp extends StatelessWidget {
  const StriveCampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, ThemeMode mode, child) {
        return MaterialApp(
          title: 'StriveCampus',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF45B08C),
              primary: const Color(0xFF45B08C),
              brightness: Brightness.light,
              surface: Colors.white,
              onSurface: const Color(0xFF1A1A2E),
            ),
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF1A1A2E),
              elevation: 0,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF45B08C),
              primary: const Color(0xFF45B08C),
              brightness: Brightness.dark,
              surface: const Color(0xFF1F1F3D),
              onSurface: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFF1A1A2E),
            useMaterial3: true,
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      
      final user = FirebaseAuth.instance.currentUser;
      
      Widget nextScreen = user != null 
          ? const MainScreen() 
          : const OnboardingScreen();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFF45B08C),
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: Center(
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'StriveCampus',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'YOUR AI STUDY PARTNER',
              style: TextStyle(
                color: Color(0x80FFFFFF),
                fontSize: 11,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 60),
            const CircularProgressIndicator(
              color: Color(0xFF45B08C),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _FirebaseErrorApp extends StatelessWidget {
  const _FirebaseErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 64),
                const SizedBox(height: 20),
                const Text(
                  'Startup Error',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Firebase failed to initialize.\nPlease check your internet connection and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0x99FFFFFF), fontSize: 14, height: 1.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

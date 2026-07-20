import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeys {
  static String get groqKey =>
      dotenv.env['GROQ_KEY'] ?? 'YOUR_GROQ_REDACTED_SECRET_HERE';

  static bool get isGroqKeyConfigured =>
      groqKey.isNotEmpty && groqKey != 'YOUR_GROQ_REDACTED_SECRET_HERE';
}

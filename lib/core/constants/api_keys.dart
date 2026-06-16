class ApiKeys {
  static const String groqKey = String.fromEnvironment(
    'GROQ_KEY',
    defaultValue: 'YOUR_GROQ_REDACTED_SECRET_HERE',
  );
}

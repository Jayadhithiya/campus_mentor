# StriveCampus — AI Mock Interview & Campus Mentor 🎓

StriveCampus is a comprehensive mobile application designed to help college students prepare for placements and manage their campus life. It features AI-powered mock interviews (HR & Technical), aptitude tests, a chatbot assistant, and analytics to track performance.

## 🚀 Features

- **AI Mock Interviews**: Realistic HR and Technical rounds with instant AI feedback using Groq (Llama 3.3).
- **Aptitude & Technical Tests**: Extensive practice tests for various subjects and difficulty levels.
- **Campus Chatbot**: A smart assistant to track attendance, assignments, and study plans.
- **Analytics Dashboard**: Visual overview of your test scores and AI-generated improvement plans.
- **Firebase Integration**: Secure authentication and real-time data storage.

---

## 📋 Requirements

Before setting up the project, ensure you have the following installed:

- **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK**: (Included with Flutter)
- **Firebase Project**: A configured Firebase project with Firestore and Auth enabled.
- **Groq API Key**: Get your key at [console.groq.com](https://console.groq.com/).

---

## 🛠️ Setup Instructions

### 1. Clone the Repository
```bash
git clone https://github.com/Jayadhithiya/Strive_campus.git
cd Strive_campus
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Setup API Keys (Security Step) 🔐
For security, the API keys file is excluded from GitHub. You must create it manually:

1. Create a folder: `lib/core/constants/`
2. Create a file named `api_keys.dart` inside that folder.
3. Paste the following code into it, replacing the placeholder with your **Groq API Key**:

```dart
class ApiKeys {
  static const String groqKey = 'YOUR_GROQ_API_KEY_HERE';
}
```

### 4. Firebase Configuration
- **Android**: Place your `google-services.json` in `android/app/`.
- **iOS**: Place your `GoogleService-Info.plist` in `ios/Runner/`.

---

## 🏃 Running the App

To run the app in debug mode on your connected device/emulator:

```bash
flutter run
```

To build a production APK for Android:

```bash
flutter build apk --release
```

---

## 🗃️ Tech Stack
- **Framework**: Flutter (Dart)
- **Backend**: Firebase (Auth, Firestore)
- **AI Engine**: Groq (Llama 3.3 70B Versatile)
- **State Management**: StatefulWidgets
- **UI**: Material Design 3 with Custom Themes

---

## 🤝 Contributing
Contributions are welcome! Please fork the repository and create a pull request with your changes.

## 📄 License
This project belongs to [Jayadhithiya](https://github.com/Jayadhithiya). Contact for usage permissions.

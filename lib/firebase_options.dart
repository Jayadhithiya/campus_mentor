import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    REDACTED_SECRET: 'REDACTED_SECRET',
    appId: '1:386966654332:web:88575fed5329f2adc428f9',
    messagingSenderId: '386966654332',
    projectId: 'campusmentor-2485c',
    authDomain: 'campusmentor-2485c.firebaseapp.com',
    storageBucket: 'campusmentor-2485c.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    REDACTED_SECRET: 'REDACTED_SECRET',
    appId: '1:386966654332:android:472e0497e4a3ea8bc428f9',
    messagingSenderId: '386966654332',
    projectId: 'campusmentor-2485c',
    storageBucket: 'campusmentor-2485c.firebasestorage.app',
  );
}
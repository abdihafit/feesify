import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Replace these placeholder values with your Firebase project's config.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError('Firebase is not configured for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAyIXWIdLW6XdIBiegn6o4toMwl2jRFE9o',
    appId: '1:556364465809:web:706fd2aa78a1fce900a130',
    messagingSenderId: '556364465809',
    projectId: 'feesify',
    authDomain: 'feesify.firebaseapp.com',
    storageBucket: 'feesify.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCu4bVWIkVZnaJquKcMLrKpy6iX3Xccxz0',
    appId: '1:556364465809:android:e662e660b0ba4c9100a130',
    messagingSenderId: '556364465809',
    projectId: 'feesify',
    storageBucket: 'feesify.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA_05NWYVzHXtVKMN4IfIEKX_-kgqZwpsc',
    appId: '1:556364465809:ios:1c9f718135a24ae600a130',
    messagingSenderId: '556364465809',
    projectId: 'feesify',
    storageBucket: 'feesify.firebasestorage.app',
    iosBundleId: 'com.example.feesify',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'replace-me',
    appId: '1:1234567890:macos:replace-me',
    messagingSenderId: '1234567890',
    projectId: 'school-finance-system',
    storageBucket: 'school-finance-system.appspot.com',
    iosBundleId: 'com.example.feesify',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'replace-me',
    appId: '1:1234567890:windows:replace-me',
    messagingSenderId: '1234567890',
    projectId: 'school-finance-system',
    storageBucket: 'school-finance-system.appspot.com',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'replace-me',
    appId: '1:1234567890:linux:replace-me',
    messagingSenderId: '1234567890',
    projectId: 'school-finance-system',
    storageBucket: 'school-finance-system.appspot.com',
  );
}

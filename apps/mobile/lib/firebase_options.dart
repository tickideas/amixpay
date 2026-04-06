// Generated Firebase options for AmixPay
// Values sourced from android/app/google-services.json
// Re-run FlutterFire CLI if project settings change:
//   flutterfire configure --project=amixpay-6625d

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAiZlnmYVTMIOnQhRiuoEaXTldoWlCg7ok',
    appId: '1:717929198625:android:d9e51d7e891aad02b45f60',
    messagingSenderId: '717929198625',
    projectId: 'amixpay-6625d',
    storageBucket: 'amixpay-6625d.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAiZlnmYVTMIOnQhRiuoEaXTldoWlCg7ok',
    appId: '1:717929198625:ios:d9e51d7e891aad02b45f60',
    messagingSenderId: '717929198625',
    projectId: 'amixpay-6625d',
    storageBucket: 'amixpay-6625d.appspot.com',
    iosBundleId: 'com.amixpay.amixpayApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAiZlnmYVTMIOnQhRiuoEaXTldoWlCg7ok',
    appId: '1:717929198625:ios:d9e51d7e891aad02b45f60',
    messagingSenderId: '717929198625',
    projectId: 'amixpay-6625d',
    storageBucket: 'amixpay-6625d.appspot.com',
    iosBundleId: 'com.amixpay.amixpayApp',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAiZlnmYVTMIOnQhRiuoEaXTldoWlCg7ok',
    appId: '1:717929198625:web:d9e51d7e891aad02b45f60',
    messagingSenderId: '717929198625',
    projectId: 'amixpay-6625d',
    storageBucket: 'amixpay-6625d.appspot.com',
    authDomain: 'amixpay-6625d.firebaseapp.com',
  );
}

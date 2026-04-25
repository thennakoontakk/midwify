import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for the Midwify project.
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBP2jCLqqi7g7CtWO1FQFY989ikh5bmS_8',
    appId: '1:203322719348:web:eff930cac9d0cd196e2521',
    messagingSenderId: '203322719348',
    projectId: 'midwify-3f933',
    authDomain: 'midwify-3f933.firebaseapp.com',
    storageBucket: 'midwify-3f933.firebasestorage.app',
    measurementId: 'G-82CGV7CXZQ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBP2jCLqqi7g7CtWO1FQFY989ikh5bmS_8',
    appId: '1:203322719348:web:eff930cac9d0cd196e2521',
    messagingSenderId: '203322719348',
    projectId: 'midwify-3f933',
    storageBucket: 'midwify-3f933.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBP2jCLqqi7g7CtWO1FQFY989ikh5bmS_8',
    appId: '1:203322719348:web:eff930cac9d0cd196e2521',
    messagingSenderId: '203322719348',
    projectId: 'midwify-3f933',
    storageBucket: 'midwify-3f933.firebasestorage.app',
  );
}

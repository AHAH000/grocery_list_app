// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDq2gweh9jE0IQUDkVaYQ7c1uMGMwvKsbM',
    appId: '1:518483517688:web:b53607c7d73ee18a781b0d',
    messagingSenderId: '518483517688',
    projectId: 'gorocery-list-firebase-app',
    authDomain: 'gorocery-list-firebase-app.firebaseapp.com',
    storageBucket: 'gorocery-list-firebase-app.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBUm4LOVKfgWMWHvyE3mgrORTu11XsIVZk',
    appId: '1:518483517688:android:c5bbcf0be29072fb781b0d',
    messagingSenderId: '518483517688',
    projectId: 'gorocery-list-firebase-app',
    storageBucket: 'gorocery-list-firebase-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB5CGqBaM2bEzy2Y03RySbqZRMpHEvOJEQ',
    appId: '1:518483517688:ios:c1e47471420150e7781b0d',
    messagingSenderId: '518483517688',
    projectId: 'gorocery-list-firebase-app',
    storageBucket: 'gorocery-list-firebase-app.firebasestorage.app',
    iosBundleId: 'com.example.groceryList',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB5CGqBaM2bEzy2Y03RySbqZRMpHEvOJEQ',
    appId: '1:518483517688:ios:c1e47471420150e7781b0d',
    messagingSenderId: '518483517688',
    projectId: 'gorocery-list-firebase-app',
    storageBucket: 'gorocery-list-firebase-app.firebasestorage.app',
    iosBundleId: 'com.example.groceryList',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDq2gweh9jE0IQUDkVaYQ7c1uMGMwvKsbM',
    appId: '1:518483517688:web:a0245b18e28bc029781b0d',
    messagingSenderId: '518483517688',
    projectId: 'gorocery-list-firebase-app',
    authDomain: 'gorocery-list-firebase-app.firebaseapp.com',
    storageBucket: 'gorocery-list-firebase-app.firebasestorage.app',
  );
}

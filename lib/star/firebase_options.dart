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
    apiKey: 'AIzaSyBocOfnX_fqAPxtHj-EZg9v_YIY_wqzRe4',
    appId: '1:477792264481:web:0cfba5f66056acf4971e60',
    messagingSenderId: '477792264481',
    projectId: 'wooki-3f810',
    authDomain: 'wooki-3f810.firebaseapp.com',
    storageBucket: 'wooki-3f810.appspot.com',
    measurementId: 'G-NJB940J29D',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAp_U3kV22OWqZ2j1S101SDzNpKJgmwprU',
    appId: '1:477792264481:android:a4a430d3ed2c63a8971e60',
    messagingSenderId: '477792264481',
    projectId: 'wooki-3f810',
    storageBucket: 'wooki-3f810.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDLCFSxjzvlgaUvq3EO0tj4oGAF3rw23-I',
    appId: '1:477792264481:ios:a662137a9499ecef971e60',
    messagingSenderId: '477792264481',
    projectId: 'wooki-3f810',
    storageBucket: 'wooki-3f810.appspot.com',
    iosBundleId: 'com.example.wooki',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDLCFSxjzvlgaUvq3EO0tj4oGAF3rw23-I',
    appId: '1:477792264481:ios:a662137a9499ecef971e60',
    messagingSenderId: '477792264481',
    projectId: 'wooki-3f810',
    storageBucket: 'wooki-3f810.appspot.com',
    iosBundleId: 'com.example.wooki',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBocOfnX_fqAPxtHj-EZg9v_YIY_wqzRe4',
    appId: '1:477792264481:web:aa7258c43ee41c7e971e60',
    messagingSenderId: '477792264481',
    projectId: 'wooki-3f810',
    authDomain: 'wooki-3f810.firebaseapp.com',
    storageBucket: 'wooki-3f810.appspot.com',
    measurementId: 'G-K2E7ZQX15S',
  );

}
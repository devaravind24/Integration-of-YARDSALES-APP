import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
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
    apiKey: 'AIzaSyDmcncuy0uxUj-pmRPyXCAzI2nhOUNVMPQ',
    appId: '1:145151817164:web:ea67913420512ee74d5969',
    messagingSenderId: '145151817164',
    projectId: 'csen268-s25-g5-f5439',
    authDomain: 'csen268-s25-g5-f5439.firebaseapp.com',
    storageBucket: 'csen268-s25-g5-f5439.firebasestorage.app',
    measurementId: 'G-LY3CFJXP82',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCF9tjh9C7nxYTaA4_bUA6wHFCFa786Yos',
    appId: '1:145151817164:android:8249f1a83c97088d4d5969',
    messagingSenderId: '145151817164',
    projectId: 'csen268-s25-g5-f5439',
    storageBucket: 'csen268-s25-g5-f5439.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDp304vm7fOuadU-dokgZVZlT-zd-NxT1k',
    appId: '1:145151817164:ios:2cb175c789e9ab294d5969',
    messagingSenderId: '145151817164',
    projectId: 'csen268-s25-g5-f5439',
    storageBucket: 'csen268-s25-g5-f5439.firebasestorage.app',
    iosBundleId: 'com.csen268.s26.g5.csen268FinalProject',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDp304vm7fOuadU-dokgZVZlT-zd-NxT1k',
    appId: '1:145151817164:ios:2cb175c789e9ab294d5969',
    messagingSenderId: '145151817164',
    projectId: 'csen268-s25-g5-f5439',
    storageBucket: 'csen268-s25-g5-f5439.firebasestorage.app',
    iosBundleId: 'com.csen268.s26.g5.csen268FinalProject',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDmcncuy0uxUj-pmRPyXCAzI2nhOUNVMPQ',
    appId: '1:145151817164:web:ea67913420512ee74d5969',
    messagingSenderId: '145151817164',
    projectId: 'csen268-s25-g5-f5439',
    authDomain: 'csen268-s25-g5-f5439.firebaseapp.com',
    storageBucket: 'csen268-s25-g5-f5439.firebasestorage.app',
    measurementId: 'G-LY3CFJXP82',
  );
}

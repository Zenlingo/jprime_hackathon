// File generated from Firebase project jprime-hackathon
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAWyd_my7B9_x4nVVreDpyYlD8FsMDKAIM',
    appId: '1:224287421928:android:47948db1bca3c86ce0205d',
    messagingSenderId: '224287421928',
    projectId: 'jprime-hackathon',
    storageBucket: 'jprime-hackathon.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDDuIgM2BYTmgBxplxsFxP1uRJMpl6Ao0E',
    appId: '1:224287421928:ios:a55a4be21401fe4fe0205d',
    messagingSenderId: '224287421928',
    projectId: 'jprime-hackathon',
    storageBucket: 'jprime-hackathon.firebasestorage.app',
    iosBundleId: 'com.jprime.mobileApp',
  );
}

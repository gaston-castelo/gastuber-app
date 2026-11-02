// Archivo de configuración de Firebase para GastUber.
// Puedes reemplazar estas credenciales con los valores de tu consola de Firebase:
// Consola de Firebase -> Configuración del proyecto -> General -> Tus apps

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
        return ios;
      default:
        return android;
    }
  }

  // Configuración Web (útil para probar la app en Google Chrome)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB-_nHxNk4gmXB92kXMqP9xbMYC4-BVT2M',
    appId: '1:243063184163:web:d5ffc050bd38210d6d4a96',
    messagingSenderId: '243063184163',
    projectId: 'gastuber-e8f8c',
    authDomain: 'gastuber-e8f8c.firebaseapp.com',
    storageBucket: 'gastuber-e8f8c.firebasestorage.app',
  );

  // Configuración Android (útil para correr en emulador o celular Android)
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB-_nHxNk4gmXB92kXMqP9xbMYC4-BVT2M',
    appId: '1:243063184163:android:gastuber-e8f8c',
    messagingSenderId: '243063184163',
    projectId: 'gastuber-e8f8c',
    storageBucket: 'gastuber-e8f8c.firebasestorage.app',
  );

  // Configuración iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB-_nHxNk4gmXB92kXMqP9xbMYC4-BVT2M',
    appId: '1:243063184163:ios:gastuber-e8f8c',
    messagingSenderId: '243063184163',
    projectId: 'gastuber-e8f8c',
    storageBucket: 'gastuber-e8f8c.firebasestorage.app',
    iosBundleId: 'com.gastuber.app',
  );
}

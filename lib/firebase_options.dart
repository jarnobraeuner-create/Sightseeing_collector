// ============================================================
//  firebase_options.dart  –  AUTOMATISCH AUSFÜLLEN
// ============================================================
//
//  SCHRITT 1 – Firebase Konsole öffnen:
//    https://console.firebase.google.com
//
//  SCHRITT 2 – App registrieren (falls noch nicht geschehen):
//    • Android: Paket-Name  →  com.sightseeing.collector
//    • iOS:     Bundle-ID   →  com.sightseeing.sightseeingCollector
//
//  SCHRITT 3 – Werte eintragen:
//    Projekteinstellungen ⚙️ → Allgemein → Deine Apps
//    Alle TODO-Felder unten mit den echten Werten ersetzen.
//
//  SCHRITT 4 – Native Konfig-Dateien ablegen:
//    • android/app/google-services.json          ← von Firebase herunterladen
//    • ios/Runner/GoogleService-Info.plist        ← von Firebase herunterladen
//
//  ALTERNATIV (empfohlen):
//    dart pub global activate flutterfire_cli
//    flutterfire configure
//    → ersetzt diese Datei automatisch mit korrekten Werten
// ============================================================

// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web-Platform ist nicht konfiguriert.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Platform ${defaultTargetPlatform.name} ist nicht konfiguriert.',
        );
    }
  }

  // ── Android ────────────────────────────────────────────────────────────────

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBZzuXuCwly6eXAjDOaKQPCK26yMNyyU58',
    appId: '1:886045906435:android:3627116bd3864168c42036',
    messagingSenderId: '886045906435',
    projectId: 'sightseeing-collector-11d2f',
    storageBucket: 'sightseeing-collector-11d2f.firebasestorage.app',
  );

  // Werte aus:  android/app/google-services.json

  // ── iOS ────────────────────────────────────────────────────────────────────

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB_zvDkE8q1u8BCqHj3dX0Lqwacog3UQJs',
    appId: '1:886045906435:ios:ce7fc047d78d8886c42036',
    messagingSenderId: '886045906435',
    projectId: 'sightseeing-collector-11d2f',
    storageBucket: 'sightseeing-collector-11d2f.firebasestorage.app',
    iosBundleId: 'com.sightseeing.sightseeingCollector',
  );

  // Werte aus:  ios/Runner/GoogleService-Info.plist
}
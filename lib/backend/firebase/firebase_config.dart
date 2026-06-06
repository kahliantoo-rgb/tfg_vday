import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyDAnFjOKq05ktKNQblIBjYamOEMXKSLeC8",
            authDomain: "tfg-sales-record.firebaseapp.com",
            projectId: "tfg-sales-record",
            storageBucket: "tfg-sales-record.firebasestorage.app",
            messagingSenderId: "326935454564",
            appId: "1:326935454564:web:23d356d5247525b9b25071"));
    try {
      await FirebaseFirestore.instance.enablePersistence();
    } catch (_) {
      // Multi-tab or unsupported browser — online-only fallback.
    }
  } else {
    await Firebase.initializeApp();
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
  }
}

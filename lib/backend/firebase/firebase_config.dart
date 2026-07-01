import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '/backend/firebase/app_check_service.dart';
import '/backend/firebase/app_environment.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(options: _webOptionsFor(appEnvironment));
    await initAppCheck();
    try {
      await FirebaseFirestore.instance.enablePersistence();
    } catch (_) {
      // Multi-tab or unsupported browser — online-only fallback.
    }
    return;
  }

  await Firebase.initializeApp();
  await initAppCheck();
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
}

FirebaseOptions _webOptionsFor(AppEnvironment env) {
  switch (env) {
    case AppEnvironment.staging:
      return const FirebaseOptions(
        apiKey: 'AIzaSyDbOJepbmawzlX3_KKPn-sWPz09HQdbCMk',
        authDomain: 'tfg-vday-record-staging.firebaseapp.com',
        projectId: 'tfg-vday-record-staging',
        storageBucket: 'tfg-vday-record-staging.firebasestorage.app',
        messagingSenderId: '972558847351',
        appId: '1:972558847351:web:3d6ebb53318abb5f9a2572',
      );
    case AppEnvironment.production:
      return const FirebaseOptions(
        apiKey: 'AIzaSyDAnFjOKq05ktKNQblIBjYamOEMXKSLeC8',
        authDomain: 'tfg-sales-record.firebaseapp.com',
        projectId: 'tfg-sales-record',
        storageBucket: 'tfg-sales-record.firebasestorage.app',
        messagingSenderId: '326935454564',
        appId: '1:326935454564:web:23d356d5247525b9b25071',
      );
  }
}

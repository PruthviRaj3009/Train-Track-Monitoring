import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:train_track_monitoring/pages/login_page.dart';
import 'package:train_track_monitoring/pages/main_navigation_page.dart';

/// Application entry point.
///
/// Ensures Flutter bindings are initialized, sets up Firebase, and launches the
/// root widget.
void main() async {
  // Required before using platform channels (Firebase initialization uses them).
  WidgetsFlutterBinding.ensureInitialized();

  // Initializes Firebase for authentication and other Firebase services.
  await Firebase.initializeApp();

  // Starts the Flutter application.
  runApp(const MyApp());
}

/// Root application widget.
///
/// Hosts a [MaterialApp] and defines the initial route/screen.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: LoginPage());
  }
}

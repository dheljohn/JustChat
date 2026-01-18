import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:messenger_app/test_google_signin_debug.dart';
// import 'firebase_options.dart';
import 'firebase_options.example.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(DebugApp());
}

class DebugApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Google Sign-In Debug',
      theme: ThemeData(primarySwatch: Colors.blue, brightness: Brightness.dark),
      home: GoogleSignInDebugScreen(),
    );
  }
}

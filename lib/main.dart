// lib/main.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lumra_project/theme/theme.dart';

import 'package:lumra_project/view/Homepage/Calendar/calendarWidgets/openCalendar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // required before using Firestore/Auth anywhere
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Demo',
      theme: LumraAppTheme.lightTheme,
      home: Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: Builder(
          builder: (scaffoldContext) => Center(
            child: FilledButton(
              child: const Text('Open Calendar'),
              onPressed: () async {
                try {
                  // 1) Sign in with your test email/password
                  final cred = await FirebaseAuth.instance
                      .signInWithEmailAndPassword(
                        email: 'adhd@test.com',
                        password: 'Password123!',
                      );
                  final String uid = cred.user!.uid;

                  // 2) Open calendar scoped to THIS uid (no partner yet)
                  openCalendar(currentUid: uid);
                } catch (e) {
                  // Minimal error surfacing
                  ScaffoldMessenger.of(
                    scaffoldContext,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

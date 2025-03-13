import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:grocery_list/auth.dart';
import 'package:grocery_list/screens/home_screen.dart';
import 'package:grocery_list/screens/login_screen.dart';
import 'package:grocery_list/screens/signup_screen.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // ✅ Required for async initialization
  await Firebase.initializeApp(); // ✅ Initialize Firebase

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        // home: const Auth(),
        routes: {
          '/': (context) => const Auth(),
          'homeScreen': (context) => const HomeScreen(),
          'SignUpScreen': (context) => const SignUpScreen(),
          'LoginScreen': (context) => LoginScreen(),
        });
  }
}

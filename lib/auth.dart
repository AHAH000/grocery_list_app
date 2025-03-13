import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grocery_list/screens/home_screen.dart';
import 'package:grocery_list/screens/login_screen.dart';

class Auth extends StatelessWidget {
  const Auth({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(), // ✅ Fixed syntax
        builder: (context, snapshot) {
          // ✅ Corrected function syntax
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator()); // ✅ Loading indicator
          } else if (snapshot.hasData) {
            return const HomeScreen(); // ✅ Ensure HomeScreen exists
          } else {
            return LoginScreen();
          }
        },
      ),
    );
  }
}

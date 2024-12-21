import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:spotfiy_rec/pages/home_page.dart';
import 'package:spotfiy_rec/pages/login_page.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showWelcome = false;

  void _onGetStarted() {
    setState(() {
      _showWelcome = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showWelcome) {
      // return WelcomePage(onGetStarted: _onGetStarted);
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user != null) {
            return const HomePage();
          } else {
            return const LoginPage();
          }
        }

        // LOAD STATE
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

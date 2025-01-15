import 'package:flutter/material.dart';
import 'package:spotfiy_rec/pages/home_page.dart';
import 'package:spotfiy_rec/pages/login_page.dart';
import 'package:spotfiy_rec/services/auth_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService().isSignedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data == true) {
          return const HomePage();
        }
        return const LoginPage();
      },
    );
  }
}

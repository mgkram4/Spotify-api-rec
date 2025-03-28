import 'package:flutter/material.dart';
import 'package:spotfiy_rec/services/auth_service.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Spotify Rec',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final authService = AuthService();
                final success = await authService.signInWithSpotify();
                if (success && context.mounted) {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              },
              child: const Text('Sign in with Spotify'),
            ),
          ],
        ),
      ),
    );
  }
}

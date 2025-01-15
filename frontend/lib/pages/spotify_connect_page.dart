import 'package:flutter/material.dart';
import 'package:spotfiy_rec/services/auth_service.dart';

class SpotifyConnectPage extends StatelessWidget {
  final AuthService _authService = AuthService();

  SpotifyConnectPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Connect to Spotify',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                bool connected = await _authService.signInWithSpotify();
                if (connected && context.mounted) {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              },
              child: const Text('Connect with Spotify'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:spotfiy_rec/services/user.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UserAuthService _auth = UserAuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showErrorSnackBar('Please enter both email and password');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.signIn(
        // Fixed typo in method name
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        // Added mounted check before using context
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage =
              'No user found for that email. Please check your email or sign up.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage =
              'The email address is not valid. Please enter a valid email.';
          break;
        case 'user-disabled':
          errorMessage =
              'This account has been disabled. Please contact support.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many login attempts. Please try again later.';
          break;
        default:
          errorMessage = 'An error occurred. Please try again.';
      }
      if (mounted) {
        // Added mounted check before showing error
        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        // Added mounted check before showing error
        _showErrorSnackBar('An unexpected error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        // Added mounted check before setState
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3), // Added explicit duration
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'), // Added const
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                // Added const
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next, // Added for better UX
            ),
            const SizedBox(height: 16), // Added const
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                // Added const
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              textInputAction: TextInputAction.done, // Added for better UX
              onSubmitted: (_) => _signIn(), // Added for better UX
            ),
            const SizedBox(height: 24), // Added const
            ElevatedButton(
              onPressed: _isLoading ? null : _signIn,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 12), // Added const
                minimumSize:
                    const Size(double.infinity, 48), // Added fixed height
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white) // Added const
                  : const Text('Login'), // Added const
            ),
            const SizedBox(height: 16), // Added const
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child:
                  const Text('Don\'t have an account? Sign up'), // Added const
            ),
          ],
        ),
      ),
    );
  }
}

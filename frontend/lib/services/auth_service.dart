import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _clientId = '308ba87093704f49bec68ee891609d88';
  static const String _redirectUri = 'com.example.myapp://callback';

  String? _spotifyToken;
  DateTime? _tokenExpiry;

  String? get spotifyToken {
    if (_spotifyToken == null ||
        _tokenExpiry == null ||
        DateTime.now().isAfter(_tokenExpiry!)) {
      _refreshToken();
    }
    return _spotifyToken;
  }

  Future<bool> signInWithSpotify() async {
    try {
      final result = await FlutterWebAuth.authenticate(
        url: 'https://accounts.spotify.com/authorize'
            '?client_id=$_clientId'
            '&response_type=token'
            '&redirect_uri=$_redirectUri'
            '&scope=user-read-private%20user-read-email%20user-top-read%20user-read-recently-played%20playlist-modify-public%20playlist-modify-private',
        callbackUrlScheme: 'spotify-rec',
      );

      _spotifyToken = Uri.parse(result)
          .fragment
          .split('&')
          .firstWhere((e) => e.startsWith('access_token='))
          .substring(13);

      if (_spotifyToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('spotify_token', _spotifyToken!);
        return true;
      }
      return false;
    } catch (e) {
      print('Error signing in with Spotify: $e');
      return false;
    }
  }

  Future<bool> isSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    _spotifyToken = prefs.getString('spotify_token');
    return _spotifyToken != null;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('spotify_token');
    _spotifyToken = null;
  }

  Future<void> _refreshToken() async {
    try {
      // Implement your token refresh logic here
      // This might involve calling your backend to get a new token
      // Update _spotifyToken and _tokenExpiry
    } catch (e) {
      print('Error refreshing token: $e');
      _spotifyToken = null;
      _tokenExpiry = null;
    }
  }
}

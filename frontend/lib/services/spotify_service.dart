import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:spotify/spotify.dart';

class SpotifyService {
  static const String clientId = 'YOUR_CLIENT_ID';
  static const String clientSecret = 'YOUR_CLIENT_SECRET';
  static const String redirectUrl = 'spotify-auth://callback';

  static const String _tokenKey = 'spotify_token';
  static const String _refreshTokenKey = 'spotify_refresh_token';
  static const String _expirationKey = 'spotify_token_expiration';

  final _storage = const FlutterSecureStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  SpotifyApi? _spotify;
  Timer? _refreshTimer;

  // Initialize Spotify client
  Future<void> initialize() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      final expirationString = await _storage.read(key: _expirationKey);

      if (token != null && refreshToken != null && expirationString != null) {
        final expiration = DateTime.parse(expirationString);

        if (expiration.isBefore(DateTime.now())) {
          await _refreshAccessToken(refreshToken);
        } else {
          _spotify = SpotifyApi(
            SpotifyApiCredentials(
              clientId,
              clientSecret,
              accessToken: token,
              refreshToken: refreshToken,
              expiration: expiration,
            ),
          );

          _setupRefreshTimer(expiration);
        }
      }
    } catch (e) {
      print('Spotify initialization error: $e');
      await _clearTokens();
    }
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _expirationKey);
    _refreshTimer?.cancel();
    _spotify = null;
  }

  void _setupRefreshTimer(DateTime expiration) {
    _refreshTimer?.cancel();
    final timeUntilRefresh =
        expiration.difference(DateTime.now()) - const Duration(minutes: 5);
    _refreshTimer = Timer(timeUntilRefresh, () async {
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      if (refreshToken != null) {
        await _refreshAccessToken(refreshToken);
      }
    });
  }

  Future<void> _refreshAccessToken(String refreshToken) async {
    try {
      final credentials = SpotifyApiCredentials(clientId, clientSecret);
      final newCredentials = await credentials.refreshAccessToken(refreshToken);

      await _storage.write(key: _tokenKey, value: newCredentials.accessToken);
      if (newCredentials.refreshToken != null) {
        await _storage.write(
            key: _refreshTokenKey, value: newCredentials.refreshToken);
      }
      await _storage.write(
        key: _expirationKey,
        value: newCredentials.expiration.toIso8601String(),
      );

      _spotify = SpotifyApi(newCredentials);
      _setupRefreshTimer(newCredentials.expiration);
    } catch (e) {
      print('Error refreshing token: $e');
      await _clearTokens();
      rethrow;
    }
  }

  // Authenticate with Spotify
  Future<bool> authenticate() async {
    try {
      final credentials = SpotifyApiCredentials(clientId, clientSecret);
      final grant = SpotifyApi.authorizationCodeGrant(credentials);
      final redirectUri = Uri.parse(redirectUrl);

      final authUri = grant.getAuthorizationUrl(
        redirectUri,
        scopes: [
          'user-read-private',
          'user-read-email',
          'playlist-modify-public',
          'playlist-modify-private',
          'user-top-read',
          'user-library-read',
          'user-library-modify',
        ],
      );

      final result = await FlutterWebAuth.authenticate(
        url: authUri.toString(),
        callbackUrlScheme: 'spotify-auth',
      );

      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) throw Exception('No authorization code received');

      final newCredentials = await grant.exchange(code);

      await _storage.write(key: _tokenKey, value: newCredentials.accessToken);
      await _storage.write(
          key: _refreshTokenKey, value: newCredentials.refreshToken);
      await _storage.write(
        key: _expirationKey,
        value: newCredentials.expiration.toIso8601String(),
      );

      _spotify = SpotifyApi(newCredentials);
      _setupRefreshTimer(newCredentials.expiration);

      return true;
    } catch (e) {
      print('Spotify authentication error: $e');
      return false;
    }
  }

  // Get user profile
  Future<User> getCurrentUser() async {
    if (_spotify == null) throw Exception('Spotify not initialized');
    return await _spotify!.me.get();
  }

  // Get user's top tracks
  Future<List<Track>> getTopTracks({
    int limit = 20,
    TimeRange timeRange = TimeRange.mediumTerm,
  }) async {
    try {
      if (_spotify == null) throw Exception('Spotify not initialized');
      final pages = await _spotify!.me.topTracks(
        limit: limit,
        timeRange: timeRange,
      );
      final tracks = await pages.all();
      return tracks;
    } catch (e) {
      print('Error getting top tracks: $e');
      rethrow;
    }
  }

  // Get user's top artists
  Future<List<Artist>> getTopArtists({
    int limit = 20,
    TimeRange timeRange = TimeRange.mediumTerm,
  }) async {
    try {
      if (_spotify == null) throw Exception('Spotify not initialized');
      final pages = await _spotify!.me.topArtists(
        limit: limit,
        timeRange: timeRange,
      );
      final artists = await pages.all();
      return artists;
    } catch (e) {
      print('Error getting top artists: $e');
      rethrow;
    }
  }

  // Create a playlist
  Future<Playlist> createPlaylist({
    required String name,
    String? description,
    bool public = true,
  }) async {
    try {
      if (_spotify == null) throw Exception('Spotify not initialized');

      final user = await getCurrentUser();
      if (user.id == null) throw Exception('User ID not available');

      final playlist = await _spotify!.playlists.createPlaylist(
        user.id!,
        name,
        public: public,
        description: description,
      );

      await _firestore
          .collection('users')
          .doc(user.id)
          .collection('playlists')
          .add({
        'spotifyId': playlist.id,
        'name': name,
        'description': description,
        'public': public,
        'createdAt': FieldValue.serverTimestamp(),
        'trackCount': 0,
        'imageUrl': playlist.images?.isNotEmpty == true
            ? playlist.images!.first.url
            : null,
      });

      return playlist;
    } catch (e) {
      print('Error creating playlist: $e');
      rethrow;
    }
  }

  // Add tracks to playlist with batch processing
  Future<void> addTracksToPlaylist(
    String playlistId,
    List<String> trackUris,
  ) async {
    try {
      if (_spotify == null) throw Exception('Spotify not initialized');

      const batchSize = 100;
      for (var i = 0; i < trackUris.length; i += batchSize) {
        final end = (i + batchSize < trackUris.length)
            ? i + batchSize
            : trackUris.length;
        final batch = trackUris.sublist(i, end);
        await _spotify!.playlists.addTracks(batch, playlistId);
      }

      // Update track count in Firestore
      final user = await getCurrentUser();
      if (user.id != null) {
        final playlistDoc = await _firestore
            .collection('users')
            .doc(user.id)
            .collection('playlists')
            .where('spotifyId', isEqualTo: playlistId)
            .get();

        if (playlistDoc.docs.isNotEmpty) {
          await playlistDoc.docs.first.reference.update({
            'trackCount': FieldValue.increment(trackUris.length),
          });
        }
      }
    } catch (e) {
      print('Error adding tracks to playlist: $e');
      rethrow;
    }
  }

  // Get recommendations
  Future<List<Track>> getRecommendations({
    List<String> seedTracks = const [],
    List<String> seedArtists = const [],
    List<String> seedGenres = const [],
    RecommendationsParameters? parameters,
    int limit = 20,
    int maxRetries = 3,
  }) async {
    if (_spotify == null) throw Exception('Spotify not initialized');

    int retryCount = 0;
    while (retryCount < maxRetries) {
      try {
        var params = {
          if (seedTracks.isNotEmpty) 'seed_tracks': seedTracks,
          if (seedArtists.isNotEmpty) 'seed_artists': seedArtists,
          if (seedGenres.isNotEmpty) 'seed_genres': seedGenres,
          if (parameters?.minTempo != null) 'min_tempo': parameters!.minTempo,
          if (parameters?.maxTempo != null) 'max_tempo': parameters!.maxTempo,
          if (parameters?.targetTempo != null)
            'target_tempo': parameters!.targetTempo,
          if (parameters?.minEnergy != null)
            'min_energy': parameters!.minEnergy,
          if (parameters?.maxEnergy != null)
            'max_energy': parameters!.maxEnergy,
          if (parameters?.targetEnergy != null)
            'target_energy': parameters!.targetEnergy,
          if (parameters?.minDanceability != null)
            'min_danceability': parameters!.minDanceability,
          if (parameters?.maxDanceability != null)
            'max_danceability': parameters!.maxDanceability,
          if (parameters?.targetDanceability != null)
            'target_danceability': parameters!.targetDanceability,
          if (parameters?.minValence != null)
            'min_valence': parameters!.minValence,
          if (parameters?.maxValence != null)
            'max_valence': parameters!.maxValence,
          if (parameters?.targetValence != null)
            'target_valence': parameters!.targetValence,
          'limit': limit,
        };

        final recommendations = await _spotify!.recommendations.get(params);

        return await recommendations.all();
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          print('Error getting recommendations after $maxRetries attempts: $e');
          rethrow;
        }
        await Future.delayed(Duration(seconds: retryCount));
      }
    }
    throw Exception('Failed to get recommendations after $maxRetries attempts');
  }

  // Search tracks with pagination
  Future<List<Track>> searchTracks(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      if (_spotify == null) throw Exception('Spotify not initialized');

      final results = await _spotify!.search.get(query,
          types: [SearchType.track]).getPage(limit: limit, offset: offset);

      return results.tracks?.items ?? [];
    } catch (e) {
      print('Error searching tracks: $e');
      rethrow;
    }
  }

  // Get audio features for tracks
  Future<List<AudioFeatures>> getAudioFeaturesForTracks(
      List<String> trackIds) async {
    try {
      if (_spotify == null) throw Exception('Spotify not initialized');

      const batchSize = 100;
      List<AudioFeatures> allFeatures = [];

      for (var i = 0; i < trackIds.length; i += batchSize) {
        final end =
            (i + batchSize < trackIds.length) ? i + batchSize : trackIds.length;
        final batch = trackIds.sublist(i, end);
        final features = await _spotify!.audioFeatures.get(batch);
        allFeatures.addAll(features);
      }

      return allFeatures;
    } catch (e) {
      print('Error getting audio features: $e');
      rethrow;
    }
  }

  void dispose() {
    _refreshTimer?.cancel();
  }
}

// Helper class for recommendation parameters
class RecommendationsParameters {
  final double? minTempo;
  final double? maxTempo;
  final double? targetTempo;
  final double? minEnergy;
  final double? maxEnergy;
  final double? targetEnergy;
  final double? minDanceability;
  final double? maxDanceability;
  final double? targetDanceability;
  final double? minValence;
  final double? maxValence;
  final double? targetValence;

  RecommendationsParameters({
    this.minTempo,
    this.maxTempo,
    this.targetTempo,
    this.minEnergy,
    this.maxEnergy,
    this.targetEnergy,
    this.minDanceability,
    this.maxDanceability,
    this.targetDanceability,
    this.minValence,
    this.maxValence,
    this.targetValence,
  });
}

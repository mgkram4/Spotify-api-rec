import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spotify/spotify.dart';

class PlaylistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String spotifyToken;
  late final SpotifyApi _spotify;

  PlaylistService(this.spotifyToken) {
    _spotify = SpotifyApi.withAccessToken(spotifyToken);
  }

  Future<Map<String, dynamic>> createPlaylistFromRecentPlays() async {
    try {
      final recentTracks = await _spotify.me.recentlyPlayed().getPage(20);
      return {
        'name': 'Recent Plays Mix',
        'tracks': recentTracks.items?.map((item) => item.track?.id).toList(),
        'type': 'recent_plays',
      };
    } catch (e) {
      print('Error creating playlist from recent plays: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createPlaylistFromTopArtists() async {
    try {
      final page =
          await _spotify.me.topArtists().getPage(5); // Get first 5 artists
      final recommendations = await _spotify.recommendations.get(
        seedArtists: page.items?.map((artist) => artist.id!).toList(),
        limit: 20,
      );

      return {
        'name': 'Your Top Artists Mix',
        'tracks': recommendations.tracks?.map((track) => track.id).toList(),
        'type': 'top_artists',
      };
    } catch (e) {
      print('Error creating playlist from top artists: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createPlaylistFromSavedTracks() async {
    try {
      final savedTracks = await _spotify.tracks.me.saved.getPage(20);
      return {
        'name': 'Liked Songs Mix',
        'tracks': savedTracks.items?.map((item) => item.track?.id).toList(),
        'type': 'saved_tracks',
      };
    } catch (e) {
      print('Error creating playlist from saved tracks: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createMoodBasedPlaylist(
    String mood,
    double minEnergy,
    double maxEnergy,
  ) async {
    try {
      // Map moods to genres
      final moodGenres = {
        'happy': ['pop', 'dance'],
        'sad': ['acoustic', 'piano'],
        'energetic': ['rock', 'electronic'],
        'relaxed': ['ambient', 'chill'],
      };

      final recommendations = await _spotify.recommendations.get(
        seedGenres: moodGenres[mood.toLowerCase()] ?? ['pop'],
        limit: 20,
      );

      return {
        'name': '$mood Mood Mix',
        'tracks': recommendations.tracks?.map((track) => track.id).toList(),
        'type': 'mood_based',
        'mood': mood,
      };
    } catch (e) {
      print('Error creating mood-based playlist: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createDecadeMix(int decade) async {
    try {
      final recommendations = await _spotify.recommendations.get(
        seedTracks: [
          '4JpKVNYnVcJ8tuMKjAj6JX'
        ], // Example track ID from that decade
        limit: 20,
      );

      return {
        'name': '${decade}s Mix',
        'tracks': recommendations.tracks?.map((track) => track.id).toList(),
        'type': 'decade',
        'decade': decade,
      };
    } catch (e) {
      print('Error creating decade mix: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createPlaylistFromSwipedTracks(
      List<String> likedTrackIds) async {
    try {
      // Create a new playlist
      final me = await _spotify.me.get();
      final playlist = await _spotify.playlists.createPlaylist(
        me.id!,
        'Your Swiped Mix',
        description: 'Created from your liked tracks while swiping',
        public: false,
      );

      // Add tracks to the playlist
      await _spotify.playlists.addTracks(
        likedTrackIds,
        playlist.id!,
      );

      return {
        'name': playlist.name,
        'id': playlist.id,
        'tracks': likedTrackIds,
        'type': 'swiped_tracks',
      };
    } catch (e) {
      print('Error creating playlist from swiped tracks: $e');
      rethrow;
    }
  }

  Future<void> savePlaylistToHistory(
    String userId,
    Map<String, dynamic> playlistData,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('playlists')
          .add({
        ...playlistData,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving playlist: $e');
      rethrow;
    }
  }

  Future<void> saveSwipedTrack(
    String userId,
    String trackId,
    bool liked,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('swiped_tracks')
          .add({
        'trackId': trackId,
        'liked': liked,
        'swipedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving swiped track: $e');
      rethrow;
    }
  }

  Stream<List<Track>> getTopTracksStream() async* {
    try {
      final pages = await _spotify.me.topTracks().all();
      yield pages.toList();
    } catch (e) {
      print('Error getting top tracks: $e');
      yield [];
    }
  }

  Stream<List<Artist>> getTopArtistsStream() {
    try {
      return _spotify.me
          .topArtists()
          .all()
          .asStream()
          .map((artists) => artists.toList());
    } catch (e) {
      print('Error getting top artists stream: $e');
      rethrow;
    }
  }

  Stream<List<PlaylistSimple>> getPlaylistsStream() async* {
    try {
      final me = await _spotify.me.get();
      final playlists = await _spotify.playlists.me.all();
      yield playlists.toList();
    } catch (e) {
      print('Error getting playlists: $e');
      yield [];
    }
  }

  Stream<Map<String, dynamic>> getUserDataStream() async* {
    try {
      final me = await _spotify.me.get();
      yield {
        'id': me.id,
        'name': me.displayName,
        'email': me.email,
        'images': me.images?.map((i) => i.url).toList(),
      };
    } catch (e) {
      print('Error getting user data: $e');
      yield {};
    }
  }

  Future<List<Track>> getPlaylistTracks(String playlistId) async {
    try {
      final playlist =
          await _spotify.playlists.getTracksByPlaylistId(playlistId).all();
      return playlist.toList();
    } catch (e) {
      print('Error getting playlist tracks: $e');
      rethrow;
    }
  }

  Future<String?> getTrackStreamUrl(String trackUri) async {
    try {
      // Get track ID from URI (format: spotify:track:id)
      final trackId = trackUri.split(':').last;

      // Get track information using the Spotify Web API
      final track = await _spotify.tracks.get(trackId);

      // Note: Due to Spotify's DRM protection, you cannot get direct streaming URLs
      // You would need to use the Spotify SDK for actual playback
      // This is just returning the preview URL as a fallback
      return track.previewUrl;
    } catch (e) {
      print('Error getting track stream URL: $e');
      return null;
    }
  }
}

// Add this class to your models folder
class UserData {
  final String id;
  final String name;
  final String email;
  final String? imageUrl;

  UserData({
    required this.id,
    required this.name,
    required this.email,
    this.imageUrl,
  });
}

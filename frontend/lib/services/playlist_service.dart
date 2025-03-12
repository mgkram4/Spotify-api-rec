import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spotify/spotify.dart' as spotify;

class PlaylistService {
final FirebaseFirestore _firestore = FirebaseFirestore.instance;
final String _token;
late final spotify.SpotifyApi _spotify;

// Add your playlist IDs here
static const Map<String, String> SEED_PLAYLISTS = {
'rock': '3bc6VkUmFKNFGQBmlYvirI',
'classical': '24ghz2gPVAazPoE9AW1Spr',
'edm': '7fUwCoNbJpujBuXGt8UkEI',
'pop': '6Gtt07NuqPzxUC4auj3ggP',
'jazz': '0R0gHbFuXSB0CynUkYGtNA',
'trap': '1Rdmyp7pVHkCDhXbdp459r',
'rap': '0SGh6IdyR5kxrvT2vYRPrC',
};

PlaylistService(this._token) {
_spotify = spotify.SpotifyApi.withAccessToken(_token);
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

Stream<List<spotify.Track>> getTopTracksStream() async* {
try {
  final pages = await _spotify.me.topTracks().all();
  yield pages.toList();
} catch (e) {
  print('Error getting top tracks: $e');
  yield [];
}
}

Stream<List<spotify.Artist>> getTopArtistsStream() {
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

Stream<List<spotify.PlaylistSimple>> getPlaylistsStream() async* {
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

Future<List<spotify.Track>> getPlaylistTracks(String playlistId) async {
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

Stream<List<spotify.Track>> getMixedRecommendationsStream({
required String genre, // 'rock', 'classical', or 'edm'
int limit = 20,
}) async* {
try {
  final playlistId = SEED_PLAYLISTS[genre.toLowerCase()];
  if (playlistId == null) {
    throw Exception('Invalid genre selected');
  }

  // Calculate how many tracks we want from each source (50/50 split)
  final playlistTracksCount = (limit / 2).round();
  final recommendationsCount = limit - playlistTracksCount;

  // 1. Get tracks from the selected genre playlist
  final playlistTracks =
      await _spotify.playlists.getTracksByPlaylistId(playlistId).all();
  final selectedPlaylistTracks = playlistTracks
      .take(playlistTracksCount)
      .map((item) => (item as spotify.PlaylistTrack).track)
      .where((track) => track != null)
      .toList();

  // 2. Get seed tracks and artists from the playlist
  final seedTrackIds = playlistTracks
      .take(5)
      .map((item) => (item as spotify.PlaylistTrack).track?.id)
      .where((id) => id != null)
      .toList();

  final seedArtistIds = playlistTracks
      .map((item) =>
          (item as spotify.PlaylistTrack).track?.artists?.first.id)
      .where((id) => id != null)
      .toSet()
      .take(5)
      .toList();

  // 3. Get recommendations based on the playlist
  final recommendations = await _spotify.recommendations.get(
    limit: recommendationsCount,
    seedTracks: seedTrackIds.cast<String>(),
    seedArtists: seedArtistIds.cast<String>(),
    market: spotify.Market.US,
  );

  // 4. Combine both lists and shuffle
  final combinedTracks = [
    ...selectedPlaylistTracks,
    ...(recommendations.tracks ?? []),
  ];
  combinedTracks.shuffle();

  yield combinedTracks.cast<spotify.Track>();
} catch (e) {
  print('Error getting mixed recommendations: $e');
  yield [];
}
}

// Get 10 random tracks from a genre-specific playlist
Future<List<spotify.Track>> getGenreRecommendations(String genre) async {
try {
  // Convert genre to lowercase for case-insensitive matching
  final genreLower = genre.toLowerCase();

  // Get the playlist ID for the genre
  final playlistId = SEED_PLAYLISTS[genreLower];
  if (playlistId == null) {
    print('No playlist found for genre: $genre');
    // Fallback to a default genre if the specific one isn't found
    final defaultGenre = 'pop';
    final defaultPlaylistId = SEED_PLAYLISTS[defaultGenre];
    if (defaultPlaylistId == null) {
      throw Exception('No default playlist found');
    }
    print('Using default genre: $defaultGenre');
    return _getRandomTracksFromPlaylist(defaultPlaylistId, 10);
  }

  return _getRandomTracksFromPlaylist(playlistId, 10);
} catch (e) {
  print('Error getting genre recommendations: $e');
  rethrow;
}
}

// Helper method to get random tracks from a playlist
Future<List<spotify.Track>> _getRandomTracksFromPlaylist(
  String playlistId, int count) async {
try {
  // Get all tracks from the playlist
  final playlistTracks =
      await _spotify.playlists.getTracksByPlaylistId(playlistId).all();

  // Convert to a list for easier manipulation
  final tracks = playlistTracks.toList();

  // If we have fewer tracks than requested, return all of them
  if (tracks.length <= count) {
    return tracks
        .map((item) => (item as spotify.PlaylistTrack).track)
        .where((track) => track != null)
        .toList()
        .cast<spotify.Track>();
  }

  // Shuffle the tracks and take the first 'count' tracks
  final random = Random();
  final selectedIndices = <int>{};

  // Select random unique indices
  while (selectedIndices.length < count) {
    selectedIndices.add(random.nextInt(tracks.length));
  }

  // Get the tracks at the selected indices
  return selectedIndices
      .map((index) => tracks[index])
      .map((item) => (item as spotify.PlaylistTrack).track)
      .where((track) => track != null)
      .toList()
      .cast<spotify.Track>();
} catch (e) {
  print('Error getting random tracks from playlist: $e');
  rethrow;
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

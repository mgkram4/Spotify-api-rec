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
    int limit = 50, // Changed from 20 to 50
  }) async* {
    try {
      print(
          'Getting mixed recommendations for genre: $genre with limit: $limit');

      // Convert genre to lowercase for case-insensitive matching
      final genreLower = genre.toLowerCase();

      final playlistId = SEED_PLAYLISTS[genreLower];
      if (playlistId == null) {
        print('Invalid genre selected: $genre');
        print('Available genres: ${SEED_PLAYLISTS.keys.join(', ')}');

        // Use a default genre
        final defaultGenre = 'pop';
        final defaultPlaylistId = SEED_PLAYLISTS[defaultGenre];
        if (defaultPlaylistId == null) {
          throw Exception('No default playlist found');
        }

        print(
            'Using default genre: $defaultGenre with playlist ID: $defaultPlaylistId');

        // Get tracks using the helper method
        final tracks = await _getMixedTracksFromPlaylistAndTopTracks(
            defaultPlaylistId, limit);
        yield tracks;
        return;
      }

      print('Found playlist ID for genre $genreLower: $playlistId');

      // Calculate how many tracks we want from each source
      // (40% genre playlist, 30% top hits, 15% recent tracks, 15% recommendations)
      final playlistTracksCount =
          (limit * 0.7).round(); // 70% from genre playlist
      final topTracksCount = (limit * 0.05).round(); // 5% from top tracks
      final recentTracksCount =
          (limit * 0.05).round(); // 5% from recent tracks
      final recommendationsCount =
          limit - playlistTracksCount - topTracksCount - recentTracksCount;

      print('Track distribution: $playlistTracksCount from playlist, $topTracksCount from top tracks, ' +
          '$recentTracksCount from recent tracks, $recommendationsCount from recommendations');

      // 1. Get tracks from the selected genre playlist
      print('Fetching tracks from genre playlist: $playlistId');
      List<spotify.Track> selectedPlaylistTracks = [];
      final seedTrackIds = <String>[];
      final seedArtistIds = <String>[];

      try {
        final playlistItems =
            await _spotify.playlists.getTracksByPlaylistId(playlistId).all();
        print('Got ${playlistItems.length} items from playlist');

        // Process each playlist item
        for (var item in playlistItems) {
          try {
            // Use dynamic to bypass type checking temporarily
            dynamic dynamicItem = item;

            // Check if it's already a Track object
            if (dynamicItem is spotify.Track) {
              selectedPlaylistTracks.add(dynamicItem);
              print('Added track (direct Track): ${dynamicItem.name}');

              // Add to seed IDs if needed
              if (seedTrackIds.length < 2 && dynamicItem.id != null) {
                seedTrackIds.add(dynamicItem.id!);
              }

              // Add artist to seed IDs if needed
              if (seedArtistIds.length < 2 &&
                  dynamicItem.artists?.isNotEmpty == true &&
                  dynamicItem.artists!.first.id != null) {
                seedArtistIds.add(dynamicItem.artists!.first.id!);
              }
            }
            // Check if it's a PlaylistTrack with a track property
            else if (dynamicItem is spotify.PlaylistTrack &&
                dynamicItem.track != null) {
              selectedPlaylistTracks.add(dynamicItem.track!);
              print(
                  'Added track: ${dynamicItem.track!.name} by ${dynamicItem.track!.artists?.first.name ?? "Unknown"}');

              // Add to seed IDs if needed
              if (seedTrackIds.length < 2 && dynamicItem.track!.id != null) {
                seedTrackIds.add(dynamicItem.track!.id!);
              }

              // Add artist to seed IDs if needed
              if (seedArtistIds.length < 2 &&
                  dynamicItem.track!.artists?.isNotEmpty == true &&
                  dynamicItem.track!.artists!.first.id != null) {
                seedArtistIds.add(dynamicItem.track!.artists!.first.id!);
              }
            } else {
              // Try to extract track using a different approach
              try {
                // Access track property directly
                final trackProperty = dynamicItem.track;
                if (trackProperty != null) {
                  // Convert to Track if possible
                  final trackId = trackProperty.id;
                  if (trackId != null &&
                      selectedPlaylistTracks.length < playlistTracksCount) {
                    // Fetch the full track
                    final fullTrack = await _spotify.tracks.get(trackId);
                    selectedPlaylistTracks.add(fullTrack);
                    print(
                        'Added track (alternative method): ${fullTrack.name}');

                    // Add to seed IDs
                    if (seedTrackIds.length < 2) {
                      seedTrackIds.add(trackId);
                    }

                    // Add artist to seed IDs
                    if (seedArtistIds.length < 2 &&
                        fullTrack.artists?.isNotEmpty == true &&
                        fullTrack.artists!.first.id != null) {
                      seedArtistIds.add(fullTrack.artists!.first.id!);
                    }
                  }
                }
              } catch (innerError) {
                print('Failed alternative track extraction: $innerError');
              }
            }
          } catch (e) {
            print('Error processing playlist item: $e');
          }
        }

        print(
            'Got ${selectedPlaylistTracks.length} tracks from genre playlist');

        // If we couldn't get any tracks, try a direct approach with the playlist ID
        if (selectedPlaylistTracks.isEmpty) {
          print('No tracks extracted from playlist, trying direct approach');
          try {
            final playlist = await _spotify.playlists.get(playlistId);
            print(
                'Playlist name: ${playlist.name}, total tracks: ${playlist.tracks?.total}');

            // Try to get tracks using a different endpoint
            final tracksPage = await _spotify.playlists
                .getTracksByPlaylistId(playlistId)
                .getPage(playlistTracksCount);
            if (tracksPage.items != null) {
              for (var item in tracksPage.items!) {
                try {
                  dynamic dynamicItem = item;
                  if (dynamicItem is spotify.PlaylistTrack &&
                      dynamicItem.track != null) {
                    selectedPlaylistTracks.add(dynamicItem.track!);
                    print(
                        'Added track (direct approach): ${dynamicItem.track!.name}');
                  }
                } catch (e) {
                  print('Error processing direct playlist item: $e');
                }
              }
            }
            print(
                'Got ${selectedPlaylistTracks.length} tracks from direct approach');
          } catch (directError) {
            print('Error with direct playlist approach: $directError');
          }
        }
      } catch (e) {
        print('Error getting tracks from playlist: $e');
        // Continue with empty playlist tracks
      }

      // 2. Get user's top tracks
      print('Fetching user\'s top tracks');
      List<spotify.Track> topTracks = [];
      try {
        final topTracksPage =
            await _spotify.me.topTracks().getPage(topTracksCount);

        if (topTracksPage.items != null) {
          topTracks.addAll(topTracksPage.items!);

          // Add to seed IDs
          for (var track in topTracks) {
            if (seedTrackIds.length < 3 && track.id != null) {
              seedTrackIds.add(track.id!);
            }

            if (seedArtistIds.length < 2 &&
                track.artists?.isNotEmpty == true &&
                track.artists!.first.id != null) {
              seedArtistIds.add(track.artists!.first.id!);
            }
          }
        }

        print('Got ${topTracks.length} top tracks');
      } catch (e) {
        print('Error getting top tracks: $e');
        // Continue with empty top tracks
      }

      // 3. Get user's recently played tracks
      print('Fetching user\'s recently played tracks');
      List<spotify.Track> recentTracks = [];
      List<String> recentTrackIds = [];
      try {
        final recentlyPlayed =
            await _spotify.me.recentlyPlayed().getPage(recentTracksCount);

        if (recentlyPlayed.items != null) {
          for (var item in recentlyPlayed.items!) {
            if (item.track != null && item.track!.id != null) {
              // Collect IDs to fetch full Track objects
              recentTrackIds.add(item.track!.id!);

              // Add to seed IDs
              if (seedTrackIds.length < 4) {
                seedTrackIds.add(item.track!.id!);
              }
            }
          }

          // Fetch full Track objects if we have IDs
          if (recentTrackIds.isNotEmpty) {
            final tracks = await _spotify.tracks.list(recentTrackIds);
            recentTracks.addAll(tracks.toList());
          }
        }

        print('Got ${recentTracks.length} recent tracks');
      } catch (e) {
        print('Error getting recent tracks: $e');
        // Continue with empty recent tracks
      }

      // 4. Get recommendations based on the playlist, top tracks, and recent tracks
      List<spotify.Track> recommendationTracks = [];
      try {
        // Ensure we have at least 1 seed and at most 5 seeds total
        final seedGenres = seedTrackIds.isEmpty && seedArtistIds.isEmpty
            ? [genre.toLowerCase()]
            : <String>[];

        // Make sure we don't exceed 5 seeds total
        final totalSeeds =
            seedTrackIds.length + seedArtistIds.length + seedGenres.length;
        if (totalSeeds > 5) {
          // Prioritize tracks, then artists, then genres
          if (seedTrackIds.length > 3) {
            seedTrackIds.length = 3;
          }
          if (seedTrackIds.length + seedArtistIds.length > 4) {
            seedArtistIds.length = 4 - seedTrackIds.length;
          }
        }

        print(
            'Using seeds - Tracks: $seedTrackIds, Artists: $seedArtistIds, Genres: $seedGenres');
        final recommendations = await _spotify.recommendations.get(
          limit: recommendationsCount,
          seedTracks: seedTrackIds,
          seedArtists: seedArtistIds,
          seedGenres: seedGenres,
          market: spotify.Market.US,
        );

        // Convert TrackSimple to Track by fetching full track data
        final recommendationTrackIds = <String>[];
        if (recommendations.tracks != null) {
          for (var trackSimple in recommendations.tracks!) {
            // Use dynamic to bypass type checking
            dynamic track = trackSimple;
            if (track.id != null) {
              recommendationTrackIds.add(track.id);
            }
          }
        }

        if (recommendationTrackIds.isNotEmpty) {
          // Fetch full track data for the recommendations
          print(
              'Fetching full track data for ${recommendationTrackIds.length} recommendations');
          final tracks = await _spotify.tracks.list(recommendationTrackIds);
          recommendationTracks.addAll(tracks.toList());
        }

        print('Got ${recommendationTracks.length} recommendation tracks');
      } catch (e) {
        print('Error getting recommendations: $e');
        // Continue with empty recommendation tracks
      }

      // 5. Combine all lists and shuffle
      final combinedTracks = <spotify.Track>[
        ...selectedPlaylistTracks,
        ...topTracks,
        ...recentTracks,
        ...recommendationTracks,
      ];

      // If we have no tracks at all, try a fallback approach
      if (combinedTracks.isEmpty) {
        print('No tracks found, trying fallback approach');
        try {
          // Get some popular tracks for the genre
          final recommendations = await _spotify.recommendations.get(
            seedGenres: [genre.toLowerCase()],
            limit: limit,
            market: spotify.Market.US,
          );

          if (recommendations.tracks != null &&
              recommendations.tracks!.isNotEmpty) {
            final trackIds = recommendations.tracks!
                .where((track) => track.id != null)
                .map((track) => track.id!)
                .toList();

            if (trackIds.isNotEmpty) {
              final tracks = await _spotify.tracks.list(trackIds);
              combinedTracks.addAll(tracks.toList());
              print('Fallback successful, got ${combinedTracks.length} tracks');
            }
          }
        } catch (fallbackError) {
          print('Fallback attempt failed: $fallbackError');
        }
      }

      // If we still have no tracks, try getting top tracks
      if (combinedTracks.isEmpty) {
        print('Still no tracks, trying to get more top tracks');
        try {
          final topTracks = await _spotify.me.topTracks().getPage(limit);
          if (topTracks.items != null && topTracks.items!.isNotEmpty) {
            combinedTracks.addAll(topTracks.items!);
            print('Got ${combinedTracks.length} top tracks as final fallback');
          }
        } catch (e) {
          print('Error getting top tracks: $e');
        }
      }

      // Make sure to shuffle the tracks thoroughly
      final random = Random();
      combinedTracks.shuffle(random);

      // Ensure we don't exceed the limit
      final finalTracks = combinedTracks.length > limit
          ? combinedTracks.sublist(0, limit)
          : combinedTracks;

      print('Returning ${finalTracks.length} combined and shuffled tracks');

      yield finalTracks;
    } catch (e) {
      print('Error getting mixed recommendations: $e');

      // Try to get some tracks as a last resort
      try {
        print('Attempting to get any available tracks as last resort');
        final topTracks = await _spotify.me.topTracks().getPage(limit);
        if (topTracks.items != null && topTracks.items!.isNotEmpty) {
          print('Got ${topTracks.items!.length} top tracks as last resort');
          yield topTracks.items!.toList();
          return;
        }
      } catch (fallbackError) {
        print('Final fallback attempt failed: $fallbackError');
      }

      yield <spotify.Track>[];
    }
  }

// Get 50 random tracks from a genre-specific playlist
  Future<List<spotify.Track>> getGenreRecommendations(String genre) async {
    try {
      print('Getting genre recommendations for: $genre');
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
        return _getMixedTracksFromPlaylistAndTopTracks(defaultPlaylistId, 50);
      }

      return _getMixedTracksFromPlaylistAndTopTracks(playlistId, 50);
    } catch (e) {
      print('Error getting genre recommendations: $e');
      rethrow;
    }
  }

// Helper method to get random tracks from a playlist mixed with top tracks
  Future<List<spotify.Track>> _getMixedTracksFromPlaylistAndTopTracks(
      String playlistId, int count) async {
    try {
      // Default to 50 tracks if not specified
      count = count > 0 ? count : 50;

      // Calculate how many tracks to get from each source
      final playlistTracksCount = (count * 0.4).round(); // 40% from playlist
      final topTracksCount = (count * 0.3).round(); // 30% from top tracks
      final recentTracksCount =
          (count * 0.15).round(); // 15% from recent tracks
      final recommendationsCount = count -
          playlistTracksCount -
          topTracksCount -
          recentTracksCount; // 15% from recommendations

      print('Getting $playlistTracksCount tracks from playlist, $topTracksCount from top tracks, ' +
          '$recentTracksCount from recent tracks, and $recommendationsCount from recommendations');

      // Get tracks from the playlist
      final playlistTracks =
          await _getRandomTracksFromPlaylist(playlistId, playlistTracksCount);
      print('Got ${playlistTracks.length} tracks from playlist');

      // Get user's top tracks
      final topTracks = <spotify.Track>[];
      try {
        print('Fetching user\'s top tracks');
        final topTracksPage =
            await _spotify.me.topTracks().getPage(topTracksCount);

        if (topTracksPage.items != null) {
          topTracks.addAll(topTracksPage.items!);
        }
        print('Got ${topTracks.length} top tracks');
      } catch (e) {
        print('Error getting top tracks: $e');
      }

      // Get user's recently played tracks
      final recentTracks = <spotify.Track>[];
      try {
        print('Fetching user\'s recently played tracks');
        final recentlyPlayed =
            await _spotify.me.recentlyPlayed().getPage(recentTracksCount);

        // Collect track IDs from recently played
        final recentTrackIds = <String>[];
        if (recentlyPlayed.items != null) {
          for (var item in recentlyPlayed.items!) {
            if (item.track != null && item.track!.id != null) {
              recentTrackIds.add(item.track!.id!);
            }
          }
        }

        // Fetch full Track objects
        if (recentTrackIds.isNotEmpty) {
          final tracks = await _spotify.tracks.list(recentTrackIds);
          recentTracks.addAll(tracks.toList());
        }

        print('Got ${recentTracks.length} recent tracks');
      } catch (e) {
        print('Error getting recent tracks: $e');
      }

      // Get recommendations based on the tracks we've collected
      final recommendationTracks = <spotify.Track>[];
      try {
        // Collect seed track and artist IDs
        final seedTrackIds = <String>[];
        final seedArtistIds = <String>[];

        // Add IDs from playlist tracks
        for (var track in playlistTracks) {
          if (seedTrackIds.length < 2 && track.id != null) {
            seedTrackIds.add(track.id!);
          }
          if (seedArtistIds.length < 1 &&
              track.artists?.isNotEmpty == true &&
              track.artists!.first.id != null) {
            seedArtistIds.add(track.artists!.first.id!);
          }
          if (seedTrackIds.length >= 2 && seedArtistIds.length >= 1) break;
        }

        // Add IDs from top tracks if needed
        if (seedTrackIds.length < 2 || seedArtistIds.length < 2) {
          for (var track in topTracks) {
            if (seedTrackIds.length < 2 && track.id != null) {
              seedTrackIds.add(track.id!);
            }
            if (seedArtistIds.length < 2 &&
                track.artists?.isNotEmpty == true &&
                track.artists!.first.id != null) {
              seedArtistIds.add(track.artists!.first.id!);
            }
            if (seedTrackIds.length >= 2 && seedArtistIds.length >= 2) break;
          }
        }

        // Get genre for the playlist
        String genre = 'pop'; // Default
        for (var entry in SEED_PLAYLISTS.entries) {
          if (entry.value == playlistId) {
            genre = entry.key;
            break;
          }
        }

        // Ensure we have at least one seed
        final seedGenres = seedTrackIds.isEmpty && seedArtistIds.isEmpty
            ? [genre]
            : <String>[];

        print(
            'Using seeds - Tracks: $seedTrackIds, Artists: $seedArtistIds, Genres: $seedGenres');

        // Get recommendations
        if (recommendationsCount > 0) {
          final recommendations = await _spotify.recommendations.get(
            limit: recommendationsCount,
            seedTracks: seedTrackIds,
            seedArtists: seedArtistIds,
            seedGenres: seedGenres,
            market: spotify.Market.US,
          );

          // Convert TrackSimple to Track
          final trackIds = <String>[];
          if (recommendations.tracks != null) {
            for (var trackSimple in recommendations.tracks!) {
              // Use dynamic to bypass type checking
              dynamic track = trackSimple;
              if (track.id != null) {
                trackIds.add(track.id);
              }
            }
          }

          if (trackIds.isNotEmpty) {
            final tracks = await _spotify.tracks.list(trackIds);
            recommendationTracks.addAll(tracks.toList());
          }

          print('Got ${recommendationTracks.length} recommendation tracks');
        }
      } catch (e) {
        print('Error getting recommendations: $e');
      }

      // Combine and shuffle
      final combinedTracks = [
        ...playlistTracks,
        ...topTracks,
        ...recentTracks,
        ...recommendationTracks
      ];

      // Make sure we have enough tracks
      if (combinedTracks.isEmpty) {
        print('No tracks found, trying fallback approach');
        try {
          // Get a genre that matches the playlist
          String genre = 'pop'; // Default
          for (var entry in SEED_PLAYLISTS.entries) {
            if (entry.value == playlistId) {
              genre = entry.key;
              break;
            }
          }

          // Get recommendations based on the genre
          final recommendations = await _spotify.recommendations.get(
            seedGenres: [genre],
            limit: count,
            market: spotify.Market.US,
          );

          if (recommendations.tracks != null &&
              recommendations.tracks!.isNotEmpty) {
            final trackIds = recommendations.tracks!
                .where((track) => track.id != null)
                .map((track) => track.id!)
                .toList();

            if (trackIds.isNotEmpty) {
              final tracks = await _spotify.tracks.list(trackIds);
              combinedTracks.addAll(tracks.toList());
            }
          }
        } catch (fallbackError) {
          print('Fallback attempt failed: $fallbackError');
        }
      }

      // Shuffle thoroughly
      final random = Random();
      combinedTracks.shuffle(random);

      // Ensure we don't exceed the requested count
      final finalTracks = combinedTracks.length > count
          ? combinedTracks.sublist(0, count)
          : combinedTracks;

      print('Returning ${finalTracks.length} combined and shuffled tracks');
      return finalTracks;
    } catch (e) {
      print('Error getting mixed tracks: $e');
      rethrow;
    }
  }

// Helper method to get random tracks from a playlist
  Future<List<spotify.Track>> _getRandomTracksFromPlaylist(
      String playlistId, int count) async {
    try {
      print('Fetching tracks from playlist: $playlistId');

      // Get all tracks from the playlist
      final playlistItems =
          await _spotify.playlists.getTracksByPlaylistId(playlistId).all();
      print('Got ${playlistItems.length} items from playlist');

      // Convert to a list and extract tracks safely
      final tracks = <spotify.Track>[];

      // Explicitly check each item's type and handle accordingly
      for (var item in playlistItems) {
        try {
          // Use dynamic to bypass type checking temporarily
          dynamic dynamicItem = item;

          // Check if it's already a Track object
          if (dynamicItem is spotify.Track) {
            tracks.add(dynamicItem);
            print('Added track (direct Track): ${dynamicItem.name}');
          }
          // Check if it's a PlaylistTrack with a track property
          else if (dynamicItem is spotify.PlaylistTrack &&
              dynamicItem.track != null) {
            tracks.add(dynamicItem.track!);
            print('Added track: ${dynamicItem.track!.name}');
          } else {
            print(
                'Item is not a PlaylistTrack or has null track: ${dynamicItem.runtimeType}');
          }
        } catch (e) {
          print('Error processing playlist item: $e');
        }
      }

      print('Successfully extracted ${tracks.length} tracks from playlist');

      // If we have fewer tracks than requested, return all of them
      if (tracks.length <= count) {
        return tracks;
      }

      // Shuffle the tracks and take 'count' random tracks
      tracks.shuffle(Random());
      return tracks.take(count).toList();
    } catch (e) {
      print('Error getting random tracks from playlist: $e');

      // Fallback: Try to get some popular tracks for the genre
      try {
        print('Attempting fallback: Getting popular tracks');
        // Get a genre that matches the playlist
        String genre = 'pop'; // Default
        for (var entry in SEED_PLAYLISTS.entries) {
          if (entry.value == playlistId) {
            genre = entry.key;
            break;
          }
        }

        print('Trying to get popular tracks for genre: $genre');

        // Try to get tracks from Spotify's featured playlists for this genre
        try {
          final featuredPlaylists = await _spotify.playlists.featured.all();
          for (var playlist in featuredPlaylists) {
            if (playlist.name?.toLowerCase().contains(genre) == true) {
              print('Found featured playlist for $genre: ${playlist.name}');
              final playlistTracks = await _spotify.playlists
                  .getTracksByPlaylistId(playlist.id!)
                  .all();
              final extractedTracks = <spotify.Track>[];

              for (var item in playlistTracks) {
                try {
                  dynamic dynamicItem = item;
                  if (dynamicItem is spotify.PlaylistTrack &&
                      dynamicItem.track != null) {
                    extractedTracks.add(dynamicItem.track!);
                  }
                } catch (e) {
                  print('Error processing featured playlist item: $e');
                }
              }

              if (extractedTracks.isNotEmpty) {
                print(
                    'Got ${extractedTracks.length} tracks from featured playlist');
                extractedTracks.shuffle(Random());
                return extractedTracks.take(count).toList();
              }
            }
          }
        } catch (e) {
          print('Error getting featured playlists: $e');
        }

        // Get recommendations based on the genre
        final recommendations = await _spotify.recommendations.get(
          seedGenres: [genre],
          limit: count,
          market: spotify.Market.US,
        );

        if (recommendations.tracks != null &&
            recommendations.tracks!.isNotEmpty) {
          print(
              'Fallback successful, got ${recommendations.tracks!.length} tracks');

          // Convert TrackSimple to Track
          final trackIds = recommendations.tracks!
              .where((track) => track.id != null)
              .map((track) => track.id!)
              .toList();

          if (trackIds.isNotEmpty) {
            final tracks = await _spotify.tracks.list(trackIds);
            return tracks.toList();
          }
        }
      } catch (fallbackError) {
        print('Fallback attempt failed: $fallbackError');
      }

      // If all else fails, try to get tracks from a different genre
      try {
        print('Trying to get tracks from a different genre as last resort');
        final defaultGenre = 'pop';
        final defaultPlaylistId = SEED_PLAYLISTS[defaultGenre];

        if (defaultPlaylistId != null && defaultPlaylistId != playlistId) {
          print('Using default genre playlist: $defaultGenre');
          final defaultPlaylistItems = await _spotify.playlists
              .getTracksByPlaylistId(defaultPlaylistId)
              .all();

          final defaultTracks = <spotify.Track>[];
          for (var item in defaultPlaylistItems) {
            try {
              dynamic dynamicItem = item;
              if (dynamicItem is spotify.PlaylistTrack &&
                  dynamicItem.track != null) {
                defaultTracks.add(dynamicItem.track!);
              }
            } catch (e) {
              print('Error processing default playlist item: $e');
            }
          }

          if (defaultTracks.isNotEmpty) {
            print('Got ${defaultTracks.length} tracks from default playlist');
            defaultTracks.shuffle(Random());
            return defaultTracks.take(count).toList();
          }
        }
      } catch (e) {
        print('Error getting tracks from default playlist: $e');
      }

      // If all else fails, return an empty list
      return [];
    }
  }

  Future<List<spotify.Track>> getArtistTopTracks(String artistId) async {
    try {
      // Get artist's top tracks for US market
      final response = await _spotify.artists.getTopTracks(artistId, 'US');
      return response.toList();
    } catch (e) {
      print('Error getting artist top tracks: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getArtistDetails(String artistId) async {
    try {
      final artist = await _spotify.artists.get(artistId);
      final stats = {
        'Popularity': artist.popularity ?? 0,
        'Followers': artist.followers?.total ?? 0,
        // Add any other stats you want to display
      };
      
      return {
        'stats': stats,
        'description': 'Artist description would go here...', // Placeholder
      };
    } catch (e) {
      print('Error getting artist details: $e');
      return {};
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
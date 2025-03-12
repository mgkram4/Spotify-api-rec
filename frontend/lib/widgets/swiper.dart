import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:spotify/spotify.dart' as spotify;

import '../services/auth_service.dart';
import '../services/playlist_service.dart';

class Swiper extends StatefulWidget {
  final String? mood;
  final List<String> categories;
  final List<String>? trackIds;

  const Swiper({
    Key? key,
    this.mood,
    required this.categories,
    this.trackIds,
  }) : super(key: key);

  @override
  State<Swiper> createState() => _SwiperState();
}

class _SwiperState extends State<Swiper> {
  // Track card position
  Offset _position = Offset.zero;
  List<spotify.Track> _likedTracks = [];
  List<spotify.Track> _tracks = [];
  late PlaylistService _playlistService;
  bool _isLoading = true;

  // Spotify colors
  static const spotifyBlack = Color(0xFF191414);
  static const spotifyGreen = Color(0xFF1DB954);
  static const spotifyGrey = Color(0xFF282828);
  static const spotifyLightGrey = Color(0xFF404040);

  int _currentIndex = 0;

  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _currentlyPlayingIndex;

  @override
  void initState() {
    super.initState();
    _initializeSpotify();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initializeSpotify() async {
    final authService = AuthService();
    var token = authService.spotifyToken;

    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not logged in to Spotify. Please log in first.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    _playlistService = PlaylistService(token);
    await _loadTracks();
  }

  Future<void> _loadTracks() async {
    try {
      setState(() => _isLoading = true);

      print('Selected mood: ${widget.mood}');
      print('Selected categories: ${widget.categories}');

      // If we have categories, use the first one as the genre
      if (widget.categories.isNotEmpty) {
        final primaryGenre = widget.categories.first.toLowerCase();
        print('Using primary genre: $primaryGenre');

        try {
          // Try to get recommendations based on the selected genre
          print(
              'Attempting to get mixed recommendations for genre: $primaryGenre');
          final tracksStream = _playlistService.getMixedRecommendationsStream(
            genre: primaryGenre,
            limit: 20,
          );

          await for (final tracks in tracksStream) {
            if (tracks.isNotEmpty) {
              print(
                  'Successfully got ${tracks.length} tracks from mixed recommendations');
              setState(() {
                _tracks = tracks;
                _isLoading = false;
              });
              return; // Exit if we got tracks
            }
          }
          print(
              'Mixed recommendations stream completed but no tracks were returned');
        } catch (e) {
          print('Error with mixed recommendations: $e');
          // Continue to fallback
        }

        // Fallback to genre recommendations
        try {
          print('Attempting to get genre recommendations for: $primaryGenre');
          final genreTracks =
              await _playlistService.getGenreRecommendations(primaryGenre);
          if (genreTracks.isNotEmpty) {
            print(
                'Successfully got ${genreTracks.length} tracks from genre recommendations');
            setState(() {
              _tracks = genreTracks;
              _isLoading = false;
            });
            return; // Exit if we got tracks
          }
          print('Genre recommendations returned no tracks');
        } catch (e) {
          print('Error with genre recommendations: $e');
          // Continue to next fallback
        }
      } else {
        print('No categories selected, skipping genre-based recommendations');
      }

      // If we get here, either we had no categories or the genre-based methods failed
      // Fallback to top tracks
      print('Falling back to top tracks');
      final topTracksStream = _playlistService.getTopTracksStream();
      await for (final tracks in topTracksStream) {
        if (tracks.isNotEmpty) {
          print('Successfully got ${tracks.length} tracks from top tracks');
          setState(() {
            _tracks = tracks;
            _isLoading = false;
          });
          return;
        }
      }
      print('Top tracks stream completed but no tracks were returned');

      // If we get here, all methods failed
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load any tracks. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error loading tracks: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading tracks: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _playTrack(spotify.Track track, int index) async {
    try {
      if (_currentlyPlayingIndex == index && _audioPlayer.playing) {
        await _audioPlayer.pause();
        setState(() {});
        return;
      }

      // Get preview URL from the track
      final previewUrl = track.previewUrl;
      if (previewUrl == null) {
        throw Exception('No preview URL available for this track');
      }

      if (_currentlyPlayingIndex != index) {
        await _audioPlayer.stop();
        await _audioPlayer.setUrl(previewUrl);
      }

      await _audioPlayer.play();
      setState(() {
        _currentlyPlayingIndex = index;
      });
    } catch (e) {
      print('Error playing track: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to play preview: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: spotifyBlack,
          appBar: AppBar(
            backgroundColor: spotifyBlack,
            elevation: 0,
            title: const Text(
              'Discover Music',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _currentIndex = _tracks.length;
                  });
                },
                icon: const Icon(Icons.stop, color: spotifyGreen),
                label: const Text(
                  'Stop Swiping',
                  style: TextStyle(color: spotifyGreen),
                ),
              ),
            ],
          ),
          body: _currentIndex >= _tracks.length
              ? _buildResultsScreen()
              : Column(
                  children: [
                    // Progress indicator
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Row(
                        children: [
                          Text(
                            '${_currentIndex + 1}/${_tracks.length}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: (_currentIndex + 1) / _tracks.length,
                              backgroundColor: spotifyGrey,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  spotifyGreen),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Swipe instructions
                    if (_currentIndex == 0)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: spotifyGrey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: spotifyGreen),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Swipe right to like, left to skip',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Cards stack
                    Expanded(
                      child: Center(
                        child: Stack(
                          children: [
                            // Background cards
                            if (_currentIndex < _tracks.length - 1)
                              Transform.translate(
                                offset: const Offset(0, 10),
                                child: _buildCard(_currentIndex + 1,
                                    scale: 0.95, opacity: 0.5),
                              ),
                            // Current card
                            GestureDetector(
                              onPanUpdate: (details) {
                                setState(() {
                                  _position += details.delta;
                                });
                              },
                              onPanEnd: (details) {
                                final status = _position.dx > 100
                                    ? 'liked'
                                    : _position.dx < -100
                                        ? 'disliked'
                                        : 'reset';

                                setState(() {
                                  if (status == 'liked') {
                                    _likedTracks.add(_tracks[_currentIndex]);
                                    _currentIndex++;
                                  } else if (status == 'disliked') {
                                    _currentIndex++;
                                  }

                                  _position = Offset.zero;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 100),
                                transform: Matrix4.identity()
                                  ..translate(_position.dx, _position.dy),
                                child: _buildCard(_currentIndex),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Swipe indicators
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildActionButton(
                            icon: Icons.close,
                            color: Colors.red,
                            isActive: _position.dx < 0,
                            label: 'Skip',
                          ),
                          const SizedBox(width: 40),
                          _buildActionButton(
                            icon: Icons.favorite,
                            color: spotifyGreen,
                            isActive: _position.dx > 0,
                            label: 'Like',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
        if (_isLoading || _tracks.isEmpty) _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: spotifyGrey,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: spotifyGreen),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(spotifyGreen),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'LOADING TRACKS...',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required bool isActive,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? color : spotifyGrey,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? color : Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(int index, {double scale = 1.0, double opacity = 1.0}) {
    // Return an empty container instead of null when index is out of range
    if (index >= _tracks.length) {
      return const SizedBox.shrink();
    }

    final track = _tracks[index];
    final isPlaying = _currentlyPlayingIndex == index && _audioPlayer.playing;

    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: 300,
          height: 600,
          decoration: BoxDecoration(
            color: spotifyGrey,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Album art container
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: spotifyBlack,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    image: track.album?.images?.isNotEmpty == true
                        ? DecorationImage(
                            image:
                                NetworkImage(track.album!.images!.first.url!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                ),
                // Song title section
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.name ?? 'Unknown Track',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        track.artists?.map((a) => a.name).join(', ') ??
                            'Unknown Artist',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Play preview button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton(
                    onPressed: () => _playTrack(track, index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: spotifyGreen,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      isPlaying ? 'Pause Preview' : 'Play Preview',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Album info section
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(15),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: spotifyLightGrey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Album: ${track.album?.name ?? 'Unknown Album'}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (track.album?.releaseDate != null)
                        Text(
                          'Released: ${track.album!.releaseDate}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    if (_isLoading || _tracks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      color: spotifyBlack,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Your Liked Songs',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _likedTracks.length,
              itemBuilder: (context, index) {
                final track = _likedTracks[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: spotifyGrey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      if (track.album?.images?.isNotEmpty == true)
                        Container(
                          width: 50,
                          height: 50,
                          margin: const EdgeInsets.only(right: 15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            image: DecorationImage(
                              image:
                                  NetworkImage(track.album!.images!.first.url!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.name ?? 'Unknown Track',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              track.artists?.map((a) => a.name).join(', ') ??
                                  'Unknown Artist',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: spotifyGrey,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_likedTracks.isNotEmpty) {
                    try {
                      await _playlistService.createPlaylistFromSwipedTracks(
                        _likedTracks.map((t) => t.id!).toList(),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Playlist created successfully!'),
                          backgroundColor: spotifyGreen,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error creating playlist: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                  setState(() {
                    _currentIndex = 0;
                    _likedTracks.clear();
                    _position = Offset.zero;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: spotifyGreen,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Create Playlist',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

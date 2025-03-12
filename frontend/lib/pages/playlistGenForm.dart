import 'package:flutter/material.dart';
import 'package:spotfiy_rec/services/auth_service.dart';
import 'package:spotfiy_rec/services/playlist_service.dart';
import 'package:spotfiy_rec/widgets/swiper.dart';
import 'package:spotify/spotify.dart' as spotify;

class PlaylistGenerator extends StatefulWidget {
  const PlaylistGenerator({Key? key}) : super(key: key);

  @override
  _PlaylistGeneratorState createState() => _PlaylistGeneratorState();
}

class _PlaylistGeneratorState extends State<PlaylistGenerator> {
  String? selectedMood;
  Set<String> selectedCategories = {};
  Set<Map<String, String>> selectedSongs = {}; // Track selected songs

  bool _isLoading = true;
  List<spotify.Track> _userTopTracks = [];
  List<spotify.Track> _recommendedTracks = [];

  late final PlaylistService _playlistService;

  final List<String> moods = [
    'Happy',
    'Sad',
    'Energetic',
    'Relaxed',
    'Focused',
    'Party'
  ];

  final List<String> musicCategories = [
    'rock',
    'classical',
    'edm',
    'pop',
    'jazz',
    'trap',
    'rap'
  ];

  @override
  void initState() {
    super.initState();
    final authService = AuthService();
    _playlistService = PlaylistService(authService.spotifyToken!);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);

      // Stream top tracks from user profile
      _playlistService.getTopTracksStream().listen((tracks) {
        setState(() {
          _userTopTracks = tracks;
          _isLoading = false;
        });
      });

      // Get recommended tracks based on user's top tracks
      // Using top tracks as seed for recommendations since getRecommendationsStream doesn't exist
      _playlistService.getTopTracksStream().listen((tracks) {
        if (tracks.isNotEmpty) {
          // Use the first few tracks as seeds for recommendations
          final seedTracks = tracks.take(5).map((t) => t.id!).toList();

          // Use a default genre if no categories are selected
          final genre =
              selectedCategories.isNotEmpty ? selectedCategories.first : 'pop';

          _playlistService
              .getGenreRecommendations(genre)
              .then((recommendations) {
            setState(() {
              _recommendedTracks = recommendations;
            });
          });
        }
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A2A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'INFINITE PLAYLIST GENERATOR',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFFB2F5B2),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading your music profile...',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Mood Dropdown
                            const Text(
                              'WHAT IS YOUR MOOD TODAY?',
                              style: TextStyle(
                                color: Colors.grey,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF3A3A3A),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: selectedMood,
                                dropdownColor: const Color(0xFF3A3A3A),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 12),
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'monospace',
                                ),
                                items: moods.map((String mood) {
                                  return DropdownMenuItem<String>(
                                    value: mood,
                                    child: Text(mood),
                                  );
                                }).toList(),
                                onChanged: (String? value) {
                                  setState(() {
                                    selectedMood = value;
                                  });
                                },
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Music Categories
                            const Text(
                              'WHAT MUSIC CATEGORY WOULD YOU LIKE?',
                              style: TextStyle(
                                color: Colors.grey,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 8),
                            GridView.count(
                              shrinkWrap: true,
                              crossAxisCount: 3,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 2.5,
                              physics: const NeverScrollableScrollPhysics(),
                              children: musicCategories.map((category) {
                                final isSelected =
                                    selectedCategories.contains(category);
                                return ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSelected
                                        ? const Color(0xFFB2F5B2)
                                        : const Color(0xFF3A3A3A),
                                    foregroundColor: isSelected
                                        ? Colors.black
                                        : Colors.white,
                                    padding: EdgeInsets.zero,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (isSelected) {
                                        selectedCategories.remove(category);
                                      } else {
                                        selectedCategories.add(category);
                                      }
                                    });
                                  },
                                  child: Text(
                                    category,
                                    style: const TextStyle(
                                        fontFamily: 'monospace'),
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 24),

                            // Recent Recommendations
                            const Text(
                              'RECOMMENDED BASED ON RECENTS:',
                              style: TextStyle(
                                color: Colors.grey,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._userTopTracks.take(5).map((track) =>
                                _buildTrackTile(track, isSelectable: true)),

                            const SizedBox(height: 24),

                            // Vibe Recommendations
                            const Text(
                              'RECOMMENDED BASED ON VIBES:',
                              style: TextStyle(
                                color: Colors.grey,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._recommendedTracks.take(5).map((track) =>
                                _buildTrackTile(track, isSelectable: true)),
                          ],
                        ),
                      ),

                      // Add Start Swiping Button at the bottom
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB2F5B2),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              if (selectedMood != null &&
                                  selectedCategories.isNotEmpty) {
                                // Convert selected songs to track IDs for the Swiper
                                final List<String> seedTrackIds = selectedSongs
                                    .map((song) => song['id']!)
                                    .where((id) => id.isNotEmpty)
                                    .toList();

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Swiper(
                                      mood: selectedMood,
                                      categories: selectedCategories.toList(),
                                      trackIds: seedTrackIds,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please select a mood and at least one category',
                                      style: TextStyle(fontFamily: 'monospace'),
                                    ),
                                    backgroundColor: Color(0xFF3A3A3A),
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              'START SWIPING',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTrackTile(spotify.Track track, {bool isSelectable = false}) {
    // Create a non-nullable map for the song data
    final Map<String, String> songMap = {
      'id': track.id ?? '',
      'name': track.name ?? 'Unknown Track',
      'artist': track.artists?.map((a) => a.name ?? '').join(', ') ??
          'Unknown Artist',
      'imageUrl': track.album?.images?.isNotEmpty == true
          ? (track.album!.images!.first.url ?? '')
          : '',
    };

    // Check if this song is in the selectedSongs set
    final bool isSongSelected =
        selectedSongs.any((s) => s['id'] == songMap['id']);

    return GestureDetector(
      onTap: isSelectable
          ? () {
              setState(() {
                // Toggle selection
                if (isSongSelected) {
                  selectedSongs.removeWhere((s) => s['id'] == songMap['id']);
                } else {
                  selectedSongs.add(songMap);
                }
              });
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSongSelected
              ? const Color(0xFF4A4A4A)
              : const Color(0xFF3A3A3A),
          borderRadius: BorderRadius.circular(4),
          border: isSongSelected
              ? Border.all(color: const Color(0xFFB2F5B2), width: 2)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(4),
                image: songMap['imageUrl']!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(songMap['imageUrl']!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: isSongSelected
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.check,
                          color: Color(0xFFB2F5B2), size: 20),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    songMap['name']!,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontWeight:
                          isSongSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    songMap['artist']!,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelectable)
              Icon(
                isSongSelected ? Icons.check_circle : Icons.add_circle_outline,
                color: isSongSelected ? const Color(0xFFB2F5B2) : Colors.grey,
              ),
          ],
        ),
      ),
    );
  }
}

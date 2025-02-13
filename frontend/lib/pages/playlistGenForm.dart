import 'package:flutter/material.dart';
import 'package:spotfiy_rec/services/auth_service.dart';
import 'package:spotfiy_rec/services/playlist_service.dart';
import 'package:spotfiy_rec/services/recommendation_service.dart';
import 'package:spotfiy_rec/widgets/swiper.dart';

class PlaylistGenerator extends StatefulWidget {
  const PlaylistGenerator({Key? key}) : super(key: key);

  @override
  _PlaylistGeneratorState createState() => _PlaylistGeneratorState();
}

class _PlaylistGeneratorState extends State<PlaylistGenerator> {
  String? selectedMood;
  Set<String> selectedCategories = {};
  final TextEditingController searchController = TextEditingController();

  final List<String> moods = [
    'Happy',
    'Sad',
    'Energetic',
    'Relaxed',
    'Focused',
    'Party'
  ];

  final List<String> musicCategories = [
    'EDM',
    'TRAP',
    'RAP',
    'POP',
    'SAD RAP',
    'ATL RAP',
    'R&B',
    'JAZZ',
    'CLASSICAL'
  ];

  final RecommendationService _recommendationService = RecommendationService();
  final PlaylistService _playlistService;
  bool _isLoading = false;

  _PlaylistGeneratorState()
      : _playlistService = PlaylistService(AuthService().spotifyToken ?? '');

  List<Map<String, String>> recentSongs = [];
  List<Map<String, dynamic>> recommendedSongs = [];

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      final recentTracks = await _playlistService.getPlaylistTracks('recent');
      setState(() {
        recentSongs = recentTracks
            .take(5)
            .map((track) => {
                  'name': track.name ?? 'Unknown',
                  'artist': track.artists?.first.name ?? 'Unknown Artist',
                })
            .toList();
      });
    } catch (e) {
      print('Error loading recent tracks: $e');
    }
  }

  Future<void> _getRecommendations() async {
    if (selectedMood == null || selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a mood and at least one category'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final recommendation = await _recommendationService.getRecommendation(
        tempo: 5,
        mood: moods.indexOf(selectedMood!),
        length: 10,
        explicit: true,
        age: 2024,
        setting: 0,
      );

      if (recommendation['songs'] != null) {
        setState(() {
          recommendedSongs = (recommendation['songs'] as List)
              .map((song) => {
                    'name': song['name'] ?? 'Unknown',
                    'artist': song['artists']?[0]?['name'] ?? 'Unknown Artist',
                  })
              .toList();
        });

        final playlistData =
            await _playlistService.createPlaylistFromSwipedTracks(
          (recommendation['songs'] as List)
              .map((song) => song['id'].toString())
              .toList(),
        );

        setState(() => _isLoading = false);

        await Future.delayed(const Duration(seconds: 2));

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Swiper(
              playlistId: playlistData['id'],
              tracks: recommendation['songs'],
            ),
          ),
        );
      }
    } catch (e) {
      print('Error getting recommendations: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
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
      body: Stack(
        children: [
          SafeArea(
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
                                  foregroundColor:
                                      isSelected ? Colors.black : Colors.white,
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
                                  style:
                                      const TextStyle(fontFamily: 'monospace'),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 24),

                          // Search Bar
                          const Text(
                            'PLEASE CHOOSE A SONG TO START GENERATING:',
                            style: TextStyle(
                              color: Colors.grey,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: searchController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'monospace',
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF3A3A3A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              hintText: 'Search...',
                              hintStyle: const TextStyle(
                                color: Colors.grey,
                                fontFamily: 'monospace',
                              ),
                            ),
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
                          ...recentSongs.map((song) => _buildSongTile(song)),

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
                          ...recommendedSongs
                              .map((song) => _buildSongTile(song)),
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
                              _getRecommendations();
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
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildSongTile(Map<String, dynamic> song) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3A),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (song['name'] ?? 'Unknown').toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                (song['artist'] ?? 'Unknown Artist').toString(),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFB2F5B2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB2F5B2)),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'GENERATING...',
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
}

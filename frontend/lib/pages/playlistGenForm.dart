import 'package:flutter/material.dart';

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

  final List<Map<String, String>> recentSongs = [
    {'name': 'Song Name', 'artist': 'Artist'},
    {'name': 'Song Name', 'artist': 'Artist'},
  ];

  final List<Map<String, String>> recommendedSongs = [
    {'name': 'Song Name', 'artist': 'Artist'},
    {'name': 'Song Name', 'artist': 'Artist'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
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
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: Colors.grey[800]!)),
                  ),
                  child: const Text(
                    'INFINITE PLAYLIST GENERATOR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

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
                              style: const TextStyle(fontFamily: 'monospace'),
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
                      ...recommendedSongs.map((song) => _buildSongTile(song)),
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

  Widget _buildSongTile(Map<String, String> song) {
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
                song['name']!,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                song['artist']!,
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
}

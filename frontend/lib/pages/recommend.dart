import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:spotfiy_rec/widgets/custom_button.dart';
import 'package:spotfiy_rec/widgets/loading.dart';
import 'package:url_launcher/url_launcher.dart';

class RecommendationPage extends StatefulWidget {
  const RecommendationPage({Key? key}) : super(key: key);

  @override
  _RecommendationPageState createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _options;
  Map<String, dynamic>? _recommendation;

  // Form values
  double _tempo = 5;
  String? _selectedMood;
  double _length = 5;
  bool _explicit = false;
  double _age = 2000;
  String? _selectedSetting;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/options'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _options = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load options');
      }
    } catch (e) {
      print('Error loading options: $e');
      // Show error message to user
    }
  }

  Future<void> _getRecommendation() async {
    if (_selectedMood == null || _selectedSetting == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/recommend'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'tempo': _tempo.round(),
          'mood': _options?['moods'].indexOf(_selectedMood),
          'length': _length.round(),
          'explicit': _explicit ? 1 : 0,
          'age': _age.round(),
          'setting': _options?['settings'].indexOf(_selectedSetting),
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _recommendation = json.decode(response.body)['recommendation'];
          _isLoading = false;
        });
        _showRecommendationDialog();
      } else {
        throw Exception('Failed to get recommendation');
      }
    } catch (e) {
      print('Error getting recommendation: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error getting recommendation')),
      );
    }
  }

  void _showRecommendationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Recommended ${_recommendation?['genre']} Songs'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Based on your preferences, here are some recommended songs:',
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _recommendation?['songs']?.length ?? 0,
                  itemBuilder: (context, index) {
                    final song = _recommendation?['songs'][index];
                    return ListTile(
                      leading: const Icon(Icons.music_note),
                      title: Text(song['title'] ?? ''),
                      subtitle: Text(song['artist'] ?? ''),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createMixedPlaylist();
            },
            child: const Text('Create Playlist'),
          ),
        ],
      ),
    );
  }

  Future<void> _createMixedPlaylist() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/create-playlist'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'genre': _recommendation?['genre'],
          'playlist_length': _length.round(),
          'split_ratio': 0.5, // 50-50 split between Spotify and song bank
        }),
      );

      if (response.statusCode == 200) {
        final playlistData = json.decode(response.body);
        _showPlaylistCreatedDialog(playlistData);
      } else {
        throw Exception('Failed to create playlist');
      }
    } catch (e) {
      print('Error creating playlist: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error creating playlist')),
      );
    }
  }

  void _showPlaylistCreatedDialog(Map<String, dynamic> playlistData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Playlist Created!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your mixed playlist has been created with:',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Text(
              '• ${playlistData['spotify_songs_count']} songs from Spotify\n'
              '• ${playlistData['songbank_songs_count']} songs from your collection',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Genre: ${_recommendation?['genre'] ?? 'Unknown'}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (playlistData['playlist_url'] != null) {
                await launchUrl(Uri.parse(playlistData['playlist_url']));
              }
            },
            child: const Text('Open in Spotify'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LottieLoadingSpinner(message: 'Loading...'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Get Recommendations'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tell us what you\'re looking for',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            // Tempo Slider
            Text('Tempo', style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _tempo,
              min: 1,
              max: 10,
              divisions: 9,
              label: _tempo.round().toString(),
              onChanged: (value) => setState(() => _tempo = value),
            ),

            const SizedBox(height: 16),

            // Mood Dropdown
            Text('Mood', style: Theme.of(context).textTheme.titleMedium),
            DropdownButtonFormField<String>(
              value: _selectedMood,
              items: (_options?['moods'] as List<dynamic>?)
                  ?.map((mood) => DropdownMenuItem(
                        value: mood.toString(),
                        child: Text(mood.toString()),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedMood = value),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Length Slider
            Text('Length', style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _length,
              min: 1,
              max: 10,
              divisions: 9,
              label: _length.round().toString(),
              onChanged: (value) => setState(() => _length = value),
            ),

            const SizedBox(height: 16),

            // Explicit Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Allow Explicit Content',
                    style: Theme.of(context).textTheme.titleMedium),
                Switch(
                  value: _explicit,
                  onChanged: (value) => setState(() => _explicit = value),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Age/Era Slider
            Text('Music Era', style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _age,
              min: 1800,
              max: 2024,
              divisions: 224,
              label: _age.round().toString(),
              onChanged: (value) => setState(() => _age = value),
            ),

            const SizedBox(height: 16),

            // Setting Dropdown
            Text('Setting', style: Theme.of(context).textTheme.titleMedium),
            DropdownButtonFormField<String>(
              value: _selectedSetting,
              items: (_options?['settings'] as List<dynamic>?)
                  ?.map((setting) => DropdownMenuItem(
                        value: setting.toString(),
                        child: Text(setting.toString()),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedSetting = value),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            CustomButton(
              text: 'Get Recommendation',
              onPressed: _getRecommendation,
              icon: Icons.music_note,
            ),
          ],
        ),
      ),
    );
  }
}

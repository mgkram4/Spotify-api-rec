import 'package:flutter/material.dart';
import 'package:spotfiy_rec/services/playlist_service.dart';
import 'package:spotfiy_rec/services/recommendation_service.dart';
import 'package:spotify/spotify.dart' as spotify;

class RecommendationPage extends StatefulWidget {
  const RecommendationPage({Key? key}) : super(key: key);

  @override
  _RecommendationPageState createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  final RecommendationService _recommendationService = RecommendationService();
  late PlaylistService _playlistService;
  bool _isLoading = false;
  bool _isInitializing = true;
  Map<String, dynamic>? _options;
  Map<String, dynamic>? _recommendation;
  List<spotify.Track>? _recommendedTracks;
  List<String> _moods = [];
  List<String> _settings = [];

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
    _initPlaylistService();
    _loadOptions();
  }

  Future<void> _initPlaylistService() async {
    // You'll need to get the token from your auth service
    final token = await _getSpotifyToken();
    _playlistService = PlaylistService(token);
  }

  Future<String> _getSpotifyToken() async {
    // Implement your method to get the token from storage or auth service
    // For example: return SpotifyAuthService().getAccessToken();
    // This is a placeholder
    return '';
  }

  Future<void> _loadOptions() async {
    try {
      final options = await _recommendationService.getOptions();
      setState(() {
        _options = options;
        _moods = (options['moods'] as List<dynamic>).cast<String>();
        _settings = (options['settings'] as List<dynamic>).cast<String>();
        _isInitializing = false;
      });
    } catch (e) {
      print('Error loading options: $e');
      // Use default values if API call fails
      setState(() {
        _moods = ['Happy', 'Sad', 'Energetic', 'Relaxed', 'Focused'];
        _settings = ['Home', 'Work', 'Gym', 'Party', 'Commute'];
        _isInitializing = false;
      });
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading options: $e')),
      );
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
      // Get genre recommendation based on form inputs
      final result = await _recommendationService.getRecommendation(
        tempo: _tempo.round(),
        mood: _moods.indexOf(_selectedMood!),
        length: _length.round(),
        explicit: _explicit,
        age: _age.round(),
        setting: _settings.indexOf(_selectedSetting!),
      );

      final genre = result['recommendation']['genre'];

      // For demonstration, we'll create sample tracks based on genre
      final sampleTracks = _createSampleTracks(genre, 10);

      setState(() => _isLoading = false);

      _showRecommendationDialog(genre, sampleTracks);
    } catch (e) {
      print('Error getting recommendation: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting recommendation: $e')),
      );
    }
  }

  List<Map<String, String>> _createSampleTracks(String genre, int count) {
    // Create some realistic sample tracks based on the genre
    final genreArtists = {
      'Rock': ['Foo Fighters', 'Led Zeppelin', 'AC/DC', 'Queen', 'Nirvana'],
      'Pop': [
        'Taylor Swift',
        'Ed Sheeran',
        'Ariana Grande',
        'Justin Bieber',
        'Dua Lipa'
      ],
      'Hip Hop': ['Kendrick Lamar', 'Drake', 'J. Cole', 'Kanye West', 'Eminem'],
      'EDM': [
        'Calvin Harris',
        'Avicii',
        'Martin Garrix',
        'Skrillex',
        'Marshmello'
      ],
      'Jazz': [
        'Miles Davis',
        'John Coltrane',
        'Ella Fitzgerald',
        'Louis Armstrong',
        'Charlie Parker'
      ],
      'Classical': ['Mozart', 'Beethoven', 'Bach', 'Chopin', 'Tchaikovsky'],
      'R&B': ['The Weeknd', 'SZA', 'Frank Ocean', 'H.E.R.', 'Daniel Caesar'],
    };

    final genreSongs = {
      'Rock': [
        'Stairway to Heaven',
        'Bohemian Rhapsody',
        'Sweet Child O\' Mine',
        'Back in Black',
        'Smells Like Teen Spirit'
      ],
      'Pop': [
        'Shake It Off',
        'Shape of You',
        'thank u, next',
        'Sorry',
        'Don\'t Start Now'
      ],
      'Hip Hop': [
        'HUMBLE.',
        'God\'s Plan',
        'Middle Child',
        'Stronger',
        'Lose Yourself'
      ],
      'EDM': ['Summer', 'Wake Me Up', 'Animals', 'Bangarang', 'Happier'],
      'Jazz': [
        'So What',
        'Giant Steps',
        'Summertime',
        'What a Wonderful World',
        'Take Five'
      ],
      'Classical': [
        'Symphony No. 5',
        'Für Elise',
        'Air on the G String',
        'Nocturne Op. 9 No. 2',
        'Swan Lake'
      ],
      'R&B': [
        'Blinding Lights',
        'Good Days',
        'Thinkin Bout You',
        'Focus',
        'Best Part'
      ],
    };

    // Default to Pop if the genre is not in our map
    final artists = genreArtists[genre] ?? genreArtists['Pop']!;
    final songs = genreSongs[genre] ?? genreSongs['Pop']!;

    return List.generate(count, (index) {
      final artistIndex = index % artists.length;
      final songIndex = index % songs.length;
      return {
        'title':
            '${songs[songIndex]} ${index > songs.length ? '${(index / songs.length).floor() + 1}' : ''}',
        'artist': artists[artistIndex],
      };
    });
  }

  void _showRecommendationDialog(
      String genre, List<Map<String, String>> tracks) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Recommended $genre Songs'),
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
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return ListTile(
                      leading: const Icon(Icons.music_note),
                      title: Text(track['title'] ?? ''),
                      subtitle: Text(track['artist'] ?? ''),
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
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.green,
              ),
              SizedBox(height: 16),
              Text("Loading..."),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Get Recommendations'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
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
                  items: _moods
                      .map((mood) => DropdownMenuItem(
                            value: mood,
                            child: Text(mood),
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
                Text('Music Era',
                    style: Theme.of(context).textTheme.titleMedium),
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
                  items: _settings
                      .map((setting) => DropdownMenuItem(
                            value: setting,
                            child: Text(setting),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedSetting = value),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 32),

                // Submit Button
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.music_note),
                    label: const Text('Get Recommendation'),
                    onPressed: _getRecommendation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.green,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Loading...",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

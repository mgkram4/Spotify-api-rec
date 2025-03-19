import 'package:flutter/material.dart';
import 'package:spotfiy_rec/services/auth_service.dart';
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
    // Use the AuthService to get the token instead of returning an empty string
    final authService = AuthService();
    final token = authService.spotifyToken;

    if (token == null) {
      // If token is null, try to refresh it
      final refreshedToken = await authService.refreshToken();
      if (refreshedToken != null) {
        return refreshedToken;
      }

      // If refresh failed and we're in this situation, there might be an issue
      // with the auth state - we could redirect to login or handle differently
      print('Warning: No valid Spotify token available');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Spotify authentication needed. Please log in again.')),
      );
      // Return a token anyway to avoid null errors, though requests will fail
      return '';
    }

    return token;
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

      // Get actual tracks from playlist service using the genre
      final tracks = await _playlistService.getGenreRecommendations(genre);

      // Take only the first 5 tracks
      final limitedTracks = tracks.length > 5 ? tracks.sublist(0, 5) : tracks;

      setState(() {
        _recommendedTracks = limitedTracks;
        _isLoading = false;
      });

      _showRecommendationDialog(genre, limitedTracks);
    } catch (e) {
      print('Error getting recommendation: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting recommendation: $e')),
      );
    }
  }

  void _showRecommendationDialog(String genre, List<spotify.Track> tracks) {
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
                      leading: track.album?.images != null &&
                              track.album!.images!.isNotEmpty
                          ? Image.network(
                              track.album!.images!.first.url!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.music_note);
                              },
                            )
                          : const Icon(Icons.music_note),
                      title: Text(track.name ?? 'Unknown Track'),
                      subtitle: Text(
                          track.artists?.map((a) => a.name).join(', ') ??
                              'Unknown Artist'),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () {
                          // For future implementation - play the track
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Playing ${track.name}')),
                          );
                        },
                      ),
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
          TextButton(
            onPressed: () {
              // For future implementation - save playlist
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Playlist saved (not implemented)')),
              );
              Navigator.pop(context);
            },
            child: const Text('Save Playlist'),
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

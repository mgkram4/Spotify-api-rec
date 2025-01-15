import 'package:flutter/material.dart';
import 'package:spotfiy_rec/widgets/loading.dart';

class CreatePlaylist extends StatefulWidget {
  const CreatePlaylist({super.key});

  @override
  State<CreatePlaylist> createState() => _CreatePlaylistState();
}

class _CreatePlaylistState extends State<CreatePlaylist> {
  bool _isLoading = true;
  List<String> _playlistTypes = [
    'Based on Recent Plays',
    'Based on Top Artists',
    'Based on Saved Tracks',
    'Based on Current Mood',
    'Discovery Mix',
    'Decade Mix',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // TODO: Load user's Spotify data
    setState(() => _isLoading = false);
  }

  void _createPlaylist(String type) {
    setState(() => _isLoading = true);
    // TODO: Implement playlist creation based on selected type
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingSpinner(message: 'Loading your music data...'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Playlist'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _playlistTypes.length + 1, // +1 for the header
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                'Create a new playlist',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            );
          }

          final typeIndex = index - 1;
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                _playlistTypes[typeIndex],
                style: Theme.of(context).textTheme.titleMedium,
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _createPlaylist(_playlistTypes[typeIndex]),
            ),
          );
        },
      ),
    );
  }
}

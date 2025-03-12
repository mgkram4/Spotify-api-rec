import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:spotfiy_rec/models/song.dart';
import 'package:spotfiy_rec/services/playlist_service.dart';
import 'package:spotify/spotify.dart' hide Image;

class PlaylistPage extends StatefulWidget {
  final String playlistId;
  final String playlistName;
  final String playlistImage;
  final String creatorName;
  final int songCount;
  final PlaylistService playlistService;
  final String userId;

  const PlaylistPage({
    Key? key,
    required this.playlistId,
    required this.playlistName,
    required this.playlistImage,
    required this.creatorName,
    required this.songCount,
    required this.playlistService,
    required this.userId,
  }) : super(key: key);

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  final List<String> likedTrackIds = [];
  final List<String> dislikedTrackIds = [];
  bool isLoading = false;
  List<Track> tracks = [];

  @override
  void initState() {
    super.initState();
    _loadPlaylistTracks();
  }

  Future<void> _loadPlaylistTracks() async {
    setState(() => isLoading = true);
    try {
      final playlistTracks =
          await widget.playlistService.getPlaylistTracks(widget.playlistId);

      // Shuffle the tracks to get a random selection
      playlistTracks.shuffle();

      setState(() {
        tracks = playlistTracks;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load tracks: $e')),
      );
    }
  }

  Future<void> _saveSwipedTrack(String trackId, bool liked) async {
    try {
      await widget.playlistService.saveSwipedTrack(
        widget.userId,
        trackId,
        liked,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save track preference: $e')),
      );
    }
  }

  Future<void> _createPlaylistFromLikedTracks() async {
    setState(() => isLoading = true);
    try {
      final playlist = await widget.playlistService
          .createPlaylistFromSwipedTracks(likedTrackIds);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playlist created successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create playlist: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showRecommendedSongs(String genre) {
    // Get a subset of tracks that match the genre (in this case, Rap)
    final genreTracks = tracks.where((track) {
      // Check if the track's genre matches the requested genre
      // This depends on how genre information is stored in your Track objects
      // You might need to adjust this logic based on your data structure
      return track.artists != null &&
          track.artists!.isNotEmpty &&
          track.artists!.any((artist) =>
              artist.genres?.contains(genre.toLowerCase()) ?? false);
    }).toList();

    // If no tracks match the genre, use all tracks
    final songsToShow = genreTracks.isEmpty ? tracks : genreTracks;

    // Shuffle and limit to 7 songs (or fewer if not enough tracks)
    songsToShow.shuffle();
    final limitedSongs =
        songsToShow.length > 7 ? songsToShow.sublist(0, 7) : songsToShow;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recommended $genre Songs',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Based on your preferences, here are some recommended songs:',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: limitedSongs.length,
              itemBuilder: (context, index) {
                final track = limitedSongs[index];
                return ListTile(
                  leading: const Icon(Icons.music_note, color: Colors.white),
                  title: Text(
                    track.name ?? 'Unknown Song',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    track.artists?.first.name ?? 'Unknown Artist',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  onTap: () {
                    // Add the track to liked tracks
                    if (track.id != null) {
                      likedTrackIds.add(track.id!);
                      _saveSwipedTrack(track.id!, true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Added ${track.name} to your liked tracks')),
                      );
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child:
                  const Text('Close', style: TextStyle(color: Colors.purple)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.playlistImage,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                widget.playlistName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Created by ${widget.creatorName}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.songCount} songs',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.shuffle,
                        label: 'Shuffle',
                        onTap: () {
                          // TODO: Implement shuffle
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.play_circle_filled,
                        label: 'Play',
                        onTap: () {
                          // TODO: Implement play
                        },
                        isPrimary: true,
                      ),
                      _buildActionButton(
                        icon: Icons.favorite_border,
                        label: 'Like',
                        onTap: () {
                          // TODO: Implement like
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.recommend,
                        label: 'Recommend',
                        onTap: () {
                          // Show recommended rap songs
                          _showRecommendedSongs('Rap');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              height: 400,
              padding: const EdgeInsets.all(16.0),
              child: tracks.isEmpty
                  ? const Center(child: Text('No tracks available'))
                  : Swiper(
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        return _buildSwipeCard(
                          title: track.name ?? 'Unknown',
                          artist: track.artists?.first.name ?? 'Unknown Artist',
                          imageUrl: track.album?.images?.first.url ??
                              'https://via.placeholder.com/300',
                        );
                      },
                      itemCount: tracks.length,
                      onIndexChanged: (index) {
                        final trackId = tracks[index].id!;
                        likedTrackIds.add(trackId);
                        _saveSwipedTrack(trackId, true);
                      },
                    ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 4.0,
                  ),
                  child: SongCard(
                    title: 'Song ${index + 1}',
                    artist: 'Artist ${index + 1}',
                    imageUrl: 'https://via.placeholder.com/80',
                    onTap: () {
                      // TODO: Implement song playback
                    },
                  ),
                );
              },
              childCount: widget.songCount,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            likedTrackIds.isEmpty ? null : _createPlaylistFromLikedTracks,
        label: const Text('Create Playlist'),
        icon: const Icon(Icons.playlist_add),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPrimary ? Colors.green : Colors.transparent,
            border: isPrimary
                ? null
                : Border.all(
                    color: Colors.white,
                    width: 1,
                  ),
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: Colors.white,
            ),
            onPressed: onTap,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeCard({
    required String title,
    required String artist,
    required String imageUrl,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  artist,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

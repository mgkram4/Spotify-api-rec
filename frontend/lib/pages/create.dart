import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:spotfiy_rec/models/song.dart';
import 'package:spotfiy_rec/services/playlist_service.dart';
import 'package:spotify/spotify.dart' hide Image;

class SwipePlaylistPage extends StatefulWidget {
  final String playlistId;
  final String playlistName;
  final String playlistImage;
  final String creatorName;
  final int songCount;
  final PlaylistService playlistService;
  final String userId;

  const SwipePlaylistPage({
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
  State<SwipePlaylistPage> createState() => _SwipePlaylistPageState();
}

class _SwipePlaylistPageState extends State<SwipePlaylistPage> {
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

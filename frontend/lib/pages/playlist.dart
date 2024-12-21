import 'package:flutter/material.dart';
import 'package:spotfiy_rec/models/song.dart';

class PlaylistPage extends StatelessWidget {
  final String playlistId;
  final String playlistName;
  final String playlistImage;
  final String creatorName;
  final int songCount;

  const PlaylistPage({
    Key? key,
    required this.playlistId,
    required this.playlistName,
    required this.playlistImage,
    required this.creatorName,
    required this.songCount, required imageUrl, required description, required followersCount, required totalDuration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                    playlistImage,
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
                playlistName,
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
                    'Created by $creatorName',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$songCount songs',
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
              childCount: songCount,
            ),
          ),
        ],
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
}

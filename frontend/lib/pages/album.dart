import 'package:flutter/material.dart';
import 'package:spotfiy_rec/models/song.dart';
import 'package:spotfiy_rec/widgets/custom_button.dart';

class AlbumPage extends StatelessWidget {
  final String albumId;
  final String albumName;
  final String artistName;
  final String imageUrl;
  final int releaseYear;
  final int trackCount;

  const AlbumPage({
    Key? key,
    required this.albumId,
    required this.albumName,
    required this.artistName,
    required this.imageUrl,
    required this.releaseYear,
    required this.trackCount,
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
                    imageUrl,
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
              title: Text(albumName),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artistName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$releaseYear • $trackCount songs',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Play',
                          onPressed: () {
                            // TODO: Implement play functionality
                          },
                          icon: Icons.play_arrow,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.favorite_border),
                        onPressed: () {
                          // TODO: Implement like functionality
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          // TODO: Show more options
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
                    title: 'Track ${index + 1}',
                    artist: artistName,
                    imageUrl: imageUrl,
                    onTap: () {
                      // TODO: Implement song playback
                    },
                  ),
                );
              },
              childCount: trackCount,
            ),
          ),
        ],
      ),
    );
  }
}

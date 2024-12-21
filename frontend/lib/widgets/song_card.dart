import 'package:flutter/material.dart';

class SongCard extends StatelessWidget {
  final String title;
  final String artist;
  final String imageUrl;
  final VoidCallback onTap;
  final bool isPlaying;
  final bool isLiked;
  final VoidCallback? onLikeTap;
  final bool showDuration;
  final Duration? duration;
  final VoidCallback? onMoreTap;

  const SongCard({
    Key? key,
    required this.title,
    required this.artist,
    required this.imageUrl,
    required this.onTap,
    this.isPlaying = false,
    this.isLiked = false,
    this.onLikeTap,
    this.showDuration = false,
    this.duration,
    this.onMoreTap,
  }) : super(key: key);

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Row(
            children: [
              // Song Image
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: isPlaying
                    ? Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.equalizer,
                          color: Colors.green,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Song Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isPlaying ? Colors.green : Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      artist,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Duration and Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showDuration && duration != null) ...[
                    Text(
                      _formatDuration(duration!),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (onLikeTap != null)
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.green : Colors.grey[400],
                        size: 20,
                      ),
                      onPressed: onLikeTap,
                      splashRadius: 24,
                    ),
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                    onPressed: onMoreTap ??
                        () {
                          _showOptionsMenu(context);
                        },
                    splashRadius: 24,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add to playlist'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement add to playlist
              },
            ),
            ListTile(
              leading: const Icon(Icons.album),
              title: const Text('View album'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to album
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('View artist'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to artist
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement share
              },
            ),
          ],
        ),
      ),
    );
  }
}

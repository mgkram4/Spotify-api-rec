import 'package:flutter/material.dart';

class SongCard extends StatelessWidget {
  final String title;
  final String artist;
  final String imageUrl;
  final VoidCallback onTap;
  final bool isPlaying;

  const SongCard({
    Key? key,
    required this.title,
    required this.artist,
    required this.imageUrl,
    required this.onTap,
    this.isPlaying = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey[900]!,
                Colors.grey[850]!,
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
              const SizedBox(width: 12),
              if (isPlaying)
                const Icon(
                  Icons.equalizer,
                  color: Colors.green,
                  size: 24,
                )
              else
                const Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 24,
                ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class SongPage extends StatefulWidget {
  final String songId;
  final String title;
  final String artist;
  final String album;
  final String imageUrl;
  final Duration duration;

  const SongPage({
    Key? key,
    required this.songId,
    required this.title,
    required this.artist,
    required this.album,
    required this.imageUrl,
    required this.duration,
  }) : super(key: key);

  @override
  _SongPageState createState() => _SongPageState();
}

class _SongPageState extends State<SongPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPlaying = false;
  bool _isLiked = false;
  bool _isShuffled = false;
  bool _isRepeating = false;
  double _currentSliderValue = 0.0;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[900]!,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'NOW PLAYING',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showOptionsSheet(context),
                    ),
                  ],
                ),
              ),

              // Album Art
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        image: DecorationImage(
                          image: NetworkImage(widget.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Song Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    Text(
                      widget.title,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.artist,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[400],
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    Slider(
                      value: _currentSliderValue,
                      onChanged: (value) {
                        setState(() {
                          _currentSliderValue = value;
                          _position = Duration(
                              milliseconds:
                                  (value * widget.duration.inMilliseconds)
                                      .round());
                        });
                      },
                      activeColor: Theme.of(context).primaryColor,
                      inactiveColor: Colors.grey[700],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(_position)),
                          Text(_formatDuration(widget.duration)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Controls
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isShuffled ? Icons.shuffle : Icons.shuffle,
                        color: _isShuffled
                            ? Theme.of(context).primaryColor
                            : Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _isShuffled = !_isShuffled;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous, size: 35),
                      onPressed: () {
                        // TODO: Previous track
                      },
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.black,
                          size: 35,
                        ),
                        onPressed: _togglePlay,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 35),
                      onPressed: () {
                        // TODO: Next track
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        _isRepeating ? Icons.repeat_one : Icons.repeat,
                        color: _isRepeating
                            ? Theme.of(context).primaryColor
                            : Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _isRepeating = !_isRepeating;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Bottom Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.devices),
                      onPressed: () {
                        // TODO: Show devices
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked
                            ? Theme.of(context).primaryColor
                            : Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _isLiked = !_isLiked;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionsSheet(BuildContext context) {
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
                // TODO: Implement add to playlist
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('View artist'),
              onTap: () {
                // TODO: Navigate to artist page
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.album),
              title: const Text('View album'),
              onTap: () {
                // TODO: Navigate to album page
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                // TODO: Implement share
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

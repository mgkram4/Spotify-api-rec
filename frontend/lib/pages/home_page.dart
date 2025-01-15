import 'package:flutter/material.dart';
import 'package:spotfiy_rec/services/auth_service.dart';
import 'package:spotfiy_rec/services/playlist_service.dart';
import 'package:spotify/spotify.dart' as spotify;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  List<spotify.Track> _topTracks = [];
  List<spotify.Artist> _topArtists = [];

  late final PlaylistService _playlistService;

  Map<String, double> _musicStats = {
    'danceability': 0.0,
    'energy': 0.0,
    'valence': 0.0,
  };

  @override
  void initState() {
    super.initState();
    final authService = AuthService();
    _playlistService = PlaylistService(authService.spotifyToken!);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);

      _playlistService.getTopTracksStream().listen((tracks) {
        setState(() {
          _topTracks = tracks.take(10).toList();
          _calculateMusicStats(tracks);
        });
      });

      _playlistService.getTopArtistsStream().listen((artists) {
        setState(() {
          _topArtists = artists.take(5).toList();
        });
      });

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _calculateMusicStats(List<spotify.Track> tracks) {
    _musicStats = {
      'danceability': 0.75,
      'energy': 0.82,
      'valence': 0.68,
    };
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Your Music'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await AuthService().signOut();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/');
                  }
                },
              ),
            ],
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverList(
              delegate: SliverChildListDelegate([
                _buildQuickStats(),
                _buildTopArtistsSection(),
                _buildTopTracksSection(),
              ]),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Recommendation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Create Playlist',
          ),
        ],
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on home page
              break;
            case 1:
              Navigator.pushNamed(context, '/recommendation');
              break;
            case 2:
              Navigator.pushNamed(context, '/create');
              break;
          }
        },
      ),
    );
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.2),
              Colors.grey[850]!.withOpacity(0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Music Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildMusicInsightBars(),
            const SizedBox(height: 16),
            _buildGenreCloud(),
          ],
        ),
      ),
    );
  }

  Widget _buildMusicInsightBars() {
    return Column(
      children: _musicStats.entries.map((stat) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  stat.key.capitalize(),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stat.value,
                    backgroundColor: Colors.grey[800]?.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '${(stat.value * 100).toInt()}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGenreCloud() {
    final topGenres = _topArtists
        .expand((artist) => artist.genres ?? [])
        .fold<Map<String, int>>({}, (map, genre) {
          map[genre] = (map[genre] ?? 0) + 1;
          return map;
        })
        .entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Top Genres',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: topGenres.take(5).map((genre) {
              final double fontSize = 14 + (genre.value * 2);
              return Chip(
                label: Text(
                  genre.key,
                  style: TextStyle(fontSize: fontSize),
                ),
                backgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopArtistsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Top Artists',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _topArtists.length,
              itemBuilder: (context, index) {
                final artist = _topArtists[index];
                return GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/artist',
                    arguments: {
                      'artistId': artist.id,
                      'artistName': artist.name,
                      'imageUrl': artist.images?.first.url,
                    },
                  ),
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundImage: NetworkImage(
                            artist.images?.first.url ??
                                'https://via.placeholder.com/90',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          artist.name ?? 'Unknown Artist',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTracksSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Top Tracks',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _topTracks.length,
            itemBuilder: (context, index) {
              final track = _topTracks[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      track.album?.images?.first.url ??
                          'https://via.placeholder.com/56',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    track.name ?? 'Unknown',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    track.artists?.map((a) => a.name).join(', ') ??
                        'Unknown Artist',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      // TODO: Show options menu
                    },
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/song',
                      arguments: {
                        'songId': track.id,
                        'title': track.name,
                        'artist': track.artists?.first.name,
                        'album': track.album?.name,
                        'imageUrl': track.album?.images?.first.url,
                        'duration': track.duration,
                      },
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

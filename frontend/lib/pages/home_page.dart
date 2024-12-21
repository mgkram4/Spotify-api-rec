import 'package:flutter/material.dart';
// import 'package:shared_preferences.dart';
import 'package:spotfiy_rec/models/song.dart';
import 'package:spotify/spotify.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  List<Track> _recommendedTracks = [];
  List<PlaylistSimple> _playlists = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);
      // TODO: Implement Spotify API calls to fetch data
      // This is where you'll integrate with your SpotifyService
      await Future.delayed(const Duration(seconds: 2)); // Simulating API call
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
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
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'For You'),
                  Tab(text: 'Playlists'),
                  Tab(text: 'Discover'),
                ],
              ),
            ),
          ];
        },
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildForYouTab(),
                  _buildPlaylistsTab(),
                  _buildDiscoverTab(),
                ],
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: 0,
        onTap: (index) {
          // TODO: Implement navigation
        },
      ),
    );
  }

  Widget _buildForYouTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Recently Played',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SongCard(
                title: 'Song ${index + 1}',
                artist: 'Artist ${index + 1}',
                imageUrl: 'https://via.placeholder.com/80',
                onTap: () {
                  // TODO: Implement song playback
                },
                isPlaying: index == 0,
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'Your Top Mixes',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (context, index) {
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[850],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ClipRRect(
                    //   borderRadius: const BorderRadius.vertical(
                    //     top: Radius.circular(12),
                    //   ),
                    //   child: Image.network(
                    //     'https://via.placeholder.com/160',
                    //     height: 160,
                    //     width: 160,
                    //     fit: BoxFit.cover,
                    //   ),
                    // ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Mix ${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistsTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[850],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  // child: Image.network(
                  //   'https://via.placeholder.com/200',
                  //   fit: BoxFit.cover,
                  //   width: double.infinity,
                  // ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Playlist ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDiscoverTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'New Releases',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SongCard(
                title: 'New Song ${index + 1}',
                artist: 'Artist ${index + 1}',
                imageUrl: 'https://via.placeholder.com/80',
                onTap: () {
                  // TODO: Implement song playback
                },
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:spotfiy_rec/models/song.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String _searchQuery = '';

  final List<String> _categories = [
    'Hip-Hop',
    'Pop',
    'Rock',
    'Jazz',
    'Electronic',
    'Classical',
    'R&B',
    'Country',
    'Latin',
    'Metal'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      _isLoading = true;
      _searchQuery = query;
    });

    // TODO: Implement actual search logic with Spotify API
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            snap: false,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search for songs, artists, or playlists',
                    filled: true,
                    fillColor: Colors.grey[900],
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: _performSearch,
                ),
              ),
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Browse Categories',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.5,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildCategoryCard(_categories[index]);
                  },
                  childCount: _categories.length,
                ),
              ),
            ),
          ] else if (_isLoading) ...[
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ] else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Results for "$_searchQuery"',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                      title: 'Search Result ${index + 1}',
                      artist: 'Artist ${index + 1}',
                      imageUrl: 'https://via.placeholder.com/80',
                      onTap: () {
                        // TODO: Implement song selection
                      },
                    ),
                  );
                },
                childCount: 10, // Replace with actual search results count
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String category) {
    return InkWell(
      onTap: () {
        _performSearch(category);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [
              Colors.primaries[
                  _categories.indexOf(category) % Colors.primaries.length],
              Colors.primaries[(_categories.indexOf(category) + 5) %
                  Colors.primaries.length],
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            category,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

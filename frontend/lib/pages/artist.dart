import 'package:flutter/material.dart';
import 'package:spotfiy_rec/services/auth_service.dart';
import 'package:spotfiy_rec/services/playlist_service.dart';
import 'package:spotify/spotify.dart' as spotify;

class ArtistPage extends StatefulWidget {
  final String artistId;
  final String artistName;
  final String? imageUrl;

  const ArtistPage({
    Key? key,
    required this.artistId,
    required this.artistName,
    this.imageUrl,
  }) : super(key: key);

  @override
  _ArtistPageState createState() => _ArtistPageState();
}

class _ArtistPageState extends State<ArtistPage> {
  bool _isLoading = true;
  List<spotify.Track> _topTracks = [];
  String _artistDescription = '';
  Map<String, dynamic> _artistStats = {};

  late final PlaylistService _playlistService;

  @override
  void initState() {
    super.initState();
    final authService = AuthService();
    _playlistService = PlaylistService(authService.spotifyToken!);
    _loadArtistData();
  }

  Future<void> _loadArtistData() async {
    try {
      setState(() => _isLoading = true);

      final topTracks =
          await _playlistService.getArtistTopTracks(widget.artistId);
      final artistDetails =
          await _playlistService.getArtistDetails(widget.artistId);

      setState(() {
        _topTracks = topTracks;
        _artistDescription =
            artistDetails['description'] ?? 'No description available';
        _artistStats = artistDetails['stats'] ?? {};
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading artist data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      widget.artistName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                    background: ShaderMask(
                      shaderCallback: (rect) {
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ).createShader(rect);
                      },
                      blendMode: BlendMode.darken,
                      child: widget.imageUrl != null
                          ? Image.network(
                              widget.imageUrl!,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Theme.of(context).scaffoldBackgroundColor,
                            ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _artistDescription,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildArtistStats(),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Top Tracks',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    ..._topTracks.take(10).map((track) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 4.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[850],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  track.album?.images?.first.url ?? '',
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              title: Text(
                                track.name ?? 'Unknown Track',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              subtitle: Text(
                                track.artists?.map((a) => a.name).join(', ') ??
                                    'Unknown Artist',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              onTap: () {
                                // Handle track tap
                              },
                            ),
                          ),
                        )),
                  ]),
                ),
              ],
            ),
    );
  }

  Widget _buildArtistStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Artist Stats',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ..._artistStats.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    _formatNumber(entry.value),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }),
          if (_artistStats.isEmpty)
            Text(
              'No stats available',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }

  String _formatNumber(dynamic number) {
    if (number == null) return '0';
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

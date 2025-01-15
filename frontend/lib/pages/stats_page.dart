import 'package:flutter/material.dart';
import 'package:spotfiy_rec/services/auth_service.dart';
import 'package:spotfiy_rec/services/playlist_service.dart';
import 'package:spotify/spotify.dart' as spotify;

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final playlistService = PlaylistService(AuthService().spotifyToken!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Stats'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Top Artists',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 200,
                child: StreamBuilder<List<spotify.Artist>>(
                  stream: playlistService.getTopArtistsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final artist = snapshot.data![index];
                        return Card(
                          child: SizedBox(
                            width: 160,
                            child: Column(
                              children: [
                                if (artist.images?.isNotEmpty ?? false)
                                  Image.network(
                                    artist.images!.first.url!,
                                    height: 120,
                                    width: 120,
                                    fit: BoxFit.cover,
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    artist.name ?? 'Unknown Artist',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Top Tracks',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              StreamBuilder<List<spotify.Track>>(
                stream: playlistService.getTopTracksStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final track = snapshot.data![index];
                      return ListTile(
                        leading: track.album?.images?.isNotEmpty ?? false
                            ? Image.network(
                                track.album!.images!.first.url!,
                                height: 50,
                                width: 50,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.music_note),
                        title: Text(track.name ?? 'Unknown Track'),
                        subtitle: Text(
                          track.artists?.map((a) => a.name).join(', ') ??
                              'Unknown Artist',
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

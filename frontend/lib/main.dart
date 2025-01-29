import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:spotfiy_rec/constants/theme.dart';
import 'package:spotfiy_rec/pages/album.dart';
import 'package:spotfiy_rec/pages/artist.dart';
import 'package:spotfiy_rec/pages/auth_wrapper.dart';
import 'package:spotfiy_rec/pages/create.dart';
import 'package:spotfiy_rec/pages/create_playlist.dart';
import 'package:spotfiy_rec/pages/home_page.dart';
import 'package:spotfiy_rec/pages/login_page.dart';
import 'package:spotfiy_rec/pages/playlistGenForm.dart';
import 'package:spotfiy_rec/pages/profile.dart';
import 'package:spotfiy_rec/pages/recommend.dart';
import 'package:spotfiy_rec/pages/register.dart';
import 'package:spotfiy_rec/pages/song.dart';
import 'package:spotfiy_rec/pages/spotify_connect_page.dart';
import 'package:spotfiy_rec/pages/stats_page.dart';
import 'package:spotfiy_rec/services/playlist_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spotify Recommendations',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/playlistGenForm': (context) => const PlaylistGenerator(),
        '/register': (context) => const SignUpPage(),
        '/spotify-connect': (context) => SpotifyConnectPage(),
        '/home': (context) => const HomePage(),
        '/create': (context) => SwipePlaylistPage(
              playlistId: '',
              playlistName: 'New Playlist',
              playlistImage: 'https://via.placeholder.com/300',
              creatorName: '',
              songCount: 0,
              playlistService: PlaylistService(''),
              userId: '',
            ),
        '/profile': (context) => const ProfilePage(),
        '/recommendation': (context) => const RecommendationPage(),
        '/album': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return AlbumPage(
            albumId: args['albumId'],
            albumName: args['albumName'],
            artistName: args['artistName'],
            imageUrl: args['imageUrl'],
            releaseYear: args['releaseYear'],
            trackCount: args['trackCount'],
          );
        },
        '/artist': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return ArtistPage(
            artistId: args['artistId'],
            artistName: args['artistName'],
            imageUrl: args['imageUrl'],
            monthlyListeners: args['monthlyListeners'],
          );
        },
        '/playlist': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return PlaylistPage(
            playlistId: args['playlistId'],
            playlistName: args['playlistName'],
            creatorName: args['creatorName'],
            songCount: args['songCount'],
            playlistImage: args['imageUrl'],
            playlistService: PlaylistService(args['userId']),
            userId: args['userId'],
          );
        },
        '/song': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return SongPage(
            songId: args['songId'],
            title: args['title'],
            artist: args['artist'],
            album: args['album'],
            imageUrl: args['imageUrl'],
            duration: args['duration'],
          );
        },
        '/stats': (context) => const StatsPage(),
      },
      onGenerateRoute: (settings) {
        // Handle dynamic routes or unknown routes here
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: HomePage(),
          ),
        );
      },
    );
  }
}

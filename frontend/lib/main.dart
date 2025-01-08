import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:spotfiy_rec/constants/theme.dart';
import 'package:spotfiy_rec/pages/album.dart';
import 'package:spotfiy_rec/pages/artist.dart';
import 'package:spotfiy_rec/pages/create_playlist.dart';
import 'package:spotfiy_rec/pages/home_page.dart';
import 'package:spotfiy_rec/pages/login_page.dart';
import 'package:spotfiy_rec/pages/playlist.dart';
import 'package:spotfiy_rec/pages/profile.dart';
import 'package:spotfiy_rec/pages/recommend.dart';
import 'package:spotfiy_rec/pages/register.dart';
import 'package:spotfiy_rec/pages/song.dart';
import 'package:spotfiy_rec/services/auth_service.dart';

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
        '/register': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
        '/search': (context) => const CreatePlaylist(),
        '/profile': (context) => const ProfilePage(),
        '/recommend': (context) => const RecommendationPage(),
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
            description: args['description'],
            creatorName: args['creatorName'],
            imageUrl: args['imageUrl'],
            followersCount: args['followersCount'],
            songCount: args['songCount'],
            totalDuration: args['totalDuration'],
            playlistImage: '',
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

// Example of how to navigate to these routes:
/*
// Navigate to album page

Navigator.pushNamed(
  context,
  '/album',
  arguments: {
    'albumId': 'album_123',
    'albumName': 'Album Name',
    'artistName': 'Artist Name',
    'imageUrl': 'https://example.com/image.jpg',
    'releaseYear': 2024,
    'trackCount': 12,
  },
);

// Navigate to artist page
Navigator.pushNamed(
  context,
  '/artist',
  arguments: {
    'artistId': 'artist_123',
    'artistName': 'Artist Name',
    'imageUrl': 'https://example.com/image.jpg',
    'monthlyListeners': 1000000,
  },
);

// Navigate to playlist page
Navigator.pushNamed(
  context,
  '/playlist',
  arguments: {
    'playlistId': 'playlist_123',
    'playlistName': 'My Playlist',
    'description': 'Awesome playlist',
    'creatorName': 'John Doe',
    'imageUrl': 'https://example.com/image.jpg',
    'followersCount': 1000,
    'songCount': 25,
    'totalDuration': const Duration(hours: 1, minutes: 30),
  },
);

// Navigate to song page
Navigator.pushNamed(
  context,
  '/song',
  arguments: {
    'songId': 'song_123',
    'title': 'Song Title',
    'artist': 'Artist Name',
    'album': 'Album Name',
    'imageUrl': 'https://example.com/image.jpg',
    'duration': const Duration(minutes: 3, seconds: 30),
  },
);
*/

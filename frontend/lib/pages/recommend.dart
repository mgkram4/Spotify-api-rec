import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:spotfiy_rec/widgets/custom_button.dart';
import 'package:spotfiy_rec/widgets/loading.dart';

class RecommendationPage extends StatefulWidget {
  const RecommendationPage({Key? key}) : super(key: key);

  @override
  _RecommendationPageState createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _options;
  Map<String, dynamic>? _recommendation;

  // Form values
  double _tempo = 5;
  String? _selectedMood;
  double _length = 5;
  bool _explicit = false;
  double _age = 2000;
  String? _selectedSetting;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/options'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _options = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load options');
      }
    } catch (e) {
      print('Error loading options: $e');
      // Show error message to user
    }
  }

  Future<void> _getRecommendation() async {
    if (_selectedMood == null || _selectedSetting == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/recommend'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'tempo': _tempo.round(),
          'mood': _options?['moods'].indexOf(_selectedMood),
          'length': _length.round(),
          'explicit': _explicit ? 1 : 0,
          'age': _age.round(),
          'setting': _options?['settings'].indexOf(_selectedSetting),
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _recommendation = json.decode(response.body)['recommendation'];
          _isLoading = false;
        });

        // Show results dialog
        _showRecommendationDialog();
      } else {
        throw Exception('Failed to get recommendation');
      }
    } catch (e) {
      print('Error getting recommendation: $e');
      setState(() => _isLoading = false);
      // Show error message to user
    }
  }

  void _showRecommendationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your Recommendation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Based on your preferences, we recommend:',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Text(
              _recommendation?['genre'] ?? 'Unknown',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to playlist creation with this genre
            },
            child: const Text('Create Playlist'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LottieLoadingSpinner(message: 'Loading...'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Get Recommendations'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tell us what you\'re looking for',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            // Tempo Slider
            Text('Tempo', style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _tempo,
              min: 1,
              max: 10,
              divisions: 9,
              label: _tempo.round().toString(),
              onChanged: (value) => setState(() => _tempo = value),
            ),

            const SizedBox(height: 16),

            // Mood Dropdown
            Text('Mood', style: Theme.of(context).textTheme.titleMedium),
            DropdownButtonFormField<String>(
              value: _selectedMood,
              items: (_options?['moods'] as List<dynamic>?)
                  ?.map((mood) => DropdownMenuItem(
                        value: mood.toString(),
                        child: Text(mood.toString()),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedMood = value),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Length Slider
            Text('Length', style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _length,
              min: 1,
              max: 10,
              divisions: 9,
              label: _length.round().toString(),
              onChanged: (value) => setState(() => _length = value),
            ),

            const SizedBox(height: 16),

            // Explicit Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Allow Explicit Content',
                    style: Theme.of(context).textTheme.titleMedium),
                Switch(
                  value: _explicit,
                  onChanged: (value) => setState(() => _explicit = value),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Age/Era Slider
            Text('Music Era', style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _age,
              min: 1800,
              max: 2024,
              divisions: 224,
              label: _age.round().toString(),
              onChanged: (value) => setState(() => _age = value),
            ),

            const SizedBox(height: 16),

            // Setting Dropdown
            Text('Setting', style: Theme.of(context).textTheme.titleMedium),
            DropdownButtonFormField<String>(
              value: _selectedSetting,
              items: (_options?['settings'] as List<dynamic>?)
                  ?.map((setting) => DropdownMenuItem(
                        value: setting.toString(),
                        child: Text(setting.toString()),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedSetting = value),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            CustomButton(
              text: 'Get Recommendation',
              onPressed: _getRecommendation,
              icon: Icons.music_note,
            ),
          ],
        ),
      ),
    );
  }
}

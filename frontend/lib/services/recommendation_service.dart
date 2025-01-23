import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class RecommendationService {
  // Get the appropriate base URL based on platform
  String get baseUrl {
    final url = Platform.isAndroid
        ? 'http://10.0.2.2:5000/api'
        : 'http://localhost:5000/api'; // Changed to localhost
    print('Base URL: $url'); // Debug print
    return url;
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get available options for recommendation parameters
  Future<Map<String, dynamic>> getOptions() async {
    try {
      final url = '$baseUrl/options';
      print('Full URL being called: $url'); // Debug print
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error in getOptions: $e'); // Add debug logging
      throw Exception('Failed to connect to server: $e');
    }
  }

  // Get genre recommendation based on user inputs
  Future<Map<String, dynamic>> getRecommendation({
    required int tempo,
    required int mood,
    required int length,
    required bool explicit,
    required int age,
    required int setting,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recommend'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'tempo': tempo,
          'mood': mood,
          'length': length,
          'explicit': explicit ? 1 : 0,
          'age': age,
          'setting': setting,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get recommendation');
      }
    } catch (e) {
      print('Error getting recommendation: $e');
      rethrow;
    }
  }

  // Save user preferences to Firestore
  Future<void> saveUserPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'preferences': preferences,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving preferences: $e');
      rethrow;
    }
  }

  // Get recommendation history for a user
  Future<List<Map<String, dynamic>>> getRecommendationHistory(
    String userId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('recommendations')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      print('Error getting recommendation history: $e');
      rethrow;
    }
  }

  // Save a recommendation to history
  Future<void> saveRecommendationToHistory(
    String userId,
    Map<String, dynamic> recommendation,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('recommendations')
          .add({
        ...recommendation,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving recommendation: $e');
      rethrow;
    }
  }

  // Get personalized recommendations based on user history
  Future<List<Map<String, dynamic>>> getPersonalizedRecommendations(
    String userId,
  ) async {
    try {
      // Get user preferences and history
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final preferences = userDoc.data()?['preferences'] ?? {};

      // Get recommendation history
      final history = await getRecommendationHistory(userId);

      // TODO: Implement more sophisticated personalization logic
      // For now, just get a basic recommendation
      final recommendation = await getRecommendation(
        tempo: preferences['preferredTempo'] ?? 5,
        mood: preferences['preferredMood'] ?? 0,
        length: preferences['preferredLength'] ?? 5,
        explicit: preferences['includeExplicit'] ?? false,
        age: preferences['preferredEra'] ?? 2000,
        setting: preferences['preferredSetting'] ?? 0,
      );

      return [recommendation];
    } catch (e) {
      print('Error getting personalized recommendations: $e');
      rethrow;
    }
  }
}

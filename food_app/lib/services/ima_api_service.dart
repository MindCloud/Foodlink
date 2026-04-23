// lib/services/ima_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ImaApiService {
  // Update this URL to match your backend server
  static const String baseUrl = 'http://localhost:5000';

  /// Get IMA match for a single donation
  static Future<Map<String, dynamic>?> getImaMatch(
    Map<String, dynamic> donation,
    List<Map<String, dynamic>> charities,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ima'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'donation': donation,
          'charities': charities,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }

  /// Get IMA matches for multiple donations (batch)
  static Future<List<Map<String, dynamic>>> getBatchImaMatches(
    List<Map<String, dynamic>> donations,
    List<Map<String, dynamic>> charities,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ima/batch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'donations': donations,
          'charities': charities,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception: $e');
      return [];
    }
  }

  /// Run evaluation and return metrics
  static Future<Map<String, dynamic>?> evaluate() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/evaluate'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }

  /// Generate evaluation report with graphs
  static Future<Map<String, dynamic>?> generateReport() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/report'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }

  /// Train the spoilage prediction model
  static Future<Map<String, dynamic>?> trainModel() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/train'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }

  /// Health check
  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Exception: $e');
      return false;
    }
  }
}

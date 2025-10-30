import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DeleteAccountService {
  static const String baseUrl = 'https://dev-klayons.onrender.com/api';

  /// Get authentication token from SharedPreferences
  static Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      debugPrint('Error getting auth token: $e');
      return null;
    }
  }

  /// Delete user account
  ///
  /// Soft deletes user account and marks user profile as deleted.
  /// Physically deletes all related data (children, enrollments, OTPs).
  ///
  /// Returns:
  /// - Map with 'success' and 'message' on success
  /// - Throws Exception on failure
  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final token = await _getAuthToken();

      if (token == null) {
        throw Exception('No authentication token found. Please login again.');
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      debugPrint('=== DELETE ACCOUNT REQUEST ===');
      debugPrint('URL: $baseUrl/auth/delete-account/');
      debugPrint('Method: DELETE');
      debugPrint('Headers: $headers');

      final response = await http.delete(
        Uri.parse('$baseUrl/auth/delete-account/'),
        headers: headers,
      );

      debugPrint('Response Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      // Parse response
      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Success - Clear all stored data
        await _clearUserData();

        return {
          'success': true,
          'message': responseData['message'] ?? 'Account deleted successfully',
          'status_code': responseData['status_code'] ?? 200,
        };
      } else if (response.statusCode == 400) {
        // Account deletion failed
        String errorMessage =
            responseData['message'] ??
            'Account deletion failed. Please try again.';
        throw Exception(errorMessage);
      } else if (response.statusCode == 500) {
        // Internal server error - Enhanced error message for database issues
        String errorMessage =
            responseData['message'] ??
            'Server error occurred. Please try again later.';

        // Check if it's a database constraint issue
        if (errorMessage.contains('value too long') ||
            errorMessage.contains('character varying')) {
          throw Exception(
            'We encountered a technical issue while deleting your account. '
            'Please contact support at support@klayons.com for assistance.',
          );
        }

        throw Exception(errorMessage);
      } else {
        // Other errors
        String errorMessage =
            responseData['message'] ??
            responseData['error'] ??
            responseData['detail'] ??
            'Failed to delete account';
        throw Exception(errorMessage);
      }
    } on http.ClientException catch (e) {
      debugPrint('Network error in deleteAccount: $e');
      throw Exception('Network error. Please check your internet connection.');
    } on FormatException catch (e) {
      debugPrint('JSON parsing error in deleteAccount: $e');
      throw Exception('Invalid response from server. Please try again.');
    } catch (e) {
      debugPrint('Error in deleteAccount: $e');
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  /// Clear all user data from SharedPreferences
  static Future<void> _clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('User data cleared from SharedPreferences');
    } catch (e) {
      debugPrint('Error clearing user data: $e');
      // Don't throw error here as the account is already deleted on server
    }
  }

  /// Check if user has an active session
  static Future<bool> hasActiveSession() async {
    final token = await _getAuthToken();
    return token != null && token.isNotEmpty;
  }
}

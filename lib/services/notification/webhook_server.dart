// webhook_server.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'local_notification_service.dart';

class WebhookServer {
  static HttpServer? _server;
  static int _port = 8080;
  static String? _webhookUrl;
  
  /// Start the local webhook server
  static Future<String?> startServer() async {
    try {
      // Try to start server on available port
      for (int port = 8080; port <= 8090; port++) {
        try {
          _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
          _port = port;
          break;
        } catch (e) {
          if (port == 8090) rethrow; // Last attempt failed
          continue; // Try next port
        }
      }
      
      if (_server == null) return null;
      
      _webhookUrl = 'http://localhost:$_port/webhook';
      
      // Listen for incoming webhook requests
      _server!.listen((HttpRequest request) async {
        await _handleWebhookRequest(request);
      });
      
      print('Webhook server started on port $_port');
      print('Webhook URL: $_webhookUrl');
      
      return _webhookUrl;
    } catch (e) {
      print('Failed to start webhook server: $e');
      return null;
    }
  }
  
  /// Handle incoming webhook requests
  static Future<void> _handleWebhookRequest(HttpRequest request) async {
    try {
      if (request.method != 'POST') {
        request.response.statusCode = HttpStatus.methodNotAllowed;
        await request.response.close();
        return;
      }
      
      // Read request body
      final body = await utf8.decoder.bind(request).join();
      final data = jsonDecode(body);
      
      print('Received webhook: $data');
      
      // Process the webhook based on event type
      await _processWebhook(data);
      
      // Send success response
      request.response.statusCode = HttpStatus.ok;
      request.response.write('{"status": "success"}');
      await request.response.close();
      
    } catch (e) {
      print('Error handling webhook request: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('{"error": "Internal server error"}');
      await request.response.close();
    }
  }
  
  /// Process webhook payload and show notifications
  static Future<void> _processWebhook(Map<String, dynamic> data) async {
    final eventType = data['event'];
    final payload = data['data'];
    
    switch (eventType) {
      case 'announcement_created':
        await LocalNotificationService.showNotification(
          id: payload['id'],
          title: 'New: ${payload['title']}',
          body: payload['content'],
          payload: 'announcement_${payload['id']}',
        );
        break;
      
      case 'announcement_updated':
        await LocalNotificationService.showNotification(
          id: payload['id'] + 1000, // Different ID for updates
          title: 'Updated: ${payload['title']}',
          body: payload['content'],
          payload: 'announcement_${payload['id']}',
        );
        break;
        
      default:
        print('Unknown webhook event: $eventType');
    }
  }
  
  /// Stop the webhook server
  static Future<void> stopServer() async {
    if (_server != null) {
      await _server!.close();
      _server = null;
      _webhookUrl = null;
      print('Webhook server stopped');
    }
  }
  
  /// Get the current webhook URL
  static String? get webhookUrl => _webhookUrl;
  
  /// Check if server is running
  static bool get isRunning => _server != null;
}

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _discordWebhookUrl =
      'https://discordapp.com/api/webhooks/1524455238675861604/ULU3Xu38ekQBgSzqWQzNXZ8sI7zWGxptzM2p5HDgkbPUXzVjF1olaOrcTob4DHOCh59c';

  /// Speichert das Feedback direkt in der Firestore-Collection „feedback".
  /// Gibt null zurück bei Erfolg, sonst die Fehlermeldung als String.
  Future<String?> sendFeedback({
    required String message,
    String? username,
    String? userEmail,
    String? imagePath,
  }) async {
    try {
      final data = <String, dynamic>{
        'message': message.trim(),
        'username': username?.trim().isNotEmpty == true
            ? username!.trim()
            : 'Unbekannt',
        'userEmail': userEmail?.trim().isNotEmpty == true
            ? userEmail!.trim()
            : 'Nicht hinterlegt',
        'sentAt': FieldValue.serverTimestamp(),
      };
      if (imagePath != null && imagePath.trim().isNotEmpty) {
        data['imagePath'] = imagePath.trim();
      }

      await _firestore.collection('feedback').add(data);

      final discordError = await sendFeedbackToDiscord(
        message: message,
        username: username,
        userEmail: userEmail,
        imagePath: imagePath,
      );
      if (discordError != null) {
        return discordError;
      }

      return null;
    } catch (e) {
      debugPrint('FeedbackService Fehler: $e');
      return e.toString();
    }
  }

  /// Sendet das Feedback als Embed an einen Discord Webhook.
  /// Gibt null zurück bei Erfolg, sonst eine Fehlermeldung.
  Future<String?> sendFeedbackToDiscord({
    required String message,
    String? username,
    String? userEmail,
    String? imagePath,
  }) async {
    try {
      final userName = username?.trim().isNotEmpty == true
          ? username!.trim()
          : 'Unbekannt';
      final email = userEmail?.trim().isNotEmpty == true
          ? userEmail!.trim()
          : 'Nicht hinterlegt';
      final image = imagePath?.trim().isNotEmpty == true
          ? imagePath!.trim()
          : '-';

      final payload = <String, dynamic>{
        'username': 'Sightseeing Feedback Bot',
        'embeds': [
          {
            'title': 'Neues App-Feedback',
            'color': 16760576,
            'fields': [
              {
                'name': 'Nutzer',
                'value': userName,
                'inline': true,
              },
              {
                'name': 'E-Mail',
                'value': email,
                'inline': true,
              },
              {
                'name': 'Nachricht',
                'value': message.trim().isNotEmpty ? message.trim() : '-',
                'inline': false,
              },
              {
                'name': 'Bildpfad',
                'value': image,
                'inline': false,
              },
            ],
            'timestamp': DateTime.now().toUtc().toIso8601String(),
          }
        ],
      };

      final response = await http.post(
        Uri.parse(_discordWebhookUrl),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return null;
      }

      debugPrint(
        'Discord Webhook Fehler: ${response.statusCode} ${response.body}',
      );
      return 'Discord Webhook Fehler (${response.statusCode})';
    } catch (e) {
      debugPrint('Discord Webhook Exception: $e');
      return 'Discord Webhook Fehler: $e';
    }
  }
}
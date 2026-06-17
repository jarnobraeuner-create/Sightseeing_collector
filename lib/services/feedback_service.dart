import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      return null;
    } catch (e) {
      debugPrint('FeedbackService Fehler: $e');
      return e.toString();
    }
  }
}
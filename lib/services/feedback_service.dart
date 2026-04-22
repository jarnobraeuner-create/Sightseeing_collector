import 'package:url_launcher/url_launcher.dart';

class FeedbackService {
  static const String placeholderRecipient = 'feedback@example.com';

  Future<bool> sendFeedbackEmail({
    required String message,
    String? username,
    String? userEmail,
    String? imagePath,
  }) async {
    final body = StringBuffer()
      ..writeln('Neues In-App-Feedback')
      ..writeln('')
      ..writeln('Nutzername: ${username?.trim().isNotEmpty == true ? username!.trim() : 'Unbekannt'}')
      ..writeln('Account-E-Mail: ${userEmail?.trim().isNotEmpty == true ? userEmail!.trim() : 'Nicht hinterlegt'}')
      ..writeln('')
      ..writeln('Nachricht:')
      ..writeln(message.trim());

    if (imagePath != null && imagePath.trim().isNotEmpty) {
      body
        ..writeln('')
        ..writeln('Ausgewähltes Bild:')
        ..writeln(imagePath.trim())
        ..writeln('')
        ..writeln('Hinweis: Die aktuelle Platzhalter-Implementierung öffnet den Mail-Client. Das Bild wird noch nicht automatisch als Anhang übergeben.');
    }

    final uri = Uri(
      scheme: 'mailto',
      path: placeholderRecipient,
      queryParameters: {
        'subject': 'App-Feedback Sightseeing Collector',
        'body': body.toString(),
      },
    );

    if (!await canLaunchUrl(uri)) {
      return false;
    }

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
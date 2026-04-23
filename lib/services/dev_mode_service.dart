import 'package:flutter/foundation.dart';

/// Usernames (Kleinbuchstaben), die den Dev-Mode sehen und nutzen dürfen.
const Set<String> _kDevModeAllowedUsernames = {
  'jarno',
  'jerryb',
};

/// E-Mail-Adressen (Kleinbuchstaben), die den Dev-Mode aktivieren dürfen.
/// Trage hier die gewünschten Accounts ein.
const Set<String> _kDevModeAllowedEmails = {
  // Beispiel: 'deine@email.de',
};

/// Firebase-UIDs, die den Dev-Mode aktivieren dürfen (alternative zur E-Mail).
const Set<String> _kDevModeAllowedUids = {
  // Beispiel: 'abc123uid',
};

/// Einfacher Toggle-Service für den Developer-Mode.
/// Dev-Mode schaltet Standort- und Coin-Beschränkungen ab.
class DevModeService extends ChangeNotifier {
  bool _enabled = false;

  bool get enabled => _enabled;

  /// Gibt true zurück wenn [username], [email] oder [uid] in der Whitelist steht.
  bool isAllowed({String? username, String? email, String? uid}) {
    if (username != null &&
        _kDevModeAllowedUsernames.contains(username.toLowerCase())) {
      return true;
    }
    if (uid != null && _kDevModeAllowedUids.contains(uid)) return true;
    if (email != null && _kDevModeAllowedEmails.contains(email.toLowerCase())) {
      return true;
    }
    return false;
  }

  /// Erzwingt, dass nicht freigegebene Accounts den Dev-Mode nicht aktiv haben.
  void syncAuthorization({String? username, String? email, String? uid}) {
    final allowed = isAllowed(username: username, email: email, uid: uid);
    if (!allowed) {
      disable();
    }
  }

  void toggle() {
    _enabled = !_enabled;
    debugPrint('DevMode: $_enabled');
    notifyListeners();
  }

  void disable() {
    if (_enabled) {
      _enabled = false;
      notifyListeners();
    }
  }
}

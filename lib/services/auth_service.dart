import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String username;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.username,
    required this.createdAt,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      email: data['email'] as String? ?? '',
      username: data['username'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'email': email,
        'username': username,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get firebaseUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  AppUser? _appUser;
  AppUser? get appUser => _appUser;

  String? _error;
  String? get error => _error;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      _appUser = null;
    } else {
      await _loadUserProfile(user.uid);
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        _appUser = AppUser.fromFirestore(doc.data()!, uid);
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  // ─── Register ─────────────────────────────────────────────────────────────

  Future<bool> register({
    required String email,
    required String password,
    required String username,
  }) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    UserCredential? credential;
    try {
      // 1. Firebase Auth-User erstellen (jetzt eingeloggt)
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // 2. Username-Eindeutigkeit prüfen (jetzt authentifiziert)
      final usernameQuery = await _db
          .collection('users')
          .where('username', isEqualTo: username.trim())
          .limit(1)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        // Username vergeben → Auth-User wieder löschen
        await credential.user!.delete();
        _error = 'Dieser Benutzername ist bereits vergeben.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 3. Profil in Firestore schreiben
      final newUser = AppUser(
        uid: credential.user!.uid,
        email: email.trim(),
        username: username.trim(),
        createdAt: DateTime.now(),
      );

      await _db
          .collection('users')
          .doc(credential.user!.uid)
          .set(newUser.toFirestore());

      _appUser = newUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _logAuthException('register', e);
      _error = _translateError(e.code, message: e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      // Firestore-Fehler: Auth-User aufräumen falls bereits erstellt
      debugPrint('Register error: $e');
      if (credential != null) {
        await credential.user?.delete().catchError((_) {});
      }
      _error = 'Registrierung fehlgeschlagen: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Login ────────────────────────────────────────────────────────────────

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _logAuthException('login', e);
      if (_isConnectionResetError(e)) {
        try {
          await Future<void>.delayed(const Duration(milliseconds: 700));
          await _auth.signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
          _isLoading = false;
          notifyListeners();
          return true;
        } on FirebaseAuthException catch (retryError) {
          _logAuthException('login-retry', retryError);
          _error = _translateError(retryError.code, message: retryError.message);
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
      _error = _translateError(e.code, message: e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Auth unknown login error: $e');
      _error = 'Ein unbekannter Fehler ist aufgetreten.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _auth.signOut();
    _appUser = null;
    notifyListeners();
  }

  // ─── Password Reset ───────────────────────────────────────────────────────

  Future<bool> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      _logAuthException('password-reset', e);
      return false;
    } catch (e) {
      debugPrint('Auth unknown password-reset error: $e');
      return false;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _translateError(String code, {String? message}) {
    final normalizedCode = code.toLowerCase();
    switch (normalizedCode) {
      case 'email-already-in-use':
        return 'Diese E-Mail-Adresse wird bereits verwendet.';
      case 'invalid-email':
        return 'Ungültige E-Mail-Adresse.';
      case 'weak-password':
        return 'Das Passwort ist zu schwach (mind. 6 Zeichen).';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-Mail oder Passwort ist falsch.';
      case 'network-request-failed':
        return 'Netzwerkfehler. Bitte prüfe deine Internetverbindung.';
      case 'operation-not-allowed':
        return 'Anmeldung ist aktuell nicht verfügbar. Bitte später erneut versuchen.';
      case 'unknown':
        if (_isConnectionResetMessage(message)) {
          return 'Netzwerkfehler (Verbindung zurückgesetzt). Bitte prüfe Internet, VPN/Firewall sowie automatische Datum-/Uhrzeiteinstellung und versuche es erneut.';
        }
        return message?.trim().isNotEmpty == true
            ? 'Anmeldung fehlgeschlagen: ${message!.trim()}'
            : 'Anmeldung fehlgeschlagen. Bitte versuche es erneut.';
      case 'user-disabled':
        return 'Dieses Konto wurde deaktiviert.';
      case 'too-many-requests':
        return 'Zu viele Versuche. Bitte warte kurz.';
      default:
        if (message?.trim().isNotEmpty == true) {
          return 'Anmeldung fehlgeschlagen: ${message!.trim()}';
        }
        return 'Anmeldung fehlgeschlagen (Code: $normalizedCode).';
    }
  }

  void _logAuthException(String operation, FirebaseAuthException e) {
    debugPrint('Auth operation failed: $operation');
    debugPrint('FULL ERROR: $e');
    debugPrint('CODE: ${e.code}');
    debugPrint('MESSAGE: ${e.message ?? 'no-message'}');
    debugPrint('EMAIL: ${e.email ?? 'n/a'}');
    debugPrint('CREDENTIAL: ${e.credential != null ? 'present' : 'null'}');
  }

  bool _isConnectionResetError(FirebaseAuthException e) {
    return e.code.toLowerCase() == 'unknown' && _isConnectionResetMessage(e.message);
  }

  bool _isConnectionResetMessage(String? message) {
    final normalizedMessage = message?.toLowerCase() ?? '';
    return normalizedMessage.contains('connection reset') ||
        normalizedMessage.contains('socket') ||
        normalizedMessage.contains('network');
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

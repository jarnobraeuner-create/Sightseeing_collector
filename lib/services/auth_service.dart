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
        'usernameLower': username.toLowerCase(),
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class AuthService extends ChangeNotifier {
  FirebaseAuth? _auth;
  FirebaseFirestore? _db;

  FirebaseAuth get auth {
    try {
      _auth ??= FirebaseAuth.instance;
      return _auth!;
    } catch (e) {
      throw Exception('Firebase not initialized: $e');
    }
  }

  FirebaseFirestore get db {
    try {
      _db ??= FirebaseFirestore.instance;
      return _db!;
    } catch (e) {
      throw Exception('Firebase not initialized: $e');
    }
  }

  User? get firebaseUser {
    try {
      return auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  bool get isLoggedIn {
    try {
      return auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  AppUser? _appUser;
  AppUser? get appUser => _appUser;

  String? _error;
  String? get error => _error;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  AuthService() {
    // Set initialized to true with a timeout - app should show immediately
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_isInitialized) {
        _isInitialized = true;
        notifyListeners();
      }
    });
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    Future.microtask(() {
      try {
        auth.authStateChanges().listen(_onAuthStateChanged);
      } catch (e) {
        debugPrint('Failed to initialize auth listener: $e');
        _isInitialized = true;
        notifyListeners();
      }
    });
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      _appUser = null;
    } else {
      await _loadUserProfile(user.uid);
    }
    if (!_isInitialized) {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _loadUserProfile(String uid) async {
    try {
      final doc = await db.collection('users').doc(uid).get();
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
      credential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // 2. Username-Eindeutigkeit prüfen (jetzt authentifiziert)
      final usernameQuery = await db
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

      await db
          .collection('users')
          .doc(credential.user!.uid)
          .set(newUser.toFirestore());

      _appUser = newUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _translateError(e.code);
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
      await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _translateError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Ein unbekannter Fehler ist aufgetreten.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await auth.signOut();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
    _appUser = null;
    notifyListeners();
  }

  // ─── Password Reset ───────────────────────────────────────────────────────

  Future<bool> sendPasswordReset(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } catch (e) {
      debugPrint('Password reset error: $e');
      return false;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _translateError(String code) {
    switch (code) {
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
      case 'user-disabled':
        return 'Dieses Konto wurde deaktiviert.';
      case 'too-many-requests':
        return 'Zu viele Versuche. Bitte warte kurz.';
      default:
        return 'Fehler: $code';
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

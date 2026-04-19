import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';
import 'home_screen.dart';

/// Listens to [AuthService] and routes to either the auth screen or the app.
class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        // Warte bis Firebase Auth initialisiert ist
        if (!auth.isInitialized) {
          return Scaffold(
            backgroundColor: Colors.grey[900],
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.amber),
                  const SizedBox(height: 16),
                  Text(
                    'Verbinde mit Firebase...',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }
        // Eingeloggt → App
        if (auth.isLoggedIn) {
          return const HomeScreen();
        }
        // Nicht eingeloggt → Login / Registrierung
        return const AuthScreen();
      },
    );
  }
}

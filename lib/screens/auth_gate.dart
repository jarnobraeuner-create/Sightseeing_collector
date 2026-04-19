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
        if (!auth.isInitialized) {
          return Scaffold(
            backgroundColor: Colors.grey[900],
            body: const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            ),
          );
        }
        if (auth.isLoggedIn) {
          return const HomeScreen();
        }
        return const AuthScreen();
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../widgets/app_lottie.dart';
import 'auth_screen.dart';
import 'home_screen.dart';

/// Listens to [AuthService] and routes to either the auth screen or the app.
class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Nach dem ersten Frame Permission anfragen (Activity ist dann bereit)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.requestPermissions();
    });
  }

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
                  const AppLottie(
                    type: AppLottieType.loading,
                    size: 88,
                  ),
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

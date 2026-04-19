import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/index.dart';
import 'screens/index.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SightseeingCollectorApp());
}

class SightseeingCollectorApp extends StatelessWidget {
  const SightseeingCollectorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => LandmarkService()),
        ChangeNotifierProvider(create: (_) => CollectionService()),
        ChangeNotifierProvider(create: (_) => AuctionService()),
        ChangeNotifierProvider(create: (_) => LootboxService()),
        ChangeNotifierProvider(create: (_) => CooldownService()),
      ],
      child: MaterialApp(
        title: 'Sightseeing Collector',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

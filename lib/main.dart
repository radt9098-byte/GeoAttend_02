import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/location_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase initialization normally goes here.
  // We'll wrap in a try/catch to not crash if config isn't added yet.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init failed (maybe missing google-services.json): $e");
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>(create: (_) => DatabaseService()),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<LocationService>(create: (_) => LocationService()),
      ],
      child: const GeoAttendApp(),
    ),
  );
}

class GeoAttendApp extends StatelessWidget {
  const GeoAttendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoAttend',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

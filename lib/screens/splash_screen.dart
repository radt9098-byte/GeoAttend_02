import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'admin_setup_screen.dart';
import 'login_screen.dart';
import 'admin_dashboard.dart';
import 'employee_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _determineStartRoute();
  }

  Future<void> _determineStartRoute() async {
    setState(() => _error = null);
    try {
      await _tryDetermineStartRoute();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error =
            'Could not connect to the server.\n\nThis usually means either:\n'
            '• No internet connection on this device, or\n'
            '• The Firestore database rules are blocking access.\n\n'
            'Details: $e';
      });
    }
  }

  Future<void> _tryDetermineStartRoute() async {
    final db = context.read<DatabaseService>();
    final auth = context.read<AuthService>();

    // 1. Check if admin exists in DB (with a timeout so we never hang
    // forever on a blocked or unreachable connection).
    final adminExists = await db.adminExists().timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception(
              'Connection timed out after 15 seconds. Check your internet connection.'),
        );
    if (!mounted) return;
    if (!adminExists) {
      _navigate(const AdminSetupScreen());
      return;
    }

    // 2. Admin exists, check saved session
    await auth.checkSavedSession();
    if (!mounted) return;

    if (auth.currentUserRole == AuthRole.employee) {
      _navigate(const EmployeeDashboardScreen());
    } else if (auth.currentUserRole == AuthRole.admin) {
      _navigate(const AdminDashboardScreen());
    } else {
      _navigate(const LoginScreen());
    }
  }

  void _navigate(Widget screen) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, size: 56, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _determineStartRoute,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

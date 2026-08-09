import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/office_config.dart';
import 'splash_screen.dart';

class AdminSetupScreen extends StatefulWidget {
  const AdminSetupScreen({super.key});

  @override
  State<AdminSetupScreen> createState() => _AdminSetupScreenState();
}

class _AdminSetupScreenState extends State<AdminSetupScreen> {
  final _adminIdController = TextEditingController();
  final _pinController = TextEditingController();
  final _answerController = TextEditingController();
  final _emailController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _radiusController = TextEditingController(text: '100');

  String _selectedQuestion = 'What is the name of the company/office?';
  final List<String> _questions = [
    'What is the name of the company/office?',
    'What city were you born in?',
    'What is your mother\'s maiden name?'
  ];

  Future<void> _setupAdmin() async {
    final db = context.read<DatabaseService>();
    final auth = context.read<AuthService>();

    await db.createAdmin(
      adminId: _adminIdController.text,
      pinHash: auth.hashPin(_pinController.text),
      securityQuestion: _selectedQuestion,
      securityAnswer: auth.hashPin(_answerController.text.trim().toLowerCase()),
      recoveryEmail: _emailController.text,
    );

    await db.setOfficeConfig(OfficeConfig(
      latitude: double.tryParse(_latController.text) ?? 0.0,
      longitude: double.tryParse(_lngController.text) ?? 0.0,
      radiusMeters: double.tryParse(_radiusController.text) ?? 100.0,
    ));

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Setup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Initial Setup - Organization Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: _adminIdController, decoration: const InputDecoration(labelText: 'Admin ID (Username)')),
            TextField(controller: _pinController, decoration: const InputDecoration(labelText: 'PIN (4-6 digits)'), obscureText: true, keyboardType: TextInputType.number),
            DropdownButtonFormField<String>(
              value: _selectedQuestion,
              items: _questions.map((q) => DropdownMenuItem(value: q, child: Text(q))).toList(),
              onChanged: (val) => setState(() => _selectedQuestion = val!),
              decoration: const InputDecoration(labelText: 'Security Question'),
            ),
            TextField(controller: _answerController, decoration: const InputDecoration(labelText: 'Security Answer')),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Recovery Email')),
            const SizedBox(height: 20),
            const Text('Office GPS Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: _latController, decoration: const InputDecoration(labelText: 'Latitude'), keyboardType: TextInputType.number),
            TextField(controller: _lngController, decoration: const InputDecoration(labelText: 'Longitude'), keyboardType: TextInputType.number),
            TextField(controller: _radiusController, decoration: const InputDecoration(labelText: 'Radius (Meters)'), keyboardType: TextInputType.number),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: _setupAdmin, child: const Text('Complete Setup')),
          ],
        ),
      ),
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/email_service.dart';

class AdminForgotPinScreen extends StatefulWidget {
  const AdminForgotPinScreen({super.key});

  @override
  State<AdminForgotPinScreen> createState() => _AdminForgotPinScreenState();
}

class _AdminForgotPinScreenState extends State<AdminForgotPinScreen> {
  final _adminIdCtrl = TextEditingController();
  final _answerCtrl = TextEditingController();
  
  Map<String, dynamic>? _adminConfig;
  bool _stepTwo = false;
  bool _isLoading = false;

  Future<void> _verifyAdminId() async {
    setState(() => _isLoading = true);
    final db = context.read<DatabaseService>();
    final config = await db.getAdminConfig();
    
    if (config != null && config['adminId'] == _adminIdCtrl.text) {
      setState(() {
        _adminConfig = config;
        _stepTwo = true;
      });
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin ID not found'), backgroundColor: Colors.red));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _verifyAnswerAndRecover() async {
    if (_adminConfig == null) return;
    setState(() => _isLoading = true);

    final auth = context.read<AuthService>();
    final correctAnswerHash = _adminConfig!['securityAnswer'].toString();
    final inputAnswerHash = auth.hashPin(_answerCtrl.text.trim().toLowerCase());

    if (inputAnswerHash == correctAnswerHash) {
      // Generate new PIN
      final newPin = (Random().nextInt(900000) + 100000).toString(); // 6 digits

      // Hash and update
      final db = context.read<DatabaseService>();
      await db.updateAdminPin(auth.hashPin(newPin));

      // Send email
      final emailService = EmailService();
      String? errorMessage;
      bool success = false;
      try {
        success = await emailService.sendRecoveryEmail(
            _adminConfig!['recoveryEmail'], newPin);
      } catch (e) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }

      if (mounted) {
        if (success) {
          showDialog(
            context: context, 
            builder: (_) => AlertDialog(
              title: const Text('PIN Recovered'),
              content: Text('A new PIN has been emailed to ${_adminConfig!['recoveryEmail']}.'),
              actions: [
                TextButton(onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // go back to login
                }, child: const Text('OK'))
              ],
            )
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(errorMessage ??
                'Failed to send recovery email. PIN was updated, but email failed.'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect Answer'), backgroundColor: Colors.red));
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Admin PIN')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _stepTwo 
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Security Question:', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(_adminConfig!['securityQuestion'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 20),
                TextField(controller: _answerCtrl, decoration: const InputDecoration(labelText: 'Your Answer')),
                const SizedBox(height: 24),
                _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(onPressed: _verifyAnswerAndRecover, child: const Text('Recover PIN')),
              ],
            )
          : Column(
              children: [
                TextField(controller: _adminIdCtrl, decoration: const InputDecoration(labelText: 'Admin ID')),
                const SizedBox(height: 24),
                _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(onPressed: _verifyAdminId, child: const Text('Next')),
              ],
            ),
      ),
    );
  }
}

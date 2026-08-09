import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'employee_dashboard.dart';
import 'admin_dashboard.dart';
import 'admin_forgot_pin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isAdminLogin = false;
  String _errorMsg = '';

  Future<void> _login() async {
    setState(() => _errorMsg = '');
    final auth = context.read<AuthService>();
    
    bool success = false;
    if (_isAdminLogin) {
      success = await auth.loginAdmin(_idController.text, _pinController.text);
    } else {
      success = await auth.loginEmployee(_idController.text, _pinController.text);
    }

    if (!mounted) return;
    
    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => _isAdminLogin ? const AdminDashboardScreen() : const EmployeeDashboardScreen()),
        (route) => false,
      );
    } else {
      setState(() => _errorMsg = 'Invalid ID or PIN');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_isAdminLogin ? 'Admin Login' : 'Employee Login', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 32),
              TextField(controller: _idController, decoration: InputDecoration(labelText: _isAdminLogin ? 'Admin ID' : 'Employee ID')),
              const SizedBox(height: 16),
              TextField(controller: _pinController, decoration: const InputDecoration(labelText: 'PIN'), obscureText: true, keyboardType: TextInputType.number),
              if (_errorMsg.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_errorMsg, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('Login'),
              ),
              const SizedBox(height: 16),
              if (_isAdminLogin)
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminForgotPinScreen())),
                  child: const Text('Forgot PIN?'),
                ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isAdminLogin = !_isAdminLogin;
                    _idController.clear();
                    _pinController.clear();
                    _errorMsg = '';
                  });
                },
                child: Text(_isAdminLogin ? 'Employee Login' : 'Admin Login', style: const TextStyle(color: Colors.grey)),
              )
            ],
          ),
        ),
      ),
    );
  }
}

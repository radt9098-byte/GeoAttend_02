import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import '../models/employee.dart';

enum AuthRole { none, admin, employee }

class AuthService {
  final DatabaseService _db = DatabaseService();
  
  AuthRole currentUserRole = AuthRole.none;
  String? currentUserId;

  // Hashes PIN using SHA-256
  String hashPin(String pin) {
    var bytes = utf8.encode(pin);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> checkSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');
    final id = prefs.getString('userId');
    
    if (role == 'admin' && id != null) {
      currentUserRole = AuthRole.admin;
      currentUserId = id;
    } else if (role == 'employee' && id != null) {
      currentUserRole = AuthRole.employee;
      currentUserId = id;
    }
  }

  Future<bool> loginAdmin(String adminId, String pin) async {
    final config = await _db.getAdminConfig();
    if (config == null) return false;
    
    if (config['adminId'] == adminId && config['pinHash'] == hashPin(pin)) {
      await _saveSession('admin', adminId);
      currentUserRole = AuthRole.admin;
      currentUserId = adminId;
      return true;
    }
    return false;
  }

  Future<bool> loginEmployee(String employeeId, String pin) async {
    final emp = await _db.getEmployee(employeeId);
    if (emp == null || !emp.isActive) return false;
    
    if (emp.pinHash == hashPin(pin)) {
      await _saveSession('employee', employeeId);
      currentUserRole = AuthRole.employee;
      currentUserId = employeeId;
      return true;
    }
    return false;
  }

  Future<void> _saveSession(String role, String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role);
    await prefs.setString('userId', id);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('role');
    await prefs.remove('userId');
    currentUserRole = AuthRole.none;
    currentUserId = null;
  }
}

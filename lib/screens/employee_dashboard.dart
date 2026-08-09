import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../models/attendance_session.dart';
import '../models/employee.dart';
import 'splash_screen.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  late Timer _timer;
  String _currentTime = '';
  Employee? _employee;
  AttendanceSession? _openSession;
  bool _isLoadingAction = false;
  
  @override
  void initState() {
    super.initState();
    _currentTime = DateFormat('hh:mm:ss a').format(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateFormat('hh:mm:ss a').format(DateTime.now());
      });
    });
    
    _loadData();
  }

  Future<void> _loadData() async {
    final db = context.read<DatabaseService>();
    final auth = context.read<AuthService>();
    final empId = auth.currentUserId;
    if (empId == null) return;

    final emp = await db.getEmployee(empId);
    final openSession = await db.getOpenSession(empId);
    
    if (mounted) {
      setState(() {
        _employee = emp;
        _openSession = openSession;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<void> _handleCheckAction() async {
    setState(() => _isLoadingAction = true);
    
    final locService = context.read<LocationService>();
    final db = context.read<DatabaseService>();
    final auth = context.read<AuthService>();
    final empId = auth.currentUserId!;

    final config = await db.getOfficeConfig();
    if (config == null) {
      _showError('Office configuration missing.');
      setState(() => _isLoadingAction = false);
      return;
    }

    final pos = await locService.getCurrentPosition();
    if (pos == null) {
      _showError('Unable to get GPS location. Ensure permissions are granted.');
      setState(() => _isLoadingAction = false);
      return;
    }

    final isWithin = locService.isWithinRadius(
      pos.latitude, pos.longitude, 
      config.latitude, config.longitude, 
      config.radiusMeters
    );

    if (!isWithin) {
      _showError('You are too far from the office to check in/out.');
      setState(() => _isLoadingAction = false);
      return;
    }

    if (_openSession == null) {
      // Check IN
      final newSession = AttendanceSession(
        employeeId: empId,
        checkInTime: DateTime.now(),
        checkInLat: pos.latitude,
        checkInLng: pos.longitude,
      );
      await db.checkIn(newSession);
    } else {
      // Check OUT
      await db.checkOut(
        empId,
        _openSession!.id!,
        DateTime.now(),
        pos.latitude,
        pos.longitude,
      );
    }

    await _loadData();
    setState(() => _isLoadingAction = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _logout() async {
    await context.read<AuthService>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final empId = context.read<AuthService>().currentUserId;
    if (_employee == null || empId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isCheckedIn = _openSession != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            color: Colors.blue.withOpacity(0.1),
            child: Column(
              children: [
                Text('${_getGreeting()}, ${_employee!.name}!', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(DateFormat('EEEE, MMM d, yyyy').format(DateTime.now()), style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                Text(_currentTime, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 2)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _isLoadingAction
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _handleCheckAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCheckedIn ? Colors.orange : Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(200, 200),
                    shape: const CircleBorder(),
                  ),
                  child: Text(
                    isCheckedIn ? 'CHECK OUT' : 'CHECK IN',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
          const SizedBox(height: 40),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(alignment: Alignment.centerLeft, child: Text('Today\'s Sessions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ),
          Expanded(
            child: StreamBuilder<List<AttendanceSession>>(
              stream: context.read<DatabaseService>().streamTodaySessions(empId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final sessions = snapshot.data!;
                double totalHours = 0;
                for (var s in sessions) {
                  totalHours += s.durationHours;
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Align(alignment: Alignment.centerRight, child: Text('Total: ${totalHours.toStringAsFixed(2)} hrs', style: const TextStyle(fontWeight: FontWeight.bold))),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          final inTime = DateFormat('hh:mm a').format(session.checkInTime);
                          final outTime = session.checkOutTime != null ? DateFormat('hh:mm a').format(session.checkOutTime!) : 'Ongoing';
                          return ListTile(
                            leading: const Icon(Icons.access_time),
                            title: Text('$inTime - $outTime'),
                            subtitle: Text('Duration: ${session.durationHours.toStringAsFixed(2)} hrs'),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

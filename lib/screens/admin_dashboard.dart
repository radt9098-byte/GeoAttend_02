import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/employee.dart';
import '../models/office_config.dart';
import 'splash_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

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
    final List<Widget> tabs = [
      const _EmployeesTab(),
      const _AttendanceTab(),
      const _SettingsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Employees'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class _EmployeesTab extends StatelessWidget {
  const _EmployeesTab();

  void _showAddDialog(BuildContext context) {
    final nameController = TextEditingController();
    final idController = TextEditingController();
    final pinController = TextEditingController();
    
    showDialog(context: context, builder: (context) {
      return AlertDialog(
        title: const Text('Add Employee'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: idController, decoration: const InputDecoration(labelText: 'Employee ID')),
            TextField(controller: pinController, decoration: const InputDecoration(labelText: 'PIN (digits)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final auth = context.read<AuthService>();
              final db = context.read<DatabaseService>();
              final newEmp = Employee(
                id: idController.text,
                name: nameController.text,
                pinHash: auth.hashPin(pinController.text),
              );
              await db.addEmployee(newEmp);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () => _showAddDialog(context),
            child: const Text('Add New Employee'),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Employee>>(
            stream: context.read<DatabaseService>().streamEmployees(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final employees = snapshot.data!;
              return ListView.builder(
                itemCount: employees.length,
                itemBuilder: (context, index) {
                  final emp = employees[index];
                  return ListTile(
                    title: Text(emp.name),
                    subtitle: Text('ID: ${emp.id}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: emp.isActive,
                          onChanged: (val) {
                            context.read<DatabaseService>().updateEmployeeStatus(emp.id, val);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            context.read<DatabaseService>().deleteEmployee(emp.id);
                          },
                        )
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AttendanceTab extends StatefulWidget {
  const _AttendanceTab();

  @override
  State<_AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<_AttendanceTab> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  Future<void> _exportCsv(BuildContext context) async {
    setState(() => _isLoading = true);
    final db = context.read<DatabaseService>();
    final sessions = await db.getSessionsForDate(_selectedDate);
    
    List<List<dynamic>> csvData = [
      ['Employee ID', 'Check-In', 'Check-Out', 'Duration (Hours)', 'Check-In Lat', 'Check-In Lng']
    ];

    for (var s in sessions) {
      csvData.add([
        s.employeeId,
        s.checkInTime.toIso8601String(),
        s.checkOutTime?.toIso8601String() ?? 'Ongoing',
        s.durationHours.toStringAsFixed(2),
        s.checkInLat,
        s.checkInLng
      ]);
    }

    String csvStr = const ListToCsvConverter().convert(csvData);
    
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/attendance_${DateFormat('yyyyMMdd').format(_selectedDate)}.csv';
    final file = File(path);
    await file.writeAsString(csvStr);
    
    setState(() => _isLoading = false);
    
    if (context.mounted) {
      await Share.shareXFiles([XFile(path)], text: 'Attendance Report for ${DateFormat('yyyy-MM-dd').format(_selectedDate)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}', style: const TextStyle(fontSize: 16)),
              ElevatedButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
                child: const Text('Change Date'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _isLoading 
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Export CSV'),
                onPressed: () => _exportCsv(context),
              ),
        ),
        const Expanded(
          child: Center(
            child: Text('Generate CSV to view full breakdown.'),
          ),
        )
      ],
    );
  }
}

class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  final _oldPinCtrl = TextEditingController();
  final _newPinCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _radCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await context.read<DatabaseService>().getOfficeConfig();
    if (config != null) {
      setState(() {
        _latCtrl.text = config.latitude.toString();
        _lngCtrl.text = config.longitude.toString();
        _radCtrl.text = config.radiusMeters.toString();
      });
    }
  }

  Future<void> _updateConfig() async {
    final config = OfficeConfig(
      latitude: double.tryParse(_latCtrl.text) ?? 0.0,
      longitude: double.tryParse(_lngCtrl.text) ?? 0.0,
      radiusMeters: double.tryParse(_radCtrl.text) ?? 100.0,
    );
    await context.read<DatabaseService>().setOfficeConfig(config);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Office location updated')));
    }
  }

  Future<void> _updatePin() async {
    final auth = context.read<AuthService>();
    final db = context.read<DatabaseService>();
    
    // Verify old PIN
    final config = await db.getAdminConfig();
    if (config != null && config['pinHash'] == auth.hashPin(_oldPinCtrl.text)) {
      await db.updateAdminPin(auth.hashPin(_newPinCtrl.text));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN updated successfully')));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Old PIN is incorrect'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text('Update Office Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextField(controller: _latCtrl, decoration: const InputDecoration(labelText: 'Latitude')),
        TextField(controller: _lngCtrl, decoration: const InputDecoration(labelText: 'Longitude')),
        TextField(controller: _radCtrl, decoration: const InputDecoration(labelText: 'Radius (m)')),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _updateConfig, child: const Text('Save Location')),
        const Divider(height: 40),
        const Text('Change Admin PIN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextField(controller: _oldPinCtrl, decoration: const InputDecoration(labelText: 'Current PIN'), obscureText: true),
        TextField(controller: _newPinCtrl, decoration: const InputDecoration(labelText: 'New PIN'), obscureText: true),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _updatePin, child: const Text('Update PIN')),
      ],
    );
  }
}

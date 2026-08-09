import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/employee.dart';
import '../models/attendance_session.dart';
import '../models/office_config.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DatabaseService() {
    // Note: Firestore enables offline persistence by default on Android.
    // Ensure persistence is set up in main.dart initialization.
  }

  // --- Admin & Config ---
  Future<bool> adminExists() async {
    try {
      final doc = await _db.collection('config').doc('admin').get(const GetOptions(source: Source.server));
      return doc.exists;
    } catch (e) {
      // In case offline, try cache
      final doc = await _db.collection('config').doc('admin').get();
      return doc.exists;
    }
  }

  Future<void> createAdmin({
    required String adminId,
    required String pinHash,
    required String securityQuestion,
    required String securityAnswer,
    required String recoveryEmail,
  }) async {
    await _db.collection('config').doc('admin').set({
      'adminId': adminId,
      'pinHash': pinHash,
      'securityQuestion': securityQuestion,
      'securityAnswer': securityAnswer,
      'recoveryEmail': recoveryEmail,
    });
  }

  Future<Map<String, dynamic>?> getAdminConfig() async {
    final doc = await _db.collection('config').doc('admin').get();
    return doc.data();
  }

  Future<void> updateAdminPin(String newPinHash) async {
    await _db.collection('config').doc('admin').update({
      'pinHash': newPinHash,
    });
  }

  // --- Office Config ---
  Future<void> setOfficeConfig(OfficeConfig config) async {
    await _db.collection('config').doc('office').set(config.toMap());
  }

  Future<OfficeConfig?> getOfficeConfig() async {
    final doc = await _db.collection('config').doc('office').get();
    if (doc.exists && doc.data() != null) {
      return OfficeConfig.fromMap(doc.data()!);
    }
    return null;
  }

  // --- Employees ---
  Stream<List<Employee>> streamEmployees() {
    return _db.collection('employees').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Employee.fromMap(doc.id, doc.data())).toList();
    });
  }

  Future<Employee?> getEmployee(String employeeId) async {
    final doc = await _db.collection('employees').doc(employeeId).get();
    if (doc.exists && doc.data() != null) {
      return Employee.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  Future<void> addEmployee(Employee employee) async {
    await _db.collection('employees').doc(employee.id).set(employee.toMap());
  }

  Future<void> updateEmployeeStatus(String employeeId, bool isActive) async {
    await _db.collection('employees').doc(employeeId).update({'isActive': isActive});
  }

  Future<void> deleteEmployee(String employeeId) async {
    await _db.collection('employees').doc(employeeId).delete();
  }

  // --- Attendance ---
  Future<void> checkIn(AttendanceSession session) async {
    // We add to sessions collection under the employee
    await _db
        .collection('attendance')
        .doc(session.employeeId)
        .collection('sessions')
        .add(session.toMap());
  }

  Future<void> checkOut(String employeeId, String sessionId, DateTime time, double lat, double lng) async {
    await _db
        .collection('attendance')
        .doc(employeeId)
        .collection('sessions')
        .doc(sessionId)
        .update({
      'checkOutTime': time.toIso8601String(),
      'checkOutLat': lat,
      'checkOutLng': lng,
    });
  }

  Future<AttendanceSession?> getOpenSession(String employeeId) async {
    // Need an open session (checkOutTime is null or not present)
    final qs = await _db
        .collection('attendance')
        .doc(employeeId)
        .collection('sessions')
        .where('checkOutTime', isNull: true)
        .limit(1)
        .get();
    
    if (qs.docs.isNotEmpty) {
      return AttendanceSession.fromMap(qs.docs.first.id, qs.docs.first.data());
    }
    return null;
  }

  Stream<List<AttendanceSession>> streamTodaySessions(String employeeId) {
    // Simplified: getting all sessions and filtering by today client-side for simplicity,
    // or querying by date range. Let's do client-side filter for robustness in this simple app.
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
    
    return _db
        .collection('attendance')
        .doc(employeeId)
        .collection('sessions')
        .where('checkInTime', isGreaterThanOrEqualTo: todayStart)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AttendanceSession.fromMap(doc.id, doc.data())).toList();
    });
  }
  
  Future<List<AttendanceSession>> getSessionsForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    // Loop per-employee instead of using a collectionGroup query. A
    // collectionGroup range query requires an explicit Firestore index to
    // be created first (it throws until you do), which would surprise an
    // admin the first time they view records. Looping per employee needs
    // no special index and is perfectly fine at small-office scale.
    final employeesSnap = await _db.collection('employees').get();
    final List<AttendanceSession> result = [];
    for (final empDoc in employeesSnap.docs) {
      final qs = await _db
          .collection('attendance')
          .doc(empDoc.id)
          .collection('sessions')
          .where('checkInTime', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('checkInTime', isLessThan: end.toIso8601String())
          .get();
      result.addAll(
          qs.docs.map((doc) => AttendanceSession.fromMap(doc.id, doc.data())));
    }
    return result;
  }
}

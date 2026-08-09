class AttendanceSession {
  final String? id;
  final String employeeId;
  final DateTime checkInTime;
  final double checkInLat;
  final double checkInLng;
  final DateTime? checkOutTime;
  final double? checkOutLat;
  final double? checkOutLng;

  AttendanceSession({
    this.id,
    required this.employeeId,
    required this.checkInTime,
    required this.checkInLat,
    required this.checkInLng,
    this.checkOutTime,
    this.checkOutLat,
    this.checkOutLng,
  });

  factory AttendanceSession.fromMap(String id, Map<String, dynamic> data) {
    return AttendanceSession(
      id: id,
      employeeId: data['employeeId'] ?? '',
      checkInTime: DateTime.parse(data['checkInTime']),
      checkInLat: data['checkInLat'] ?? 0.0,
      checkInLng: data['checkInLng'] ?? 0.0,
      checkOutTime: data['checkOutTime'] != null ? DateTime.parse(data['checkOutTime']) : null,
      checkOutLat: data['checkOutLat'],
      checkOutLng: data['checkOutLng'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'checkInTime': checkInTime.toIso8601String(),
      'checkInLat': checkInLat,
      'checkInLng': checkInLng,
      'checkOutTime': checkOutTime?.toIso8601String(),
      'checkOutLat': checkOutLat,
      'checkOutLng': checkOutLng,
    };
  }

  double get durationHours {
    if (checkOutTime == null) return 0.0;
    return checkOutTime!.difference(checkInTime).inMinutes / 60.0;
  }
}

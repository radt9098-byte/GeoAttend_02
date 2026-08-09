class OfficeConfig {
  final double latitude;
  final double longitude;
  final double radiusMeters;

  OfficeConfig({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  factory OfficeConfig.fromMap(Map<String, dynamic> data) {
    return OfficeConfig(
      latitude: data['latitude'] ?? 0.0,
      longitude: data['longitude'] ?? 0.0,
      radiusMeters: (data['radiusMeters'] ?? 100).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
    };
  }
}

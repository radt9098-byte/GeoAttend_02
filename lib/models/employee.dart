class Employee {
  final String id;
  final String name;
  final String pinHash;
  final bool isActive;

  Employee({
    required this.id,
    required this.name,
    required this.pinHash,
    this.isActive = true,
  });

  factory Employee.fromMap(String id, Map<String, dynamic> data) {
    return Employee(
      id: id,
      name: data['name'] ?? '',
      pinHash: data['pinHash'] ?? '',
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'pinHash': pinHash,
      'isActive': isActive,
    };
  }
}

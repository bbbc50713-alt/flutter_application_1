class Customer {
  String id;
  String companyName;
  String companyAddress;
  String phoneNumber;
  String email;
  String batteryNumber;
  String batteryInfo;
  DateTime createdAt;

  Customer({
    required this.id,
    required this.companyName,
    this.companyAddress = '',
    this.phoneNumber = '',
    required this.email,
    required this.batteryNumber,
    this.batteryInfo = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyName': companyName,
      'companyAddress': companyAddress,
      'phoneNumber': phoneNumber,
      'email': email,
      'batteryNumber': batteryNumber,
      'batteryInfo': batteryInfo,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      companyName: map['companyName'],
      companyAddress: map['companyAddress'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'],
      batteryNumber: map['batteryNumber'],
      batteryInfo: map['batteryInfo'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Customer copyWith({
    String? id,
    String? companyName,
    String? companyAddress,
    String? phoneNumber,
    String? email,
    String? batteryNumber,
    String? batteryInfo,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      batteryNumber: batteryNumber ?? this.batteryNumber,
      batteryInfo: batteryInfo ?? this.batteryInfo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

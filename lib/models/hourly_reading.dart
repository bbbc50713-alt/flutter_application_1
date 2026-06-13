import 'cell_voltage.dart';

class HourlyReading {
  int hour;
  List<CellVoltage> voltages;
  DateTime recordedAt;

  HourlyReading({
    required this.hour,
    required this.voltages,
    DateTime? recordedAt,
  }) : recordedAt = recordedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'hour': hour,
      'voltages': voltages.map((v) => v.toMap()).toList(),
      'recordedAt': recordedAt.toIso8601String(),
    };
  }

  factory HourlyReading.fromMap(Map<String, dynamic> map) {
    return HourlyReading(
      hour: map['hour'],
      voltages: (map['voltages'] as List)
          .map((v) => CellVoltage.fromMap(v))
          .toList(),
      recordedAt: DateTime.parse(map['recordedAt']),
    );
  }

  bool hasCriticalVoltage() {
    return voltages.any((v) => v.status == VoltageStatus.critical);
  }

  double? getMinVoltage() {
    if (voltages.isEmpty) return null;
    return voltages.map((v) => v.voltage).reduce((a, b) => a < b ? a : b);
  }
}

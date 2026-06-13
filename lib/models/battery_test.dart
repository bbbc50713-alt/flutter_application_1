import 'hourly_reading.dart';

enum TestStatus {
  ongoing,
  completed,
  stopped,
}

class BatteryTest {
  String id;
  String batteryNumber;
  String batteryInfo;
  String batteryImagePath;
  String customerId;
  String providerId;
  DateTime startTime;
  DateTime? endTime;
  TestStatus status;
  List<HourlyReading> readings;
  int cellCount;
  int testDuration;

  BatteryTest({
    required this.id,
    required this.batteryNumber,
    required this.batteryInfo,
    required this.batteryImagePath,
    required this.customerId,
    required this.providerId,
    required this.startTime,
    this.endTime,
    this.status = TestStatus.ongoing,
    this.readings = const [],
    this.cellCount = 24,
    this.testDuration = 6,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batteryNumber': batteryNumber,
      'batteryInfo': batteryInfo,
      'batteryImagePath': batteryImagePath,
      'customerId': customerId,
      'providerId': providerId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'status': status.index,
      'readings': readings.map((r) => r.toMap()).toList(),
      'cellCount': cellCount,
      'testDuration': testDuration,
    };
  }

  factory BatteryTest.fromMap(Map<String, dynamic> map) {
    return BatteryTest(
      id: map['id'],
      batteryNumber: map['batteryNumber'],
      batteryInfo: map['batteryInfo'] ?? '',
      batteryImagePath: map['batteryImagePath'],
      customerId: map['customerId'],
      providerId: map['providerId'],
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      status: TestStatus.values[map['status']],
      readings: (map['readings'] as List? ?? [])
          .map((r) => HourlyReading.fromMap(r))
          .toList(),
      cellCount: map['cellCount'] ?? 24,
      testDuration: map['testDuration'] ?? 6,
    );
  }

  // Backward compatibility getter - timer interval is always 60 minutes (1 hour)
  int get timerIntervalMinutes => 60;

  Duration get elapsedTime {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  bool get isComplete => readings.length >= testDuration;

  int get currentHour => readings.length + 1;

  bool shouldStopDueToLowVoltage() {
    if (readings.isEmpty) return false;
    final lastReading = readings.last;
    return lastReading.hasCriticalVoltage();
  }

  BatteryTest copyWith({
    String? id,
    String? batteryNumber,
    String? batteryInfo,
    String? batteryImagePath,
    String? customerId,
    String? providerId,
    DateTime? startTime,
    DateTime? endTime,
    TestStatus? status,
    List<HourlyReading>? readings,
    int? cellCount,
    int? testDuration,
  }) {
    return BatteryTest(
      id: id ?? this.id,
      batteryNumber: batteryNumber ?? this.batteryNumber,
      batteryInfo: batteryInfo ?? this.batteryInfo,
      batteryImagePath: batteryImagePath ?? this.batteryImagePath,
      customerId: customerId ?? this.customerId,
      providerId: providerId ?? this.providerId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      readings: readings ?? this.readings,
      cellCount: cellCount ?? this.cellCount,
      testDuration: testDuration ?? this.testDuration,
    );
  }
}

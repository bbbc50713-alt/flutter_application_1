enum VoltageStatus {
  normal, // > 1.95V - GREEN
  warning, // 1.70V - 1.95V - YELLOW
  critical, // < 1.70V - RED
}

class CellVoltage {
  int cellNumber;
  double voltage;
  VoltageStatus status;

  CellVoltage({
    required this.cellNumber,
    required this.voltage,
    required this.status,
  });

  static VoltageStatus getStatus(double voltage) {
    if (voltage < 1.70) {
      return VoltageStatus.critical;
    } else if (voltage <= 1.95) {
      return VoltageStatus.warning;
    } else {
      return VoltageStatus.normal;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'cellNumber': cellNumber,
      'voltage': voltage,
      'status': status.index,
    };
  }

  factory CellVoltage.fromMap(Map<String, dynamic> map) {
    return CellVoltage(
      cellNumber: map['cellNumber'],
      voltage: map['voltage'],
      status: VoltageStatus.values[map['status']],
    );
  }
}

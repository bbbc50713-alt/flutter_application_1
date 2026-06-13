import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service.dart';

class TestProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<BatteryTest> _ongoingTests = [];
  ServiceProvider? _currentProvider;
  bool _isLoading = false;

  List<BatteryTest> get ongoingTests => _ongoingTests;
  ServiceProvider? get currentProvider => _currentProvider;
  bool get isLoading => _isLoading;

  TestProvider() {
    loadOngoingTests();
    loadProvider();
  }

  Future<void> loadOngoingTests() async {
    _isLoading = true;
    notifyListeners();

    _ongoingTests = await _db.getOngoingTests();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadProvider() async {
    _currentProvider = await _db.getProvider();
    notifyListeners();
  }

  Future<void> saveProvider(ServiceProvider provider) async {
    await _db.insertProvider(provider);
    _currentProvider = provider;
    notifyListeners();
  }

  Future<String> startNewTest({
    required Customer customer,
    required String imagePath,
    int cellCount = 24,
    int testDuration = 6,
  }) async {
    if (_currentProvider == null) return '';

    final test = BatteryTest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      batteryNumber: customer.batteryNumber,
      batteryInfo: customer.batteryInfo,
      batteryImagePath: imagePath,
      customerId: customer.id,
      providerId: _currentProvider!.id,
      startTime: DateTime.now(),
      status: TestStatus.ongoing,
      readings: [],
      cellCount: cellCount,
      testDuration: testDuration,
    );

    await _db.insertBatteryTest(test);
    await loadOngoingTests();
    return test.id;
  }

  Future<void> addHourlyReading(String testId, HourlyReading reading) async {
    final test = await _db.getBatteryTestById(testId);
    if (test == null) return;

    final updatedReadings = [...test.readings, reading];
    final updatedTest = test.copyWith(readings: updatedReadings);

    await _db.updateBatteryTest(updatedTest);
    await loadOngoingTests();
  }

  Future<void> stopTest(String testId) async {
    final test = await _db.getBatteryTestById(testId);
    if (test == null) return;

    final updatedTest = test.copyWith(
      status: TestStatus.stopped,
      endTime: DateTime.now(),
    );

    await _db.updateBatteryTest(updatedTest);
    await loadOngoingTests();
  }

  Future<void> completeTest(String testId) async {
    final test = await _db.getBatteryTestById(testId);
    if (test == null) return;

    final updatedTest = test.copyWith(
      status: TestStatus.completed,
      endTime: DateTime.now(),
    );

    await _db.updateBatteryTest(updatedTest);
    await loadOngoingTests();
  }

  Future<void> deleteTest(String testId) async {
    await _db.deleteBatteryTest(testId);
    await loadOngoingTests();
  }

  BatteryTest? getTestById(String id) {
    try {
      return _ongoingTests.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }
}

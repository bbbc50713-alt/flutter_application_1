import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bdl_database.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE providers(
        id TEXT PRIMARY KEY,
        companyName TEXT NOT NULL,
        address TEXT,
        phoneNumber TEXT,
        email TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE customers(
        id TEXT PRIMARY KEY,
        companyName TEXT NOT NULL,
        companyAddress TEXT,
        phoneNumber TEXT,
        email TEXT NOT NULL,
        batteryNumber TEXT NOT NULL,
        batteryInfo TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE battery_tests(
        id TEXT PRIMARY KEY,
        batteryNumber TEXT NOT NULL,
        batteryInfo TEXT,
        batteryImagePath TEXT NOT NULL,
        customerId TEXT NOT NULL,
        providerId TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT,
        status INTEGER NOT NULL,
        readings TEXT NOT NULL,
        cellCount INTEGER NOT NULL DEFAULT 24,
        testDuration INTEGER NOT NULL DEFAULT 6,
        timerIntervalMinutes INTEGER NOT NULL DEFAULT 60,
        FOREIGN KEY (customerId) REFERENCES customers(id),
        FOREIGN KEY (providerId) REFERENCES providers(id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE battery_tests ADD COLUMN cellCount INTEGER NOT NULL DEFAULT 24');
      await db.execute('ALTER TABLE battery_tests ADD COLUMN testDuration INTEGER NOT NULL DEFAULT 6');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE battery_tests ADD COLUMN timerIntervalMinutes INTEGER NOT NULL DEFAULT 60');
    }
  }

  // Provider operations
  Future<void> insertProvider(ServiceProvider provider) async {
    final db = await database;
    await db.insert(
      'providers',
      provider.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ServiceProvider?> getProvider() async {
    final db = await database;
    final maps = await db.query('providers', limit: 1);
    if (maps.isNotEmpty) {
      return ServiceProvider.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateProvider(ServiceProvider provider) async {
    final db = await database;
    await db.update(
      'providers',
      provider.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [provider.id],
    );
  }

  // Customer operations
  Future<void> insertCustomer(Customer customer) async {
    final db = await database;
    await db.insert(
      'customers',
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final maps = await db.query('customers', orderBy: 'createdAt DESC');
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final db = await database;
    final maps = await db.query(
      'customers',
      where: 'companyName LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  Future<Customer?> findDuplicateCustomer(String companyName, String email) async {
    final db = await database;
    final maps = await db.query(
      'customers',
      where: 'companyName = ? AND email = ?',
      whereArgs: [companyName, email],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await database;
    await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<Customer?> getCustomerById(String id) async {
    final db = await database;
    final maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  // Battery Test operations
  Future<void> insertBatteryTest(BatteryTest test) async {
    final db = await database;
    await db.insert(
      'battery_tests',
      {
        ...test.toMap(),
        'readings': jsonEncode(test.readings.map((r) => r.toMap()).toList()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateBatteryTest(BatteryTest test) async {
    final db = await database;
    await db.update(
      'battery_tests',
      {
        ...test.toMap(),
        'readings': jsonEncode(test.readings.map((r) => r.toMap()).toList()),
      },
      where: 'id = ?',
      whereArgs: [test.id],
    );
  }

  Future<List<BatteryTest>> getOngoingTests() async {
    final db = await database;
    final maps = await db.query(
      'battery_tests',
      where: 'status = ?',
      whereArgs: [TestStatus.ongoing.index],
      orderBy: 'startTime DESC',
    );
    return maps.map((map) => _batteryTestFromMap(map)).toList();
  }

  Future<List<BatteryTest>> getAllTests() async {
    final db = await database;
    final maps = await db.query('battery_tests', orderBy: 'startTime DESC');
    return maps.map((map) => _batteryTestFromMap(map)).toList();
  }

  Future<BatteryTest?> getBatteryTestById(String id) async {
    final db = await database;
    final maps = await db.query(
      'battery_tests',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return _batteryTestFromMap(maps.first);
    }
    return null;
  }

  BatteryTest _batteryTestFromMap(Map<String, dynamic> map) {
    final readingsJson = jsonDecode(map['readings'] as String) as List;
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
      readings: readingsJson.map((r) => HourlyReading.fromMap(r)).toList(),
      cellCount: map['cellCount'] ?? 24,
      testDuration: map['testDuration'] ?? 6,
    );
  }

  Future<void> deleteBatteryTest(String id) async {
    final db = await database;
    await db.delete(
      'battery_tests',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

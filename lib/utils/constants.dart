import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF1976D2);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color accent = Color(0xFF4CAF50);

  // Voltage status colors
  static const Color voltageNormal = Color(0xFF4CAF50); // GREEN > 1.95V
  static const Color voltageWarning = Color(0xFFFFC107); // YELLOW 1.70-1.95V
  static const Color voltageCritical = Color(0xFFF44336); // RED < 1.70V

  // Alarm colors
  static const Color alarmGreen = Color(0xFF4CAF50);
  static const Color alarmRed = Color(0xFFF44336);

  // Light theme colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color onSurface = Color(0xFF212121);
  static const Color onBackground = Color(0xFF212121);

  // Dark theme colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);
  static const Color darkOnSurface = Colors.white;
  static const Color darkOnBackground = Colors.white;
  static const Color darkPrimary = Color(0xFF90CAF9);

  // Semantic colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);
}

class AppConstants {
  static const int totalCells = 24;
  static const int totalHours = 6;
  static const int minCells = 6;
  static const int maxCells = 24;
  static const int minHours = 1;
  static const int maxHours = 6;
  static const double voltageThresholdCritical = 1.70;
  static const double voltageThresholdWarning = 1.95;
  static const Duration hourTimerDuration = Duration(hours: 1);
}

class AppStrings {
  static const String appName = 'BDL - Battery Discharge Logger';
  static const String version = 'v3.0';

  // Buttons
  static const String startTest = 'Start Test';
  static const String stopTest = 'Stop Test';
  static const String done = 'DONE';
  static const String sendReport = 'Send Report';
  static const String cancel = 'Cancel';
  static const String ok = 'OK';

  // Labels
  static const String providerInfo = 'Service Provider Info';
  static const String customerInfo = 'Customer Info';
  static const String ongoingTests = 'Ongoing Tests';
  static const String dataEntry = 'Data Entry';
  static const String testReport = 'Test Report';

  // Fields
  static const String companyName = 'Company Name';
  static const String address = 'Address';
  static const String phoneNumber = 'Phone Number';
  static const String email = 'Email';
  static const String batteryNumber = 'Battery #';
  static const String batteryInfo = 'Battery Info';

  // Validation
  static const String requiredField = 'This field is required';
  static const String invalidEmail = 'Please enter a valid email';
}

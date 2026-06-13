import 'package:intl/intl.dart';

class Formatters {
  static String formatVoltage(double voltage) {
    return '${voltage.toStringAsFixed(2)}V';
  }

  static String formatVoltageInput(String input) {
    if (input.isEmpty) return '';
    if (input.length == 1) return '${input[0]}.';
    if (input.length == 2) return '${input[0]}.${input[1]}';
    return '${input[0]}.${input.substring(1)}';
  }

  static double? parseVoltageInput(String input) {
    if (input.length < 3) return null;
    try {
      return double.parse('${input[0]}.${input.substring(1)}');
    } catch (e) {
      return null;
    }
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  static String formatShortDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }
}

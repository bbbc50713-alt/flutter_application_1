import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../utils/utils.dart';

/// Service for providing user feedback through toasts and haptic feedback
class FeedbackService {
  FeedbackService._();

  /// Show a success toast notification
  static void successToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show an error toast notification
  static void errorToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.voltageCritical,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show a warning toast notification
  static void warningToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.voltageWarning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show an info toast notification
  static void infoToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Light impact haptic feedback for tap interactions
  static Future<void> hapticTap() async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        await Vibration.vibrate(duration: 10);
      }
    } catch (_) {
      // Vibration not supported on this device
    }
  }

  /// Medium impact haptic feedback for selection changes
  static Future<void> hapticSelection() async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        await Vibration.vibrate(duration: 20);
      }
    } catch (_) {
      // Vibration not supported on this device
    }
  }

  /// Success haptic feedback pattern
  static Future<void> hapticSuccess() async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        // Short burst pattern for success
        await Vibration.vibrate(pattern: [0, 50, 50, 50]);
      }
    } catch (_) {
      // Vibration not supported on this device
    }
  }

  /// Error haptic feedback pattern
  static Future<void> hapticError() async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        // Longer buzz for error
        await Vibration.vibrate(duration: 100);
      }
    } catch (_) {
      // Vibration not supported on this device
    }
  }

  /// Warning haptic feedback pattern
  static Future<void> hapticWarning() async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        // Double tap pattern for warning
        await Vibration.vibrate(pattern: [0, 30, 50, 30]);
      }
    } catch (_) {
      // Vibration not supported on this device
    }
  }
}

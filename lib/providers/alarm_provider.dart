import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class AlarmProvider extends ChangeNotifier {
  static const _systemSoundChannel = MethodChannel('com.example.flutter_application_1/system_sound');

  final Map<String, Timer> _hourTimers = {};
  final Map<String, Timer> _alarmLoops = {};
  final Map<String, bool> _isAlarming = {};
  final Map<String, Duration> _remainingTimes = {};
  final Map<String, DateTime> _endTimes = {};
  final Map<String, AudioPlayer> _audioPlayers = {}; // Per-test audio players
  final Map<String, String> _lastDisplayedTime = {}; // Track displayed time to reduce rebuilds
  final Map<String, Duration> _timerDurations = {}; // Store per-test timer durations
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _notificationsInitialized = false;

  bool isAlarming(String testId) => _isAlarming[testId] ?? false;
  Duration? getRemainingTime(String testId) => _remainingTimes[testId];

  AlarmProvider() {
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    if (_notificationsInitialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    if (Platform.isAndroid) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }

    _notificationsInitialized = true;
  }

  void startHourTimer(String testId, {VoidCallback? onAlarm, Duration duration = const Duration(hours: 1)}) {
    _hourTimers[testId]?.cancel();
    _alarmLoops[testId]?.cancel();
    _isAlarming[testId] = false;
    _timerDurations[testId] = duration; // Store duration for reset
    _endTimes[testId] = DateTime.now().add(duration);
    _remainingTimes[testId] = duration;
    _lastDisplayedTime.remove(testId); // Clear previous display time

    _hourTimers[testId] = Timer.periodic(const Duration(seconds: 1), (timer) {
      final endTime = _endTimes[testId];
      if (endTime == null) {
        timer.cancel();
        return;
      }

      final remaining = endTime.difference(DateTime.now());
      if (remaining.isNegative || remaining.inSeconds <= 0) {
        timer.cancel();
        _remainingTimes[testId] = Duration.zero;
        _lastDisplayedTime.remove(testId);
        _triggerAlarm(testId);
        onAlarm?.call();
      } else {
        _remainingTimes[testId] = remaining;

        // Only notify listeners when displayed time changes (MM:SS format)
        final displayTime = '${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';
        if (_lastDisplayedTime[testId] != displayTime) {
          _lastDisplayedTime[testId] = displayTime;
          if (hasListeners) {
            notifyListeners();
          }
        }
      }
    });

    _scheduleNotification(testId);
    if (hasListeners) {
      notifyListeners();
    }
  }

  Future<void> _scheduleNotification(String testId) async {
    if (!_notificationsInitialized) {
      await _initNotifications();
    }

    final endTime = _endTimes[testId];
    if (endTime == null) return;

    final scheduledDate = tz.TZDateTime.from(endTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'bdl_hour_timer',
      'BDL Hour Timer',
      channelDescription: 'Notification when hour timer expires',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _notifications.zonedSchedule(
        testId.hashCode,
        'BDL Hour Timer',
        'Time to enter voltage readings for your battery test!',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: testId,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  void _triggerAlarm(String testId) {
    _isAlarming[testId] = true;
    if (hasListeners) {
      notifyListeners();
    }

    _alarmLoops[testId]?.cancel();

    _startContinuousAlarm(testId);
  }

  Future<void> _startContinuousAlarm(String testId) async {
    // Use system alarm sound instead of custom alarm.mp3
    await _playSystemAlarmSound(testId);
    _startVibrationLoop(testId);
  }

  /// Play system default alarm sound via platform Method Channel
  /// Uses Android RingtoneManager.TYPE_ALARM for reliable system sound playback
  Future<void> _playSystemAlarmSound(String testId) async {
    try {
      await _systemSoundChannel.invokeMethod('playAlarmSound');
      debugPrint('System alarm sound playing for test $testId');
    } catch (e) {
      debugPrint('Error playing system alarm for test $testId: $e');
    }
  }

  /// Stop system alarm sound
  Future<void> _stopSystemAlarmSound() async {
    try {
      await _systemSoundChannel.invokeMethod('stopAlarmSound');
    } catch (e) {
      debugPrint('Error stopping system alarm: $e');
    }
  }

  // ============================================================
  // Original alarm.mp3 playback logic (preserved but not used)
  // ============================================================
  // Future<void> _startLoopingAudio(String testId) async {
  //   // Create a dedicated AudioPlayer for this test
  //   _audioPlayers[testId]?.dispose();
  //   final player = AudioPlayer();
  //   _audioPlayers[testId] = player;
  //
  //   try {
  //     // Use alarm audio stream for louder playback that bypasses silent mode
  //     await player.setAudioContext(
  //       AudioContext(
  //         android: AudioContextAndroid(
  //           isSpeakerphoneOn: true,
  //           stayAwake: true,
  //           contentType: AndroidContentType.music,
  //           usageType: AndroidUsageType.alarm,
  //           audioFocus: AndroidAudioFocus.gainTransient,
  //         ),
  //         iOS: AudioContextIOS(
  //           category: AVAudioSessionCategory.playback,
  //           options: [
  //             AVAudioSessionOptions.duckOthers,
  //             AVAudioSessionOptions.defaultToSpeaker,
  //           ],
  //         ),
  //       ),
  //     );
  //
  //     await player.setReleaseMode(ReleaseMode.loop);
  //     await player.setVolume(1.0);
  //     await player.play(AssetSource('sounds/alarm.mp3'));
  //     debugPrint('Alarm sound playing for test $testId');
  //   } catch (e) {
  //     debugPrint('Error playing alarm for test $testId: $e');
  //   }
  // }

  void _startVibrationLoop(String testId) {
    _alarmLoops[testId]?.cancel();

    // Vibrate immediately, then repeat while alarming
    _vibrateOnce();
    _alarmLoops[testId] = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isAlarming[testId] == true) {
        _vibrateOnce();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _vibrateOnce() async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        Vibration.vibrate(duration: 800);
      }
    } catch (e) {
      debugPrint('Error vibrating: $e');
    }
  }

  void resetHourTimer(String testId, {VoidCallback? onAlarm, Duration? duration}) {
    _stopAlarmLoop(testId);
    _cancelNotification(testId);
    // Use stored duration if not provided
    final timerDuration = duration ?? _timerDurations[testId] ?? const Duration(hours: 1);
    startHourTimer(testId, onAlarm: onAlarm, duration: timerDuration);
  }

  void stopAlarm(String testId) {
    _hourTimers[testId]?.cancel();
    _hourTimers.remove(testId);
    _stopAlarmLoop(testId);
    _isAlarming[testId] = false;
    _remainingTimes.remove(testId);
    _endTimes.remove(testId);
    _lastDisplayedTime.remove(testId);
    _timerDurations.remove(testId);

    _cancelNotification(testId);
    if (hasListeners) {
      notifyListeners();
    }
  }

  void acknowledgeAlarm(String testId) {
    _stopAlarmLoop(testId);
    _isAlarming[testId] = false;
    if (hasListeners) {
      notifyListeners();
    }
  }

  void _stopAlarmLoop(String testId) {
    // Cancel this test's vibration timer
    _alarmLoops[testId]?.cancel();
    _alarmLoops.remove(testId);

    // Stop system alarm sound
    _stopSystemAlarmSound();

    // Stop and dispose this test's dedicated audio player (if any)
    try {
      _audioPlayers[testId]?.stop();
      _audioPlayers[testId]?.dispose();
      _audioPlayers.remove(testId);
    } catch (e) {
      debugPrint('Error stopping audio for test $testId: $e');
    }

    // Only cancel vibration if NO other tests are currently alarming
    final hasOtherAlarms = _isAlarming.entries
        .where((entry) => entry.key != testId && entry.value == true)
        .isNotEmpty;

    if (!hasOtherAlarms) {
      try {
        Vibration.cancel();
      } catch (e) {
        debugPrint('Error canceling vibration: $e');
      }
    }
  }

  Future<void> _cancelNotification(String testId) async {
    try {
      await _notifications.cancel(testId.hashCode);
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }

  void stopAllAlarms() {
    for (final testId in _hourTimers.keys.toList()) {
      _hourTimers[testId]?.cancel();
      _alarmLoops[testId]?.cancel();
      _isAlarming[testId] = false;
    }
    _alarmLoops.clear();

    // Stop system alarm sound
    _stopSystemAlarmSound();

    // Dispose all per-test audio players
    for (final player in _audioPlayers.values) {
      try {
        player.stop();
        player.dispose();
      } catch (e) {
        debugPrint('Error disposing audio player: $e');
      }
    }
    _audioPlayers.clear();

    try {
      Vibration.cancel();
    } catch (e) {
      debugPrint('Error canceling vibration: $e');
    }

    _remainingTimes.clear();
    _endTimes.clear();
    _lastDisplayedTime.clear();
    _timerDurations.clear();

    _notifications.cancelAll();
    if (hasListeners) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopAllAlarms();
    super.dispose();
  }
}

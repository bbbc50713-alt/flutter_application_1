import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/utils.dart';

class TestListItem extends StatelessWidget {
  final BatteryTest test;
  final VoidCallback? onTap;

  const TestListItem({
    super.key,
    required this.test,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AlarmProvider>(
      builder: (context, alarmProvider, child) {
        final isAlarming = alarmProvider.isAlarming(test.id);
        final remainingTime = alarmProvider.getRemainingTime(test.id);
        final hoursCompleted = test.readings.length;

        return Semantics(
          label: 'Test for battery ${test.batteryNumber}',
          hint: 'Tap to enter voltage readings',
          value: '$hoursCompleted of ${test.testDuration} hours completed. '
              '${isAlarming ? "Alarm active. " : ""}'
              '${remainingTime != null ? "${Formatters.formatShortDuration(remainingTime)} remaining in current hour." : ""}',
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Battery Icon
                        ExcludeSemantics(
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.battery_full,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Battery Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                test.batteryNumber,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (test.batteryInfo.isNotEmpty)
                                Text(
                                  test.batteryInfo,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),

                        // Timers
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Hour Timer (Countdown)
                            Row(
                              children: [
                                Icon(
                                  Icons.timer,
                                  size: 16,
                                  color: isAlarming ? AppColors.alarmRed : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  remainingTime != null
                                      ? Formatters.formatShortDuration(remainingTime)
                                      : _formatFallbackTime(60),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isAlarming ? AppColors.alarmRed : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            // Total Time
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  Formatters.formatDuration(test.elapsedTime),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(width: 16),

                        // Alarm Indicator with animation
                        _AnimatedAlarmIndicator(isAlarming: isAlarming),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Progress indicator
                    _buildProgressIndicator(hoursCompleted),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _formatFallbackTime(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:00';
    }
    return '${minutes.toString().padLeft(2, '0')}:00';
  }

  Widget _buildProgressIndicator(int hoursCompleted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Progress: $hoursCompleted/${test.testDuration} hours',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            Text(
              '${((hoursCompleted / test.testDuration) * 100).round()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: hoursCompleted / test.testDuration,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

/// Animated alarm indicator with pulsing effect
class _AnimatedAlarmIndicator extends StatefulWidget {
  final bool isAlarming;

  const _AnimatedAlarmIndicator({required this.isAlarming});

  @override
  State<_AnimatedAlarmIndicator> createState() => _AnimatedAlarmIndicatorState();
}

class _AnimatedAlarmIndicatorState extends State<_AnimatedAlarmIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 4, end: 12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isAlarming) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_AnimatedAlarmIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAlarming && !oldWidget.isAlarming) {
      _controller.repeat(reverse: true);
    } else if (!widget.isAlarming && oldWidget.isAlarming) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isAlarming ? _scaleAnimation.value : 1.0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isAlarming ? AppColors.alarmRed : AppColors.alarmGreen,
                boxShadow: widget.isAlarming
                    ? [
                        BoxShadow(
                          color: AppColors.alarmRed.withOpacity(0.5),
                          blurRadius: _glowAnimation.value,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: widget.isAlarming
                  ? const Icon(
                      Icons.notifications_active,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/feedback_service.dart';
import '../utils/utils.dart';
import '../widgets/provider_info_dialog.dart';
import '../widgets/customer_info_dialog.dart';
import '../widgets/test_list_item.dart';
import '../widgets/alarm_dialog.dart';
import 'data_entry_screen.dart';
import 'report_screen.dart';

class TestListScreen extends StatefulWidget {
  const TestListScreen({super.key});

  @override
  State<TestListScreen> createState() => _TestListScreenState();
}

class _TestListScreenState extends State<TestListScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final testProvider = context.read<TestProvider>();
      await testProvider.loadOngoingTests();

      // Restore timers for all ongoing tests
      final alarmProvider = context.read<AlarmProvider>();
      for (final test in testProvider.ongoingTests) {
        if (alarmProvider.getRemainingTime(test.id) == null) {
          alarmProvider.startHourTimer(
            test.id,
            duration: const Duration(hours: 1),
            onAlarm: () {
              if (mounted) {
                AlarmDialog.show(context, test.id, test.batteryNumber);
              }
            },
          );
        }
      }
    });
  }

  Future<void> _onStartTest() async {
    final testProvider = context.read<TestProvider>();

    // Step 1: Show Provider Info Dialog
    final provider = await ProviderInfoDialog.show(
      context,
      existing: testProvider.currentProvider,
    );
    if (provider == null) return;

    FeedbackService.hapticTap();

    // Step 2: Show Customer Info Dialog
    final customerResult = await CustomerInfoDialog.show(context);
    if (customerResult == null) return;

    FeedbackService.hapticTap();

    // Step 3: Take Battery Photo
    final imagePath = await _takeBatteryPhoto();
    if (imagePath == null) return;

    // Step 4: Create Test and get its ID
    String newTestId;
    try {
      newTestId = await testProvider.startNewTest(
        customer: customerResult.customer,
        imagePath: imagePath,
        cellCount: customerResult.cellCount,
        testDuration: customerResult.testDuration,
      );

      if (newTestId.isEmpty) {
        throw Exception('Failed to create test');
      }

      if (mounted) {
        FeedbackService.hapticSuccess();
        FeedbackService.successToast(context, 'Test started for ${customerResult.customer.batteryNumber}');
      }
    } catch (e) {
      if (mounted) {
        FeedbackService.hapticError();
        FeedbackService.errorToast(context, ErrorMessages.testCreationFailed);
      }
      return;
    }

    // Step 5: Start Timer with the returned test ID
    final alarmProvider = context.read<AlarmProvider>();
    alarmProvider.startHourTimer(
      newTestId,
      duration: const Duration(hours: 1),
      onAlarm: () {
        if (mounted) {
          final test = testProvider.getTestById(newTestId);
          if (test != null) {
            AlarmDialog.show(context, test.id, test.batteryNumber);
          }
        }
      },
    );
  }

  Future<String?> _takeBatteryPhoto() async {
    try {
      // Windows doesn't support camera, use gallery instead
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final XFile? photo = await _imagePicker.pickImage(
          source: ImageSource.gallery,
        );
        return photo?.path;
      } else {
        // Mobile platforms support camera
        final XFile? photo = await _imagePicker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.rear,
        );
        return photo?.path;
      }
    } catch (e) {
      if (mounted) {
        FeedbackService.errorToast(context, ErrorMessages.fromException(e as Exception));
      }
      return null;
    }
  }

  Future<void> _onStopTest() async {
    final testProvider = context.read<TestProvider>();
    final alarmProvider = context.read<AlarmProvider>();
    final ongoingTests = testProvider.ongoingTests;

    if (ongoingTests.isEmpty) {
      FeedbackService.hapticWarning();
      FeedbackService.infoToast(context, 'No ongoing tests to stop');
      return;
    }

    FeedbackService.hapticTap();

    final result = await showDialog<BatteryTest?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.stop_circle, color: AppColors.voltageCritical),
            SizedBox(width: 8),
            Text('Stop Test'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select a test to stop and generate report:'),
            const SizedBox(height: 16),
            ...ongoingTests.map((test) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.battery_std, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          test.batteryNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Hour ${test.currentHour} of ${test.testDuration}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, test),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.voltageCritical,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Text('Stop'),
                  ),
                ],
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result != null) {
      await testProvider.stopTest(result.id);
      alarmProvider.stopAlarm(result.id);
      FeedbackService.hapticSuccess();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportScreen(test: result),
          ),
        );
      }
    }
  }

  void _onTestItemTap(BatteryTest test) {
    FeedbackService.hapticTap();

    // Check if test is already complete
    if (test.isComplete) {
      FeedbackService.hapticWarning();
      FeedbackService.infoToast(
        context,
        'Test is complete. View the report instead.',
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReportScreen(test: test),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DataEntryScreen(test: test),
      ),
    ).then((result) {
      if (result == true) {
        // Fetch updated test from provider to ensure we have latest data
        final updatedTest = context.read<TestProvider>().getTestById(test.id);
        if (updatedTest != null) {
          // Reset timer with test's configured interval
          context.read<AlarmProvider>().resetHourTimer(
            updatedTest.id,
            duration: const Duration(hours: 1),
            onAlarm: () {
              if (mounted) {
                AlarmDialog.show(context, updatedTest.id, updatedTest.batteryNumber);
              }
            },
          );
        }
      }
    });
  }

  void _toggleTheme() {
    final themeProvider = context.read<ThemeProvider>();
    themeProvider.toggleTheme();
    FeedbackService.hapticSelection();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('${AppStrings.appName} ${AppStrings.version}'),
        centerTitle: true,
        actions: [
          // Theme toggle button
          IconButton(
            onPressed: _toggleTheme,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return RotationTransition(
                  turns: Tween<double>(begin: 0.5, end: 1).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
                key: ValueKey(isDarkMode),
              ),
            ),
            tooltip: isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _AnimatedButton(
                    onPressed: _onStartTest,
                    icon: Icons.play_arrow,
                    label: AppStrings.startTest,
                    backgroundColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _AnimatedButton(
                    onPressed: _onStopTest,
                    icon: Icons.stop,
                    label: AppStrings.stopTest,
                    backgroundColor: AppColors.voltageCritical,
                  ),
                ),
              ],
            ),
          ),

          // Ongoing Tests List
          Expanded(
            child: Consumer<TestProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return _buildLoadingSkeleton();
                }

                if (provider.ongoingTests.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: provider.ongoingTests.length,
                  itemBuilder: (context, index) {
                    final test = provider.ongoingTests[index];
                    return TestListItem(
                      test: test,
                      onTap: () => _onTestItemTap(test),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: _ShimmerLoading(
            isLoading: true,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Battery icon skeleton
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 16,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 12,
                            width: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.battery_charging_full,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No ongoing tests',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Start Test" to begin',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated button with scale effect
class _AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color backgroundColor;

  const _AnimatedButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: ElevatedButton.icon(
          onPressed: null, // Handled by GestureDetector
          icon: Icon(widget.icon),
          label: Text(widget.label),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.backgroundColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            disabledBackgroundColor: widget.backgroundColor,
            disabledForegroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Shimmer loading effect widget
class _ShimmerLoading extends StatefulWidget {
  final bool isLoading;
  final Widget child;

  const _ShimmerLoading({
    required this.isLoading,
    required this.child,
  });

  @override
  State<_ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<_ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0x00000000),
                Color(0x1A000000),
                Color(0x00000000),
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

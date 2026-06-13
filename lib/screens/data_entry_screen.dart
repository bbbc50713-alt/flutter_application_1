import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/feedback_service.dart';
import '../utils/utils.dart';
import 'report_screen.dart';

class VoltageInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    String display;
    if (digits.length == 1) {
      display = digits;
    } else {
      display = '${digits[0]}.${digits.substring(1)}';
    }

    return TextEditingValue(
      text: display,
      selection: TextSelection.collapsed(offset: display.length),
    );
  }
}

class DataEntryScreen extends StatefulWidget {
  final BatteryTest test;

  const DataEntryScreen({
    super.key,
    required this.test,
  });

  @override
  State<DataEntryScreen> createState() => _DataEntryScreenState();
}

class _DataEntryScreenState extends State<DataEntryScreen> {
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  int _currentHour = 1;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _currentHour = widget.test.currentHour;
    _initializeControllers();
  }

  void _initializeControllers() {
    for (int i = 0; i < widget.test.cellCount; i++) {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onVoltageChanged(int index, String value) {
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.length > 3) {
      final formatted = '${digitsOnly[0]}.${digitsOnly.substring(1, 3)}';
      _controllers[index].text = formatted;
      _controllers[index].selection = TextSelection.fromPosition(
        TextPosition(offset: formatted.length),
      );
    }

    setState(() => _hasUnsavedChanges = true);

    if (digitsOnly.length == 3 && index < widget.test.cellCount - 1) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    }
  }

  /// Get voltage status text for accessibility
  String _getVoltageStatusText(double voltage) {
    if (voltage < AppConstants.voltageThresholdCritical) {
      return 'Critical - voltage too low';
    } else if (voltage <= AppConstants.voltageThresholdWarning) {
      return 'Warning - voltage below normal';
    } else {
      return 'Normal';
    }
  }

  /// Get voltage status color
  Color _getVoltageStatusColor(double voltage) {
    if (voltage < AppConstants.voltageThresholdCritical) {
      return AppColors.voltageCritical;
    } else if (voltage <= AppConstants.voltageThresholdWarning) {
      return AppColors.voltageWarning;
    } else {
      return AppColors.voltageNormal;
    }
  }

  Future<void> _onDone() async {
    // Validate hour limit
    if (_currentHour > widget.test.testDuration) {
      FeedbackService.hapticWarning();
      if (mounted) {
        FeedbackService.errorToast(
          context,
          'Test duration is ${widget.test.testDuration} hours. Cannot enter data for hour $_currentHour.',
        );
      }
      return;
    }

    // Validate all fields are filled
    final unfilledCells = <int>[];
    for (int i = 0; i < widget.test.cellCount; i++) {
      final digits = _controllers[i].text.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length != 3) {
        unfilledCells.add(i + 1);
      }
    }

    if (unfilledCells.isNotEmpty) {
      FeedbackService.hapticWarning();
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Incomplete Data'),
          content: Text(
            'The following cells are not filled: ${unfilledCells.take(5).join(", ")}${unfilledCells.length > 5 ? "..." : ""}\n\nDo you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continue Editing'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save Anyway'),
            ),
          ],
        ),
      );

      if (shouldContinue != true) return;
    }

    setState(() => _isSaving = true);

    // Create voltage readings
    final voltages = <CellVoltage>[];
    for (int i = 0; i < widget.test.cellCount; i++) {
      final input = _controllers[i].text;
      final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length == 3) {
        final voltage = double.parse('${digits[0]}.${digits.substring(1)}');
        voltages.add(CellVoltage(
          cellNumber: i + 1,
          voltage: voltage,
          status: CellVoltage.getStatus(voltage),
        ));
      }
    }

    // Create hourly reading
    final reading = HourlyReading(
      hour: _currentHour,
      voltages: voltages,
    );

    // Save to database
    await context.read<TestProvider>().addHourlyReading(
      widget.test.id,
      reading,
    );

    setState(() {
      _isSaving = false;
      _hasUnsavedChanges = false;
    });

    // Success feedback
    if (mounted) {
      FeedbackService.hapticSuccess();
      FeedbackService.successToast(context, 'Hour $_currentHour readings saved successfully');
    }

    // Check for low voltage warning
    final hasCriticalVoltage = voltages.any(
      (v) => v.status == VoltageStatus.critical,
    );

    if (hasCriticalVoltage && mounted) {
      FeedbackService.hapticWarning();
      final shouldStop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Low Voltage Detected'),
          content: const Text(
            'Critical voltage level detected (< 1.70V). Do you want to stop the test?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continue'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.voltageCritical,
              ),
              child: const Text('Stop Test'),
            ),
          ],
        ),
      );

      if (shouldStop == true) {
        await context.read<TestProvider>().stopTest(widget.test.id);
        context.read<AlarmProvider>().stopAlarm(widget.test.id);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ReportScreen(test: widget.test),
            ),
          );
        }
        return;
      }
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved voltage readings. Are you sure you want to go back?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.voltageCritical,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${AppStrings.dataEntry} - ${widget.test.batteryNumber}'),
          actions: [
            TextButton.icon(
              onPressed: _isSaving ? null : _onDone,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text(AppStrings.done.toUpperCase()),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Hour Indicator
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.primary.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Hour $_currentHour / ${widget.test.testDuration}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _currentHour / widget.test.testDuration,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        minHeight: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Data Table
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Header Row
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Cell #',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Voltage (V)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Status',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Data Rows
                    ...List.generate(widget.test.cellCount, (index) {
                      final input = _controllers[index].text;
                      final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
                      final hasValidVoltage = digits.length == 3;
                      final voltage = hasValidVoltage
                          ? double.parse('${digits[0]}.${digits.substring(1)}')
                          : 0.0;
                      final statusColor = hasValidVoltage
                          ? _getVoltageStatusColor(voltage)
                          : Colors.transparent;
                      final statusText = hasValidVoltage
                          ? _getVoltageStatusText(voltage)
                          : '';

                      return Semantics(
                        label: 'Cell ${index + 1}',
                        value: hasValidVoltage ? '${voltage.toStringAsFixed(2)} volts, $statusText' : 'Empty',
                        hint: 'Enter 3-digit voltage reading',
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: TextField(
                                    controller: _controllers[index],
                                    focusNode: _focusNodes[index],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    maxLength: 5,
                                    buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                                    inputFormatters: [
                                      VoltageInputFormatter(),
                                    ],
                                    decoration: InputDecoration(
                                      hintText: '2.15',
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    onChanged: (value) => _onVoltageChanged(index, value),
                                    onSubmitted: (_) {
                                      if (index < widget.test.cellCount - 1) {
                                        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              // Status indicator with accessibility
                              Expanded(
                                flex: 2,
                                child: ExcludeSemantics(
                                  child: Center(
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: hasValidVoltage
                                          ? BoxDecoration(
                                              color: statusColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            )
                                          : null,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: statusColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          if (hasValidVoltage) ...[
                                            const SizedBox(width: 4),
                                            Text(
                                              voltage < AppConstants.voltageThresholdCritical
                                                  ? 'C'
                                                  : voltage <= AppConstants.voltageThresholdWarning
                                                      ? 'W'
                                                      : 'N',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: statusColor,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Legend
            Container(
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegendItem('Normal', AppColors.voltageNormal, '>1.95V'),
                  _buildLegendItem('Warning', AppColors.voltageWarning, '1.70-1.95V'),
                  _buildLegendItem('Critical', AppColors.voltageCritical, '<1.70V'),
                ],
              ),
            ),

            // Hint
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).cardColor,
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Enter 3 digits (e.g., 215 for 2.15V). Auto-advances to next cell. When finished entering readings, please press the DONE button.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String range) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              range,
              style: TextStyle(
                fontSize: 8,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

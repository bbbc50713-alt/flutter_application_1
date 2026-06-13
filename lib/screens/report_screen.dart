import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import '../widgets/graph_3d_widget.dart';
import '../services/report_service.dart';
import '../services/feedback_service.dart';
import '../services/database_service.dart';
import '../models/models.dart';
import '../utils/error_messages.dart';

/// Screen 3: 报告页面 - 显示 3D 放电曲线图和测试统计
class ReportScreen extends StatefulWidget {
  final BatteryTest test;

  const ReportScreen({Key? key, required this.test}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late List<List<double>> _voltageData;
  bool _isSaving = false;
  bool _isSending = false;
  final GlobalKey<Graph3DWidgetState> _graphKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    try {
      _extractVoltageDataFromTest();
    } catch (e) {
      // ignore: avoid_print
      print('Error extracting voltage data, using default values: $e');
      _voltageData = List.generate(widget.test.cellCount, (_) => List.generate(widget.test.testDuration, (_) => 0));
    }
  }

  void _extractVoltageDataFromTest() {
    _voltageData = List.generate(
      widget.test.cellCount,
      (cellIndex) => List.generate(
        widget.test.testDuration,
        (hourIndex) {
          final reading = widget.test.readings.firstWhere(
            (r) => r.hour == hourIndex + 1,
            orElse: () => HourlyReading(hour: hourIndex + 1, voltages: []),
          );

          final voltage = reading.voltages.firstWhere(
            (v) => v.cellNumber == cellIndex + 1,
            orElse: () => CellVoltage(
              cellNumber: cellIndex + 1,
              voltage: 0,
              status: VoltageStatus.normal,
            ),
          );

          return voltage.voltage > 0 ? voltage.voltage : 0;
        },
      ),
    );

    assert(_voltageData.length == widget.test.cellCount,
      'Voltage data rows (${_voltageData.length}) must match cellCount (${widget.test.cellCount})');
    assert(_voltageData.isNotEmpty && _voltageData[0].length == widget.test.testDuration,
      'Voltage data columns (${_voltageData.isNotEmpty ? _voltageData[0].length : 0}) must match testDuration (${widget.test.testDuration})');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Report - ${widget.test.batteryNumber}'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isSending 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send),
            tooltip: 'Send Report',
            onPressed: _isSending ? null : _sendReport,
          ),
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_alt),
            tooltip: 'Save Report',
            onPressed: _isSaving ? null : _saveReport,
          ),
        ],
      ),
      body: Column(
        children: [
          // 3D 图表区域
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              child: _buildGraphSection(),
            ),
          ),
          
          // 图例和统计信息
          Expanded(
            flex: 1,
            child: _buildLegendAndStats(),
          ),
        ],
      ),
    );
  }

  /// 构建 3D 图表区域
  Widget _buildGraphSection() {
    return Column(
      children: [
        // 标题
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Icon(
                Icons.show_chart,
                color: Color(0xFF1976D2),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                '3D Discharge Graph',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.fullscreen, size: 20),
                tooltip: 'Full Screen',
                onPressed: () => _showFullScreenGraph(),
              ),
            ],
          ),
        ),
        
        // 3D 图表
        Expanded(
          child: Graph3DWidget(
            key: _graphKey,
            voltageData: _voltageData,
            cellCount: widget.test.cellCount,
            hourCount: widget.test.testDuration,
            minHeight: 300,
            onGraphReady: () {
              // ignore: avoid_print
              print('3D graph is ready!');
            },
          ),
        ),
      ],
    );
  }

  /// 构建图例和统计信息
  Widget _buildLegendAndStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 图例
          _buildLegend(),
          
          const SizedBox(height: 12),
          
          // 统计信息
          _buildStatistics(),
        ],
      ),
    );
  }

  /// 构建颜色图例
  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(
          color: const Color(0xFF1a9850),
          label: '>1.95V Normal',
          icon: Icons.check_circle,
        ),
        const SizedBox(width: 24),
        _buildLegendItem(
          color: const Color(0xFFfee08b),
          label: '1.70-1.95V Warning',
          icon: Icons.warning,
        ),
        const SizedBox(width: 24),
        _buildLegendItem(
          color: const Color(0xFFd73027),
          label: '<1.70V Critical',
          icon: Icons.error,
        ),
      ],
    );
  }

  /// 构建图例项
  Widget _buildLegendItem({
    required Color color,
    required String label,
    IconData? icon,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
        ),
        if (icon != null) ...[
          const SizedBox(width: 4),
          Icon(icon, size: 14, color: color),
        ],
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  /// 构建统计信息
  Widget _buildStatistics() {
    // 计算统计数据
    int normalCount = 0;
    int warningCount = 0;
    int criticalCount = 0;

    for (var cell in _voltageData) {
      for (var voltage in cell) {
        if (voltage <= 0) continue;  // Skip missing/unused readings
        if (voltage >= 1.95) {
          normalCount++;
        } else if (voltage >= 1.70) {
          warningCount++;
        } else {
          criticalCount++;
        }
      }
    }
    int totalCells = normalCount + warningCount + criticalCount;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(
          label: 'Total Readings',
          value: totalCells.toString(),
          icon: Icons.analytics,
        ),
        _buildVerticalDivider(),
        _buildStatItem(
          label: 'Normal',
          value: normalCount.toString(),
          valueColor: const Color(0xFF1a9850),
          icon: Icons.check_circle,
        ),
        _buildVerticalDivider(),
        _buildStatItem(
          label: 'Warning',
          value: warningCount.toString(),
          valueColor: const Color(0xFFfee08b),
          icon: Icons.warning,
        ),
        _buildVerticalDivider(),
        _buildStatItem(
          label: 'Critical',
          value: criticalCount.toString(),
          valueColor: const Color(0xFFd73027),
          icon: Icons.error,
        ),
      ],
    );
  }

  /// 构建统计项
  Widget _buildStatItem({
    required String label,
    required String value,
    IconData? icon,
    Color? valueColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: valueColor ?? const Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  /// 构建垂直分隔线
  Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey.shade300,
    );
  }

  /// 显示全屏图表
  void _showFullScreenGraph() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('3D Graph - Full Screen'),
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
          ),
          body: Container(
            padding: const EdgeInsets.all(16),
            child: Graph3DWidget(
              voltageData: _voltageData,
              cellCount: widget.test.cellCount,
              hourCount: widget.test.testDuration,
              minHeight: MediaQuery.of(context).size.height * 0.8,
            ),
          ),
        ),
      ),
    );
  }

  /// Capture graph screenshot with proper readiness detection
  Future<Uint8List?> _captureGraphScreenshot() async {
    final state = _graphKey.currentState;
    if (state == null) {
      debugPrint('Graph widget state is null');
      return null;
    }

    try {
      debugPrint('Waiting for graph to be ready...');
      await state.waitForGraphReady();

      debugPrint('Capturing screenshot...');
      final imageData = await state.captureScreenshot();

      if (imageData != null && imageData.isNotEmpty) {
        debugPrint('Screenshot captured successfully: ${imageData.length} bytes');
        return imageData;
      }

      debugPrint('Screenshot capture returned null or empty');
      return null;
    } catch (e) {
      debugPrint('Error capturing graph screenshot: $e');
      return null;
    }
  }

  Future<void> _saveReport() async {
    setState(() => _isSaving = true);

    try {
      // 生成 PDF 报告
      final graphImage = await _captureGraphScreenshot();

      // Warn user if graph capture failed
      if (graphImage == null && mounted) {
        final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Graph Capture Warning'),
            content: const Text(
              'Failed to capture the 3D graph screenshot. The PDF will be generated without the 3D graph image.\n\nDo you want to continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue'),
              ),
            ],
          ),
        );

        if (shouldContinue != true) {
          setState(() => _isSaving = false);
          return;
        }
      }

      final reportService = ReportService();
      final file = await reportService.generateReport(widget.test, graphImage: graphImage);

      // Platform-specific save logic
      if (Platform.isAndroid || Platform.isIOS) {
        // Android/iOS: Use Storage Access Framework (SAF) - no permissions needed
        final fileName = 'BDL_Report_${widget.test.batteryNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';

        // Read file bytes (required for Android/iOS)
        final fileBytes = await file.readAsBytes();

        final outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save PDF Report',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          bytes: fileBytes,
        );

        if (outputPath == null) {
          // User canceled
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Save canceled')),
            );
          }
          return;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Report saved successfully'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Desktop (Windows/macOS/Linux) - keep existing logic
        final saveDir = await getDownloadsDirectory();

        if (saveDir == null) {
          throw Exception('Cannot access Downloads directory');
        }

        final fileName = path.basename(file.path);
        final savedFile = await file.copy(path.join(saveDir.path, fileName));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Report saved to: ${savedFile.path}'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Open',
                textColor: const Color(0xFF1976D2),
                onPressed: () async {
                  final result = await OpenFile.open(savedFile.path);
                  if (result.type != ResultType.done) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error opening file: ${result.message}')),
                      );
                    }
                  }
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error saving report';

        // Provide context-specific messages
        if (e.toString().contains('canceled') || e.toString().contains('cancelled')) {
          errorMessage = 'Save canceled';
        } else {
          errorMessage = 'Could not save the report. Please try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: e.toString().contains('cancel') ? null : Colors.red,
            action: e.toString().contains('cancel') ? null : SnackBarAction(
              label: 'Details',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Error Details'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: Text(e.toString()),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _sendReport() async {
    if (_isSending) return;

    setState(() => _isSending = true);

    try {
      // Capture 3D graph screenshot
      Uint8List? graphImage;
      try {
        graphImage = await _captureGraphScreenshot();
      } catch (e) {
        debugPrint('Failed to capture graph: $e');
        if (mounted) {
          final proceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 12),
                  Text('Graph Capture Failed'),
                ],
              ),
              content: const Text('Unable to capture 3D graph. Continue without graph in report?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Continue'),
                ),
              ],
            ),
          );

          if (proceed != true) {
            setState(() => _isSending = false);
            return;
          }
        }
      }

      // Show confirmation dialog
      await FeedbackService.hapticSelection();
      final confirmed = await _showConfirmDialog();
      if (!confirmed) {
        setState(() => _isSending = false);
        return;
      }

      // Attempt to send email
      final reportService = ReportService();

      try {
        await reportService.emailReport(widget.test, graphImage: graphImage);

        // Email client opened successfully - show feedback dialog
        if (mounted) {
          await FeedbackService.hapticSuccess();
          await _showFeedbackDialog();
        }
      } on PlatformException catch (e) {
        if (e.code == 'not_available') {
          // No email client installed - show fallback dialog
          if (mounted) {
            await FeedbackService.hapticWarning();
            await _showFallbackDialog(reportService, graphImage);
          }
        } else {
          // Other platform exception
          if (mounted) {
            await FeedbackService.hapticError();
            FeedbackService.errorToast(
              context,
              'Email error: ${e.message ?? ErrorMessages.reportEmailError}',
            );
          }
        }
      } catch (e) {
        // Generic error
        if (mounted) {
          await FeedbackService.hapticError();
          FeedbackService.errorToast(
            context,
            'Error sending report: ${e.toString()}',
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<bool> _showConfirmDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.send, color: Colors.blue),
            SizedBox(width: 12),
            Text(ErrorMessages.emailConfirmTitle),
          ],
        ),
        content: const Text(ErrorMessages.emailConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _showFeedbackDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 12),
            Text(ErrorMessages.emailFeedbackTitle),
          ],
        ),
        content: const Text(ErrorMessages.emailFeedbackMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text('Encountered Problem'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Sent Successfully'),
          ),
        ],
      ),
    );

    if (mounted) {
      if (result == true) {
        await FeedbackService.hapticSuccess();
        FeedbackService.successToast(context, ErrorMessages.emailSentSuccess);
      } else if (result == false) {
        FeedbackService.infoToast(context, ErrorMessages.emailRetryOptions);
      }
    }
  }

  Future<void> _showFallbackDialog(ReportService reportService, Uint8List? graphImage) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.email_outlined, color: Colors.orange),
            SizedBox(width: 12),
            Text(ErrorMessages.emailFallbackTitle),
          ],
        ),
        content: const Text(ErrorMessages.emailNotAvailable),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'copy'),
            child: const Text(ErrorMessages.emailFallbackOption1),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'share'),
            child: const Text(ErrorMessages.emailFallbackOption2),
          ),
        ],
      ),
    );

    if (mounted && choice != null) {
      if (choice == 'copy') {
        await _copyReportToClipboard();
      } else if (choice == 'share') {
        try {
          await reportService.shareReport(widget.test, graphImage: graphImage);
        } catch (e) {
          FeedbackService.errorToast(context, 'Error sharing report: $e');
        }
      }
    }
  }

  Future<void> _copyReportToClipboard() async {
    try {
      final db = DatabaseService();
      final customer = await db.getCustomerById(widget.test.customerId);
      final provider = await db.getProvider();

      final reportService = ReportService();
      final emailBody = reportService.getEmailBodyText(
        widget.test,
        provider: provider,
        customer: customer,
      );

      await Clipboard.setData(ClipboardData(text: emailBody));

      if (mounted) {
        await FeedbackService.hapticTap();
        FeedbackService.successToast(context, ErrorMessages.emailCopySuccess);
      }
    } catch (e) {
      if (mounted) {
        FeedbackService.errorToast(context, 'Error copying to clipboard: $e');
      }
    }
  }
}

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import '../models/models.dart';
import 'database_service.dart';

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  final _db = DatabaseService();

  Future<File> generateReport(BatteryTest test, {Uint8List? graphImage}) async {
    try {
      final provider = await _db.getProvider();
      final customer = await _db.getCustomerById(test.customerId);

      final effectiveProvider = provider ?? ServiceProvider(
        id: test.providerId,
        companyName: 'Test Provider',
        address: '',
        phoneNumber: '',
        email: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final effectiveCustomer = customer ?? Customer(
        id: test.customerId,
        companyName: test.batteryInfo.split(' ').first,
        companyAddress: '',
        phoneNumber: '',
        email: '',
        batteryNumber: test.batteryNumber,
        batteryInfo: test.batteryInfo,
        createdAt: DateTime.now(),
      );

      final pdf = pw.Document();

      final List<pw.Widget> contentWidgets = [
        _buildHeader(),
        pw.SizedBox(height: 20),
        _buildProviderSection(effectiveProvider),
        pw.SizedBox(height: 20),
        _buildCustomerSection(effectiveCustomer),
        pw.SizedBox(height: 20),
        if (test.batteryImagePath.isNotEmpty && File(test.batteryImagePath).existsSync())
          _buildBatteryImage(test.batteryImagePath),
        pw.SizedBox(height: 20),
        _buildDataTable(test),
        pw.SizedBox(height: 20),
      ];

      if (graphImage != null) {
        contentWidgets.add(_build3DGraphImage(graphImage));
        contentWidgets.add(pw.SizedBox(height: 20));
      }

      contentWidgets.add(_buildHeatmapChart(test));
      contentWidgets.add(pw.SizedBox(height: 20));
      contentWidgets.add(_buildTestSummary(test));

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => contentWidgets,
        ),
      );

      final output = await getApplicationCacheDirectory();
      final file = File('${output.path}/BDL_Report_${test.batteryNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      // Validate the file was written successfully
      if (!file.existsSync() || file.lengthSync() == 0) {
        throw Exception('PDF file generation failed: file is empty or missing');
      }

      return file;
    } catch (e) {
      // ignore: avoid_print
      print('Error generating report: $e');
      rethrow; // 向上传播错误以便 UI 层处理
    }
  }

  pw.Widget _buildHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('1976D2'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'BATTERY DISCHARGE TEST REPORT',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'BDL - Battery Discharge Logger v3.0',
            style: pw.TextStyle(
              fontSize: 14,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildProviderSection(ServiceProvider? provider) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SERVICE PROVIDER INFORMATION',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('1976D2'),
            ),
          ),
          pw.Divider(),
          _buildInfoRow('Company:', provider?.companyName ?? 'N/A'),
          _buildInfoRow('Address:', provider?.address ?? 'N/A'),
          _buildInfoRow('Phone:', provider?.phoneNumber ?? 'N/A'),
          _buildInfoRow('Email:', provider?.email ?? 'N/A'),
        ],
      ),
    );
  }

  pw.Widget _buildCustomerSection(Customer? customer) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CUSTOMER INFORMATION',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('1976D2'),
            ),
          ),
          pw.Divider(),
          _buildInfoRow('Company:', customer?.companyName ?? 'N/A'),
          _buildInfoRow('Address:', customer?.companyAddress ?? 'N/A'),
          _buildInfoRow('Phone:', customer?.phoneNumber ?? 'N/A'),
          _buildInfoRow('Email:', customer?.email ?? 'N/A'),
          _buildInfoRow('Battery #:', customer?.batteryNumber ?? 'N/A'),
          _buildInfoRow('Battery Info:', customer?.batteryInfo ?? 'N/A'),
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBatteryImage(String imagePath) {
    try {
      final imageFile = File(imagePath);
      if (imageFile.existsSync()) {
        final imageBytes = imageFile.readAsBytesSync();
        return pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'BATTERY PHOTO',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('1976D2'),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Image(
                  pw.MemoryImage(imageBytes),
                  height: 200,
                  fit: pw.BoxFit.contain,
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      reportDebugPrint('Error loading image: $e');
    }
    return pw.Container();
  }

  pw.Widget _buildDataTable(BatteryTest test) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${test.testDuration}-HOUR DISCHARGE DATA TABLE',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('1976D2'),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildTableCell('Cell #', isHeader: true),
                  ...List.generate(test.testDuration, (hour) => _buildTableCell('H${hour + 1}', isHeader: true)),
                ],
              ),
              ...List.generate(test.cellCount, (cellIndex) {
                return pw.TableRow(
                  children: [
                    _buildTableCell('${cellIndex + 1}', isHeader: true),
                    ...List.generate(test.testDuration, (hourIndex) {
                      final voltage = _getVoltageForCellAndHour(test, cellIndex + 1, hourIndex + 1);
                      return _buildTableCell(voltage);
                    }),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Color Legend: Green (>1.95V) | Yellow (1.70-1.95V) | Red (<1.70V)',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : null,
          fontSize: 8,
        ),
      ),
    );
  }

  String _getVoltageForCellAndHour(BatteryTest test, int cellNumber, int hour) {
    final reading = test.readings.firstWhere(
      (r) => r.hour == hour,
      orElse: () => HourlyReading(hour: hour, voltages: []),
    );
    final voltage = reading.voltages.firstWhere(
      (v) => v.cellNumber == cellNumber,
      orElse: () => CellVoltage(cellNumber: cellNumber, voltage: 0, status: VoltageStatus.normal),
    );
    return voltage.voltage > 0 ? '${voltage.voltage.toStringAsFixed(2)}V' : '-';
  }

  /// ✅ 新增：构建2D热力图/俯视图
  pw.Widget _buildHeatmapChart(BatteryTest test) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'VOLTAGE HEATMAP (Top View)',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('1976D2'),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Visual representation of cell voltages over time. Green=Normal, Yellow=Warning, Red=Critical.',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 12),
          
          // 绘制热力图网格
          _drawHeatmapGrid(test),

          pw.SizedBox(height: 8),

          // Axis label
          pw.Center(
            child: pw.Text(
              'Time (Hours)',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic),
            ),
          ),

          pw.SizedBox(height: 8),

          // 图例
          _buildHeatmapLegend(),
        ],
      ),
    );
  }

  /// 绘制热力图网格
  pw.Widget _drawHeatmapGrid(BatteryTest test) {
    // A4 usable width = 595.28 - 32*2 (page margins) - 12*2 (container padding) = 507pt
    const double availableWidth = 507.0;

    // Calculate dynamic cell size based on test parameters
    final int totalColumns = 1 + test.testDuration; // 1 label column + hour columns
    final double labelWidth = 30.0;
    final double cellWidth = (availableWidth - labelWidth) / test.testDuration;
    final double cellHeight = 14.0;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: pw.FixedColumnWidth(labelWidth),
        for (int i = 1; i < totalColumns; i++)
          i: pw.FixedColumnWidth(cellWidth),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Container(
              height: cellHeight,
              alignment: pw.Alignment.center,
              child: pw.Text('Cell', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
            ),
            ...List.generate(test.testDuration, (hour) =>
              pw.Container(
                height: cellHeight,
                alignment: pw.Alignment.center,
                child: pw.Text('H${hour + 1}', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
              ),
            ),
          ],
        ),
        // Data rows - one per cell
        ...List.generate(test.cellCount, (cellIndex) {
          return pw.TableRow(
            children: [
              // Row label (cell number)
              pw.Container(
                height: cellHeight,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(color: PdfColors.grey200),
                child: pw.Text('${cellIndex + 1}', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
              ),
              // Colored cells for each hour
              ...List.generate(test.testDuration, (hourIndex) {
                final voltage = _getVoltageValue(test, cellIndex + 1, hourIndex + 1);
                final color = _getVoltageColor(voltage);
                return pw.Container(
                  height: cellHeight,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(color: color),
                  child: voltage > 0
                      ? pw.Text(
                          voltage.toStringAsFixed(2),
                          style: pw.TextStyle(fontSize: 5, color: PdfColors.black),
                        )
                      : null,
                );
              }),
            ],
          );
        }),
      ],
    );
  }

  double _getVoltageValue(BatteryTest test, int cellNumber, int hour) {
    try {
      final reading = test.readings.firstWhere(
        (r) => r.hour == hour,
        orElse: () => HourlyReading(hour: hour, voltages: []),
      );
      
      final voltage = reading.voltages.firstWhere(
        (v) => v.cellNumber == cellNumber,
        orElse: () => CellVoltage(cellNumber: cellNumber, voltage: 0, status: VoltageStatus.normal),
      );
      
      return voltage.voltage > 0 ? voltage.voltage : 0;
    } catch (e) {
      return 0;
    }
  }

  PdfColor _getVoltageColor(double voltage) {
    if (voltage >= 1.95) {
      return PdfColor.fromInt(0xFF1a9850);
    } else if (voltage >= 1.70) {
      return PdfColor.fromInt(0xFFfee08b);
    } else if (voltage > 0) {
      return PdfColor.fromInt(0xFFd73027);
    } else {
      return PdfColors.grey300;
    }
  }

  /// 构建热力图图例
  pw.Widget _buildHeatmapLegend() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        _buildLegendItem(PdfColor.fromInt(0xFF1a9850), '>1.95V Normal'),
        pw.SizedBox(width: 16),
        _buildLegendItem(PdfColor.fromInt(0xFFfee08b), '1.70-1.95V Warning'),
        pw.SizedBox(width: 16),
        _buildLegendItem(PdfColor.fromInt(0xFFd73027), '<1.70V Critical'),
      ],
    );
  }

  pw.Widget _buildLegendItem(PdfColor color, String label) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 12,
          height: 12,
          decoration: pw.BoxDecoration(
            color: color,
            border: pw.Border.all(color: PdfColors.grey400),
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Text(label, style: pw.TextStyle(fontSize: 8)),
      ],
    );
  }

  pw.Widget _build3DGraphImage(Uint8List imageBytes) {
    // Validate image data
    if (imageBytes.isEmpty || imageBytes.length < 1000) {
      return _buildGraphPlaceholder('Image data is empty or too small');
    }

    // Validate PNG header
    if (imageBytes.length < 8 ||
        imageBytes[0] != 0x89 || imageBytes[1] != 0x50 ||
        imageBytes[2] != 0x4E || imageBytes[3] != 0x47) {
      return _buildGraphPlaceholder('Invalid image format (not PNG)');
    }

    try {
      final image = pw.MemoryImage(imageBytes);
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '3D DISCHARGE CURVE (45° View)',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('1976D2'),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Image(
                image,
                width: 450,
                height: 300,
                fit: pw.BoxFit.contain,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error creating PDF image: $e');
      return _buildGraphPlaceholder('Failed to create image: ${e.toString()}');
    }
  }

  pw.Widget _buildGraphPlaceholder(String errorMessage) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '3D DISCHARGE CURVE (45° View)',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('1976D2'),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            width: 450,
            height: 300,
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey400, width: 2),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    '3D Graph Unavailable',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    errorMessage,
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTestSummary(BatteryTest test) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'TEST SUMMARY',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('1976D2'),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Total Hours Recorded: ${test.readings.length}'),
          pw.Text('Start Time: ${test.startTime}'),
          if (test.endTime != null)
            pw.Text('End Time: ${test.endTime}'),
          pw.SizedBox(height: 8),
          
          // 统计信息
          _buildStatisticsSummary(test),
        ],
      ),
    );
  }

  /// 构建统计摘要
  pw.Widget _buildStatisticsSummary(BatteryTest test) {
    int totalCells = 0;
    int normalCount = 0;
    int warningCount = 0;
    int criticalCount = 0;
    
    for (var reading in test.readings) {
      for (var voltage in reading.voltages) {
        totalCells++;
        if (voltage.voltage >= 1.95) {
          normalCount++;
        } else if (voltage.voltage >= 1.70) {
          warningCount++;
        } else {
          criticalCount++;
        }
      }
    }
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          pw.Column(
            children: [
              pw.Text('Total', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.Text('$totalCells', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Column(
            children: [
              pw.Text('✓ Normal', style: pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF1a9850))),
              pw.Text('$normalCount', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1a9850))),
            ],
          ),
          pw.Column(
            children: [
              pw.Text('⚠ Warning', style: pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFFf57c00))),
              pw.Text('$warningCount', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFFf57c00))),
            ],
          ),
          pw.Column(
            children: [
              pw.Text('✗ Critical', style: pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFFd73027))),
              pw.Text('$criticalCount', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFFd73027))),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> shareReport(BatteryTest test, {Uint8List? graphImage}) async {
    final file = await generateReport(test, graphImage: graphImage);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'BDL Battery Discharge Test Report - ${test.batteryNumber}',
    );
  }

  Future<void> emailReport(BatteryTest test, {Uint8List? graphImage}) async {
    final file = await generateReport(test, graphImage: graphImage);
    final customer = await _db.getCustomerById(test.customerId);
    final provider = await _db.getProvider();

    // Validate file before attaching
    if (!file.existsSync() || file.lengthSync() == 0) {
      throw Exception('Report file is missing or empty');
    }

    final email = Email(
      subject: 'BDL Battery Discharge Test Report - ${test.batteryNumber}',
      body: _buildEmailBody(test, provider: provider, customer: customer),
      recipients: [
        if (customer != null && customer.email.isNotEmpty) customer.email,
        if (provider != null && provider.email.isNotEmpty) provider.email,
      ],
      attachmentPaths: [file.path],
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email);
    } catch (e) {
      // Fallback to share_plus if Mail.app is not configured (common on iOS)
      if (Platform.isIOS && e.toString().contains('not_available')) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'BDL Battery Discharge Test Report - ${test.batteryNumber}',
          text: _buildEmailBody(test, provider: provider, customer: customer),
        );
      } else {
        rethrow;
      }
    }
  }

  String _buildEmailBody(BatteryTest test, {ServiceProvider? provider, Customer? customer}) {
    final buffer = StringBuffer();

    buffer.writeln('Battery Discharge Test Report');
    buffer.writeln('=' * 50);
    buffer.writeln('');

    // Test Information
    buffer.writeln('TEST INFORMATION');
    buffer.writeln('-' * 50);
    buffer.writeln('Battery #: ${test.batteryNumber}');
    buffer.writeln('Battery Info: ${test.batteryInfo}');
    buffer.writeln('Start Time: ${test.startTime}');
    if (test.endTime != null) {
      buffer.writeln('End Time: ${test.endTime}');
    }
    buffer.writeln('Duration: ${test.testDuration} hours');
    buffer.writeln('Cells Tested: ${test.cellCount}');
    buffer.writeln('');

    // Test Results Summary
    if (test.readings.isNotEmpty) {
      int criticalCount = 0;
      int warningCount = 0;
      int normalCount = 0;

      for (var reading in test.readings) {
        for (var cell in reading.voltages) {
          if (cell.voltage < 1.70) {
            criticalCount++;
          } else if (cell.voltage < 1.95) {
            warningCount++;
          } else {
            normalCount++;
          }
        }
      }

      buffer.writeln('TEST RESULTS SUMMARY');
      buffer.writeln('-' * 50);
      buffer.writeln('Critical Readings (< 1.70V): $criticalCount');
      buffer.writeln('Warning Readings (1.70-1.95V): $warningCount');
      buffer.writeln('Normal Readings (> 1.95V): $normalCount');
      buffer.writeln('');
    }

    // Service Provider Info
    if (provider != null) {
      buffer.writeln('SERVICE PROVIDER');
      buffer.writeln('-' * 50);
      buffer.writeln('Company: ${provider.companyName}');
      if (provider.address.isNotEmpty) {
        buffer.writeln('Address: ${provider.address}');
      }
      if (provider.phoneNumber.isNotEmpty) {
        buffer.writeln('Phone: ${provider.phoneNumber}');
      }
      buffer.writeln('Email: ${provider.email}');
      buffer.writeln('');
    }

    // Customer Info
    if (customer != null) {
      buffer.writeln('CUSTOMER INFORMATION');
      buffer.writeln('-' * 50);
      buffer.writeln('Company: ${customer.companyName}');
      if (customer.companyAddress.isNotEmpty) {
        buffer.writeln('Address: ${customer.companyAddress}');
      }
      if (customer.phoneNumber.isNotEmpty) {
        buffer.writeln('Phone: ${customer.phoneNumber}');
      }
      buffer.writeln('Email: ${customer.email}');
      buffer.writeln('');
    }

    buffer.writeln('=' * 50);
    buffer.writeln('Please find the detailed report with 3D discharge model in the attached PDF.');
    buffer.writeln('');
    buffer.writeln('This report was generated by BDL - Battery Discharge Logger');

    return buffer.toString();
  }

  /// Get email body text for clipboard copy (public wrapper)
  String getEmailBodyText(BatteryTest test, {ServiceProvider? provider, Customer? customer}) {
    return _buildEmailBody(test, provider: provider, customer: customer);
  }
}

void reportDebugPrint(String message) {
  // ignore: avoid_print
  print(message);
}

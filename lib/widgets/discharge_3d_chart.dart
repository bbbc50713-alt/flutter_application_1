import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/utils.dart';

class Discharge3DChart extends StatelessWidget {
  final List<HourlyReading> readings;

  const Discharge3DChart({
    super.key,
    required this.readings,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return Column(
      children: [
        // 3D Surface Plot
        Expanded(
          flex: 3,
          child: _build3DSurface(),
        ),
        // Legend
        _buildLegend(),
      ],
    );
  }

  Widget _build3DSurface() {
    return CustomPaint(
      size: Size.infinite,
      painter: _Surface3DPainter(readings: readings),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem('>1.95V', AppColors.voltageNormal),
          const SizedBox(width: 16),
          _buildLegendItem('1.70-1.95V', AppColors.voltageWarning),
          const SizedBox(width: 16),
          _buildLegendItem('<1.70V', AppColors.voltageCritical),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _Surface3DPainter extends CustomPainter {
  final List<HourlyReading> readings;

  _Surface3DPainter({required this.readings});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Draw axes
    _drawAxes(canvas, width, height);

    // Draw 3D surface
    _draw3DSurface(canvas, width, height);

    // Draw labels
    _drawLabels(canvas, width, height);
  }

  void _drawAxes(Canvas canvas, double width, double height) {
    final axisPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2;

    final margin = 60.0;
    final chartWidth = width - margin * 2;
    final chartHeight = height - margin * 2;

    // X axis (Hours) - bottom
    canvas.drawLine(
      Offset(margin, height - margin),
      Offset(width - margin, height - margin),
      axisPaint,
    );

    // Y axis (Voltage) - left
    canvas.drawLine(
      Offset(margin, margin),
      Offset(margin, height - margin),
      axisPaint,
    );

    // Z axis (Cell #) - diagonal for 3D effect
    canvas.drawLine(
      Offset(width - margin, height - margin),
      Offset(width - margin + 40, height - margin - 40),
      axisPaint,
    );
  }

  void _draw3DSurface(Canvas canvas, double width, double height) {
    final margin = 60.0;
    final chartWidth = width - margin * 2;
    final chartHeight = height - margin * 2;

    // Create grid of voltage values
    for (int hour = 0; hour < 6; hour++) {
      for (int cell = 0; cell < 24; cell++) {
        final voltage = _getVoltage(cell + 1, hour + 1);
        if (voltage == null) continue;

        // Calculate 3D position
        final x = margin + (hour / 5) * chartWidth;
        final z = (cell / 23) * 40; // 3D depth offset
        final y = height - margin - ((voltage - 1.5) / 1.0) * chartHeight - z;

        // Determine color based on voltage
        final color = _getVoltageColor(voltage);

        // Draw cell as a 3D-like rectangle
        final cellSize = 12.0;
        final rect = Rect.fromCenter(
          center: Offset(x, y),
          width: cellSize,
          height: cellSize,
        );

        // Draw shadow for 3D effect
        final shadowPaint = Paint()
          ..color = Colors.black.withOpacity(0.2)
          ..style = PaintingStyle.fill;
        canvas.drawRect(
          rect.shift(const Offset(2, 2)),
          shadowPaint,
        );

        // Draw cell
        final cellPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        canvas.drawRect(rect, cellPaint);

        // Draw border
        final borderPaint = Paint()
          ..color = Colors.white.withOpacity(0.5)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;
        canvas.drawRect(rect, borderPaint);
      }
    }

    // Draw connecting lines for surface mesh
    _drawSurfaceMesh(canvas, margin, chartWidth, chartHeight, height);
  }

  void _drawSurfaceMesh(Canvas canvas, double margin, double chartWidth,
      double chartHeight, double height) {
    final linePaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    // Draw hour lines
    for (int hour = 0; hour < 6; hour++) {
      final x = margin + (hour / 5) * chartWidth;
      final path = Path();
      bool first = true;

      for (int cell = 0; cell < 24; cell++) {
        final voltage = _getVoltage(cell + 1, hour + 1);
        if (voltage == null) continue;

        final z = (cell / 23) * 40;
        final y = height - margin - ((voltage - 1.5) / 1.0) * chartHeight - z;

        if (first) {
          path.moveTo(x, y);
          first = false;
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, linePaint);
    }

    // Draw cell lines
    for (int cell = 0; cell < 24; cell++) {
      final z = (cell / 23) * 40;
      final path = Path();
      bool first = true;

      for (int hour = 0; hour < 6; hour++) {
        final voltage = _getVoltage(cell + 1, hour + 1);
        if (voltage == null) continue;

        final x = margin + (hour / 5) * chartWidth;
        final y = height - margin - ((voltage - 1.5) / 1.0) * chartHeight - z;

        if (first) {
          path.moveTo(x, y);
          first = false;
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, linePaint);
    }
  }

  void _drawLabels(Canvas canvas, double width, double height) {
    final textStyle = TextStyle(
      color: Colors.grey.shade700,
      fontSize: 12,
    );
    final margin = 60.0;

    // X axis labels (Hours)
    for (int i = 0; i < 6; i++) {
      final textSpan = TextSpan(
        text: 'H${i + 1}',
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final x = margin + (i / 5) * (width - margin * 2) - textPainter.width / 2;
      textPainter.paint(canvas, Offset(x, height - margin + 10));
    }

    // Y axis labels (Voltage)
    for (double v = 1.5; v <= 2.5; v += 0.25) {
      final textSpan = TextSpan(
        text: '${v.toStringAsFixed(2)}V',
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final y = height - margin - ((v - 1.5) / 1.0) * (height - margin * 2) -
          textPainter.height / 2;
      textPainter.paint(canvas, Offset(10, y));
    }

    // Axis titles
    final titleStyle = TextStyle(
      color: Colors.grey.shade800,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );

    // X axis title
    final xTitle = TextPainter(
      text: TextSpan(text: 'Hours', style: titleStyle),
      textDirection: TextDirection.ltr,
    );
    xTitle.layout();
    xTitle.paint(
      canvas,
      Offset(width / 2 - xTitle.width / 2, height - 20),
    );

    // Y axis title (rotated)
    final yTitle = TextPainter(
      text: TextSpan(text: 'Voltage (V)', style: titleStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    yTitle.layout();
    canvas.save();
    canvas.translate(20, height / 2);
    canvas.rotate(-3.14159 / 2);
    yTitle.paint(canvas, Offset(-yTitle.width / 2, 0));
    canvas.restore();

    // Z axis title
    final zTitle = TextPainter(
      text: TextSpan(text: 'Cell #', style: titleStyle),
      textDirection: TextDirection.ltr,
    );
    zTitle.layout();
    zTitle.paint(
      canvas,
      Offset(width - 40, height - margin - 60),
    );
  }

  double? _getVoltage(int cellNumber, int hour) {
    final reading = readings.firstWhere(
      (r) => r.hour == hour,
      orElse: () => HourlyReading(hour: hour, voltages: []),
    );
    final voltage = reading.voltages.firstWhere(
      (v) => v.cellNumber == cellNumber,
      orElse: () =>
          CellVoltage(cellNumber: cellNumber, voltage: 0, status: VoltageStatus.normal),
    );
    return voltage.voltage > 0 ? voltage.voltage : null;
  }

  Color _getVoltageColor(double voltage) {
    if (voltage < 1.70) {
      return AppColors.voltageCritical;
    } else if (voltage <= 1.95) {
      return AppColors.voltageWarning;
    } else {
      return AppColors.voltageNormal;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

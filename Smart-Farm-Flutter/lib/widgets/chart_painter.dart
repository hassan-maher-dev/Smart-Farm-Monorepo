import 'package:flutter/material.dart';

class LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  LineChartPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // حساب أقل وأكبر قيمة لرسم الاسكيل مظبوط
    double maxVal = data.reduce((a, b) => a > b ? a : b);
    double minVal = data.reduce((a, b) => a < b ? a : b);
    
    if (maxVal == minVal) {
      maxVal += 1;
      minVal -= 1;
    }

    final range = maxVal - minVal;
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minVal) / range) * size.height;
      points.add(Offset(x, y));
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    for (final point in points) {
      canvas.drawCircle(point, 3.5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
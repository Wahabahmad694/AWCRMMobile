import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/response/dashboard_response.dart';
import '../../utils/app_colors.dart';
import '../../utils/extractor.dart';

class SalesChartWidget extends StatefulWidget {
  const SalesChartWidget({
    super.key,
    required this.points,
    this.onViewReports,
  });

  final List<TrendPoint> points;
  final VoidCallback? onViewReports;

  @override
  State<SalesChartWidget> createState() => _SalesChartWidgetState();
}

class _SalesChartWidgetState extends State<SalesChartWidget> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final points = widget.points.isNotEmpty ? widget.points : _defaultPoints();
    final maxValuePaisa = points.map((p) => p.valuePaisa).fold(0, max);
    final maxRupees = maxValuePaisa > 0 ? (maxValuePaisa / 100.0) : 125.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sales performance',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Your net sales over time',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              if (widget.onViewReports != null)
                InkWell(
                  onTap: widget.onViewReports,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Reports',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(Icons.arrow_outward_rounded, size: 14, color: AppColors.primary),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (_selectedIndex != null && _selectedIndex! < points.length)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySubtle,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${points[_selectedIndex!].label}: ${Extractor.formatPkr(points[_selectedIndex!].valuePaisa)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          SizedBox(
            height: 180,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onPanDown: (details) => _handleTouch(details.localPosition.dx, constraints.maxWidth, points.length),
                  onPanUpdate: (details) => _handleTouch(details.localPosition.dx, constraints.maxWidth, points.length),
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, 180),
                    painter: _SalesChartPainter(
                      points: points,
                      maxRupees: maxRupees,
                      selectedIndex: _selectedIndex,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleTouch(double x, double totalWidth, int count) {
    if (count <= 1 || totalWidth <= 0) return;
    final step = totalWidth / (count - 1);
    final index = (x / step).round().clamp(0, count - 1);
    setState(() => _selectedIndex = index);
  }

  List<TrendPoint> _defaultPoints() {
    return [
      const TrendPoint(label: '10-01', valuePaisa: 0),
      const TrendPoint(label: '10-04', valuePaisa: 0),
      const TrendPoint(label: '10-07', valuePaisa: 0),
      const TrendPoint(label: '10-10', valuePaisa: 0),
      const TrendPoint(label: '10-13', valuePaisa: 0),
      const TrendPoint(label: '10-16', valuePaisa: 0),
      const TrendPoint(label: '10-19', valuePaisa: 12550),
      const TrendPoint(label: '10-22', valuePaisa: 0),
      const TrendPoint(label: '10-25', valuePaisa: 0),
      const TrendPoint(label: '10-28', valuePaisa: 0),
      const TrendPoint(label: '10-31', valuePaisa: 0),
    ];
  }
}

class _SalesChartPainter extends CustomPainter {
  _SalesChartPainter({
    required this.points,
    required this.maxRupees,
    this.selectedIndex,
  });

  final List<TrendPoint> points;
  final double maxRupees;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final leftPadding = 35.0;
    final bottomPadding = 25.0;
    final chartWidth = size.width - leftPadding;
    final chartHeight = size.height - bottomPadding;

    // Draw Grid Lines & Y-axis labels
    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final ySteps = 4;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i <= ySteps; i++) {
      final y = chartHeight - (i * (chartHeight / ySteps));
      final value = (maxRupees / ySteps) * i;

      // Dashed grid line
      _drawDashedLine(canvas, Offset(leftPadding, y), Offset(size.width, y), gridPaint);

      // Y-axis label
      textPainter.text = TextSpan(
        text: value.toInt().toString(),
        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(leftPadding - textPainter.width - 6, y - textPainter.height / 2));
    }

    if (points.isEmpty) return;

    final stepX = points.length > 1 ? chartWidth / (points.length - 1) : chartWidth;
    final coords = <Offset>[];

    for (int i = 0; i < points.length; i++) {
      final x = leftPadding + (i * stepX);
      final valRupees = points[i].valuePaisa / 100.0;
      final ratio = maxRupees > 0 ? (valRupees / maxRupees) : 0.0;
      final y = chartHeight - (ratio * chartHeight);
      coords.add(Offset(x, y));

      // X-axis label
      if (i % 2 == 0 || i == points.length - 1) {
        textPainter.text = TextSpan(
          text: points[i].label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - textPainter.width / 2, chartHeight + 8));
      }
    }

    // Build smooth cubic bezier path
    final path = Path();
    final fillPath = Path();

    path.moveTo(coords[0].dx, coords[0].dy);
    fillPath.moveTo(coords[0].dx, chartHeight);
    fillPath.lineTo(coords[0].dx, coords[0].dy);

    for (int i = 0; i < coords.length - 1; i++) {
      final p0 = coords[i];
      final p1 = coords[i + 1];
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);

      path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p1.dx, p1.dy);
      fillPath.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p1.dx, p1.dy);
    }

    fillPath.lineTo(coords.last.dx, chartHeight);
    fillPath.close();

    // Fill gradient
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.primary.withValues(alpha: 0.18),
        AppColors.primary.withValues(alpha: 0.0),
      ],
    );
    final fillPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(leftPadding, 0, chartWidth, chartHeight))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Draw main curve line
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    // Highlight selected or peak point
    if (selectedIndex != null && selectedIndex! < coords.length) {
      final selectedOffset = coords[selectedIndex!];
      final dotPaint = Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.fill;
      final outerDot = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(selectedOffset, 6, dotPaint);
      canvas.drawCircle(selectedOffset, 3.5, outerDot);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = p1.dx;
    while (startX < p2.dx) {
      canvas.drawLine(Offset(startX, p1.dy), Offset(min(startX + dashWidth, p2.dx), p1.dy), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _SalesChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.selectedIndex != selectedIndex;
  }
}

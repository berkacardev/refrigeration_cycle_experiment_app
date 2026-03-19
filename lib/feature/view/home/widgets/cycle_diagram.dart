import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:refrigeration_cycle_experiment_app/feature/viewmodel/experiment_provider.dart';
import 'package:refrigeration_cycle_experiment_app/product/theme/app_theme.dart';
import 'package:refrigeration_cycle_experiment_app/product/lang/tr.dart';

class CycleStrip extends StatefulWidget {
  const CycleStrip();
  @override
  State<CycleStrip> createState() => _CycleStripState();
}

class _CycleStripState extends State<CycleStrip> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ExperimentProvider>();
    final r = prov.latest;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
      child: CycleDiagram(
        fluidLabel: prov.selectedFluid.label,
        running: prov.running,
        animController: _animCtrl,
        evapTemp: r?.evapTemp,
        evapPressure: r?.evapPressure,
        condenserTemp: r?.condenserTemp,
        waterTemp: r?.waterTemp,
      ),
    );
  }
}

class CycleDiagram extends StatelessWidget {
  final String fluidLabel;
  final bool running;
  final AnimationController? animController;
  final double? evapTemp;
  final double? evapPressure;
  final double? condenserTemp;
  final double? waterTemp;
  const CycleDiagram({
    super.key,
    required this.fluidLabel,
    this.running = false,
    this.animController,
    this.evapTemp,
    this.evapPressure,
    this.condenserTemp,
    this.waterTemp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x0A1E3250), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: (animController != null && running)
            ? AnimatedBuilder(
          animation: animController!,
          builder: (_, __) => CustomPaint(
            painter: _CyclePainter(
              fluidLabel: fluidLabel,
              flowPhase: animController!.value,
              evapTemp: evapTemp,
              evapPressure: evapPressure,
              condenserTemp: condenserTemp,
              waterTemp: waterTemp,
            ),
            child: const SizedBox.expand(),
          ),
        )
            : CustomPaint(
          painter: _CyclePainter(
            fluidLabel: fluidLabel,
            flowPhase: -1,
            evapTemp: evapTemp,
            evapPressure: evapPressure,
            condenserTemp: condenserTemp,
            waterTemp: waterTemp,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _CyclePainter extends CustomPainter {
  final String fluidLabel;
  final double flowPhase;
  final double? evapTemp;
  final double? evapPressure;
  final double? condenserTemp;
  final double? waterTemp;
  const _CyclePainter({
    required this.fluidLabel,
    this.flowPhase = -1,
    this.evapTemp,
    this.evapPressure,
    this.condenserTemp,
    this.waterTemp,
  });

  bool get _animating => flowPhase >= 0;

  Paint _line(Color c, {double w = 2.0}) =>
      Paint()..color = c..strokeWidth = w..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;

  Paint _fill(Color c) => Paint()..color = c..style = PaintingStyle.fill;

  void _arrow(Canvas canvas, Offset tip, double angleDeg, Color color, {double sz = 9}) {
    final a = angleDeg * pi / 180;
    final hw = sz * 0.45;
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(tip.dx - sz * cos(a) + hw * sin(a), tip.dy - sz * sin(a) - hw * cos(a))
        ..lineTo(tip.dx - sz * cos(a) - hw * sin(a), tip.dy - sz * sin(a) + hw * cos(a))
        ..close(),
      _fill(color),
    );
  }

  void _dashedLine(Canvas canvas, Offset from, Offset to, Color color, {double w = 1.5}) {
    final paint = _line(color, w: w);
    final dx = to.dx - from.dx, dy = to.dy - from.dy;
    final len = sqrt(dx * dx + dy * dy);
    if (len < 1) return;
    const dash = 6.0, gap = 4.0;
    double dist = 0;
    bool draw = true;
    final ux = dx / len, uy = dy / len;
    while (dist < len) {
      final end = min(dist + (draw ? dash : gap), len);
      if (draw) {
        canvas.drawLine(
            Offset(from.dx + ux * dist, from.dy + uy * dist),
            Offset(from.dx + ux * end, from.dy + uy * end),
            paint);
      }
      dist = end;
      draw = !draw;
    }
  }

  void _text(Canvas canvas, String txt, Offset pos,
      {double size = 10, Color color = AppColors.text3, bool bold = false, bool center = false}) {
    final tp = TextPainter(
      text: TextSpan(
          text: txt,
          style: TextStyle(
            fontSize: size,
            color: color,
            fontFamily: 'Inter',
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          )),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center ? Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2) : pos);
  }

  void _gradientBox(Canvas canvas, Rect r, Color c1, Color c2, Color stroke, {double radius = 10}) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
    canvas.drawRRect(
        rr,
        Paint()
          ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c1, c2]).createShader(r)
          ..style = PaintingStyle.fill);
    canvas.drawRRect(rr, _line(stroke, w: 2));
  }

  void _pipe(Canvas canvas, List<Offset> pts, Color color, {double w = 3.0}) {
    if (pts.length < 2) return;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) path.lineTo(pts[i].dx, pts[i].dy);
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = w
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
  }

  void _drawCondenserCoils(Canvas canvas, Rect r, Color color) {
    final paint = _line(color.withOpacity(0.25), w: 1.5);
    final innerL = r.left + 12;
    final innerR = r.right - 12;
    final rows = 3;
    final rowH = (r.height - 16) / rows;
    final startY = r.top + 8;
    for (int i = 0; i < rows; i++) {
      final y = startY + rowH * i + rowH / 2;
      final path = Path()..moveTo(innerL, y);
      final segments = 8;
      final segW = (innerR - innerL) / segments;
      for (int j = 0; j < segments; j++) {
        final x1 = innerL + segW * j + segW / 2;
        final yOff = (j % 2 == 0) ? -rowH * 0.2 : rowH * 0.2;
        final x2 = innerL + segW * (j + 1);
        path.quadraticBezierTo(x1, y + yOff, x2, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawEvaporatorTubes(Canvas canvas, Rect r, Color color) {
    final paint = _line(color.withOpacity(0.25), w: 1.5);
    final innerL = r.left + 14;
    final innerR = r.right - 14;
    final rows = 3;
    final rowH = (r.height - 16) / rows;
    final startY = r.top + 8;
    for (int i = 0; i < rows; i++) {
      final y = startY + rowH * i + rowH / 2;
      canvas.drawLine(Offset(innerL, y), Offset(innerR, y), paint);
      if (i < rows - 1) {
        final nextY = startY + rowH * (i + 1) + rowH / 2;
        final connectX = (i % 2 == 0) ? innerR : innerL;
        canvas.drawArc(
          Rect.fromCenter(center: Offset(connectX, (y + nextY) / 2), width: 8, height: nextY - y),
          (i % 2 == 0) ? -pi / 2 : pi / 2,
          pi,
          false,
          paint,
        );
      }
    }
    _text(canvas, '❄', Offset(r.left + 6, r.center.dy), size: 10, color: color.withOpacity(0.3), center: true);
    _text(canvas, '❄', Offset(r.right - 6, r.center.dy), size: 10, color: color.withOpacity(0.3), center: true);
  }

  void _drawCompressorSymbol(Canvas canvas, Offset center, double radius, Color fill, Color stroke) {
    canvas.drawCircle(center, radius, _fill(fill));
    canvas.drawCircle(center, radius, _line(stroke, w: 2.5));
  }

  void _drawExpansionValve(Canvas canvas, Offset center, double size, Color fill, Color stroke) {
    final left = Path()
      ..moveTo(center.dx - size, center.dy - size * 0.6)
      ..lineTo(center.dx, center.dy)
      ..lineTo(center.dx - size, center.dy + size * 0.6)
      ..close();
    final right = Path()
      ..moveTo(center.dx + size, center.dy - size * 0.6)
      ..lineTo(center.dx, center.dy)
      ..lineTo(center.dx + size, center.dy + size * 0.6)
      ..close();
    canvas.drawPath(left, _fill(fill));
    canvas.drawPath(left, _line(stroke, w: 2));
    canvas.drawPath(right, _fill(fill));
    canvas.drawPath(right, _line(stroke, w: 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerX = w / 2;

    final loopHalf = w * 0.28;
    final loopL = centerX - loopHalf;
    final loopR = centerX + loopHalf;
    final loopT = h * 0.15;
    final loopB = h * 0.85;

    const condW = 260.0;
    const condH = 44.0;
    final condRect = Rect.fromCenter(center: Offset(centerX, loopT), width: condW, height: condH);
    final evapRect = Rect.fromCenter(center: Offset(centerX, loopB), width: condW, height: condH);
    final compCenter = Offset(loopR, (loopT + loopB) / 2);
    const compR = 24.0;
    final valveC = Offset(loopL, (loopT + loopB) / 2);
    const valveSize = 12.0;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.40), _fill(const Color(0x06E53935)));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.60, w, h * 0.40), _fill(const Color(0x061565C0)));

    _dashedLine(canvas, Offset(loopL - 6, h * 0.50), Offset(loopR + 6, h * 0.50), const Color(0x18607D8B), w: 0.8);
    _text(canvas, AppStrings.highPressure, Offset(centerX, h * 0.40), color: const Color(0xFFE53935), bold: true, size: 10, center: true);
    _text(canvas, AppStrings.lowPressure, Offset(centerX, h * 0.60), color: const Color(0xFF1565C0), bold: true, size: 10, center: true);

    _pipe(canvas, [
      Offset(loopR, compCenter.dy - compR),
      Offset(loopR, loopT),
      Offset(condRect.right, loopT),
    ], AppColors.hot);
    final basmaArrowY = loopT + (compCenter.dy - compR - loopT) * 0.5;
    _arrow(canvas, Offset(loopR, basmaArrowY), 270, AppColors.hot, sz: 10);
    _arrow(canvas, Offset((condRect.right + loopR) / 2, loopT), 180, AppColors.hot, sz: 10);

    _pipe(canvas, [
      Offset(condRect.left, loopT),
      Offset(loopL, loopT),
      Offset(loopL, valveC.dy - valveSize - 4),
    ], AppColors.water);
    final siviArrowY = (loopT + valveC.dy) / 2 - 10;
    _arrow(canvas, Offset((condRect.left + loopL) / 2, loopT), 180, AppColors.water, sz: 10);
    _arrow(canvas, Offset(loopL, siviArrowY), 90, AppColors.water, sz: 10);

    _pipe(canvas, [
      Offset(loopL, valveC.dy + valveSize + 4),
      Offset(loopL, loopB),
      Offset(evapRect.left, loopB),
    ], const Color(0xFF42A5F5));
    final islakArrowY = (valveC.dy + loopB) / 2 + 10;
    _arrow(canvas, Offset(loopL, islakArrowY), 90, const Color(0xFF42A5F5), sz: 10);
    _arrow(canvas, Offset((loopL + evapRect.left) / 2, loopB), 0, const Color(0xFF42A5F5), sz: 10);

    _pipe(canvas, [
      Offset(evapRect.right, loopB),
      Offset(loopR, loopB),
      Offset(loopR, compCenter.dy + compR),
    ], AppColors.cold);
    final emisArrowY = (compCenter.dy + compR + loopB) / 2;
    _arrow(canvas, Offset((evapRect.right + loopR) / 2, loopB), 0, AppColors.cold, sz: 10);
    _arrow(canvas, Offset(loopR, emisArrowY), 270, AppColors.cold, sz: 10);

    _text(canvas, AppStrings.dischargeLine, Offset(loopR + 14, basmaArrowY - 7), color: const Color(0xFFD32F2F), bold: true, size: 11);
    _text(canvas, AppStrings.superheatedVapor, Offset(loopR + 14, basmaArrowY + 7), color: const Color(0xFFD32F2F), size: 10);
    _text(canvas, AppStrings.suctionLine, Offset(loopR + 14, emisArrowY - 7), color: const Color(0xFF1565C0), bold: true, size: 11);
    _text(canvas, AppStrings.saturatedVapor, Offset(loopR + 14, emisArrowY + 7), color: const Color(0xFF1565C0), size: 10);
    _text(canvas, AppStrings.liquidLine, Offset(loopL - 50, siviArrowY - 7), color: const Color(0xFF1565C0), bold: true, size: 11, center: true);
    _text(canvas, AppStrings.condensedLiquid, Offset(loopL - 50, siviArrowY + 7), color: const Color(0xFF1565C0), size: 10, center: true);
    _text(canvas, AppStrings.afterExpansion, Offset(loopL - 56, islakArrowY - 7), color: const Color(0xFF1976D2), bold: true, size: 11, center: true);
    _text(canvas, AppStrings.wetVapor, Offset(loopL - 56, islakArrowY + 7), color: const Color(0xFF1976D2), size: 10, center: true);

    _gradientBox(canvas, condRect, const Color(0xFFFFEBEE), const Color(0xFFFFCDD2), AppColors.hot);
    _drawCondenserCoils(canvas, condRect, AppColors.hot);
    _text(canvas, AppStrings.condenserLabel, Offset(centerX, condRect.center.dy - 3), color: AppColors.hot, bold: true, size: 14, center: true);
    _text(canvas, AppStrings.heatRejection, Offset(centerX, condRect.center.dy + 13), color: const Color(0xFFB71C1C), size: 10, center: true);

    _gradientBox(canvas, evapRect, const Color(0xFFE3F2FD), const Color(0xFFBBDEFB), AppColors.cold);
    _drawEvaporatorTubes(canvas, evapRect, AppColors.cold);
    _text(canvas, AppStrings.evaporatorLabel, Offset(centerX, evapRect.center.dy - 3), color: AppColors.cold, bold: true, size: 14, center: true);
    _text(canvas, AppStrings.heatAbsorption, Offset(centerX, evapRect.center.dy + 13), color: const Color(0xFF1565C0), size: 10, center: true);

    _drawCompressorSymbol(canvas, compCenter, compR, const Color(0xFFFFF8E1), AppColors.amber);
    _text(canvas, 'K', Offset(compCenter.dx, compCenter.dy), color: AppColors.amber, bold: true, size: 13, center: true);
    _text(canvas, AppStrings.compressorLabel, Offset(compCenter.dx - compR - 38, compCenter.dy), color: AppColors.amber, bold: true, size: 10, center: true);
    final wTip = Offset(compCenter.dx + compR + 2, compCenter.dy);
    canvas.drawLine(Offset(compCenter.dx + compR + 20, compCenter.dy), wTip, _line(AppColors.text3, w: 2));
    _arrow(canvas, wTip, 180, AppColors.text3, sz: 7);
    _text(canvas, 'W', Offset(compCenter.dx + compR + 24, compCenter.dy), color: AppColors.text2, bold: true, size: 12, center: true);

    _drawExpansionValve(canvas, valveC, valveSize, const Color(0xFFFFF8E1), AppColors.amber);
    _text(canvas, AppStrings.expansionValve, Offset(loopL + valveSize + 30, valveC.dy - 8), color: AppColors.amber, bold: true, size: 10, center: true);
    _text(canvas, AppStrings.valve, Offset(loopL + valveSize + 30, valveC.dy + 6), color: AppColors.amber, bold: true, size: 10, center: true);

    _text(canvas, fluidLabel, Offset(w - 10, h - 10), color: AppColors.text3, size: 9, bold: true);

    if (evapTemp != null || evapPressure != null) {
      _drawEvapProbes(canvas, evapRect, loopR, loopB);
    }
    if (condenserTemp != null) {
      _drawCondenserProbes(canvas, condRect, loopL, loopT);
    }
    if (waterTemp != null) {
      _drawWaterTempProbe(canvas, condRect, evapRect, loopR, loopB);
    }

    if (_animating) {
      _drawFlowDots(canvas, loopL, loopR, loopT, loopB, compCenter, compR, valveC, valveSize, condRect, evapRect);
    }
  }

  void _drawEvapProbes(Canvas canvas, Rect evapRect, double loopR, double loopB) {
    final pipeY = loopB;
    final segmentLen = loopR - evapRect.right;

    final p1X = evapRect.right + segmentLen * 0.30;
    final p2X = evapRect.right + segmentLen * 0.60;

    const stemH = 22.0;
    const stemW = 2.0;

    _drawProbeUnit(
      canvas,
      pipeX: p1X,
      pipeY: pipeY,
      stemH: stemH,
      stemW: stemW,
      icon: '°C',
      label: AppStrings.probeEvapTemp,
      value: evapTemp != null ? '${evapTemp!.toStringAsFixed(1)}' : '—',
      unit: '°C',
      accentColor: AppColors.cold,
    );

    _drawProbeUnit(
      canvas,
      pipeX: p2X,
      pipeY: pipeY,
      stemH: stemH,
      stemW: stemW,
      icon: 'P',
      label: AppStrings.probeEvapPressure,
      value: evapPressure != null ? '${evapPressure!.toStringAsFixed(2)}' : '—',
      unit: 'bar',
      accentColor: AppColors.cold,
    );
  }

  void _drawProbeUnit(Canvas canvas, {
    required double pipeX,
    required double pipeY,
    required double stemH,
    required double stemW,
    required String icon,
    required String label,
    required String value,
    required String unit,
    required Color accentColor,
  }) {
    final stemTop = pipeY - stemH;

    canvas.drawCircle(Offset(pipeX, pipeY), 5.0, _fill(Colors.white));
    canvas.drawCircle(Offset(pipeX, pipeY), 5.0, _line(accentColor, w: 2.5));
    canvas.drawCircle(Offset(pipeX, pipeY), 2.0, _fill(accentColor));

    canvas.drawLine(
      Offset(pipeX, pipeY - 5),
      Offset(pipeX, stemTop + 2),
      _line(accentColor, w: stemW),
    );

    final cardCenterY = stemTop - 16;

    final valueTp = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontSize: 14, color: accentColor,
          fontFamily: 'JetBrainsMono', fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final unitTp = TextPainter(
      text: TextSpan(
        text: ' $unit',
        style: TextStyle(
          fontSize: 10, color: accentColor.withOpacity(0.7),
          fontFamily: 'JetBrainsMono', fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelTp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 8, color: accentColor.withOpacity(0.6),
          fontFamily: 'Inter', fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final rowW = valueTp.width + unitTp.width;
    final cardW = max(rowW, labelTp.width) + 18;
    final cardH = valueTp.height + labelTp.height + 12;
    final cardRect = Rect.fromCenter(
      center: Offset(pipeX, cardCenterY),
      width: cardW,
      height: cardH,
    );

    final shadowRect = cardRect.shift(const Offset(0, 1.5));
    canvas.drawRRect(
      RRect.fromRectAndRadius(shadowRect, const Radius.circular(7)),
      _fill(Colors.black.withOpacity(0.08)),
    );

    final cardRR = RRect.fromRectAndRadius(cardRect, const Radius.circular(7));
    canvas.drawRRect(cardRR, _fill(Colors.white));
    canvas.drawRRect(cardRR, _line(accentColor.withOpacity(0.4), w: 1.5));

    final accentBar = RRect.fromLTRBAndCorners(
      cardRect.left, cardRect.top + 3, cardRect.left + 4, cardRect.bottom - 3,
      topLeft: const Radius.circular(2), bottomLeft: const Radius.circular(2),
    );
    canvas.drawRRect(accentBar, _fill(accentColor));

    labelTp.paint(canvas, Offset(
      cardRect.left + (cardW - labelTp.width) / 2,
      cardRect.top + 4,
    ));

    final rowStartX = cardRect.left + (cardW - rowW) / 2;
    valueTp.paint(canvas, Offset(rowStartX, cardRect.top + 5 + labelTp.height + 2));
    unitTp.paint(canvas, Offset(rowStartX + valueTp.width, cardRect.top + 5 + labelTp.height + 6));

    _dashedLine(
      canvas,
      Offset(pipeX, cardRect.bottom),
      Offset(pipeX, stemTop + 2),
      accentColor.withOpacity(0.3),
      w: 0.8,
    );
  }

  void _drawCondenserProbes(Canvas canvas, Rect condRect, double loopL, double loopT) {
    final pipeY = loopT;
    final segmentLen = condRect.left - loopL;

    final p1X = condRect.left - segmentLen * 0.40;

    const stemH = 22.0;
    const stemW = 2.0;

    _drawProbeUnitDown(
      canvas,
      pipeX: p1X,
      pipeY: pipeY,
      stemH: stemH,
      stemW: stemW,
      icon: '°C',
      label: AppStrings.probeCondTemp,
      value: condenserTemp != null ? '${condenserTemp!.toStringAsFixed(1)}' : '—',
      unit: '°C',
      accentColor: AppColors.amber,
    );
  }

  void _drawWaterTempProbe(Canvas canvas, Rect condRect, Rect evapRect, double loopR, double loopB) {
    final color = AppColors.hot;

    final startX = condRect.right;
    final startY = condRect.bottom;

    final extendX = condRect.right + 70;

    final loopT = condRect.top + (condRect.height / 2) - (condRect.height / 2);
    final condPipeY = condRect.center.dy;
    const stemH = 22.0;
    final sensorHeadY = condPipeY + stemH;

    canvas.drawCircle(Offset(startX, startY), 4.0, _fill(Colors.white));
    canvas.drawCircle(Offset(startX, startY), 4.0, _line(color, w: 2.0));
    canvas.drawCircle(Offset(startX, startY), 1.5, _fill(color));

    canvas.drawLine(
      Offset(startX + 4, startY),
      Offset(extendX, startY),
      _line(color, w: 2.0),
    );

    canvas.drawLine(
      Offset(extendX, startY),
      Offset(extendX, sensorHeadY),
      _line(color, w: 2.0),
    );

    canvas.drawCircle(Offset(extendX, startY), 2.5, _fill(color));

    final cardTopY = sensorHeadY + 4;

    final valueTp = TextPainter(
      text: TextSpan(
        text: waterTemp != null ? '${waterTemp!.toStringAsFixed(1)}' : '—',
        style: TextStyle(fontSize: 14, color: color, fontFamily: 'JetBrainsMono', fontWeight: FontWeight.w900),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final unitTp = TextPainter(
      text: TextSpan(
        text: ' °C',
        style: TextStyle(fontSize: 10, color: color.withOpacity(0.7), fontFamily: 'JetBrainsMono', fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelTp = TextPainter(
      text: TextSpan(
        text: AppStrings.probeWaterTemp,
        style: TextStyle(fontSize: 8, color: color.withOpacity(0.6), fontFamily: 'Inter', fontWeight: FontWeight.w600, letterSpacing: 0.5),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final rowW = valueTp.width + unitTp.width;
    final cardW = max(rowW, labelTp.width) + 18;
    final cardH = valueTp.height + labelTp.height + 12;
    final cardRect = Rect.fromCenter(
      center: Offset(extendX, cardTopY + cardH / 2),
      width: cardW,
      height: cardH,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(cardRect.shift(const Offset(0, 1.5)), const Radius.circular(7)),
      _fill(Colors.black.withOpacity(0.08)),
    );
    final cardRR = RRect.fromRectAndRadius(cardRect, const Radius.circular(7));
    canvas.drawRRect(cardRR, _fill(Colors.white));
    canvas.drawRRect(cardRR, _line(color.withOpacity(0.4), w: 1.5));
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        cardRect.left, cardRect.top + 3, cardRect.left + 4, cardRect.bottom - 3,
        topLeft: const Radius.circular(2), bottomLeft: const Radius.circular(2),
      ),
      _fill(color),
    );
    labelTp.paint(canvas, Offset(cardRect.left + (cardW - labelTp.width) / 2, cardRect.top + 4));
    final rsx = cardRect.left + (cardW - rowW) / 2;
    valueTp.paint(canvas, Offset(rsx, cardRect.top + 5 + labelTp.height + 2));
    unitTp.paint(canvas, Offset(rsx + valueTp.width, cardRect.top + 5 + labelTp.height + 6));

    _dashedLine(canvas, Offset(extendX, sensorHeadY), Offset(extendX, cardRect.top), color.withOpacity(0.3), w: 0.8);
  }

  void _drawProbeUnitDown(Canvas canvas, {
    required double pipeX,
    required double pipeY,
    required double stemH,
    required double stemW,
    required String icon,
    required String label,
    required String value,
    required String unit,
    required Color accentColor,
  }) {
    final stemBottom = pipeY + stemH;

    canvas.drawCircle(Offset(pipeX, pipeY), 5.0, _fill(Colors.white));
    canvas.drawCircle(Offset(pipeX, pipeY), 5.0, _line(accentColor, w: 2.5));
    canvas.drawCircle(Offset(pipeX, pipeY), 2.0, _fill(accentColor));

    canvas.drawLine(
      Offset(pipeX, pipeY + 5),
      Offset(pipeX, stemBottom),
      _line(accentColor, w: stemW),
    );

    final cardCenterY = stemBottom + 18;

    final valueTp = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontSize: 14, color: accentColor,
          fontFamily: 'JetBrainsMono', fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final unitTp = TextPainter(
      text: TextSpan(
        text: ' $unit',
        style: TextStyle(
          fontSize: 10, color: accentColor.withOpacity(0.7),
          fontFamily: 'JetBrainsMono', fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelTp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 8, color: accentColor.withOpacity(0.6),
          fontFamily: 'Inter', fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final rowW = valueTp.width + unitTp.width;
    final cardW = max(rowW, labelTp.width) + 18;
    final cardH = valueTp.height + labelTp.height + 12;
    final cardRect = Rect.fromCenter(
      center: Offset(pipeX, cardCenterY),
      width: cardW,
      height: cardH,
    );

    final shadowRect = cardRect.shift(const Offset(0, 1.5));
    canvas.drawRRect(
      RRect.fromRectAndRadius(shadowRect, const Radius.circular(6)),
      _fill(Colors.black.withOpacity(0.06)),
    );

    final cardRR = RRect.fromRectAndRadius(cardRect, const Radius.circular(6));
    canvas.drawRRect(cardRR, _fill(Colors.white));
    canvas.drawRRect(cardRR, _line(accentColor.withOpacity(0.35), w: 1.2));

    final accentBar = RRect.fromLTRBAndCorners(
      cardRect.left, cardRect.top + 2, cardRect.left + 3, cardRect.bottom - 2,
      topLeft: const Radius.circular(2), bottomLeft: const Radius.circular(2),
    );
    canvas.drawRRect(accentBar, _fill(accentColor));

    labelTp.paint(canvas, Offset(
      cardRect.left + (cardW - labelTp.width) / 2,
      cardRect.top + 4,
    ));

    final rowStartX = cardRect.left + (cardW - rowW) / 2;
    valueTp.paint(canvas, Offset(rowStartX, cardRect.top + 4 + labelTp.height + 2));
    unitTp.paint(canvas, Offset(rowStartX + valueTp.width, cardRect.top + 4 + labelTp.height + 4));

    _dashedLine(
      canvas,
      Offset(pipeX, stemBottom),
      Offset(pipeX, cardRect.top),
      accentColor.withOpacity(0.3),
      w: 0.8,
    );
  }

  void _drawFlowDots(Canvas canvas, double loopL, double loopR, double loopT, double loopB,
      Offset compCenter, double compR, Offset valveC, double valveSize, Rect condRect, Rect evapRect) {
    final segments = <List<Offset>>[];
    final colors = <Color>[];

    segments.add([
      Offset(loopR, compCenter.dy - compR),
      Offset(loopR, loopT),
      Offset(condRect.right, loopT),
    ]);
    colors.add(AppColors.hot);

    segments.add([
      Offset(condRect.left, loopT),
      Offset(loopL, loopT),
      Offset(loopL, valveC.dy - valveSize - 4),
    ]);
    colors.add(AppColors.water);

    segments.add([
      Offset(loopL, valveC.dy + valveSize + 4),
      Offset(loopL, loopB),
      Offset(evapRect.left, loopB),
    ]);
    colors.add(const Color(0xFF42A5F5));

    segments.add([
      Offset(evapRect.right, loopB),
      Offset(loopR, loopB),
      Offset(loopR, compCenter.dy + compR),
    ]);
    colors.add(AppColors.cold);

    const int dotsPerSegment = 4;
    for (int s = 0; s < segments.length; s++) {
      final pts = segments[s];
      final color = colors[s];

      double totalLen = 0;
      final segLens = <double>[];
      for (int i = 0; i < pts.length - 1; i++) {
        final dx = pts[i + 1].dx - pts[i].dx;
        final dy = pts[i + 1].dy - pts[i].dy;
        final len = sqrt(dx * dx + dy * dy);
        segLens.add(len);
        totalLen += len;
      }
      if (totalLen < 1) continue;

      for (int d = 0; d < dotsPerSegment; d++) {
        final t = ((flowPhase + d / dotsPerSegment) % 1.0);
        final targetDist = t * totalLen;

        double accumulated = 0;
        for (int i = 0; i < segLens.length; i++) {
          if (accumulated + segLens[i] >= targetDist) {
            final localT = (targetDist - accumulated) / segLens[i];
            final x = pts[i].dx + (pts[i + 1].dx - pts[i].dx) * localT;
            final y = pts[i].dy + (pts[i + 1].dy - pts[i].dy) * localT;

            final opacity = 0.4 + 0.6 * (1.0 - (d / dotsPerSegment));
            canvas.drawCircle(Offset(x, y), 3.5, Paint()..color = color.withOpacity(opacity));
            canvas.drawCircle(Offset(x, y), 2.0, Paint()..color = Colors.white.withOpacity(opacity * 0.8));
            break;
          }
          accumulated += segLens[i];
        }
      }
    }
  }

  @override
  bool shouldRepaint(_CyclePainter old) =>
      old.fluidLabel != fluidLabel ||
          old.flowPhase != flowPhase ||
          old.evapTemp != evapTemp ||
          old.evapPressure != evapPressure ||
          old.condenserTemp != condenserTemp ||
          old.waterTemp != waterTemp;
}

class DiagramToggleBtn extends StatefulWidget {
  final bool show;
  final VoidCallback onTap;
  const DiagramToggleBtn({required this.show, required this.onTap});

  @override
  State<DiagramToggleBtn> createState() => _DiagramToggleBtnState();
}

class _DiagramToggleBtnState extends State<DiagramToggleBtn> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Tooltip(
        message: widget.show ? AppStrings.hideDiagram : AppStrings.showDiagram,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _hovering ? const Color(0xFFE3F2FD) : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _hovering ? AppColors.cold : AppColors.divider,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.show ? Icons.visibility_off : Icons.visibility,
                  size: 14,
                  color: _hovering ? AppColors.cold : AppColors.text3,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.show ? AppStrings.hide : AppStrings.showDiagram,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: _hovering ? AppColors.cold : AppColors.text3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
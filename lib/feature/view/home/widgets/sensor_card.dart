import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:refrigeration_cycle_experiment_app/product/theme/app_theme.dart';
import 'package:refrigeration_cycle_experiment_app/product/widgets/shared_widgets.dart';
import 'package:refrigeration_cycle_experiment_app/product/lang/tr.dart';

class SensorCard extends StatelessWidget {
  final String title;
  final String unit;
  final double? value;
  final Color accentColor;
  final Color softColor;
  final List<double> buffer;
  final List<double>? buffer2;
  final Color? color2;
  final List<DateTime> timestamps;
  final List<Widget>? valueBadges;
  final VoidCallback? onMinimize;
  final VoidCallback? onFullscreen;
  final bool showWindowControls;

  const SensorCard({
    super.key,
    required this.title,
    required this.unit,
    required this.value,
    required this.accentColor,
    required this.softColor,
    required this.buffer,
    required this.timestamps,
    this.buffer2,
    this.color2,
    this.valueBadges,
    this.onMinimize,
    this.onFullscreen,
    this.showWindowControls = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4EAEF), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x0F1E3250), offset: Offset(0, 2), blurRadius: 8),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(height: 4.0, color: accentColor),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(title, style: AppTextStyles.label(), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 6),
                    if (showWindowControls && (onMinimize != null || onFullscreen != null))
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onMinimize != null)
                            MiniIconBtn(
                              icon: Icons.minimize,
                              tooltip: AppStrings.minimize,
                              color: accentColor,
                              onTap: onMinimize!,
                              size: 16,
                            ),
                          if (onFullscreen != null)
                            MiniIconBtn(
                              icon: Icons.open_in_full,
                              tooltip: AppStrings.fullscreen,
                              color: accentColor,
                              onTap: onFullscreen!,
                              size: 16,
                            ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    LiveBadge(value: value, unit: unit, color: accentColor, softColor: softColor),
                  ],
                ),
                if (valueBadges != null && valueBadges!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: valueBadges!,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value != null ? value!.toStringAsFixed(unit == 'bar' ? 2 : 1) : '—',
                      style: AppTextStyles.monoBig(color: accentColor),
                    ),
                    const SizedBox(width: 4),
                    Text(unit, style: AppTextStyles.unit()),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _MiniLineChart(
                    buffer: buffer,
                    buffer2: buffer2,
                    timestamps: timestamps,
                    lineColor: accentColor,
                    fillColor: softColor.withOpacity(0.4),
                    lineColor2: color2,
                    unit: unit,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LiveBadge extends StatelessWidget {
  final double? value;
  final String unit;
  final Color color, softColor;
  const LiveBadge({required this.value, required this.unit, required this.color, required this.softColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: softColor, borderRadius: BorderRadius.circular(20)),
      child: Text(
        value != null ? '${value!.toStringAsFixed(unit == 'bar' ? 2 : 1)} $unit' : '— $unit',
        style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 9, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _MiniLineChart extends StatefulWidget {
  final List<double> buffer;
  final List<double>? buffer2;
  final List<DateTime> timestamps;
  final Color lineColor, fillColor;
  final Color? lineColor2;
  final String unit;

  const _MiniLineChart({
    required this.buffer,
    this.buffer2,
    required this.timestamps,
    required this.lineColor,
    required this.fillColor,
    this.lineColor2,
    this.unit = '',
  });

  @override
  State<_MiniLineChart> createState() => _MiniLineChartState();
}

class _MiniLineChartState extends State<_MiniLineChart>
    with SingleTickerProviderStateMixin {
  final Set<int> _lockedIndices = {};

  late AnimationController _yAxisCtrl;
  double _currentMinY = -20;
  double _currentMaxY = 50;
  double _targetMinY = -20;
  double _targetMaxY = 50;
  double _fromMinY = -20;
  double _fromMaxY = 50;
  bool _firstData = true;

  @override
  void initState() {
    super.initState();
    _yAxisCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(() {
      final t = Curves.easeOutCubic.transform(_yAxisCtrl.value);
      setState(() {
        _currentMinY = _fromMinY + (_targetMinY - _fromMinY) * t;
        _currentMaxY = _fromMaxY + (_targetMaxY - _fromMaxY) * t;
      });
    });
  }

  @override
  void dispose() {
    _yAxisCtrl.dispose();
    super.dispose();
  }

  void _updateYBounds(double newMin, double newMax) {
    if (_firstData) {
      _firstData = false;
      _currentMinY = newMin;
      _currentMaxY = newMax;
      _targetMinY = newMin;
      _targetMaxY = newMax;
      _fromMinY = newMin;
      _fromMaxY = newMax;
      return;
    }
    if ((newMin - _targetMinY).abs() < 0.1 && (newMax - _targetMaxY).abs() < 0.1) return;

    _fromMinY = _currentMinY;
    _fromMaxY = _currentMaxY;
    _targetMinY = newMin;
    _targetMaxY = newMax;
    _yAxisCtrl.forward(from: 0);
  }

  List<FlSpot> _spots(List<double> buf) {
    final spots = <FlSpot>[];
    for (int i = 0; i < buf.length; i++) {
      spots.add(FlSpot(i.toDouble(), buf[i]));
    }
    return spots;
  }

  double _calcMin(List<double> buf) {
    if (buf.isEmpty) return widget.unit == 'bar' ? 0 : -20;
    final v = buf.reduce((a, b) => a < b ? a : b);
    final padding = _dynamicPadding(buf);
    final raw = v - padding;
    final interval = _computeYInterval(raw, _calcMaxRaw(buf) + padding);
    return (raw / interval).floorToDouble() * interval;
  }

  double _calcMax(List<double> buf) {
    if (buf.isEmpty) return widget.unit == 'bar' ? 10 : 50;
    final v = buf.reduce((a, b) => a > b ? a : b);
    final padding = _dynamicPadding(buf);
    final raw = v + padding;
    final interval = _computeYInterval(_calcMinRaw(buf) - padding, raw);
    return (raw / interval).ceilToDouble() * interval;
  }

  double _calcMinRaw(List<double> buf) => buf.reduce((a, b) => a < b ? a : b);
  double _calcMaxRaw(List<double> buf) => buf.reduce((a, b) => a > b ? a : b);

  double _dynamicPadding(List<double> buf) {
    if (buf.length < 2) return 1.0;
    final minV = buf.reduce((a, b) => a < b ? a : b);
    final maxV = buf.reduce((a, b) => a > b ? a : b);
    final range = maxV - minV;
    if (range < 0.5) return 1.0;
    return (range * 0.15).clamp(0.3, 5.0);
  }

  double _computeYInterval(double minY, double maxY) {
    final range = maxY - minY;
    if (range <= 0) return 1.0;

    final raw = range / 5.0;

    final mag = pow(10, (log(raw) / ln10).floorToDouble()).toDouble();
    final candidates = [mag, mag * 2, mag * 5, mag * 10];
    for (final c in candidates) {
      if (c >= raw) return c < 1 ? 1.0 : c;
    }
    return raw.ceilToDouble().clamp(1.0, 100.0);
  }

  String _fmtDur(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}s ${m.toString().padLeft(2, '0')}dk';
    if (m > 0) return '${m}dk ${s.toString().padLeft(2, '0')}sn';
    return '${s}sn';
  }

  String _fmtTime(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
  }

  double _niceTimeInterval(double totalSeconds, int targetCount) {
    if (totalSeconds <= 0 || targetCount <= 1) return 1.0;
    final raw = totalSeconds / targetCount;
    const niceSteps = [1, 2, 5, 10, 15, 30, 60, 120, 300, 600, 900, 1800, 3600];
    for (final s in niceSteps) {
      if (s >= raw) return s.toDouble();
    }
    return (raw / 3600).ceilToDouble() * 3600;
  }

  int _closestIndex(List<DateTime> timestamps, DateTime targetTime) {
    int best = 0;
    int bestDiff = (timestamps[0].difference(targetTime).inMilliseconds).abs();
    for (int i = 1; i < timestamps.length; i++) {
      final diff = (timestamps[i].difference(targetTime).inMilliseconds).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = i;
      }
      if (diff > bestDiff) break;
    }
    return best;
  }

  Set<int> _computeTimeBasedIndices(List<DateTime> timestamps, int targetCount) {
    if (timestamps.length < 2) return {};

    final firstTime = timestamps.first;
    final totalSec = timestamps.last.difference(firstTime).inMilliseconds / 1000.0;

    if (totalSec <= 0) return {0};

    final interval = _niceTimeInterval(totalSec, targetCount);
    final result = <int>{};
    final seenLabels = <String>{};

    double t = 0;
    while (t <= totalSec + 0.01) {
      final targetTime = firstTime.add(Duration(milliseconds: (t * 1000).round()));
      final idx = _closestIndex(timestamps, targetTime);
      final elapsed = timestamps[idx].difference(firstTime);
      final label = _fmtDur(elapsed);
      if (!seenLabels.contains(label)) {
        seenLabels.add(label);
        result.add(idx);
      }
      t += interval;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final spots1 = _spots(widget.buffer);
    final allVals = [widget.buffer, if (widget.buffer2 != null) widget.buffer2!].expand((b) => b).toList();

    final targetMinY = _calcMin(allVals);
    final targetMaxY = _calcMax(allVals);
    _updateYBounds(targetMinY, targetMaxY);

    final minY = _currentMinY;
    final maxY = _currentMaxY;
    final maxX = widget.buffer.isEmpty ? 1.0 : (widget.buffer.length - 1).toDouble();
    final hasTimes = widget.timestamps.isNotEmpty && widget.timestamps.length >= 2;

    const int targetLabelCount = 10;
    final alw = _computeTimeBasedIndices(widget.timestamps, targetLabelCount);

    final yInt = _computeYInterval(minY, maxY);

    final ds = <LineChartBarData>[
      LineChartBarData(
        spots: spots1.isEmpty ? [const FlSpot(0, 0)] : spots1,
        isCurved: true,
        curveSmoothness: 0.35,
        color: widget.lineColor,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: _lockedIndices.isNotEmpty,
          checkToShowDot: (spot, barData) => _lockedIndices.contains(spot.x.round()),
          getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
            radius: 5,
            color: Colors.white,
            strokeWidth: 2.5,
            strokeColor: widget.lineColor,
          ),
        ),
        belowBarData: BarAreaData(show: true, color: widget.fillColor),
      ),
      if (widget.buffer2 != null && widget.lineColor2 != null)
        LineChartBarData(
          spots: _spots(widget.buffer2!).isEmpty ? [const FlSpot(0, 0)] : _spots(widget.buffer2!),
          isCurved: true,
          curveSmoothness: 0.35,
          color: widget.lineColor2!,
          barWidth: 2,
          isStrokeCapRound: true,
          dashArray: [5, 3],
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
    ];

    const double leftPad = 56.0;
    const double bottomPad = 28.0;
    final effectiveMaxX = maxX == 0 ? 1.0 : maxX + (maxX * 0.02);

    return LayoutBuilder(builder: (context, constraints) {
      final chartW = constraints.maxWidth - leftPad;

      return Stack(
        clipBehavior: Clip.none,
        children: [
          LineChart(
            LineChartData(
              minX: 0,
              maxX: effectiveMaxX,
              minY: minY,
              maxY: maxY,
              clipData: const FlClipData.all(),
              extraLinesData: ExtraLinesData(
                verticalLines: (_lockedIndices.toList()..sort())
                    .where((i) => i < widget.buffer.length)
                    .map((i) => VerticalLine(
                  x: i.toDouble(),
                  color: widget.lineColor.withOpacity(0.35),
                  strokeWidth: 1.5,
                  dashArray: [4, 3],
                ))
                    .toList(),
              ),
              gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yInt,
                  getDrawingHorizontalLine: (_) => FlLine(color: const Color(0x0F1E3250), strokeWidth: 1)),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 56,
                        interval: yInt,
                        getTitlesWidget: (v, meta) {
                          final isBar = widget.unit == 'bar';
                          final abs = v.abs().toStringAsFixed(isBar ? 1 : 0);
                          final sign = v < 0 ? '−' : ' ';
                          return Container(
                            width: 52,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 4),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF212121),
                                ),
                                children: [
                                  TextSpan(text: sign),
                                  TextSpan(text: abs),
                                ],
                              ),
                            ),
                          );
                        })),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: hasTimes && widget.buffer.length > 1,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.round();
                          if ((value - idx).abs() > 0.01) return const SizedBox.shrink();
                          if (idx < 0 || idx >= widget.timestamps.length || !alw.contains(idx)) return const SizedBox.shrink();
                          final elapsed = widget.timestamps[idx].difference(widget.timestamps.first);
                          return Padding(
                              padding: const EdgeInsets.only(top: 4, right: 8),
                              child: Text(_fmtDur(elapsed),
                                  style: const TextStyle(
                                      fontFamily: 'JetBrainsMono',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF212121))));
                        })),
              ),
              lineBarsData: ds,
              lineTouchData: LineTouchData(
                enabled: true,
                touchCallback: (event, response) {
                  if (event is FlTapUpEvent) {
                    if (response?.lineBarSpots != null && response!.lineBarSpots!.isNotEmpty) {
                      final idx = response.lineBarSpots!.first.spotIndex;
                      setState(() {
                        if (_lockedIndices.contains(idx)) {
                          _lockedIndices.remove(idx);
                        } else {
                          _lockedIndices.add(idx);
                        }
                      });
                    }
                  }
                },
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xF5FFFFFF),
                  tooltipBorder: BorderSide(color: widget.lineColor.withOpacity(0.4)),
                  tooltipBorderRadius: BorderRadius.circular(8),
                  tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final idx = spot.x.round();
                      String ts = '', el = '';
                      if (idx >= 0 && idx < widget.timestamps.length) {
                        ts = _fmtTime(widget.timestamps[idx]);
                        el = _fmtDur(widget.timestamps[idx].difference(widget.timestamps.first));
                      }
                      final pinned = _lockedIndices.contains(idx);
                      final decimals = widget.unit == 'bar' ? 2 : 1;
                      return LineTooltipItem(
                          '${pinned ? '\u{1F4CC} ' : ''}${spot.y.toStringAsFixed(decimals)} ${widget.unit}\n$ts ($el)${pinned ? '  \u{2716}' : ''}',
                          TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: spot.bar.color ?? widget.lineColor));
                    }).toList();
                  },
                ),
                handleBuiltInTouches: true,
                getTouchedSpotIndicator: (data, indices) {
                  return indices
                      .map((i) => TouchedSpotIndicatorData(
                      FlLine(color: widget.lineColor.withOpacity(0.4), strokeWidth: 1.5, dashArray: [4, 3]),
                      FlDotData(
                          show: true,
                          getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                              radius: 4, color: Colors.white, strokeWidth: 2, strokeColor: widget.lineColor))))
                      .toList();
                },
              ),
            ),
            duration: const Duration(milliseconds: 200),
          ),
          ...(_lockedIndices.toList()..sort()).where((i) => i < widget.buffer.length).map((i) {
            final xRatio = effectiveMaxX > 0 ? (i.toDouble() / effectiveMaxX) : 0.0;
            final pixelX = leftPad + (chartW * xRatio);
            final val = widget.buffer[i].toStringAsFixed(widget.unit == 'bar' ? 2 : 1);
            final time = i < widget.timestamps.length ? _fmtTime(widget.timestamps[i]) : '';
            final dur = i < widget.timestamps.length && widget.timestamps.isNotEmpty
                ? _fmtDur(widget.timestamps[i].difference(widget.timestamps.first))
                : '';
            return Positioned(
              left: (pixelX - 32).clamp(0.0, constraints.maxWidth - 70),
              top: 2,
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 3, 4, 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: widget.lineColor, width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 4, offset: const Offset(0, 1))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$val ${widget.unit}',
                          style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 9, fontWeight: FontWeight.w800, color: widget.lineColor),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          time,
                          style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 7, fontWeight: FontWeight.w600, color: widget.lineColor.withOpacity(0.7)),
                        ),
                        Text(
                          dur,
                          style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 7, color: widget.lineColor.withOpacity(0.5)),
                        ),
                      ],
                    ),
                    const SizedBox(width: 3),
                    GestureDetector(
                      onTap: () => setState(() => _lockedIndices.remove(i)),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: widget.lineColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close, size: 10, color: widget.lineColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          if (_lockedIndices.length > 1)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => setState(() => _lockedIndices.clear()),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.hot.withOpacity(0.5)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 3)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.delete_sweep, size: 12, color: AppColors.hot),
                        const SizedBox(width: 3),
                        Text(AppStrings.clearCount(_lockedIndices.length),
                            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: AppColors.hot)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

class ValueBadge extends StatelessWidget {
  final String label;
  final double? value;
  final String unit;
  final Color color;
  final Color softColor;

  const ValueBadge({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.softColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: color,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: color.withOpacity(0.75),
              ),
            ),
            TextSpan(
              text: value != null ? '${value!.toStringAsFixed(unit == 'bar' ? 2 : 1)} $unit' : '— $unit',
            ),
          ],
        ),
      ),
    );
  }
}

class SuperheatBadge extends StatefulWidget {
  final double? value;
  const SuperheatBadge({super.key, this.value});

  @override
  State<SuperheatBadge> createState() => _SuperheatBadgeState();
}

class _SuperheatBadgeState extends State<SuperheatBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnim = Tween(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _updateAnimation();
  }

  @override
  void didUpdateWidget(SuperheatBadge old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _updateAnimation();
  }

  void _updateAnimation() {
    final v = widget.value;
    if (v != null && v < 0) {
      _pulseCtrl.repeat(reverse: true);
    } else {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Color _bgColor(double v) {
    if (v >= 5) return const Color(0xFFFFEBEE);
    if (v >= 0) {
      final t = v / 5.0;
      return Color.lerp(const Color(0xFFF3E5F5), const Color(0xFFFFEBEE), t)!;
    }
    return const Color(0xFF7B1FA2);
  }

  Color _borderColor(double v) {
    if (v >= 5) return const Color(0xFFEF9A9A);
    if (v >= 0) {
      final t = v / 5.0;
      return Color.lerp(const Color(0xFFCE93D8), const Color(0xFFEF9A9A), t)!;
    }
    return const Color(0xFF4A148C);
  }

  Color _textColor(double v) {
    if (v >= 5) return const Color(0xFFC62828);
    if (v >= 0) {
      final t = v / 5.0;
      return Color.lerp(const Color(0xFF6A1B9A), const Color(0xFFE53935), t)!;
    }
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.value;

    if (v == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFE082), width: 1),
        ),
        child: const Text(
          AppStrings.superheatNull,
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Color(0xFFE65100),
          ),
        ),
      );
    }

    final bg     = _bgColor(v);
    final border = _borderColor(v);
    final text   = _textColor(v);
    final danger = v < 0;

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: danger ? 1.8 : 1.0),
        boxShadow: danger
            ? [BoxShadow(color: const Color(0xFF7B1FA2).withOpacity(0.45), blurRadius: 10, spreadRadius: 1)]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (danger) ...[
            const Icon(Icons.warning_rounded, size: 11, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            AppStrings.superheatValue(v),
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: text,
            ),
          ),
          if (danger) ...[
            const SizedBox(width: 4),
            const Icon(Icons.warning_rounded, size: 11, color: Colors.white),
          ],
        ],
      ),
    );

    if (!danger) return badge;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) => Transform.scale(scale: _pulseAnim.value, child: child),
      child: badge,
    );
  }
}
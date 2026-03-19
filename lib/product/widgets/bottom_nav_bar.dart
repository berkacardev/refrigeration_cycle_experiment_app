import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:refrigeration_cycle_experiment_app/feature/viewmodel/experiment_provider.dart';
import 'package:refrigeration_cycle_experiment_app/product/models/device_fault.dart';
import 'package:refrigeration_cycle_experiment_app/product/theme/app_theme.dart';
import 'package:refrigeration_cycle_experiment_app/product/lang/tr.dart';

class AppBottomNavBar extends StatefulWidget {
  final Set<String> minimizedCards;
  final ValueChanged<String>? onRestoreCard;
  final ValueChanged<String>? onFullscreenCard;

  const AppBottomNavBar({
    super.key,
    this.minimizedCards = const {},
    this.onRestoreCard,
    this.onFullscreenCard,
  });

  @override
  State<AppBottomNavBar> createState() => _AppBottomNavBarState();
}

class _AppBottomNavBarState extends State<AppBottomNavBar> {
  late Stream<DateTime> _clockStream;

  @override
  void initState() {
    super.initState();
    _clockStream = Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
  }

  static IconData _iconForCard(String key) {
    if (key.contains(AppStrings.condenser) && key.contains('Soğutma')) return Icons.water_drop_outlined;
    if (key.contains(AppStrings.condenser)) return Icons.thermostat_outlined;
    if (key.contains(AppStrings.evaporator) && key.contains('Doyma')) return Icons.ac_unit;
    if (key.contains('Basınç')) return Icons.speed_outlined;
    return Icons.show_chart;
  }

  static Color _colorForCard(String key) {
    if (key.contains(AppStrings.condenser) && key.contains('Soğutma')) return AppColors.water;
    if (key.contains(AppStrings.condenser)) return AppColors.hot;
    if (key.contains(AppStrings.evaporator) && key.contains('Doyma')) return AppColors.evap;
    if (key.contains('Basınç')) return AppColors.cold;
    return AppColors.text2;
  }

  static String _shortLabel(String key) {
    if (key.contains(AppStrings.condenser) && key.contains('Soğutma')) return AppStrings.waterShortLabel;
    if (key.contains(AppStrings.condenser)) return AppStrings.condShortLabel;
    if (key.contains(AppStrings.evaporator) && key.contains('Doyma')) return AppStrings.evapTempShortLabel;
    if (key.contains('Basınç')) return AppStrings.evapPressureShortLabel;
    return key;
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ExperimentProvider>();
    final hasMinimized = widget.minimizedCards.isNotEmpty;

    return Container(
      height: hasMinimized ? 62 : 56,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.divider, width: 1)),
        boxShadow: const [BoxShadow(color: Color(0x0C1E3250), blurRadius: 8, offset: Offset(0, -2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _StatusChip(connected: prov.connected, faultCount: prov.faultCount, hasCritical: prov.hasCriticalFault),
          const SizedBox(width: 8),
          _BottomFluidChip(fluid: prov.selectedFluid.label),
          if (prov.hasFaults) ...[
            const SizedBox(width: 8),
            _FaultBadge(count: prov.faultCount, critical: prov.hasCriticalFault),
          ],

          if (hasMinimized) ...[
            const SizedBox(width: 12),
            Container(width: 1, height: 32, color: AppColors.divider),
            const SizedBox(width: 10),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.minimizedCards.map((key) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _BottomMinimizedChip(
                        label: _shortLabel(key),
                        fullLabel: key,
                        icon: _iconForCard(key),
                        color: _colorForCard(key),
                        onRestore: () => widget.onRestoreCard?.call(key),
                        onFullscreen: () => widget.onFullscreenCard?.call(key),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(width: 1, height: 32, color: AppColors.divider),
            const SizedBox(width: 12),
          ],

          if (!hasMinimized) const Spacer(),

          StreamBuilder<DateTime>(
            stream: _clockStream,
            initialData: DateTime.now(),
            builder: (_, snap) {
              final dt = snap.data ?? DateTime.now();
              final ts = '${dt.hour.toString().padLeft(2, '0')}:'
                  '${dt.minute.toString().padLeft(2, '0')}:'
                  '${dt.second.toString().padLeft(2, '0')}';
              return Text(ts,
                  style: const TextStyle(
                      fontFamily: 'JetBrainsMono', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.cold));
            },
          ),
          const SizedBox(width: 16),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(AppStrings.experimentDuration, style: AppTextStyles.label(color: AppColors.text3)),
              Text(prov.elapsedLabel,
                  style: const TextStyle(
                      fontFamily: 'JetBrainsMono', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.success)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomMinimizedChip extends StatefulWidget {
  final String label;
  final String fullLabel;
  final IconData icon;
  final Color color;
  final VoidCallback onRestore;
  final VoidCallback onFullscreen;

  const _BottomMinimizedChip({
    required this.label,
    required this.fullLabel,
    required this.icon,
    required this.color,
    required this.onRestore,
    required this.onFullscreen,
  });

  @override
  State<_BottomMinimizedChip> createState() => _BottomMinimizedChipState();
}

class _BottomMinimizedChipState extends State<_BottomMinimizedChip>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) {
        final glowOpacity = 0.15 + (_glowAnim.value * 0.15);
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: Tooltip(
            message: '${widget.fullLabel}\nTıklayarak geri yükle',
            child: GestureDetector(
              onTap: widget.onRestore,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.color.withOpacity(_hovering ? 0.20 : 0.08),
                      widget.color.withOpacity(_hovering ? 0.12 : 0.03),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.color.withOpacity(_hovering ? 0.8 : 0.45),
                    width: _hovering ? 1.8 : 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(glowOpacity),
                      blurRadius: _hovering ? 12 : 6,
                      spreadRadius: _hovering ? 1 : 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withOpacity(0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(widget.icon, size: 13, color: widget.color),
                    const SizedBox(width: 5),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: widget.color,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: _hovering
                            ? widget.color.withOpacity(0.2)
                            : widget.color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.open_in_new,
                        size: 11,
                        color: widget.color.withOpacity(_hovering ? 1.0 : 0.6),
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
}

class _StatusChip extends StatelessWidget {
  final bool connected;
  final int faultCount;
  final bool hasCritical;
  const _StatusChip({required this.connected, this.faultCount = 0, this.hasCritical = false});

  @override
  Widget build(BuildContext context) {
    final hasError = faultCount > 0;
    final color = hasCritical
        ? AppColors.hot
        : (hasError ? AppColors.amber : (connected ? AppColors.success : AppColors.hot));
    final bg = hasCritical
        ? AppColors.hotSoft
        : (hasError ? const Color(0xFFFFF8E1) : (connected ? const Color(0xFFE8F5E9) : AppColors.hotSoft));
    final label = hasCritical
        ? AppStrings.criticalFault
        : (hasError ? 'Arıza: $faultCount' : (connected ? AppStrings.arduinoConnected : AppStrings.notConnected));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulseDot(color: color, active: connected || hasError),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _FaultBadge extends StatelessWidget {
  final int count;
  final bool critical;
  const _FaultBadge({required this.count, required this.critical});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFaultDialog(context),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: critical ? const Color(0xFFFFEBEE) : const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: critical ? AppColors.hot : AppColors.amber, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(critical ? Icons.error : Icons.warning_amber, size: 14, color: critical ? AppColors.hot : AppColors.amber),
              const SizedBox(width: 4),
              Text('$count Arıza',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: critical ? AppColors.hot : AppColors.amber)),
            ],
          ),
        ),
      ),
    );
  }

  void _showFaultDialog(BuildContext context) {
    final prov = context.read<ExperimentProvider>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.hot, size: 24),
            const SizedBox(width: 8),
            const Text(AppStrings.activeFaults, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...prov.activeFaults.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Text(f.severityIcon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(f.code, style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f.message, style: const TextStyle(fontSize: 12))),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              prov.clearFaults();
              Navigator.pop(context);
            },
            child: const Text(AppStrings.clearFaults),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text(AppStrings.close)),
        ],
      ),
    );
  }
}

class _BottomFluidChip extends StatelessWidget {
  final String fluid;
  const _BottomFluidChip({required this.fluid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.evapSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCE93D8), width: 1.5),
      ),
      child: Text(
        fluid,
        style: const TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.purple,
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  final bool active;
  const _PulseDot({required this.color, required this.active});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      );
    }
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: widget.color.withOpacity(0.5), blurRadius: 4)],
          ),
        ),
      ),
    );
  }
}
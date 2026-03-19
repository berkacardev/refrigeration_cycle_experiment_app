import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:refrigeration_cycle_experiment_app/feature/viewmodel/experiment_provider.dart';
import 'package:refrigeration_cycle_experiment_app/product/enums/refrigerant_fluid.dart';
import 'package:refrigeration_cycle_experiment_app/product/enums/filter_type.dart';
import 'package:refrigeration_cycle_experiment_app/product/theme/app_theme.dart';
import 'package:refrigeration_cycle_experiment_app/product/widgets/shared_widgets.dart';
import 'package:refrigeration_cycle_experiment_app/product/lang/tr.dart';

class AppSidebar extends StatelessWidget {
  final VoidCallback? onCollapse;
  const AppSidebar({super.key, this.onCollapse});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.divider, width: 1)),
        boxShadow: [BoxShadow(color: Color(0x0A1E3250), blurRadius: 8, offset: Offset(2, 0))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.cold, Color(0xFF7B1FA2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [BoxShadow(color: Color(0x4D1E88E5), blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  child: const Center(child: Text('❄', style: TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.appSubtitle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text1)),
                      Text(AppStrings.appSubtitleFull, style: TextStyle(fontSize: 9, color: AppColors.text3)),
                    ],
                  ),
                ),
                if (onCollapse != null)
                  GestureDetector(
                    onTap: onCollapse,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.chevron_left, size: 16, color: AppColors.text3),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _FluidSection(),
                  _ExperimentControlSection(),
                  _FilterSection(),
                  _ExperimentListSection(),
                  _LogSection(),
                  _ConnectionSection(),
                ],
              ),
            ),
          ),
          const _DeveloperFooter(),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  final Widget child;
  const _Section({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.label()),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _FluidSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ExperimentProvider>();
    return _Section(
      label: AppStrings.fluidType,
      child: Column(
        children: RefrigerantFluid.values
            .map((f) => _SidebarFluidChip(fluid: f, selected: prov.selectedFluid == f))
            .toList(),
      ),
    );
  }
}

class _SidebarFluidChip extends StatelessWidget {
  final RefrigerantFluid fluid;
  final bool selected;
  const _SidebarFluidChip({required this.fluid, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        onTap: () => context.read<ExperimentProvider>().selectFluid(fluid),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.coldSoft : AppColors.surface2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? AppColors.cold : AppColors.divider, width: 1.5),
          ),
          child: Text(
            fluid.label,
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.cold : AppColors.text2,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterSection extends StatefulWidget {
  @override
  State<_FilterSection> createState() => _FilterSectionState();
}

class _FilterSectionState extends State<_FilterSection>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _arrowCtrl;
  late Animation<double> _arrowAnim;

  static const _sensorLabels = {
    'condenserTemp': AppStrings.filterSensorCondenser,
    'waterTemp': AppStrings.filterSensorWater,
    'evapTemp': AppStrings.filterSensorEvapTemp,
    'evapPressure': AppStrings.filterSensorEvapPressure,
  };

  @override
  void initState() {
    super.initState();
    _arrowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _arrowAnim = Tween(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _arrowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _arrowCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _arrowCtrl.forward();
      } else {
        _arrowCtrl.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ExperimentProvider>();
    final active = prov.filterType != FilterType.none;
    final usesAlpha = prov.filterType == FilterType.lowPass ||
        prov.filterType == FilterType.exponentialMovingAverage;
    final usesWindow = prov.filterType == FilterType.movingAverage ||
        prov.filterType == FilterType.median;

    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
      child: Column(
        children: [
          GestureDetector(
            onTap: _toggle,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                child: Row(
                  children: [
                    Text(AppStrings.filterSectionTitle, style: AppTextStyles.label()),
                    if (prov.isFilterActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.coldSoft,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cold.withOpacity(0.4)),
                        ),
                        child: Text(
                          prov.filterType.shortLabel,
                          style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 7, fontWeight: FontWeight.w700, color: AppColors.cold),
                        ),
                      ),
                    ],
                    const Spacer(),
                    RotationTransition(
                      turns: _arrowAnim,
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: _expanded ? AppColors.cold : AppColors.text3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: active ? AppColors.cold : AppColors.divider, width: 1.5),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<FilterType>(
                        value: prov.filterType,
                        isExpanded: true,
                        style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, color: AppColors.text2),
                        items: FilterType.values.map((f) => DropdownMenuItem(
                          value: f,
                          child: Text(f.label),
                        )).toList(),
                        onChanged: (v) => v != null ? prov.setFilterType(v) : null,
                      ),
                    ),
                  ),
                  if (active) ...[
                    const SizedBox(height: 8),
                    if (usesAlpha) ...[
                      Row(
                        children: [
                          Text(AppStrings.filterAlphaLabel(prov.filterAlpha),
                              style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 9, color: AppColors.text2)),
                          const Spacer(),
                          Text(AppStrings.filterSoft, style: TextStyle(fontSize: 8, color: AppColors.text3)),
                          const SizedBox(width: 2),
                          Text('↔', style: TextStyle(fontSize: 8, color: AppColors.text3)),
                          const SizedBox(width: 2),
                          Text(AppStrings.filterFast, style: TextStyle(fontSize: 8, color: AppColors.text3)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          activeTrackColor: AppColors.cold,
                          inactiveTrackColor: AppColors.divider,
                          thumbColor: AppColors.cold,
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        ),
                        child: Slider(
                          value: prov.filterAlpha,
                          min: 0.01,
                          max: 1.0,
                          onChanged: (v) => prov.setFilterAlpha(v),
                        ),
                      ),
                    ],
                    if (usesWindow) ...[
                      Row(
                        children: [
                          Text(AppStrings.filterWindowLabel(prov.filterWindow),
                              style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 9, color: AppColors.text2)),
                          const Spacer(),
                          Text(AppStrings.filterNarrow, style: TextStyle(fontSize: 8, color: AppColors.text3)),
                          const SizedBox(width: 2),
                          Text('↔', style: TextStyle(fontSize: 8, color: AppColors.text3)),
                          const SizedBox(width: 2),
                          Text(AppStrings.filterWide, style: TextStyle(fontSize: 8, color: AppColors.text3)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          activeTrackColor: AppColors.cold,
                          inactiveTrackColor: AppColors.divider,
                          thumbColor: AppColors.cold,
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        ),
                        child: Slider(
                          value: prov.filterWindow.toDouble(),
                          min: 2,
                          max: 30,
                          divisions: 28,
                          onChanged: (v) => prov.setFilterWindow(v.round()),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(AppStrings.filterSensors, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.text2)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => prov.setAllSensorsFiltered(prov.filteredSensors.length < ExperimentProvider.allSensorKeys.length),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Text(
                              prov.filteredSensors.length < ExperimentProvider.allSensorKeys.length ? AppStrings.filterSelectAll : AppStrings.filterSelectNone,
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: AppColors.cold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...ExperimentProvider.allSensorKeys.map((key) {
                      final checked = prov.isSensorFiltered(key);
                      return GestureDetector(
                        onTap: () => prov.toggleSensorFilter(key),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 120),
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: checked ? AppColors.cold : AppColors.surface2,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: checked ? AppColors.cold : AppColors.divider, width: 1.5),
                                  ),
                                  child: checked ? const Icon(Icons.check, size: 11, color: Colors.white) : null,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _sensorLabels[key] ?? key,
                                  style: TextStyle(
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: checked ? AppColors.cold : AppColors.text3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

class _ExperimentControlSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ExperimentProvider>();
    final isConnected = prov.connected;

    return _Section(
      label: AppStrings.experiment,
      child: Column(
        children: [
          SideBtn(
            label: AppStrings.startExperiment,
            bg: isConnected ? AppColors.success : AppColors.surface2,
            fg: isConnected ? Colors.white : AppColors.text3,
            border: isConnected ? Colors.transparent : AppColors.divider,
            onTap: (!isConnected || prov.running) ? null : () => prov.startExperiment(),
          ),
          const SizedBox(height: 5),
          SideBtn(
            label: AppStrings.stopExperiment,
            bg: Colors.transparent,
            fg: (isConnected && prov.running) ? AppColors.hot : AppColors.text3,
            border: (isConnected && prov.running) ? AppColors.hot : AppColors.divider,
            onTap: (isConnected && prov.running) ? () => prov.stopExperiment() : null,
          ),
          if (!isConnected) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 12, color: Color(0xFFE65100)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      AppStrings.arduinoRequired,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFFE65100)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExperimentListSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ExperimentProvider>();
    final exps = prov.experiments.reversed.toList();
    return _Section(
      label: AppStrings.experimentList,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 130),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: exps.length,
          itemBuilder: (_, i) {
            final origIndex = prov.experiments.length - 1 - i;
            final sel = prov.selectedExpIndex == origIndex;
            final exp = exps[i];
            final imported = prov.isImported(origIndex);
            final isRunning = prov.isRunningExperiment(origIndex);
            final isFinished = prov.isFinished(origIndex);
            return GestureDetector(
              onTap: () => prov.selectExperiment(origIndex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                margin: const EdgeInsets.only(bottom: 3),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: sel
                      ? AppColors.coldSoft
                      : (isRunning ? const Color(0xFFE8F5E9) : Colors.transparent),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: sel
                        ? AppColors.cold
                        : (isRunning ? AppColors.success : Colors.transparent),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    if (isRunning) ...[
                      Tooltip(
                        message: AppStrings.runningExperiment,
                        child: AnimatedRecordDot(color: AppColors.success),
                      ),
                      const SizedBox(width: 4),
                    ] else if (imported) ...[
                      Tooltip(
                        message: AppStrings.importedExperiment,
                        child: Icon(Icons.file_download_done, size: 12, color: AppColors.purple),
                      ),
                      const SizedBox(width: 4),
                    ] else if (isFinished) ...[
                      Tooltip(
                        message: AppStrings.completedExperiment,
                        child: Icon(Icons.check_circle_outline, size: 12, color: AppColors.success),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(exp.id,
                          style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: isRunning
                                  ? AppColors.success
                                  : (imported
                                  ? AppColors.purple
                                  : (sel ? AppColors.cold : AppColors.text3))),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Text(exp.dateLabel,
                        style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 8, color: AppColors.text3)),
                    if (!isRunning) ...[
                      const SizedBox(width: 4),
                      MiniIconBtn(
                        icon: Icons.close,
                        tooltip: AppStrings.delete,
                        color: AppColors.hot,
                        onTap: () => _confirmDelete(context, prov, origIndex, exp.id),
                        size: 14,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ExperimentProvider prov, int index, String expId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.delete_outline, color: AppColors.hot, size: 40),
        title: const Text(AppStrings.deleteExperiment, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(AppStrings.deleteConfirm),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.hot.withOpacity(0.3)),
              ),
              child: Text(
                expId,
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.hot,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.deleteIrreversible,
              style: TextStyle(fontSize: 11, color: AppColors.text3),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              prov.deleteExperiment(index);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.hot),
            child: const Text(AppStrings.delete, style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _LogSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lines = context.watch<ExperimentProvider>().logLines;
    return _Section(
      label: AppStrings.liveDataStream,
      child: SizedBox(
        height: 80,
        child: lines.isEmpty
            ? Text(AppStrings.waitingExperiment, style: AppTextStyles.monoSm())
            : ListView.builder(
          itemCount: lines.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: Text(lines[i], style: AppTextStyles.monoSm(color: AppColors.text3)),
          ),
        ),
      ),
    );
  }
}

class _ConnectionSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ExperimentProvider>();
    final ports = prov.availablePorts;
    final currentPort = ports.contains(prov.selectedPort) ? prov.selectedPort : null;

    return _Section(
      label: AppStrings.arduinoConnection,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider, width: 1.5),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: currentPort,
                      isExpanded: true,
                      hint: Text(
                        ports.isEmpty ? AppStrings.portNotFound : AppStrings.selectPort,
                        style: const TextStyle(fontSize: 10),
                      ),
                      style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10, color: AppColors.text2),
                      items: ports.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                      onChanged: prov.connected ? null : (v) => v != null ? prov.selectPort(v) : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: prov.connected ? null : () => prov.scanPorts(),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: prov.connected ? AppColors.surface2 : AppColors.coldSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: prov.connected ? AppColors.divider : AppColors.cold,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.refresh,
                    size: 16,
                    color: prov.connected ? AppColors.text3 : AppColors.cold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SideBtn(
            label: prov.connecting
                ? AppStrings.connecting
                : (prov.connected ? AppStrings.disconnect : AppStrings.connect),
            bg: Colors.transparent,
            fg: prov.connecting
                ? AppColors.text3
                : (prov.connected ? AppColors.hot : AppColors.amber),
            border: prov.connecting
                ? AppColors.divider
                : (prov.connected ? AppColors.hot : AppColors.amber),
            onTap: prov.connecting
                ? null
                : () async {
              if (prov.connected) {
                prov.connect();
              } else {
                await prov.connect();
                if (!context.mounted) return;
                if (prov.connected) {
                  _showHandshakeCheck(context);
                } else {
                  _showConnectionError(context);
                }
              }
            },
          ),
          const SizedBox(height: 5),
          SideBtn(
            label: AppStrings.exportCsv,
            bg: Colors.transparent,
            fg: prov.canExportCsv ? AppColors.purple : AppColors.text3,
            border: prov.canExportCsv ? AppColors.purple : AppColors.divider,
            onTap: prov.canExportCsv
                ? () async {
              final path = await prov.exportCsv();
              if (!context.mounted) return;
              if (path != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppStrings.csvSaved(path)),
                    duration: const Duration(seconds: 3),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(AppStrings.exportCancelledOrEmpty),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }
                : null,
          ),
          const SizedBox(height: 5),
          SideBtn(
            label: AppStrings.importCsv,
            bg: Colors.transparent,
            fg: const Color(0xFF00897B),
            border: const Color(0xFF00897B),
            onTap: () async {
              final id = await prov.importCsv();
              if (!context.mounted) return;
              if (id != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppStrings.imported(id)),
                    duration: const Duration(seconds: 3),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(AppStrings.importCancelledOrInvalid),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

void _showConnectionError(BuildContext context) {
  final prov = context.read<ExperimentProvider>();
  final port = prov.selectedPort;
  final lastLog = prov.logLines.isNotEmpty ? prov.logLines.first : '';

  String title = AppStrings.connectionFailed;
  String message;
  IconData icon = Icons.error_outline;
  Color iconColor = AppColors.hot;

  if (lastLog.contains('başka bir uygulama')) {
    title = AppStrings.portBusy;
    message = AppStrings.portBusyMessage(port);
    icon = Icons.lock_outline;
    iconColor = AppColors.amber;
  } else if (lastLog.contains('bulunamadı') || lastLog.contains('not found')) {
    title = AppStrings.deviceNotFound;
    message = AppStrings.deviceNotFoundMessage(port);
    icon = Icons.usb_off;
  } else if (lastLog.contains('erişim izni')) {
    title = AppStrings.accessDenied;
    message = AppStrings.accessDeniedMessage(port);
    icon = Icons.shield_outlined;
  } else {
    message = AppStrings.connectionFailedMessage(port);
  }

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      icon: Icon(icon, color: iconColor, size: 48),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(8)),
            child: Text(
              lastLog.isNotEmpty ? lastLog : AppStrings.noDetail,
              style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 9, color: Color(0xFF757575)),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            prov.scanPorts();
          },
          child: const Text(AppStrings.scanPorts),
        ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text(AppStrings.close)),
      ],
    ),
  );
}

void _showHandshakeCheck(BuildContext context) {
  Future.delayed(const Duration(milliseconds: 1500), () {
    if (!context.mounted) return;
    final prov = context.read<ExperimentProvider>();

    if (prov.deviceVerified) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 48),
          title: const Text(AppStrings.deviceVerified, style: TextStyle(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(AppStrings.deviceConnected),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  AppStrings.deviceLabel(prov.deviceId),
                  style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text(AppStrings.ok)),
          ],
        ),
      );
    } else if (prov.connected) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.warning_amber, color: Color(0xFFFF9800), size: 48),
          title: const Text(AppStrings.unknownDevice, style: TextStyle(fontWeight: FontWeight.w700)),
          content: Text(
            AppStrings.unknownDeviceMessage(prov.deviceId),
          ),
          actions: [
            TextButton(
              onPressed: () {
                prov.connect();
                Navigator.pop(context);
              },
              child: const Text(AppStrings.disconnectBtn),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text(AppStrings.continueAnyway)),
          ],
        ),
      );
    }
  });
}

class _DeveloperFooter extends StatelessWidget {
  const _DeveloperFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
      child: GestureDetector(
        onTap: () async {
          final uri = Uri.parse(AppStrings.linkedinUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(color: const Color(0xFF0A66C2), borderRadius: BorderRadius.circular(4)),
                child: const Center(
                  child: Text('in', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.developerName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.text1)),
                    Text(AppStrings.developedBy, style: TextStyle(fontSize: 8, color: AppColors.text3)),
                  ],
                ),
              ),
              Icon(Icons.open_in_new, size: 12, color: AppColors.text3),
            ],
          ),
        ),
      ),
    );
  }
}
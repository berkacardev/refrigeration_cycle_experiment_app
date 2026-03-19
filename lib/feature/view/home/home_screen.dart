import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:refrigeration_cycle_experiment_app/feature/viewmodel/experiment_provider.dart';
import 'package:refrigeration_cycle_experiment_app/product/theme/app_theme.dart';
import 'package:refrigeration_cycle_experiment_app/product/widgets/title_bar.dart';
import 'widgets/cycle_diagram.dart';
import 'widgets/sensor_card.dart';
import 'widgets/sidebar.dart';
import 'package:refrigeration_cycle_experiment_app/product/widgets/bottom_nav_bar.dart';
import 'package:refrigeration_cycle_experiment_app/product/widgets/shared_widgets.dart';
import 'package:refrigeration_cycle_experiment_app/product/lang/tr.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _minContentW = 1080;
  static const double _minContentH = 800;

  bool _showSidebar = true;
  bool _showDiagram = true;

  final Set<String> _minimizedCards = {};

  String? _fullscreenCard;

  void _toggleMinimize(String cardKey) {
    setState(() {
      if (_minimizedCards.contains(cardKey)) {
        _minimizedCards.remove(cardKey);
      } else {
        _minimizedCards.add(cardKey);
      }
    });
  }

  void _toggleFullscreen(String cardKey) {
    setState(() {
      if (_fullscreenCard == cardKey) {
        _fullscreenCard = null;
      } else {
        _fullscreenCard = cardKey;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Column(
            children: [
              const CustomTitleBar(),
              Expanded(
                child: Row(
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: SizedBox(
                        width: _showSidebar ? 0 : 32,
                        child: _showSidebar
                            ? const SizedBox.shrink()
                            : MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Tooltip(
                            message: AppStrings.openMenu,
                            child: GestureDetector(
                              onTap: () => setState(() => _showSidebar = true),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  border: const Border(right: BorderSide(color: AppColors.divider)),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(2, 0))],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 14),
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: AppColors.coldSoft,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(Icons.chevron_right, size: 16, color: AppColors.cold),
                                    ),
                                    const SizedBox(height: 6),
                                    RotatedBox(
                                      quarterTurns: 3,
                                      child: Text(AppStrings.menu, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 2, color: AppColors.text2)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: SizedBox(
                        width: _showSidebar ? 220 : 0,
                        child: _showSidebar
                            ? AppSidebar(
                          onCollapse: () => setState(() => _showSidebar = false),
                        )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final needHScroll = constraints.maxWidth < _minContentW;
                          final needVScroll = constraints.maxHeight < _minContentH;

                          Widget content = SizedBox(
                            width: needHScroll ? _minContentW : constraints.maxWidth,
                            height: needVScroll ? _minContentH : constraints.maxHeight,
                            child: Column(
                              children: [
                                Expanded(
                                  child: _ContentArea(
                                    showDiagram: _showDiagram,
                                    onToggleDiagram: () => setState(() => _showDiagram = !_showDiagram),
                                    minimizedCards: _minimizedCards,
                                    onToggleMinimize: _toggleMinimize,
                                    onToggleFullscreen: _toggleFullscreen,
                                  ),
                                ),
                                AppBottomNavBar(
                                  minimizedCards: _minimizedCards,
                                  onRestoreCard: _toggleMinimize,
                                  onFullscreenCard: _toggleFullscreen,
                                ),
                              ],
                            ),
                          );

                          if (needHScroll || needVScroll) {
                            content = SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: content,
                              ),
                            );
                          }

                          return content;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (_fullscreenCard != null)
            _FullscreenOverlay(
              cardKey: _fullscreenCard!,
              onClose: () => setState(() => _fullscreenCard = null),
              onMinimize: (key) {
                setState(() {
                  _fullscreenCard = null;
                  _minimizedCards.add(key);
                });
              },
            ),
        ],
      ),
    );
  }
}

class _FullscreenOverlay extends StatelessWidget {
  final String cardKey;
  final VoidCallback onClose;
  final ValueChanged<String> onMinimize;

  const _FullscreenOverlay({
    required this.cardKey,
    required this.onClose,
    required this.onMinimize,
  });

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ExperimentProvider>();
    final r = prov.latest;

    return Material(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 8)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                _FullscreenHeader(
                  title: cardKey,
                  onClose: onClose,
                  onMinimize: () => onMinimize(cardKey),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildFullscreenChart(context, prov, r),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullscreenChart(BuildContext context, ExperimentProvider prov, dynamic r) {
    if (cardKey == AppStrings.condenserTemp) {
      return SensorCard(
        title: AppStrings.condenserTemp,
        unit: '°C',
        value: r?.condenserTemp,
        accentColor: AppColors.hot,
        softColor: AppColors.hotSoft,
        buffer: prov.filteredCondenserTempBuf,
        timestamps: prov.timestampBuf,
        showWindowControls: false,
      );
    } else if (cardKey == AppStrings.condenserWaterTemp) {
      return SensorCard(
        title: AppStrings.condenserWaterTemp,
        unit: '°C',
        value: r?.waterTemp,
        accentColor: AppColors.water,
        softColor: AppColors.waterSoft,
        buffer: prov.filteredWaterTempBuf,
        timestamps: prov.timestampBuf,
        showWindowControls: false,
      );
    } else if (cardKey == AppStrings.evapAndSatTemp) {
      return SensorCard(
        title: AppStrings.evapAndSatTemp,
        unit: '°C',
        value: r?.evapTemp,
        accentColor: AppColors.evap,
        softColor: AppColors.evapSoft,
        buffer: prov.filteredEvapTempBuf,
        timestamps: prov.timestampBuf,
        buffer2: prov.filteredSatTempBuf,
        color2: const Color(0xFFFF6F00),
        showWindowControls: false,
        valueBadges: [
          ValueBadge(
            label: AppStrings.evaporator,
            value: r?.evapTemp,
            unit: '°C',
            color: AppColors.evap,
            softColor: AppColors.evapSoft,
          ),
          ValueBadge(
            label: AppStrings.saturationTemp,
            value: r?.saturationTemp,
            unit: '°C',
            color: const Color(0xFFFF6F00),
            softColor: const Color(0xFFFFF3E0),
          ),
          SuperheatBadge(value: r?.superheat),
        ],
      );
    } else if (cardKey == AppStrings.evapPressure) {
      return SensorCard(
        title: AppStrings.evapPressure,
        unit: 'bar',
        value: r?.evapPressure,
        accentColor: AppColors.cold,
        softColor: AppColors.coldSoft,
        buffer: prov.filteredEvapPressureBuf,
        timestamps: prov.timestampBuf,
        showWindowControls: false,
      );
    }
    return const Center(child: Text(AppStrings.unknownChart));
  }
}

class _FullscreenHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  final VoidCallback onMinimize;

  const _FullscreenHeader({
    required this.title,
    required this.onClose,
    required this.onMinimize,
  });

  Color _colorForTitle(String t) {
    if (t.contains(AppStrings.condenser) && t.contains('Soğutma')) return AppColors.water;
    if (t.contains(AppStrings.condenser)) return AppColors.hot;
    if (t.contains(AppStrings.evaporator) && t.contains('Doyma')) return AppColors.evap;
    if (t.contains('Basınç')) return AppColors.cold;
    return AppColors.text2;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForTitle(title);
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        border: Border(bottom: BorderSide(color: color.withOpacity(0.2), width: 1.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 22,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const Spacer(),
          HeaderIconBtn(
            icon: Icons.minimize,
            tooltip: AppStrings.minimize,
            color: color,
            onTap: onMinimize,
          ),
          const SizedBox(width: 4),
          HeaderIconBtn(
            icon: Icons.close_fullscreen,
            tooltip: AppStrings.normalSize,
            color: color,
            onTap: onClose,
          ),
        ],
      ),
    );
  }
}

class _ContentArea extends StatelessWidget {
  final bool showDiagram;
  final VoidCallback onToggleDiagram;
  final Set<String> minimizedCards;
  final ValueChanged<String> onToggleMinimize;
  final ValueChanged<String> onToggleFullscreen;

  const _ContentArea({
    required this.showDiagram,
    required this.onToggleDiagram,
    required this.minimizedCards,
    required this.onToggleMinimize,
    required this.onToggleFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: showDiagram ? 4 : 1,
          child: Container(
            color: const Color(0xFFFFF5F5),
            child: _CondenserRow(
              minimizedCards: minimizedCards,
              onToggleMinimize: onToggleMinimize,
              onToggleFullscreen: onToggleFullscreen,
            ),
          ),
        ),

        ZoneLabel(
          label: AppStrings.condenserZone,
          color: AppColors.hot,
          bgColor: const Color(0xFFFFF5F5),
          borderColor: const Color(0xFFFFCDD2),
          isTop: false,
        ),

        if (showDiagram)
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                const CycleStrip(),
                Positioned(
                  top: 8,
                  right: 20,
                  child: DiagramToggleBtn(
                    show: true,
                    onTap: onToggleDiagram,
                  ),
                ),
              ],
            ),
          ),

        if (!showDiagram)
          DiagramToggleBtn(
            show: false,
            onTap: onToggleDiagram,
          ),

        ZoneLabel(
          label: AppStrings.evaporatorZone,
          color: AppColors.cold,
          bgColor: const Color(0xFFF0F7FF),
          borderColor: const Color(0xFFBBDEFB),
          isTop: true,
        ),

        Expanded(
          flex: showDiagram ? 4 : 1,
          child: Container(
            color: const Color(0xFFF0F7FF),
            child: _EvapRow(
              minimizedCards: minimizedCards,
              onToggleMinimize: onToggleMinimize,
              onToggleFullscreen: onToggleFullscreen,
            ),
          ),
        ),
      ],
    );
  }
}

class _CondenserRow extends StatelessWidget {
  final Set<String> minimizedCards;
  final ValueChanged<String> onToggleMinimize;
  final ValueChanged<String> onToggleFullscreen;

  const _CondenserRow({
    required this.minimizedCards,
    required this.onToggleMinimize,
    required this.onToggleFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ExperimentProvider>();
    final r = prov.latest;

    final card1Hidden = minimizedCards.contains(AppStrings.condenserTemp);
    final card2Hidden = minimizedCards.contains(AppStrings.condenserWaterTemp);

    if (card1Hidden && card2Hidden) {
      return const Center(
        child: Text(
          AppStrings.allCondenserMinimized,
          style: TextStyle(fontSize: 11, color: AppColors.text3),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      child: Row(
        children: [
          if (!card1Hidden)
            Expanded(
              child: SensorCard(
                title: AppStrings.condenserTemp,
                unit: '°C',
                value: r?.condenserTemp,
                accentColor: AppColors.hot,
                softColor: AppColors.hotSoft,
                buffer: prov.filteredCondenserTempBuf,
                timestamps: prov.timestampBuf,
                onMinimize: () => onToggleMinimize(AppStrings.condenserTemp),
                onFullscreen: () => onToggleFullscreen(AppStrings.condenserTemp),
              ),
            ),
          if (!card1Hidden && !card2Hidden)
            const SizedBox(width: 10),
          if (!card2Hidden)
            Expanded(
              child: SensorCard(
                title: AppStrings.condenserWaterTemp,
                unit: '°C',
                value: r?.waterTemp,
                accentColor: AppColors.water,
                softColor: AppColors.waterSoft,
                buffer: prov.filteredWaterTempBuf,
                timestamps: prov.timestampBuf,
                onMinimize: () => onToggleMinimize(AppStrings.condenserWaterTemp),
                onFullscreen: () => onToggleFullscreen(AppStrings.condenserWaterTemp),
              ),
            ),
        ],
      ),
    );
  }
}

class _EvapRow extends StatelessWidget {
  final Set<String> minimizedCards;
  final ValueChanged<String> onToggleMinimize;
  final ValueChanged<String> onToggleFullscreen;

  const _EvapRow({
    required this.minimizedCards,
    required this.onToggleMinimize,
    required this.onToggleFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ExperimentProvider>();
    final r = prov.latest;

    final card1Hidden = minimizedCards.contains(AppStrings.evapAndSatTemp);
    final card2Hidden = minimizedCards.contains(AppStrings.evapPressure);

    if (card1Hidden && card2Hidden) {
      return const Center(
        child: Text(
          AppStrings.allEvapMinimized,
          style: TextStyle(fontSize: 11, color: AppColors.text3),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      child: Row(
        children: [
          if (!card1Hidden)
            Expanded(
              child: SensorCard(
                title: AppStrings.evapAndSatTemp,
                unit: '°C',
                value: r?.evapTemp,
                accentColor: AppColors.evap,
                softColor: AppColors.evapSoft,
                buffer: prov.filteredEvapTempBuf,
                timestamps: prov.timestampBuf,
                buffer2: prov.filteredSatTempBuf,
                color2: const Color(0xFFFF6F00),
                onMinimize: () => onToggleMinimize(AppStrings.evapAndSatTemp),
                onFullscreen: () => onToggleFullscreen(AppStrings.evapAndSatTemp),
                valueBadges: [
                  ValueBadge(
                    label: AppStrings.evaporator,
                    value: r?.evapTemp,
                    unit: '°C',
                    color: AppColors.evap,
                    softColor: AppColors.evapSoft,
                  ),
                  ValueBadge(
                    label: AppStrings.saturationTemp,
                    value: r?.saturationTemp,
                    unit: '°C',
                    color: const Color(0xFFFF6F00),
                    softColor: const Color(0xFFFFF3E0),
                  ),
                  SuperheatBadge(value: r?.superheat),
                ],
              ),
            ),
          if (!card1Hidden && !card2Hidden)
            const SizedBox(width: 10),
          if (!card2Hidden)
            Expanded(
              child: SensorCard(
                title: AppStrings.evapPressure,
                unit: 'bar',
                value: r?.evapPressure,
                accentColor: AppColors.cold,
                softColor: AppColors.coldSoft,
                buffer: prov.filteredEvapPressureBuf,
                timestamps: prov.timestampBuf,
                onMinimize: () => onToggleMinimize(AppStrings.evapPressure),
                onFullscreen: () => onToggleFullscreen(AppStrings.evapPressure),
              ),
            ),
        ],
      ),
    );
  }
}
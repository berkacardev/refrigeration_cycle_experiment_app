import 'package:flutter/material.dart';
import 'package:refrigeration_cycle_experiment_app/product/theme/app_theme.dart';

class HeaderIconBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const HeaderIconBtn({super.key,
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  State<HeaderIconBtn> createState() => _HeaderIconBtnState();
}

class _HeaderIconBtnState extends State<HeaderIconBtn> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _hovering ? widget.color.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(widget.icon, size: 16, color: _hovering ? widget.color : AppColors.text3),
          ),
        ),
      ),
    );
  }
}

class MiniIconBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;
  final double size;

  const MiniIconBtn({super.key,
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
    this.size = 16,
  });

  @override
  State<MiniIconBtn> createState() => _MiniIconBtnState();
}

class _MiniIconBtnState extends State<MiniIconBtn> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: widget.size + 8,
            height: widget.size + 8,
            decoration: BoxDecoration(
              color: _hovering ? widget.color.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              widget.icon,
              size: widget.size - 2,
              color: _hovering ? widget.color : AppColors.text3,
            ),
          ),
        ),
      ),
    );
  }
}

class ZoneLabel extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final bool isTop;

  const ZoneLabel({super.key,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.isTop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: isTop ? BorderSide(color: borderColor, width: 2) : BorderSide.none,
          bottom: !isTop ? BorderSide(color: borderColor, width: 2) : BorderSide.none,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: color.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}

class SideBtn extends StatelessWidget {
  final String label;
  final Color bg, fg, border;
  final VoidCallback? onTap;
  const SideBtn({super.key, required this.label, required this.bg, required this.fg, required this.border, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border, width: 1.5),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: onTap == null ? AppColors.text3 : fg,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedRecordDot extends StatefulWidget {
  final Color color;
  const AnimatedRecordDot({super.key, required this.color});

  @override
  State<AnimatedRecordDot> createState() => _AnimatedRecordDotState();
}

class _AnimatedRecordDotState extends State<AnimatedRecordDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: widget.color.withOpacity(0.5), blurRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}
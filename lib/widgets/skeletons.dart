import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_colors.dart' show AppShadows;

class StatCardSkeleton extends StatefulWidget {
  const StatCardSkeleton();
  @override
  State<StatCardSkeleton> createState() => _StatCardSkeletonState();
}

class _StatCardSkeletonState extends State<StatCardSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppShadows.card(context),
        ),
        child: Column(children: [
          Container(width: 38, height: 38,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800.withOpacity(_anim.value) : Colors.grey.shade200.withOpacity(_anim.value),
              borderRadius: BorderRadius.circular(11))),
          const SizedBox(height: 8),
          Container(width: 28, height: 16,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800.withOpacity(_anim.value) : Colors.grey.shade200.withOpacity(_anim.value),
              borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 4),
          Container(width: 44, height: 10,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900.withOpacity(_anim.value) : Colors.grey.shade100.withOpacity(_anim.value),
              borderRadius: BorderRadius.circular(4))),
        ]),
      ),
    );
  }
}

class ToyCardSkeleton extends StatefulWidget {
  const ToyCardSkeleton();
  @override
  State<ToyCardSkeleton> createState() => _ToyCardSkeletonState();
}

class _ToyCardSkeletonState extends State<ToyCardSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget box(double w, double h, {bool circle = false}) => Container(
      width: w == 0 ? double.infinity : w, height: h,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800.withOpacity(_anim.value) : Colors.grey.shade200.withOpacity(_anim.value),
        borderRadius: circle ? BorderRadius.circular(100) : BorderRadius.circular(8),
      ),
    );
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppShadows.card(context),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [box(80, 22), const SizedBox(width: 8), box(56, 22)]),
          const SizedBox(height: 12),
          box(0, 17),
          const SizedBox(height: 6),
          box(200, 13),
          const SizedBox(height: 14),
          Row(children: [
            box(24, 24, circle: true), const SizedBox(width: 8), box(70, 13),
            const Spacer(), box(80, 32),
          ]),
        ]),
      ),
    );
  }
}

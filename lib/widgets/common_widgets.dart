import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/firestore_service.dart';

// ── ToyChip ──────────────────────────────────────────────
class ToyChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final IconData? icon;
  const ToyChip({
    super.key,
    required this.label,
    required this.color,
    required this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 160),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: icon != null ? 8 : 10, vertical: 5),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: textColor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── UserAvatar ───────────────────────────────────────────
class UserAvatar extends StatelessWidget {
  final String name;
  final double size;
  final List<Color>? gradient;
  const UserAvatar({super.key, required this.name, this.size = 44, this.gradient});

  @override
  Widget build(BuildContext context) {
    final colors = gradient ?? AppColors.heroGradient;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: colors.first.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.4,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

// ── UserRatingBadge ──────────────────────────────────────
class UserRatingBadge extends StatelessWidget {
  final String userId;
  final double size;
  final bool showStars;
  final bool lightMode;

  const UserRatingBadge({
    super.key,
    required this.userId,
    this.size = 14,
    this.showStars = true,
    this.lightMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<Map<String, dynamic>>(
      future: FirestoreService.getUserRating(userId),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final data = snap.data!;
        final total = data['total'] as int;
        if (total == 0) return const SizedBox.shrink();
        final percentage = data['percentage'] as int;
        final positive = data['positive'] as int;
        final average = (data['average'] as double? ?? 0.0) * 5;
        final color = _getRatingColor(percentage);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: lightMode ? Colors.white.withOpacity(0.2) : color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: lightMode ? Colors.white.withOpacity(0.3) : color.withOpacity(0.2)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (showStars) ...[
              Icon(_getStarIcon(average), size: size, color: lightMode ? Colors.white : color),
              const SizedBox(width: 4),
            ],
            Text('$positive/$total ($percentage%)',
              style: TextStyle(fontSize: size - 1, fontWeight: FontWeight.w800,
                color: lightMode ? Colors.white : color)),
          ]),
        );
      },
    );
  }

  Color _getRatingColor(int percentage) {
    if (percentage >= 90) return AppColors.success;
    if (percentage >= 70) return AppColors.accent;
    if (percentage >= 50) return AppColors.warning;
    return AppColors.error;
  }

  IconData _getStarIcon(double average) {
    if (average >= 4.5) return Icons.star_rounded;
    if (average >= 3.5) return Icons.star_half_rounded;
    return Icons.star_border_rounded;
  }
}

// ── Section Label ────────────────────────────────────────
Widget sectionLabel(String label, {Color? color}) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Row(children: [
    Container(
      width: 3.5, height: 16,
      decoration: BoxDecoration(color: color ?? AppColors.primary, borderRadius: BorderRadius.circular(2)),
    ),
    const SizedBox(width: 8),
    Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
      color: color ?? AppColors.primary, letterSpacing: 0.5)),
  ]),
);

// ── Empty State ──────────────────────────────────────────
Widget emptyState({required IconData icon, required String title, String? subtitle, Color? color}) {
  final c = color ?? Colors.grey.shade300;
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: c.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, size: 36, color: c),
        ),
        const SizedBox(height: 20),
        Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.grey.shade500)),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade400), textAlign: TextAlign.center),
        ],
      ]),
    ),
  );
}

// ── Error State ──────────────────────────────────────────
Widget errorState({required String message, VoidCallback? onRetry}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.error_outline_rounded, size: 36, color: AppColors.error),
        ),
        const SizedBox(height: 20),
        const Text('Something went wrong',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Text(message, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center),
        if (onRetry != null) ...[
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ],
      ]),
    ),
  );
}

// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/task_item.dart';
import '../../theme/app_theme.dart';

/// Authentic iOS callout banner for overdue tasks awaiting reflection.
class IosReflectionBanner extends StatelessWidget {
  final List<TaskItem> overdueTasks;
  final VoidCallback? onReflect;
  final EdgeInsetsGeometry margin;

  const IosReflectionBanner({
    super.key,
    required this.overdueTasks,
    required this.onReflect,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    if (overdueTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final redColor = isDark ? AppTheme.darkSystemRed : AppTheme.systemRed;

    final bannerBg = redColor.withValues(alpha: isDark ? 0.14 : 0.08);
    final borderColor = redColor.withValues(alpha: isDark ? 0.35 : 0.22);
    final iconBg = redColor.withValues(alpha: isDark ? 0.25 : 0.14);

    final titleColor =
        isDark ? const Color(0xFFFF857D) : const Color(0xFF8B1218);
    final subtitleColor =
        isDark ? const Color(0xFFC78E91) : const Color(0xFF7A2026);

    final count = overdueTasks.length;
    final titleText = '$count task${count == 1 ? '' : 's'} awaiting reflection';

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.arrow_2_circlepath,
              color: redColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titleText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Take a moment to reschedule or let go',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: -0.1,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minSize: 30,
            color: redColor,
            borderRadius: BorderRadius.circular(16),
            onPressed: () {
              HapticFeedback.lightImpact();
              onReflect?.call();
            },
            child: const Text(
              'Reflect',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

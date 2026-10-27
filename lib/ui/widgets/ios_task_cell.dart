// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../models/task_item.dart';
import '../../theme/app_theme.dart';

/// An authentic Apple iOS Reminders-style task cell widget.
///
/// Features:
/// - Inset grouped cell styling with Cupertino & HIG typography.
/// - Circular checklist toggle with haptic feedback (`HapticFeedback.lightImpact()`).
/// - Strikethrough title with secondary label styling when completed.
/// - Note subtitle preview with truncation.
/// - Cupertino planned time badge (subtle gray or tinted alert red if overdue).
/// - Cancel reason pill badge if cancelled.
/// - Trailing action menu trigger (`CupertinoActionSheet`).
/// - Swipe-to-dismiss support (`Dismissible`).
/// - 44px indented hairline separator (`showDivider: bool`, default true).
class IosTaskCell extends StatelessWidget {
  final TaskItem task;
  final ValueChanged<TaskItem>? onToggleComplete;
  final ValueChanged<TaskItem>? onReschedule;
  final ValueChanged<TaskItem>? onCancel;
  final ValueChanged<TaskItem>? onDelete;
  final ValueChanged<TaskItem>? onReflect;
  final VoidCallback? onTap;
  final bool showDivider;
  final bool? isOverdueOverride;
  final ConfirmDismissCallback? confirmDismiss;
  final DismissDirectionCallback? onDismissed;

  const IosTaskCell({
    super.key,
    required this.task,
    this.onToggleComplete,
    this.onReschedule,
    this.onCancel,
    this.onDelete,
    this.onReflect,
    this.onTap,
    this.showDivider = true,
    this.isOverdueOverride,
    this.confirmDismiss,
    this.onDismissed,
  });

  bool get isOverdue {
    if (isOverdueOverride != null) return isOverdueOverride!;
    if (task.isCompleted || task.isCancelled || task.plannedTime == null) {
      return false;
    }
    return task.plannedTime!.isBefore(DateTime.now());
  }

  static String formatPlannedTime(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    final timeStr = DateFormat.jm().format(local);
    final isToday = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = local.year == tomorrow.year &&
        local.month == tomorrow.month &&
        local.day == tomorrow.day;

    if (isToday) {
      return 'Today, $timeStr';
    } else if (isTomorrow) {
      return 'Tomorrow, $timeStr';
    } else {
      final dateStr = DateFormat.MMMd().format(local);
      return '$dateStr, $timeStr';
    }
  }

  void _showActionSheet(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(
          task.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        message: task.notes != null && task.notes!.trim().isNotEmpty
            ? Text(
                task.notes!.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              HapticFeedback.lightImpact();
              onToggleComplete?.call(task);
            },
            child: Text(
              task.isCompleted ? 'Mark as Incomplete' : 'Mark as Completed',
            ),
          ),
          if (onReflect != null)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                onReflect?.call(task);
              },
              child: const Text('Reflect on Task'),
            ),
          if (onReschedule != null)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                onReschedule?.call(task);
              },
              child: const Text('Set Reminder / Reschedule'),
            ),
          if (onCancel != null && !task.isCancelled)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(ctx);
                onCancel?.call(task);
              },
              child: const Text('Cancel with Reason'),
            ),
          if (onDelete != null)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(ctx);
                onDelete?.call(task);
              },
              child: const Text('Delete Task'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryTextColor =
        isDark ? AppTheme.primaryLabelDark : AppTheme.primaryLabelLight;
    final secondaryTextColor =
        isDark ? AppTheme.secondaryLabelDark : AppTheme.secondaryLabelLight;
    final dividerColor =
        isDark ? AppTheme.hairlineDividerDark : AppTheme.hairlineDividerLight;
    final alertRedColor =
        isDark ? AppTheme.systemRedDark : AppTheme.systemRedLight;
    final systemBlueColor =
        isDark ? AppTheme.systemBlueDark : AppTheme.systemBlueLight;
    final systemOrangeColor =
        isDark ? AppTheme.systemOrangeDark : AppTheme.systemOrangeLight;
    final uncheckedBorderColor =
        isDark ? AppTheme.systemGray2Dark : AppTheme.systemGray3Light;

    return Dismissible(
      key: ValueKey('ios_task_dismissible_${task.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: alertRedColor,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.trash, color: Colors.white, size: 20),
            SizedBox(width: 6),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: confirmDismiss ??
          (direction) async {
            if (onDelete != null) {
              return true;
            } else if (onCancel != null) {
              onCancel!(task);
              return false;
            }
            return false;
          },
      onDismissed: onDismissed ??
          (direction) {
            onDelete?.call(task);
          },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Circular Reminders-style checklist toggle (44pt touch target)
                    GestureDetector(
                      key: ValueKey('ios_task_toggle_${task.id}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onToggleComplete?.call(task);
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeInOut,
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: task.isCompleted
                                ? systemBlueColor
                                : Colors.transparent,
                            border: Border.all(
                              color: task.isCompleted
                                  ? systemBlueColor
                                  : uncheckedBorderColor,
                              width: 1.5,
                            ),
                          ),
                          child: task.isCompleted
                              ? const Center(
                                  child: Icon(
                                    CupertinoIcons.check_mark,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Main Content (Title, Notes, Badges)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Task Title
                            Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 16,
                                letterSpacing: -0.3,
                                fontWeight: task.isCompleted
                                    ? FontWeight.w400
                                    : FontWeight.w500,
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                decorationColor: secondaryTextColor,
                                color: task.isCompleted
                                    ? secondaryTextColor
                                    : primaryTextColor,
                              ),
                            ),

                            // Notes Preview Subhead
                            if (task.notes != null &&
                                task.notes!.trim().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                task.notes!.trim(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  letterSpacing: -0.1,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],

                            // Badges Row (Planned Time & Cancel Reason)
                            if (task.plannedTime != null ||
                                (task.isCancelled &&
                                    task.cancelReason != null &&
                                    task.cancelReason!.trim().isNotEmpty)) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  // Planned Time Badge
                                  if (task.plannedTime != null)
                                    GestureDetector(
                                      key: ValueKey(
                                        'ios_task_planned_badge_${task.id}',
                                      ),
                                      onTap: onReschedule != null
                                          ? () => onReschedule!(task)
                                          : null,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isOverdue
                                              ? alertRedColor.withValues(
                                                  alpha: 0.12,
                                                )
                                              : (isDark
                                                  ? AppTheme.systemGray5Dark
                                                  : AppTheme.systemGray5Light),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: isOverdue
                                              ? Border.all(
                                                  color: alertRedColor
                                                      .withValues(alpha: 0.35),
                                                  width: 0.5,
                                                )
                                              : null,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isOverdue
                                                  ? CupertinoIcons
                                                      .exclamationmark_circle_fill
                                                  : CupertinoIcons.clock,
                                              size: 12,
                                              color: isOverdue
                                                  ? alertRedColor
                                                  : systemBlueColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isOverdue
                                                  ? 'Overdue: ${formatPlannedTime(task.plannedTime!)}'
                                                  : formatPlannedTime(
                                                      task.plannedTime!,
                                                    ),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: isOverdue
                                                    ? FontWeight.w600
                                                    : FontWeight.w500,
                                                letterSpacing: -0.1,
                                                color: isOverdue
                                                    ? alertRedColor
                                                    : primaryTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                  // Cancel Reason Badge
                                  if (task.isCancelled &&
                                      task.cancelReason != null &&
                                      task.cancelReason!.trim().isNotEmpty)
                                    Container(
                                      key: ValueKey(
                                        'ios_task_cancel_badge_${task.id}',
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: systemOrangeColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: systemOrangeColor.withValues(
                                            alpha: 0.35,
                                          ),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            CupertinoIcons.xmark_circle,
                                            size: 12,
                                            color: systemOrangeColor,
                                          ),
                                          const SizedBox(width: 4),
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 220,
                                            ),
                                            child: Text(
                                              task.cancelReason!.trim(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: -0.1,
                                                color: systemOrangeColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Trailing Action Menu Button (Ellipsis)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 32,
                      onPressed: () => _showActionSheet(context),
                      child: Icon(
                        CupertinoIcons.ellipsis,
                        size: 18,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 44px Indented Hairline Divider (indented 48px to align with text)
          if (showDivider)
            Padding(
              key: ValueKey('ios_task_divider_${task.id}'),
              padding: const EdgeInsets.only(left: 48),
              child: Container(
                height: 0.5,
                color: dividerColor,
              ),
            ),
        ],
      ),
    );
  }
}

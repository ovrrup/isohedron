import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/task_item.dart';
import '../theme/app_theme.dart';
import 'cancel_reason_dialog.dart';
import 'plan_task_dialog.dart';

enum ReflectionAction { reschedule, complete, cancel }

class ReflectionResult {
  final ReflectionAction action;
  final DateTime? newPlannedTime;
  final String? cancelReason;

  const ReflectionResult.reschedule(this.newPlannedTime)
      : action = ReflectionAction.reschedule,
        cancelReason = null;

  const ReflectionResult.complete()
      : action = ReflectionAction.complete,
        newPlannedTime = null,
        cancelReason = null;

  const ReflectionResult.cancel(this.cancelReason)
      : action = ReflectionAction.cancel,
        newPlannedTime = null;
}

/// Authentic iOS Cupertino action sheet for task reflection loop.
Future<ReflectionResult?> showReflectionDialog({
  required BuildContext context,
  required TaskItem task,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final planned = task.plannedTime?.toLocal();

  String message =
      '"${task.title}"\nPlans change, and that is okay. Choose what you would like to do:';
  if (planned != null) {
    message =
        '"${task.title}"\nWas planned for ${planned.month}/${planned.day} at ${planned.hour}:${planned.minute.toString().padLeft(2, '0')}.\nChoose how you would like to proceed:';
  }

  return showCupertinoModalPopup<ReflectionResult>(
    context: context,
    builder: (ctx) {
      return CupertinoActionSheet(
        title: const Text(
          'Task Reflection',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        message: Text(
          message,
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          // Reschedule Action
          CupertinoActionSheetAction(
            onPressed: () async {
              HapticFeedback.lightImpact();
              final selected = await showPlanTaskDialog(
                context: context,
                initialTime: task.plannedTime,
              );
              if (ctx.mounted) {
                if (selected != null) {
                  Navigator.of(ctx).pop(ReflectionResult.reschedule(selected));
                } else {
                  Navigator.of(ctx).pop(null);
                }
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.clock,
                  size: 18,
                  color: isDark ? AppTheme.darkSystemBlue : AppTheme.systemBlue,
                ),
                const SizedBox(width: 8),
                const Text('Reschedule'),
              ],
            ),
          ),

          // Mark Done Action
          CupertinoActionSheetAction(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(ctx).pop(const ReflectionResult.complete());
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.checkmark_circle,
                  size: 18,
                  color:
                      isDark ? AppTheme.darkSystemGreen : AppTheme.systemGreen,
                ),
                const SizedBox(width: 8),
                const Text('Mark Done'),
              ],
            ),
          ),

          // Cancel & Reflect Action
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              HapticFeedback.lightImpact();
              final reason = await showCancelReasonDialog(
                context: context,
                task: task,
              );
              if (ctx.mounted) {
                if (reason != null) {
                  Navigator.of(ctx).pop(ReflectionResult.cancel(reason));
                } else {
                  Navigator.of(ctx).pop(null);
                }
              }
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.xmark_circle, size: 18),
                SizedBox(width: 8),
                Text('Cancel & Reflect'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.of(ctx).pop(null);
          },
          child: const Text('Later'),
        ),
      );
    },
  );
}

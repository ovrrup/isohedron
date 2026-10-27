import 'package:flutter/material.dart';
import '../models/task_item.dart';
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

Future<ReflectionResult?> showReflectionDialog({
  required BuildContext context,
  required TaskItem task,
}) {
  return showDialog<ReflectionResult>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(context);
      final planned = task.plannedTime?.toLocal();

      return AlertDialog(
        title: Row(
          children: [
            Icon(Icons.psychology_alt_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Task Reflection'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (planned != null) ...[
              const SizedBox(height: 6),
              Text(
                'Was planned for: ${planned.month}/${planned.day} at ${planned.hour}:${planned.minute.toString().padLeft(2, '0')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Plans change, and that is okay. Choose what you would like to do with this task:',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Later'),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.cancel_outlined, size: 16),
            label: const Text('Cancel & Reflect'),
            onPressed: () async {
              final reason = await showCancelReasonDialog(
                context: context,
                task: task,
              );
              if (reason != null && ctx.mounted) {
                Navigator.of(ctx).pop(ReflectionResult.cancel(reason));
              }
            },
          ),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Mark Done'),
            onPressed: () =>
                Navigator.of(ctx).pop(const ReflectionResult.complete()),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.schedule, size: 16),
            label: const Text('Reschedule'),
            onPressed: () async {
              final selected = await showPlanTaskDialog(context: context);
              if (selected != null && ctx.mounted) {
                Navigator.of(ctx).pop(ReflectionResult.reschedule(selected));
              }
            },
          ),
        ],
      );
    },
  );
}

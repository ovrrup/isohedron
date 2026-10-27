import 'package:flutter/material.dart';
import '../controllers/isohedron_app_controller.dart';
import '../models/task_filter.dart';
import '../theme/app_theme.dart';
import 'cancel_reason_dialog.dart';
import 'onboarding_screen.dart';
import 'plan_task_dialog.dart';
import 'reflection_dialog.dart';
import 'task_list_switcher.dart';
import 'widgets/isohedron_logo.dart';

export '../controllers/isohedron_app_controller.dart';

class HomeScreen extends StatefulWidget {
  final IsohedronAppController controller;

  const HomeScreen({super.key, required this.controller});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _searchOpen = false;
  final TextEditingController _searchController = TextEditingController();

  IsohedronAppController get controller => widget.controller;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final visibleTasks = controller.visibleTasks;
        final overdueTasks = controller.overdueTasks;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const IsohedronLogo(size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: TaskListSwitcherDropdown(
                    availableLists: controller.taskLists,
                    selectedListId: controller.selectedListId,
                    onListSelected: (id) async {
                      await controller.switchList(id);
                    },
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(_searchOpen ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() {
                    _searchOpen = !_searchOpen;
                    if (!_searchOpen) {
                      _searchController.clear();
                      controller.setSearchQuery('');
                    }
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.info_outline_rounded),
                tooltip: 'About Isohedron',
                onPressed: () => _showAboutDialog(context),
              ),
            ],
          ),
          body: Column(
            children: [
              if (_searchOpen)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search tasks...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (text) {
                      controller.setSearchQuery(text);
                    },
                  ),
                ),

              // Reflection Loop Banner for Missed/Overdue Tasks
              if (overdueTasks.isNotEmpty &&
                  controller.currentFilter != TaskFilter.completed &&
                  controller.currentFilter != TaskFilter.cancelled)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.accent.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.autorenew_rounded,
                            color: AppTheme.accent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${overdueTasks.length} task(s) awaiting reflection',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: theme.brightness == Brightness.dark
                                      ? AppTheme.darkAccent
                                      : const Color(0xFF5E0B12),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'A gentle pause to reschedule or let go',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.brightness == Brightness.dark
                                      ? AppTheme.darkTextSecondary
                                      : const Color(0xFF7A1C24),
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                          ),
                          onPressed: () async {
                            final first = overdueTasks.first;
                            final res = await showReflectionDialog(
                              context: context,
                              task: first,
                            );
                            if (res != null) {
                              if (res.action == ReflectionAction.complete) {
                                await controller.completeTask(first.id);
                              } else if (res.action ==
                                  ReflectionAction.cancel) {
                                await controller.cancelTask(
                                  first.id,
                                  reason: res.cancelReason ?? 'Skipped',
                                );
                              } else if (res.action ==
                                      ReflectionAction.reschedule &&
                                  res.newPlannedTime != null) {
                                await controller.rescheduleTask(
                                  first.id,
                                  res.newPlannedTime!,
                                );
                              }
                            }
                          },
                          child: const Text(
                            'Reflect',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<TaskFilter>(
                    segments: const [
                      ButtonSegment(value: TaskFilter.all, label: Text('All')),
                      ButtonSegment(
                        value: TaskFilter.today,
                        label: Text('Today'),
                      ),
                      ButtonSegment(
                        value: TaskFilter.planned,
                        label: Text('Planned'),
                      ),
                      ButtonSegment(
                        value: TaskFilter.completed,
                        label: Text('Done'),
                      ),
                      ButtonSegment(
                        value: TaskFilter.cancelled,
                        label: Text('Cancelled'),
                      ),
                    ],
                    selected: {controller.currentFilter},
                    onSelectionChanged: (selected) {
                      controller.setFilter(selected.first);
                    },
                  ),
                ),
              ),
              Expanded(
                child: visibleTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Opacity(
                              opacity: 0.5,
                              child: IsohedronLogo(size: 72),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Sanctuary is Clear',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tap + below to set your next intention',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: visibleTasks.length,
                        itemBuilder: (context, index) {
                          final task = visibleTasks[index];
                          final isOverdue = !task.isCompleted &&
                              !task.isCancelled &&
                              task.plannedTime != null &&
                              task.plannedTime!.isBefore(DateTime.now());

                          return Dismissible(
                            key: ValueKey(task.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: theme.colorScheme.errorContainer,
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Icon(
                                Icons.cancel_outlined,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              final reason = await showCancelReasonDialog(
                                context: context,
                                task: task,
                              );
                              if (reason != null) {
                                await controller.cancelTask(
                                  task.id,
                                  reason: reason,
                                );
                                return false;
                              }
                              return false;
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              elevation: 0.5,
                              child: ListTile(
                                leading: Checkbox(
                                  value: task.isCompleted,
                                  onChanged: (checked) async {
                                    if (checked == true) {
                                      await controller.completeTask(task.id);
                                    } else {
                                      await controller.reopenTask(task.id);
                                    }
                                  },
                                ),
                                title: Text(
                                  task.title,
                                  style: TextStyle(
                                    decoration: task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: task.isCompleted
                                        ? theme.colorScheme.outline
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (task.notes != null &&
                                        task.notes!.isNotEmpty)
                                      Text(
                                        task.notes!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        if (task.plannedTime != null)
                                          ActionChip(
                                            avatar: Icon(
                                              isOverdue
                                                  ? Icons.warning_amber
                                                  : Icons.alarm,
                                              size: 14,
                                              color: isOverdue
                                                  ? theme.colorScheme.error
                                                  : null,
                                            ),
                                            label: Text(
                                              isOverdue
                                                  ? 'Missed: ${task.plannedTime!.toLocal().month}/${task.plannedTime!.toLocal().day} ${task.plannedTime!.toLocal().hour}:${task.plannedTime!.toLocal().minute.toString().padLeft(2, '0')}'
                                                  : 'Planned: ${task.plannedTime!.toLocal().month}/${task.plannedTime!.toLocal().day} ${task.plannedTime!.toLocal().hour}:${task.plannedTime!.toLocal().minute.toString().padLeft(2, '0')}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isOverdue
                                                    ? theme.colorScheme.error
                                                    : null,
                                              ),
                                            ),
                                            backgroundColor: isOverdue
                                                ? theme
                                                    .colorScheme.errorContainer
                                                    .withValues(alpha: 0.3)
                                                : null,
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            onPressed: () async {
                                              final res =
                                                  await showReflectionDialog(
                                                context: context,
                                                task: task,
                                              );
                                              if (res != null) {
                                                if (res.action ==
                                                    ReflectionAction.complete) {
                                                  await controller
                                                      .completeTask(task.id);
                                                } else if (res.action ==
                                                    ReflectionAction.cancel) {
                                                  await controller.cancelTask(
                                                    task.id,
                                                    reason: res.cancelReason ??
                                                        'Skipped',
                                                  );
                                                } else if (res.action ==
                                                        ReflectionAction
                                                            .reschedule &&
                                                    res.newPlannedTime !=
                                                        null) {
                                                  await controller
                                                      .rescheduleTask(
                                                    task.id,
                                                    res.newPlannedTime!,
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        if (task.isCancelled &&
                                            task.cancelReason != null)
                                          Chip(
                                            avatar: Icon(
                                              Icons.info_outline,
                                              size: 14,
                                              color: theme.colorScheme.error,
                                            ),
                                            label: Text(
                                              task.cancelReason!,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: theme.colorScheme.error,
                                              ),
                                            ),
                                            backgroundColor: theme
                                                .colorScheme.errorContainer
                                                .withValues(alpha: 0.5),
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (val) async {
                                    if (val == 'reflect') {
                                      final res = await showReflectionDialog(
                                        context: context,
                                        task: task,
                                      );
                                      if (res != null) {
                                        if (res.action ==
                                            ReflectionAction.complete) {
                                          await controller
                                              .completeTask(task.id);
                                        } else if (res.action ==
                                            ReflectionAction.cancel) {
                                          await controller.cancelTask(
                                            task.id,
                                            reason:
                                                res.cancelReason ?? 'Skipped',
                                          );
                                        } else if (res.action ==
                                                ReflectionAction.reschedule &&
                                            res.newPlannedTime != null) {
                                          await controller.rescheduleTask(
                                            task.id,
                                            res.newPlannedTime!,
                                          );
                                        }
                                      }
                                    } else if (val == 'plan') {
                                      final planned = await showPlanTaskDialog(
                                        context: context,
                                        initialTime: task.plannedTime,
                                      );
                                      if (planned != null) {
                                        await controller.rescheduleTask(
                                          task.id,
                                          planned,
                                        );
                                      }
                                    } else if (val == 'cancel') {
                                      final reason =
                                          await showCancelReasonDialog(
                                        context: context,
                                        task: task,
                                      );
                                      if (reason != null) {
                                        await controller.cancelTask(
                                          task.id,
                                          reason: reason,
                                        );
                                      }
                                    } else if (val == 'delete') {
                                      await controller.deleteTask(task.id);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'reflect',
                                      child: Row(
                                        children: [
                                          Icon(Icons.psychology_outlined,
                                              size: 18),
                                          SizedBox(width: 8),
                                          Text('Reflect on Task'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'plan',
                                      child: Row(
                                        children: [
                                          Icon(Icons.alarm_add, size: 18),
                                          SizedBox(width: 8),
                                          Text('Set Reminder'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'cancel',
                                      child: Row(
                                        children: [
                                          Icon(Icons.cancel_outlined, size: 18),
                                          SizedBox(width: 8),
                                          Text('Cancel with Reason'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, size: 18),
                                          SizedBox(width: 8),
                                          Text('Delete'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: const Text('New Task'),
            onPressed: () => _showCreateTaskDialog(context),
          ),
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _AboutIsohedronDialog(
        controller: controller,
      ),
    );
  }

  void _showCreateTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    DateTime? plannedTime;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Task in ${controller.currentList.title}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Task title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.alarm, size: 16),
                        label: Text(
                          plannedTime != null
                              ? 'Planned: ${plannedTime!.toLocal().month}/${plannedTime!.toLocal().day} ${plannedTime!.toLocal().hour}:${plannedTime!.toLocal().minute.toString().padLeft(2, '0')}'
                              : 'Set Reminder',
                        ),
                        onPressed: () async {
                          final selected =
                              await showPlanTaskDialog(context: context);
                          if (selected != null) {
                            setModalState(() {
                              plannedTime = selected;
                            });
                          }
                        },
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () async {
                          final title = titleController.text.trim();
                          if (title.isNotEmpty) {
                            await controller.createTask(
                              title: title,
                              notes: notesController.text.trim().isNotEmpty
                                  ? notesController.text.trim()
                                  : null,
                              plannedTime: plannedTime,
                            );
                            if (ctx.mounted) Navigator.of(ctx).pop();
                          }
                        },
                        child: const Text('Add Task'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AboutIsohedronDialog extends StatelessWidget {
  final IsohedronAppController controller;

  const _AboutIsohedronDialog({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      title: const Center(
        child: IsohedronLogo(size: 44, showText: true),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 6),
            Text(
              'Sovereign Task Sanctuary',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'A minimal, geometric space designed for quiet focus and reflection.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '100% Offline & Private',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Your tasks and reflection logs are stored locally on this device.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => OnboardingScreen(controller: controller),
              ),
            );
          },
          icon: const Icon(Icons.menu_book_rounded, size: 18),
          label: const Text('Welcome Guide'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

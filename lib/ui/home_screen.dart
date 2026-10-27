import 'package:flutter/material.dart';
import '../models/task_filter.dart';
import '../models/task_item.dart';
import '../models/task_list.dart';
import '../services/google_tasks_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import 'cancel_reason_dialog.dart';
import 'plan_task_dialog.dart';
import 'task_list_switcher.dart';

class IsohedronAppController {
  final StorageService storage;
  final NotificationService notifications;
  final GoogleTasksService googleTasks;

  TaskFilter _currentFilter = TaskFilter.all;
  String _searchQuery = '';
  List<TaskList> _taskLists = [];
  String _selectedListId = 'local_default';
  List<TaskItem> _currentTasks = [];
  bool _isSyncing = false;

  IsohedronAppController({
    required this.storage,
    required this.notifications,
    required this.googleTasks,
  });

  TaskFilter get currentFilter => _currentFilter;
  String get searchQuery => _searchQuery;
  List<TaskList> get taskLists => List.unmodifiable(_taskLists);
  String get selectedListId => _selectedListId;
  bool get isSyncing => _isSyncing;
  bool get isGoogleConnected => googleTasks.isAuthenticated;
  String? get googleEmail => googleTasks.userEmail;

  TaskList get currentList {
    return _taskLists.firstWhere(
      (l) => l.id == _selectedListId,
      orElse: () => _taskLists.isNotEmpty
          ? _taskLists.first
          : StorageService.defaultLocalList,
    );
  }

  List<TaskItem> get visibleTasks {
    return storage.filterTasks(
      _currentTasks,
      _currentFilter,
      searchQuery: _searchQuery,
    );
  }

  Future<void> init() async {
    await storage.init();
    await notifications.init();
    await loadTaskLists();
    await loadCurrentTasks();
  }

  Future<void> loadTaskLists() async {
    final localLists = await storage.getTaskLists();
    final combined = List<TaskList>.from(localLists);

    if (googleTasks.isAuthenticated) {
      try {
        final googleLists = await googleTasks.fetchTaskLists();
        for (final gList in googleLists) {
          if (!combined.any((l) => l.id == gList.id)) {
            combined.add(gList);
          }
        }
      } catch (_) {
        // Fall back to local lists on network failure
      }
    }

    _taskLists = combined;
    _selectedListId = await storage.getSelectedTaskListId();
    if (!_taskLists.any((l) => l.id == _selectedListId)) {
      _selectedListId = _taskLists.first.id;
      await storage.setSelectedTaskListId(_selectedListId);
    }
  }

  Future<void> loadCurrentTasks() async {
    _currentTasks = await storage.getTasks(_selectedListId);
  }

  void setFilter(TaskFilter filter) {
    _currentFilter = filter;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
  }

  Future<void> switchList(String listId) async {
    _selectedListId = listId;
    await storage.setSelectedTaskListId(listId);
    await loadCurrentTasks();
  }

  Future<void> signInGoogle() async {
    final success = await googleTasks.signIn();
    if (success) {
      await loadTaskLists();
      await loadCurrentTasks();
    }
  }

  Future<void> signOutGoogle() async {
    await googleTasks.signOut();
    await loadTaskLists();
    if (!currentList.isLocal) {
      await switchList('local_default');
    }
  }

  Future<void> syncCurrentList() async {
    if (!isGoogleConnected || currentList.isLocal) return;
    _isSyncing = true;
    try {
      await googleTasks.syncList(_selectedListId, storage);
      await loadCurrentTasks();
    } catch (_) {
      // Gracefully handle network disconnection or timeouts without crashing
    } finally {
      _isSyncing = false;
    }
  }

  Future<TaskItem> createTask({
    required String title,
    String? notes,
    DateTime? due,
    DateTime? plannedTime,
  }) async {
    final task = TaskItem(
      id: 'local_task_${DateTime.now().millisecondsSinceEpoch}',
      taskListId: _selectedListId,
      title: title,
      notes: notes,
      due: due,
      plannedTime: plannedTime,
      updatedAt: DateTime.now(),
    );

    await storage.upsertTask(task);
    if (plannedTime != null) {
      await notifications.scheduleTaskReminder(task);
    }

    if (isGoogleConnected && !currentList.isLocal) {
      try {
        await googleTasks.pushTask(task);
      } catch (_) {
        // Queued locally in storage for next sync
      }
    }

    await loadCurrentTasks();
    return task;
  }

  Future<void> completeTask(String taskId) async {
    final task = _currentTasks.cast<TaskItem?>().firstWhere(
          (t) => t?.id == taskId,
          orElse: () => null,
        );
    if (task == null) return;

    final updated = task.copyWith(
      isCompleted: true,
      isCancelled: false,
      clearCancelReason: true,
      updatedAt: DateTime.now(),
    );

    await storage.upsertTask(updated);
    await notifications.cancelReminder(taskId);

    if (isGoogleConnected && !currentList.isLocal) {
      try {
        await googleTasks.pushTask(updated);
      } catch (_) {
        // Saved locally for sync
      }
    }

    await loadCurrentTasks();
  }

  Future<void> cancelTask(String taskId, {required String reason}) async {
    final task = _currentTasks.cast<TaskItem?>().firstWhere(
          (t) => t?.id == taskId,
          orElse: () => null,
        );
    if (task == null) return;

    final updated = task.copyWith(
      isCompleted: true, // Maps to completed so it clears active view
      isCancelled: true,
      cancelReason: reason,
      updatedAt: DateTime.now(),
    );

    await storage.upsertTask(updated);
    await notifications.cancelReminder(taskId);

    if (isGoogleConnected && !currentList.isLocal) {
      try {
        await googleTasks.pushTask(updated);
      } catch (_) {
        // Saved locally for sync
      }
    }

    await loadCurrentTasks();
  }

  Future<void> deleteTask(String taskId) async {
    await storage.deleteTask(_selectedListId, taskId);
    await notifications.cancelReminder(taskId);
    await loadCurrentTasks();
  }
}

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
    final visibleTasks = controller.visibleTasks;

    return Scaffold(
      appBar: AppBar(
        title: TaskListSwitcherDropdown(
          availableLists: controller.taskLists,
          selectedListId: controller.selectedListId,
          onListSelected: (id) async {
            await controller.switchList(id);
            setState(() {});
          },
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
          if (controller.isGoogleConnected && !controller.currentList.isLocal)
            IconButton(
              icon: controller.isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.sync),
              tooltip: 'Sync Google Tasks',
              onPressed: controller.isSyncing
                  ? null
                  : () async {
                      await controller.syncCurrentList();
                      setState(() {});
                    },
            ),
          IconButton(
            icon: Icon(
              controller.isGoogleConnected
                  ? Icons.account_circle
                  : Icons.cloud_off_outlined,
            ),
            tooltip: controller.isGoogleConnected
                ? 'Connected: ${controller.googleEmail}'
                : 'Connect Google Tasks',
            onPressed: () => _showAccountDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searchOpen)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  setState(() {
                    controller.setSearchQuery(text);
                  });
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<TaskFilter>(
                segments: const [
                  ButtonSegment(value: TaskFilter.all, label: Text('All')),
                  ButtonSegment(value: TaskFilter.today, label: Text('Today')),
                  ButtonSegment(value: TaskFilter.planned, label: Text('Planned')),
                  ButtonSegment(value: TaskFilter.completed, label: Text('Done')),
                  ButtonSegment(value: TaskFilter.cancelled, label: Text('Cancelled')),
                ],
                selected: {controller.currentFilter},
                onSelectionChanged: (selected) {
                  setState(() {
                    controller.setFilter(selected.first);
                  });
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
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No tasks found',
                          style: theme.textTheme.titleMedium?.copyWith(
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
                      return Dismissible(
                        key: ValueKey(task.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: theme.colorScheme.errorContainer,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
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
                            await controller.cancelTask(task.id, reason: reason);
                            setState(() {});
                            return false;
                          }
                          return false;
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          elevation: 0.5,
                          child: ListTile(
                            leading: Checkbox(
                              value: task.isCompleted,
                              onChanged: (checked) async {
                                if (checked == true) {
                                  await controller.completeTask(task.id);
                                } else {
                                  // Re-open task
                                  await controller.createTask(
                                    title: task.title,
                                    notes: task.notes,
                                    due: task.due,
                                    plannedTime: task.plannedTime,
                                  );
                                  await controller.deleteTask(task.id);
                                }
                                setState(() {});
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
                                if (task.notes != null && task.notes!.isNotEmpty)
                                  Text(
                                    task.notes!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (task.plannedTime != null)
                                      Chip(
                                        avatar: const Icon(Icons.alarm, size: 14),
                                        label: Text(
                                          '${task.plannedTime!.toLocal().month}/${task.plannedTime!.toLocal().day} ${task.plannedTime!.toLocal().hour}:${task.plannedTime!.toLocal().minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                      ),
                                    if (task.isCancelled && task.cancelReason != null) ...[
                                      const SizedBox(width: 6),
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
                                        backgroundColor: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (val) async {
                                if (val == 'plan') {
                                  final planned = await showPlanTaskDialog(
                                    context: context,
                                    initialTime: task.plannedTime,
                                  );
                                  final updated = task.copyWith(
                                    plannedTime: planned,
                                    updatedAt: DateTime.now(),
                                  );
                                  await controller.storage.upsertTask(updated);
                                  if (planned != null) {
                                    await controller.notifications.scheduleTaskReminder(updated);
                                  } else {
                                    await controller.notifications.cancelReminder(task.id);
                                  }
                                  await controller.loadCurrentTasks();
                                  setState(() {});
                                } else if (val == 'cancel') {
                                  final reason = await showCancelReasonDialog(
                                    context: context,
                                    task: task,
                                  );
                                  if (reason != null) {
                                    await controller.cancelTask(task.id, reason: reason);
                                    setState(() {});
                                  }
                                } else if (val == 'delete') {
                                  await controller.deleteTask(task.id);
                                  setState(() {});
                                }
                              },
                              itemBuilder: (context) => [
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
                                      Text('Cancel with Reflection'),
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
  }

  void _showAccountDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Google Tasks Account'),
          content: controller.isGoogleConnected
              ? Text('Signed in as:\n${controller.googleEmail}')
              : const Text(
                  'Connect Google Tasks to sync tasks and lists across devices.\n\nIsohedron works 100% offline with local storage when not connected.',
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
            if (controller.isGoogleConnected)
              FilledButton(
                onPressed: () async {
                  await controller.signOutGoogle();
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  setState(() {});
                },
                child: const Text('Sign Out'),
              )
            else
              FilledButton(
                onPressed: () async {
                  await controller.signInGoogle();
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  setState(() {});
                },
                child: const Text('Sign In with Google'),
              ),
          ],
        );
      },
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
                  Text('New Task in ${controller.currentList.title}',
                      style: Theme.of(context).textTheme.titleLarge),
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
                          final selected = await showPlanTaskDialog(context: context);
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
                            setState(() {});
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

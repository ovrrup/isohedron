import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String? get googleLastError => googleTasks.lastError;

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

    // 1. Attempt silent restore from Google Play Services
    try {
      await googleTasks.signInSilently();
    } catch (_) {}

    // 2. If not authenticated, attempt restore from persisted OAuth access token
    if (!googleTasks.isAuthenticated) {
      final savedToken = await storage.getGoogleAccessToken();
      final savedEmail = await storage.getGoogleUserEmail();
      if (savedToken != null && savedToken.trim().isNotEmpty) {
        try {
          await googleTasks.connectWithToken(savedToken, email: savedEmail);
        } catch (_) {}
      }
    }

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

  Future<bool> signInGoogle() async {
    final success = await googleTasks.signIn();
    if (success) {
      await loadTaskLists();
      await loadCurrentTasks();
      return true;
    }
    return false;
  }

  Future<bool> connectGoogleWithToken(String token, {String? email}) async {
    final success = await googleTasks.connectWithToken(token, email: email);
    if (success) {
      await storage.saveGoogleAuth(
        token: token.trim(),
        email: email?.trim().isNotEmpty == true ? email!.trim() : googleTasks.userEmail,
      );
      await loadTaskLists();
      await loadCurrentTasks();
      return true;
    }
    return false;
  }

  Future<void> signOutGoogle() async {
    await googleTasks.signOut();
    await storage.clearGoogleAuth();
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
      builder: (ctx) => _GoogleAccountDialog(
        controller: controller,
        onStateChanged: () => setState(() {}),
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

class _GoogleAccountDialog extends StatefulWidget {
  final IsohedronAppController controller;
  final VoidCallback onStateChanged;

  const _GoogleAccountDialog({
    required this.controller,
    required this.onStateChanged,
  });

  @override
  State<_GoogleAccountDialog> createState() => _GoogleAccountDialogState();
}

class _GoogleAccountDialogState extends State<_GoogleAccountDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tokenController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _statusError;
  bool _showTokenGuide = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tokenController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConnected = widget.controller.isGoogleConnected;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isConnected ? Icons.cloud_done : Icons.cloud_sync_outlined,
            color: isConnected ? Colors.green : theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('Google Tasks Account'),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: isConnected
              ? _buildConnectedView(theme)
              : _buildConnectOptions(theme),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildConnectedView(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status: Active & Connected',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      widget.controller.googleEmail ?? 'Google Account',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Tasks and lists sync automatically. You can also trigger an immediate sync below.',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.sync),
                label: const Text('Sync Now'),
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() => _isLoading = true);
                        try {
                          await widget.controller.syncCurrentList();
                          widget.onStateChanged();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tasks synced successfully.'),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.logout),
                label: const Text('Disconnect'),
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() => _isLoading = true);
                        await widget.controller.signOutGoogle();
                        widget.onStateChanged();
                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Disconnected from Google Tasks.'),
                            ),
                          );
                        }
                      },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectOptions(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Connect Google Tasks to sync your task lists across devices.',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 12),
        TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.outline,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'Direct Token', icon: Icon(Icons.key, size: 18)),
            Tab(text: 'Google Play', icon: Icon(Icons.android, size: 18)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 320,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTokenTab(theme),
              _buildPlayServicesTab(theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTokenTab(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Instant Direct Sync',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Connect instantly with an OAuth access token. Guarantees live sync on all devices without Google Cloud keystore setup.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _tokenController,
            decoration: const InputDecoration(
              labelText: 'OAuth Access Token (ya29...)',
              hintText: 'Paste OAuth Bearer Token',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email or Label (optional)',
              hintText: 'user@gmail.com',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          if (_statusError != null) ...[
            const SizedBox(height: 8),
            Text(
              _statusError!,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.link),
                  label: const Text('Connect & Sync'),
                  onPressed: _isLoading
                      ? null
                      : () async {
                          final token = _tokenController.text.trim();
                          if (token.isEmpty) {
                            setState(
                              () => _statusError =
                                  'Please paste an OAuth access token.',
                            );
                            return;
                          }
                          setState(() {
                            _isLoading = true;
                            _statusError = null;
                          });
                          final email = _emailController.text.trim();
                          final success =
                              await widget.controller.connectGoogleWithToken(
                            token,
                            email: email.isNotEmpty ? email : null,
                          );
                          if (mounted) {
                            if (success) {
                              widget.onStateChanged();
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Connected to Google Tasks as ${widget.controller.googleEmail}',
                                  ),
                                ),
                              );
                            } else {
                              setState(() {
                                _isLoading = false;
                                _statusError =
                                    widget.controller.googleLastError ??
                                        'Failed to connect with token. Ensure Tasks API is enabled.';
                              });
                            }
                          }
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            icon: Icon(
              _showTokenGuide ? Icons.expand_less : Icons.help_outline,
              size: 16,
            ),
            label: Text(
              _showTokenGuide ? 'Hide Token Guide' : 'How to get a token (30s)',
            ),
            onPressed: () => setState(() => _showTokenGuide = !_showTokenGuide),
          ),
          if (_showTokenGuide)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '1. Open developers.google.com/oauthplayground\n'
                '2. Under "Tasks API v1", select "https://www.googleapis.com/auth/tasks"\n'
                '3. Click "Authorize APIs" and sign in\n'
                '4. Click "Exchange authorization code for tokens"\n'
                '5. Copy the generated "Access token" and paste it here.',
                style: TextStyle(fontSize: 11, height: 1.4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayServicesTab(ThemeData theme) {
    final lastErr = widget.controller.googleLastError;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Native Google Play Sign-In',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            '1-Tap account picker via Google Play Services on Android.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.account_circle),
              label: const Text('Sign In with Google'),
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() => _isLoading = true);
                      final success = await widget.controller.signInGoogle();
                      if (mounted) {
                        setState(() => _isLoading = false);
                        if (success) {
                          widget.onStateChanged();
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Connected to Google Tasks as ${widget.controller.googleEmail}',
                              ),
                            ),
                          );
                        }
                      }
                    },
            ),
          ),
          if (lastErr != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Play Services Error: $lastErr',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (lastErr.contains('10')) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Note: ApiException 10 means Google Play Services cannot verify the APK because the SHA-1 is not registered in Google Cloud Console. Use Direct Token tab or register the credentials below in GCP.',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Release Signing Fingerprints:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const SizedBox(height: 6),
          _buildCopyRow('Package', 'com.ovrrup.isohedron'),
          _buildCopyRow(
            'SHA-1',
            '94:55:00:41:DC:C6:94:AB:0C:21:5D:93:2D:C6:6B:03:73:0A:2B:5B',
          ),
        ],
      ),
    );
  }

  Widget _buildCopyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label: $value',
              style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 14),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Copy $label',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied $label to clipboard'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

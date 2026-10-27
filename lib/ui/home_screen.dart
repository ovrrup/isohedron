import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/isohedron_app_controller.dart';
import '../models/task_filter.dart';
import '../theme/app_theme.dart';
import 'cancel_reason_dialog.dart';
import 'onboarding_screen.dart';
import 'plan_task_dialog.dart';
import 'reflection_dialog.dart';
import 'task_list_switcher.dart';
import 'widgets/ios_task_cell.dart';
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
              if (controller.isGoogleConnected &&
                  !controller.currentList.isLocal)
                IconButton(
                  icon: controller.isSyncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.sync),
                  tooltip: 'Sync Google Tasks',
                  onPressed: controller.isSyncing
                      ? null
                      : () async {
                          await controller.syncCurrentList();
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
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.8),
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
                          return IosTaskCell(
                            task: task,
                            showDivider: index < visibleTasks.length - 1,
                            onToggleComplete: (t) async {
                              if (t.isCompleted) {
                                await controller.reopenTask(t.id);
                              } else {
                                await controller.completeTask(t.id);
                              }
                            },
                            onReflect: (t) async {
                              final res = await showReflectionDialog(
                                context: context,
                                task: t,
                              );
                              if (res != null) {
                                if (res.action == ReflectionAction.complete) {
                                  await controller.completeTask(t.id);
                                } else if (res.action ==
                                    ReflectionAction.cancel) {
                                  await controller.cancelTask(
                                    t.id,
                                    reason: res.cancelReason ?? 'Skipped',
                                  );
                                } else if (res.action ==
                                        ReflectionAction.reschedule &&
                                    res.newPlannedTime != null) {
                                  await controller.rescheduleTask(
                                    t.id,
                                    res.newPlannedTime!,
                                  );
                                }
                              }
                            },
                            onReschedule: (t) async {
                              final planned = await showPlanTaskDialog(
                                context: context,
                                initialTime: t.plannedTime,
                              );
                              if (planned != null) {
                                await controller.rescheduleTask(
                                  t.id,
                                  planned,
                                );
                              }
                            },
                            onCancel: (t) async {
                              final reason = await showCancelReasonDialog(
                                context: context,
                                task: t,
                              );
                              if (reason != null) {
                                await controller.cancelTask(
                                  t.id,
                                  reason: reason,
                                );
                              }
                            },
                            onDelete: (t) async {
                              await controller.deleteTask(t.id);
                            },
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

  void _showAccountDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _GoogleAccountDialog(
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

class _GoogleAccountDialog extends StatefulWidget {
  final IsohedronAppController controller;

  const _GoogleAccountDialog({
    required this.controller,
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
          const IsohedronLogo(size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isConnected ? 'Connected Account' : 'Account & Sync',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
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
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => OnboardingScreen(controller: widget.controller),
              ),
            );
          },
          child: const Text('Welcome Guide'),
        ),
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
            'Connect instantly with an OAuth access token. Guarantees live sync on all devices without Google Cloud setup.',
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
                                _statusError = widget
                                        .controller.googleLastError ??
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
                      'Note: ApiException 10 indicates that an Android OAuth Client ID is needed in Google Cloud Console matching the application ID.',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildCopyRow('Package Name', 'com.ovrrup.isohedron'),
          const SizedBox(height: 6),
          const Text(
            'Tip: For immediate zero-setup sync on any device, use the "Direct Token" tab above.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
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

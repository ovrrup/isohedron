// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/isohedron_app_controller.dart';
import '../models/task_filter.dart';
import '../models/task_item.dart';
import '../theme/app_theme.dart';
import 'cancel_reason_dialog.dart';
import 'onboarding_screen.dart';
import 'plan_task_dialog.dart';
import 'reflection_dialog.dart';
import 'task_list_switcher.dart';
import 'widgets/ios_reflection_banner.dart';
import 'widgets/ios_segmented_filter.dart';
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

  Map<TaskFilter, int> _computeFilterCounts() {
    final allTasks = controller.allTasksForCurrentList;
    final now = DateTime.now();

    final todayTasks = allTasks.where((TaskItem t) {
      if (t.isCompleted || t.isCancelled) return false;
      if (t.plannedTime == null) return false;
      final local = t.plannedTime!.toLocal();
      return local.year == now.year &&
          local.month == now.month &&
          local.day == now.day;
    }).length;

    final plannedTasks = allTasks.where((TaskItem t) {
      return !t.isCompleted && !t.isCancelled && t.plannedTime != null;
    }).length;

    final completedTasks = allTasks.where((TaskItem t) => t.isCompleted).length;
    final cancelledTasks = allTasks.where((TaskItem t) => t.isCancelled).length;

    return {
      TaskFilter.all: allTasks.length,
      TaskFilter.today: todayTasks,
      TaskFilter.planned: plannedTasks,
      TaskFilter.completed: completedTasks,
      TaskFilter.cancelled: cancelledTasks,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scaffoldBg = isDark
        ? AppTheme.darkSystemGroupedBackground
        : AppTheme.lightSystemGroupedBackground;

    final secondaryBg = isDark
        ? AppTheme.darkSecondaryGroupedBackground
        : AppTheme.lightSecondaryGroupedBackground;

    final textPrimary =
        isDark ? AppTheme.darkLabelPrimary : AppTheme.lightLabelPrimary;

    final textSecondary =
        isDark ? AppTheme.darkLabelSecondary : AppTheme.lightLabelSecondary;

    final systemBlue = isDark ? AppTheme.darkSystemBlue : AppTheme.systemBlue;
    final separatorColor =
        isDark ? AppTheme.darkSeparator : AppTheme.lightSeparator;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final visibleTasks = controller.visibleTasks;
        final overdueTasks = controller.overdueTasks;
        final filterCounts = _computeFilterCounts();

        return Scaffold(
          backgroundColor: scaffoldBg,
          appBar: AppBar(
            backgroundColor: scaffoldBg,
            scrolledUnderElevation: 0,
            elevation: 0,
            leadingWidth: 44,
            leading: const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Center(
                child: IsohedronLogo(size: 24),
              ),
            ),
            title: TaskListSwitcherDropdown(
              availableLists: controller.taskLists,
              selectedListId: controller.selectedListId,
              onListSelected: (id) async {
                await controller.switchList(id);
              },
            ),
            centerTitle: true,
            actions: [
              // Search toggle
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minSize: 36,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _searchOpen = !_searchOpen;
                    if (!_searchOpen) {
                      _searchController.clear();
                      controller.setSearchQuery('');
                    }
                  });
                },
                child: Icon(
                  _searchOpen
                      ? CupertinoIcons.xmark_circle_fill
                      : CupertinoIcons.search,
                  color: systemBlue,
                  size: 20,
                ),
              ),

              // Sync Google Tasks (if applicable)
              if (controller.isGoogleConnected &&
                  !controller.currentList.isLocal)
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minSize: 36,
                  onPressed: controller.isSyncing
                      ? null
                      : () async {
                          await HapticFeedback.lightImpact();
                          await controller.syncCurrentList();
                        },
                  child: controller.isSyncing
                      ? const CupertinoActivityIndicator(radius: 8)
                      : Icon(
                          CupertinoIcons.arrow_2_circlepath,
                          color: systemBlue,
                          size: 20,
                        ),
                ),

              // Account & Sync options
              CupertinoButton(
                padding: const EdgeInsets.only(right: 16, left: 4),
                minSize: 36,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showAccountDialog(context);
                },
                child: Icon(
                  controller.isGoogleConnected
                      ? CupertinoIcons.person_crop_circle_fill
                      : CupertinoIcons.person_crop_circle,
                  color:
                      controller.isGoogleConnected ? systemBlue : textSecondary,
                  size: 22,
                ),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // iOS Large Title Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      controller.currentList.title,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${visibleTasks.length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // iOS Search Field
              if (_searchOpen)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: CupertinoSearchTextField(
                    controller: _searchController,
                    placeholder: 'Search reminders',
                    style: TextStyle(color: textPrimary, fontSize: 14),
                    onChanged: (text) => controller.setSearchQuery(text),
                    onSuffixTap: () {
                      _searchController.clear();
                      controller.setSearchQuery('');
                    },
                  ),
                ),

              // Cupertino Sliding Segmented Filter Control
              IosSegmentedFilter(
                currentFilter: controller.currentFilter,
                counts: filterCounts,
                onFilterChanged: (filter) {
                  controller.setFilter(filter);
                },
              ),

              // Reflection Loop Callout Banner for Overdue Tasks
              if (overdueTasks.isNotEmpty &&
                  controller.currentFilter != TaskFilter.completed &&
                  controller.currentFilter != TaskFilter.cancelled)
                IosReflectionBanner(
                  overdueTasks: overdueTasks,
                  onReflect: () async {
                    final first = overdueTasks.first;
                    final res = await showReflectionDialog(
                      context: context,
                      task: first,
                    );
                    if (res != null) {
                      if (res.action == ReflectionAction.complete) {
                        await controller.completeTask(first.id);
                      } else if (res.action == ReflectionAction.cancel) {
                        await controller.cancelTask(
                          first.id,
                          reason: res.cancelReason ?? 'Skipped',
                        );
                      } else if (res.action == ReflectionAction.reschedule &&
                          res.newPlannedTime != null) {
                        await controller.rescheduleTask(
                          first.id,
                          res.newPlannedTime!,
                        );
                      }
                    }
                  },
                ),

              const SizedBox(height: 4),

              // Grouped Inset Task List Container
              Expanded(
                child: visibleTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Opacity(
                              opacity: 0.35,
                              child: Icon(
                                CupertinoIcons.tray,
                                size: 56,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'No Reminders',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap "New Reminder" below to create one',
                              style: TextStyle(
                                fontSize: 13,
                                letterSpacing: -0.1,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                        children: [
                          Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: secondaryBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                for (int i = 0; i < visibleTasks.length; i++)
                                  IosTaskCell(
                                    task: visibleTasks[i],
                                    showDivider: i < visibleTasks.length - 1,
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
                                        if (res.action ==
                                            ReflectionAction.complete) {
                                          await controller.completeTask(t.id);
                                        } else if (res.action ==
                                            ReflectionAction.cancel) {
                                          await controller.cancelTask(
                                            t.id,
                                            reason:
                                                res.cancelReason ?? 'Skipped',
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
                                      if (planned ==
                                          PlanTaskHelper
                                              .clearReminderSentinel) {
                                        await controller.clearReminder(t.id);
                                      } else if (planned != null) {
                                        await controller.rescheduleTask(
                                          t.id,
                                          planned,
                                        );
                                      }
                                    },
                                    onCancel: (t) async {
                                      final reason =
                                          await showCancelReasonDialog(
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
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),

          // Authentic iOS Bottom Action Bar (replacing Android FAB)
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: secondaryBg,
              border: Border(
                top: BorderSide(
                  color: separatorColor,
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 38,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _showCreateTaskSheet(context);
                      },
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.plus_circle_fill,
                            color: systemBlue,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'New Reminder',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: systemBlue,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 38,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        _showListSwitcherActionSheet(context);
                      },
                      child: Row(
                        children: [
                          Text(
                            controller.currentList.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            CupertinoIcons.list_bullet,
                            color: textSecondary,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showListSwitcherActionSheet(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Switch Task List'),
        actions: controller.taskLists.map((list) {
          final isSelected = list.id == controller.selectedListId;
          return CupertinoActionSheetAction(
            onPressed: () async {
              await HapticFeedback.lightImpact();
              Navigator.of(ctx).pop();
              if (!isSelected) {
                await controller.switchList(list.id);
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  list.isLocal
                      ? CupertinoIcons.device_phone_portrait
                      : CupertinoIcons.cloud,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  list.title,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.checkmark, size: 16),
                ],
              ],
            ),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
      ),
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

  /// Authentic iOS modal sheet for quick reminder creation
  void _showCreateTaskSheet(BuildContext context) {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    DateTime? plannedTime;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final sheetBg = isDark
            ? AppTheme.darkSecondaryGroupedBackground
            : AppTheme.lightSecondaryGroupedBackground;

        final inputBg = isDark
            ? AppTheme.darkTertiaryGroupedBackground
            : AppTheme.systemGray6Light;

        final textPrimary =
            isDark ? AppTheme.darkLabelPrimary : AppTheme.lightLabelPrimary;

        final textSecondary =
            isDark ? AppTheme.darkLabelSecondary : AppTheme.lightLabelSecondary;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: sheetBg,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // iOS Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              minSize: 32,
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Cancel'),
                            ),
                            Text(
                              'New Reminder',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                                color: textPrimary,
                              ),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              minSize: 32,
                              onPressed: () async {
                                final title = titleController.text.trim();
                                if (title.isNotEmpty) {
                                  await HapticFeedback.lightImpact();
                                  await controller.createTask(
                                    title: title,
                                    notes:
                                        notesController.text.trim().isNotEmpty
                                            ? notesController.text.trim()
                                            : null,
                                    plannedTime: plannedTime,
                                  );
                                  if (ctx.mounted) Navigator.of(ctx).pop();
                                }
                              },
                              child: const Text(
                                'Add',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Input Group
                        Container(
                          decoration: BoxDecoration(
                            color: inputBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Column(
                            children: [
                              CupertinoTextField(
                                controller: titleController,
                                autofocus: true,
                                placeholder: 'Title',
                                placeholderStyle: TextStyle(
                                  color: textSecondary,
                                  fontSize: 15,
                                ),
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 15,
                                ),
                                decoration: const BoxDecoration(),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                              ),
                              const Divider(height: 12, thickness: 0.5),
                              CupertinoTextField(
                                controller: notesController,
                                placeholder: 'Notes',
                                placeholderStyle: TextStyle(
                                  color: textSecondary,
                                  fontSize: 14,
                                ),
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 14,
                                ),
                                decoration: const BoxDecoration(),
                                maxLines: 2,
                                minLines: 1,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Date & Time reminder button
                        GestureDetector(
                          onTap: () async {
                            await HapticFeedback.selectionClick();
                            final selected = await showPlanTaskDialog(
                              context: context,
                              initialTime: plannedTime,
                            );
                            if (selected != null) {
                              setModalState(() {
                                plannedTime = selected;
                              });
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: inputBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.alarm,
                                  size: 18,
                                  color: plannedTime != null
                                      ? (isDark
                                          ? AppTheme.darkSystemBlue
                                          : AppTheme.systemBlue)
                                      : textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    plannedTime != null
                                        ? '${plannedTime!.toLocal().month}/${plannedTime!.toLocal().day} at ${plannedTime!.toLocal().hour}:${plannedTime!.toLocal().minute.toString().padLeft(2, '0')}'
                                        : 'Set Date & Time',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: plannedTime != null
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: plannedTime != null
                                          ? textPrimary
                                          : textSecondary,
                                    ),
                                  ),
                                ),
                                Icon(
                                  CupertinoIcons.chevron_right,
                                  size: 14,
                                  color: textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
          child: const Text('Revisit Onboarding'),
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
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            child: Icon(Icons.check),
          ),
          title: Text(widget.controller.googleEmail ?? 'Google Account'),
          subtitle: const Text('Google Tasks sync active'),
        ),
        const SizedBox(height: 16),
        FilledButton.tonal(
          onPressed: () async {
            Navigator.of(context).pop();
            await widget.controller.syncCurrentList();
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sync, size: 18),
              SizedBox(width: 8),
              Text('Sync Current List Now'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () async {
            await widget.controller.signOutGoogle();
            setState(() {});
          },
          child: const Center(child: Text('Sign Out & Switch to Local Only')),
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
          'Connect with Google Tasks for cloud synchronization across devices:',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 12),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Google Sign-In'),
            Tab(text: 'Direct Token'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: _showTokenGuide ? 240 : 160,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSignInTab(theme),
              _buildTokenTab(theme),
            ],
          ),
        ),
        if (_statusError != null) ...[
          const SizedBox(height: 8),
          Text(
            _statusError!,
            style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildSignInTab(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'One-tap sign-in via Google Play Services.',
          style: TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.login),
          label: const Text('Sign In with Google'),
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() {
                    _isLoading = true;
                    _statusError = null;
                  });
                  try {
                    final ok = await widget.controller.signInGoogle();
                    if (!ok && mounted) {
                      setState(() {
                        _statusError = widget.controller.googleLastError ??
                            'Sign in cancelled or failed';
                      });
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() {
                        _statusError = e.toString();
                      });
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
        ),
      ],
    );
  }

  Widget _buildTokenTab(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Account Email (optional)',
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _tokenController,
            decoration: const InputDecoration(
              labelText: 'OAuth Access Token (ya29...)',
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _showTokenGuide = !_showTokenGuide;
                  });
                },
                child:
                    Text(_showTokenGuide ? 'Hide Info' : 'Where to get token?'),
              ),
              FilledButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        final token = _tokenController.text.trim();
                        if (token.isEmpty) return;
                        setState(() {
                          _isLoading = true;
                          _statusError = null;
                        });
                        try {
                          final ok =
                              await widget.controller.connectGoogleWithToken(
                            token,
                            email: _emailController.text.trim(),
                          );
                          if (!ok && mounted) {
                            setState(() {
                              _statusError =
                                  widget.controller.googleLastError ??
                                      'Token connection failed';
                            });
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() {
                              _statusError = e.toString();
                            });
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        }
                      },
                child: const Text('Connect Token'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

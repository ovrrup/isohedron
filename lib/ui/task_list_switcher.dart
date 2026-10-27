// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/task_list.dart';
import '../theme/app_theme.dart';

class TaskListSwitcherHelper {
  static String formatLabel(TaskList list) {
    return list.title;
  }
}

class TaskListSwitcherState {
  final List<TaskList> availableLists;
  final String selectedListId;

  const TaskListSwitcherState({
    required this.availableLists,
    required this.selectedListId,
  });

  bool get hasMultipleLists => availableLists.length > 1;

  TaskList get currentList {
    return availableLists.firstWhere(
      (l) => l.id == selectedListId,
      orElse: () => availableLists.isNotEmpty
          ? availableLists.first
          : const TaskList(id: 'local_default', title: 'My Tasks'),
    );
  }
}

/// Authentic iOS Navigation bar dropdown switcher for task lists.
class TaskListSwitcherDropdown extends StatelessWidget {
  final List<TaskList> availableLists;
  final String selectedListId;
  final ValueChanged<String> onListSelected;

  const TaskListSwitcherDropdown({
    super.key,
    required this.availableLists,
    required this.selectedListId,
    required this.onListSelected,
  });

  void _showCupertinoPicker(BuildContext context) {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Select Task List'),
        actions: availableLists.map((list) {
          final isSelected = list.id == selectedListId;
          final primaryColor =
              isDark ? AppTheme.darkSystemBlue : AppTheme.systemBlue;

          return CupertinoActionSheetAction(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(ctx).pop();
              if (!isSelected) {
                onListSelected(list.id);
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.folder,
                  size: 16,
                  color: isSelected ? primaryColor : AppTheme.systemGray,
                ),
                const SizedBox(width: 8),
                Text(
                  list.title,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected ? primaryColor : null,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Icon(CupertinoIcons.checkmark, size: 16, color: primaryColor),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = availableLists.firstWhere(
      (l) => l.id == selectedListId,
      orElse: () => availableLists.isNotEmpty
          ? availableLists.first
          : const TaskList(id: 'local_default', title: 'My Tasks'),
    );

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 32,
      onPressed: () => _showCupertinoPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.darkTertiaryGroupedBackground
              : AppTheme.systemGray6Light,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.folder,
              size: 14,
              color: isDark ? AppTheme.darkSystemBlue : AppTheme.systemBlue,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                current.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: isDark
                      ? AppTheme.darkLabelPrimary
                      : AppTheme.lightLabelPrimary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.chevron_down,
              size: 12,
              color: isDark
                  ? AppTheme.darkLabelSecondary
                  : AppTheme.lightLabelSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

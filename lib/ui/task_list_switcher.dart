import 'package:flutter/material.dart';
import '../models/task_list.dart';

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

  TaskList get currentList {
    return availableLists.firstWhere(
      (l) => l.id == selectedListId,
      orElse: () => availableLists.isNotEmpty
          ? availableLists.first
          : const TaskList(id: 'local_default', title: 'My Tasks', isLocal: true),
    );
  }

  String get currentLabel => TaskListSwitcherHelper.formatLabel(currentList);
}

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: availableLists.any((l) => l.id == selectedListId)
            ? selectedListId
            : (availableLists.isNotEmpty ? availableLists.first.id : null),
        icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurface),
        dropdownColor: theme.colorScheme.surface,
        onChanged: (id) {
          if (id != null) onListSelected(id);
        },
        items: availableLists.map((list) {
          return DropdownMenuItem<String>(
            value: list.id,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  list.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

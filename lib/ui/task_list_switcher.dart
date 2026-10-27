import 'package:flutter/material.dart';
import '../models/task_list.dart';

class TaskListSwitcherHelper {
  static String formatLabel(TaskList list) {
    final type = list.isLocal ? 'Local' : 'Google';
    return '${list.title} ($type)';
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
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: availableLists.any((l) => l.id == selectedListId)
            ? selectedListId
            : (availableLists.isNotEmpty ? availableLists.first.id : null),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        dropdownColor: Theme.of(context).colorScheme.surface,
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
                  list.isLocal ? Icons.smartphone : Icons.cloud_outlined,
                  size: 16,
                  color: list.isLocal
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  list.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

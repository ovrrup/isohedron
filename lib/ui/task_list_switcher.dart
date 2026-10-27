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

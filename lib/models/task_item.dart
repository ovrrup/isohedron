class TaskItem {
  final String id;
  final String taskListId;
  final String title;
  final String? notes;
  final DateTime? due;
  final DateTime? plannedTime;
  final bool isCompleted;
  final bool isCancelled;
  final String? cancelReason;
  final DateTime updatedAt;

  const TaskItem({
    required this.id,
    required this.taskListId,
    required this.title,
    this.notes,
    this.due,
    this.plannedTime,
    this.isCompleted = false,
    this.isCancelled = false,
    this.cancelReason,
    required this.updatedAt,
  });

  TaskItem copyWith({
    String? id,
    String? taskListId,
    String? title,
    String? notes,
    bool clearNotes = false,
    DateTime? due,
    bool clearDue = false,
    DateTime? plannedTime,
    bool clearPlannedTime = false,
    bool? isCompleted,
    bool? isCancelled,
    String? cancelReason,
    bool clearCancelReason = false,
    DateTime? updatedAt,
  }) {
    return TaskItem(
      id: id ?? this.id,
      taskListId: taskListId ?? this.taskListId,
      title: title ?? this.title,
      notes: clearNotes ? null : (notes ?? this.notes),
      due: clearDue ? null : (due ?? this.due),
      plannedTime: clearPlannedTime ? null : (plannedTime ?? this.plannedTime),
      isCompleted: isCompleted ?? this.isCompleted,
      isCancelled: isCancelled ?? this.isCancelled,
      cancelReason:
          clearCancelReason ? null : (cancelReason ?? this.cancelReason),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskListId': taskListId,
      'title': title,
      'notes': notes,
      'due': due?.toIso8601String(),
      'plannedTime': plannedTime?.toIso8601String(),
      'isCompleted': isCompleted,
      'isCancelled': isCancelled,
      'cancelReason': cancelReason,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TaskItem.fromMap(Map<String, dynamic> map) {
    return TaskItem(
      id: map['id'] as String,
      taskListId: map['taskListId'] as String,
      title: map['title'] as String,
      notes: map['notes'] as String?,
      due: map['due'] != null ? DateTime.parse(map['due'] as String) : null,
      plannedTime: map['plannedTime'] != null
          ? DateTime.parse(map['plannedTime'] as String)
          : null,
      isCompleted: (map['isCompleted'] as bool?) ?? false,
      isCancelled: (map['isCancelled'] as bool?) ?? false,
      cancelReason: map['cancelReason'] as String?,
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}

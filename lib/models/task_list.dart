class TaskList {
  final String id;
  final String title;
  final bool isDefault;
  final bool isLocal;

  const TaskList({
    required this.id,
    required this.title,
    this.isDefault = false,
    this.isLocal = true,
  });

  TaskList copyWith({
    String? id,
    String? title,
    bool? isDefault,
    bool? isLocal,
  }) {
    return TaskList(
      id: id ?? this.id,
      title: title ?? this.title,
      isDefault: isDefault ?? this.isDefault,
      isLocal: isLocal ?? this.isLocal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isDefault': isDefault,
      'isLocal': isLocal,
    };
  }

  factory TaskList.fromMap(Map<String, dynamic> map) {
    return TaskList(
      id: map['id'] as String,
      title: map['title'] as String,
      isDefault: (map['isDefault'] as bool?) ?? false,
      isLocal: (map['isLocal'] as bool?) ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskList &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          isDefault == other.isDefault &&
          isLocal == other.isLocal;

  @override
  int get hashCode =>
      id.hashCode ^ title.hashCode ^ isDefault.hashCode ^ isLocal.hashCode;
}

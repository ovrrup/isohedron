import 'package:intl/intl.dart';

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

  static final RegExp _plannedRegex = RegExp(r'\[Planned:\s*([^\]]+)\]');
  static final RegExp _cancelledRegex = RegExp(r'\[Cancelled:\s*([^\]]+)\]');

  factory TaskItem.parseFromGoogleTask({
    required String id,
    required String taskListId,
    required String title,
    String? rawNotes,
    DateTime? due,
    required bool isCompleted,
    required DateTime updatedAt,
  }) {
    DateTime? parsedPlannedTime;
    String? parsedCancelReason;
    bool parsedIsCancelled = false;
    String cleanedNotes = rawNotes ?? '';

    if (rawNotes != null && rawNotes.isNotEmpty) {
      // Check for planned timestamp
      final plannedMatch = _plannedRegex.firstMatch(rawNotes);
      if (plannedMatch != null) {
        final dateStr = plannedMatch.group(1)?.trim();
        if (dateStr != null) {
          try {
            parsedPlannedTime = DateTime.parse(dateStr);
          } catch (_) {
            // Malformed date: ignore and leave parsedPlannedTime null
          }
        }
        cleanedNotes =
            cleanedNotes.replaceAll(plannedMatch.group(0)!, '').trim();
      }

      // Check for cancellation reflection
      final cancelledMatch = _cancelledRegex.firstMatch(rawNotes);
      if (cancelledMatch != null) {
        parsedIsCancelled = true;
        final rawReason = cancelledMatch.group(1)?.trim() ?? '';

        // Strip trailing " on YYYY-MM-DD" if present
        final onDateRegex = RegExp(r'\s+on\s+\d{4}-\d{2}-\d{2}$');
        final match = onDateRegex.firstMatch(rawReason);
        if (match != null) {
          parsedCancelReason = rawReason.substring(0, match.start).trim();
        } else {
          parsedCancelReason = rawReason;
        }

        cleanedNotes =
            cleanedNotes.replaceAll(cancelledMatch.group(0)!, '').trim();
      }

      // Clean up separation markers like "---" left by note formatting
      cleanedNotes = cleanedNotes.replaceAll(RegExp(r'\n---\n*'), '\n').trim();
    }

    return TaskItem(
      id: id,
      taskListId: taskListId,
      title: title,
      notes: cleanedNotes.isEmpty ? null : cleanedNotes,
      due: due,
      plannedTime: parsedPlannedTime,
      isCompleted: isCompleted,
      isCancelled: parsedIsCancelled,
      cancelReason: parsedCancelReason,
      updatedAt: updatedAt,
    );
  }

  static String toGoogleNotes({
    String? userNotes,
    DateTime? plannedTime,
    String? cancelReason,
  }) {
    final buffer = StringBuffer();
    if (userNotes != null && userNotes.trim().isNotEmpty) {
      buffer.writeln(userNotes.trim());
    }

    final metadata = <String>[];
    if (plannedTime != null) {
      metadata.add('[Planned: ${plannedTime.toUtc().toIso8601String()}]');
    }

    if (cancelReason != null && cancelReason.trim().isNotEmpty) {
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      metadata.add('[Cancelled: ${cancelReason.trim()} on $dateStr]');
    }

    if (metadata.isNotEmpty) {
      if (buffer.isNotEmpty) {
        buffer.writeln('\n---');
      }
      for (final tag in metadata) {
        buffer.writeln(tag);
      }
    }

    return buffer.toString().trim();
  }

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

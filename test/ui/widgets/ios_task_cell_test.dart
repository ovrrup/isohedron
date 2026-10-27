import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isohedron/models/task_item.dart';
import 'package:isohedron/theme/app_theme.dart';
import 'package:isohedron/ui/widgets/ios_task_cell.dart';

void main() {
  Widget buildTestCell({
    required TaskItem task,
    ValueChanged<TaskItem>? onToggleComplete,
    ValueChanged<TaskItem>? onReschedule,
    ValueChanged<TaskItem>? onCancel,
    ValueChanged<TaskItem>? onDelete,
    ValueChanged<TaskItem>? onReflect,
    VoidCallback? onTap,
    bool showDivider = true,
    bool? isOverdueOverride,
    Brightness brightness = Brightness.light,
  }) {
    return MaterialApp(
      theme: brightness == Brightness.dark
          ? AppTheme.iosDarkTheme
          : AppTheme.iosLightTheme,
      home: Scaffold(
        body: IosTaskCell(
          task: task,
          onToggleComplete: onToggleComplete,
          onReschedule: onReschedule,
          onCancel: onCancel,
          onDelete: onDelete,
          onReflect: onReflect,
          onTap: onTap,
          showDivider: showDivider,
          isOverdueOverride: isOverdueOverride,
        ),
      ),
    );
  }

  group('IosTaskCell Widget Tests', () {
    final activeTask = TaskItem(
      id: 'task-1',
      taskListId: 'list-1',
      title: 'Review PR for iOS redesign',
      notes: 'Check Cupertino widgets and 44px dividers',
      isCompleted: false,
      updatedAt: DateTime(2026, 10, 27, 12, 0),
    );

    final completedTask = TaskItem(
      id: 'task-2',
      taskListId: 'list-1',
      title: 'Submit App Store screenshots',
      isCompleted: true,
      updatedAt: DateTime(2026, 10, 27, 13, 0),
    );

    testWidgets('renders active task title without strikethrough',
        (tester) async {
      await tester.pumpWidget(buildTestCell(task: activeTask));

      final titleFinder = find.text('Review PR for iOS redesign');
      expect(titleFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(titleFinder);
      expect(textWidget.style?.decoration, isNot(TextDecoration.lineThrough));
    });

    testWidgets(
        'renders completed task title with strikethrough and secondary label color',
        (tester) async {
      await tester.pumpWidget(buildTestCell(task: completedTask));

      final titleFinder = find.text('Submit App Store screenshots');
      expect(titleFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(titleFinder);
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);
      expect(textWidget.style?.color, AppTheme.secondaryLabelLight);
    });

    testWidgets(
        'tapping circular toggle invokes onToggleComplete with haptic feedback',
        (tester) async {
      TaskItem? toggledTask;
      await tester.pumpWidget(
        buildTestCell(
          task: activeTask,
          onToggleComplete: (task) {
            toggledTask = task;
          },
        ),
      );

      final toggleFinder = find.byKey(const ValueKey('ios_task_toggle_task-1'));
      expect(toggleFinder, findsOneWidget);

      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      expect(toggledTask, isNotNull);
      expect(toggledTask?.id, 'task-1');
    });

    testWidgets('renders unchecked circular border when task is incomplete',
        (tester) async {
      await tester.pumpWidget(buildTestCell(task: activeTask));

      // Checkmark icon should not be present
      expect(find.byIcon(CupertinoIcons.check_mark), findsNothing);
    });

    testWidgets('renders filled checkmark circle when task is completed',
        (tester) async {
      await tester.pumpWidget(buildTestCell(task: completedTask));

      // Checkmark icon should be visible
      expect(find.byIcon(CupertinoIcons.check_mark), findsOneWidget);
    });

    testWidgets('renders subhead note preview when notes are present',
        (tester) async {
      await tester.pumpWidget(buildTestCell(task: activeTask));

      final noteFinder = find.text('Check Cupertino widgets and 44px dividers');
      expect(noteFinder, findsOneWidget);

      final noteWidget = tester.widget<Text>(noteFinder);
      expect(noteWidget.maxLines, 2);
      expect(noteWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('omits note preview when notes are null', (tester) async {
      await tester.pumpWidget(buildTestCell(task: completedTask));

      expect(
          find.text('Check Cupertino widgets and 44px dividers'), findsNothing);
    });

    testWidgets('renders planned time pill badge when plannedTime is set',
        (tester) async {
      final plannedTask = TaskItem(
        id: 'task-3',
        taskListId: 'list-1',
        title: 'Team sync call',
        plannedTime: DateTime(2026, 10, 27, 16, 30),
        isCompleted: false,
        updatedAt: DateTime(2026, 10, 27, 10, 0),
      );

      await tester.pumpWidget(
        buildTestCell(
          task: plannedTask,
          isOverdueOverride: false,
        ),
      );

      expect(find.byIcon(CupertinoIcons.clock), findsOneWidget);
      expect(find.byKey(const ValueKey('ios_task_planned_badge_task-3')),
          findsOneWidget);
    });

    testWidgets('renders overdue alert pill badge when task is overdue',
        (tester) async {
      final overdueTask = TaskItem(
        id: 'task-4',
        taskListId: 'list-1',
        title: 'Overdue task',
        plannedTime: DateTime(2026, 10, 26, 9, 0), // in the past
        isCompleted: false,
        updatedAt: DateTime(2026, 10, 26, 9, 0),
      );

      await tester.pumpWidget(
        buildTestCell(
          task: overdueTask,
          isOverdueOverride: true,
        ),
      );

      expect(find.byIcon(CupertinoIcons.exclamationmark_circle_fill),
          findsOneWidget);
      expect(find.textContaining('Overdue:'), findsOneWidget);
    });

    testWidgets('renders cancel reason badge when task is cancelled',
        (tester) async {
      final cancelledTask = TaskItem(
        id: 'task-5',
        taskListId: 'list-1',
        title: 'Gym workout',
        isCancelled: true,
        cancelReason: 'Rain and sore muscles',
        updatedAt: DateTime(2026, 10, 27, 14, 0),
      );

      await tester.pumpWidget(buildTestCell(task: cancelledTask));

      expect(find.text('Rain and sore muscles'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.xmark_circle), findsOneWidget);
    });

    testWidgets(
        'renders 44px indented hairline divider when showDivider is true',
        (tester) async {
      await tester.pumpWidget(
        buildTestCell(
          task: activeTask,
          showDivider: true,
        ),
      );

      final dividerFinder =
          find.byKey(const ValueKey('ios_task_divider_task-1'));
      expect(dividerFinder, findsOneWidget);
    });

    testWidgets('omits hairline divider when showDivider is false',
        (tester) async {
      await tester.pumpWidget(
        buildTestCell(
          task: activeTask,
          showDivider: false,
        ),
      );

      final dividerFinder =
          find.byKey(const ValueKey('ios_task_divider_task-1'));
      expect(dividerFinder, findsNothing);
    });

    testWidgets('wraps cell in Dismissible with swipe actions', (tester) async {
      await tester.pumpWidget(buildTestCell(task: activeTask));

      final dismissibleFinder =
          find.byKey(const ValueKey('ios_task_dismissible_task-1'));
      expect(dismissibleFinder, findsOneWidget);

      final dismissible = tester.widget<Dismissible>(dismissibleFinder);
      expect(dismissible.direction, DismissDirection.endToStart);
    });
  });
}

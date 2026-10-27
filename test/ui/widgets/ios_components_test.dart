import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isohedron/models/task_filter.dart';
import 'package:isohedron/models/task_item.dart';
import 'package:isohedron/theme/app_theme.dart';
import 'package:isohedron/ui/widgets/ios_reflection_banner.dart';
import 'package:isohedron/ui/widgets/ios_segmented_filter.dart';

void main() {
  group('IosSegmentedFilter', () {
    testWidgets('renders all 5 task filters in Cupertino sliding control',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.iosLightTheme,
          home: Scaffold(
            body: IosSegmentedFilter(
              currentFilter: TaskFilter.all,
              onFilterChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(CupertinoSlidingSegmentedControl<TaskFilter>),
          findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Planned'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
    });

    testWidgets('displays badge counts when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.iosLightTheme,
          home: Scaffold(
            body: IosSegmentedFilter(
              currentFilter: TaskFilter.today,
              counts: const {
                TaskFilter.today: 3,
                TaskFilter.planned: 5,
              },
              onFilterChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Today (3)'), findsOneWidget);
      expect(find.text('Planned (5)'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
    });

    testWidgets('tapping segment invokes onFilterChanged', (tester) async {
      TaskFilter? selected;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.iosLightTheme,
          home: Scaffold(
            body: IosSegmentedFilter(
              currentFilter: TaskFilter.all,
              onFilterChanged: (filter) => selected = filter,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Done'));
      await tester.pump();

      expect(selected, TaskFilter.completed);
    });
  });

  group('IosReflectionBanner', () {
    testWidgets('returns shrink when overdue tasks list is empty',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.iosLightTheme,
          home: const Scaffold(
            body: IosReflectionBanner(
              overdueTasks: [],
              onReflect: null,
            ),
          ),
        ),
      );

      expect(find.textContaining('awaiting reflection'), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('displays singular task copy when 1 overdue task',
        (tester) async {
      final task = TaskItem(
        id: 'task_1',
        taskListId: 'local_default',
        title: 'Review proposal',
        plannedTime: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.iosLightTheme,
          home: Scaffold(
            body: IosReflectionBanner(
              overdueTasks: [task],
              onReflect: () {},
            ),
          ),
        ),
      );

      expect(find.text('1 task awaiting reflection'), findsOneWidget);
      expect(find.text('Reflect'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.arrow_2_circlepath), findsOneWidget);
    });

    testWidgets('displays plural task copy when multiple overdue tasks',
        (tester) async {
      final task1 = TaskItem(
        id: 'task_1',
        taskListId: 'local_default',
        title: 'Task 1',
        plannedTime: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now(),
      );
      final task2 = TaskItem(
        id: 'task_2',
        taskListId: 'local_default',
        title: 'Task 2',
        plannedTime: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.iosLightTheme,
          home: Scaffold(
            body: IosReflectionBanner(
              overdueTasks: [task1, task2],
              onReflect: () {},
            ),
          ),
        ),
      );

      expect(find.text('2 tasks awaiting reflection'), findsOneWidget);
    });

    testWidgets('tapping Reflect triggers onReflect callback', (tester) async {
      bool reflected = false;
      final task = TaskItem(
        id: 'task_1',
        taskListId: 'local_default',
        title: 'Task 1',
        plannedTime: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.iosLightTheme,
          home: Scaffold(
            body: IosReflectionBanner(
              overdueTasks: [task],
              onReflect: () => reflected = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Reflect'));
      await tester.pump();

      expect(reflected, isTrue);
    });
  });
}

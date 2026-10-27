import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/task_filter.dart';
import '../../theme/app_theme.dart';

/// Authentic iOS Cupertino sliding segmented filter for task lists.
class IosSegmentedFilter extends StatelessWidget {
  final TaskFilter currentFilter;
  final ValueChanged<TaskFilter> onFilterChanged;
  final Map<TaskFilter, int>? counts;
  final EdgeInsetsGeometry padding;

  const IosSegmentedFilter({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
    this.counts,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  String _labelFor(TaskFilter filter) {
    String base;
    switch (filter) {
      case TaskFilter.all:
        base = 'All';
        break;
      case TaskFilter.today:
        base = 'Today';
        break;
      case TaskFilter.planned:
        base = 'Planned';
        break;
      case TaskFilter.completed:
        base = 'Done';
        break;
      case TaskFilter.cancelled:
        base = 'Cancelled';
        break;
    }

    final count = counts?[filter];
    if (count != null && count > 0) {
      return '$base ($count)';
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? AppTheme.darkSecondaryGroupedBackground
        : AppTheme.systemGray5Light;

    final thumbColor = isDark
        ? AppTheme.darkTertiaryGroupedBackground
        : AppTheme.lightSecondaryGroupedBackground;

    final activeTextColor =
        isDark ? AppTheme.darkLabelPrimary : AppTheme.lightLabelPrimary;

    final inactiveTextColor =
        isDark ? AppTheme.darkLabelSecondary : AppTheme.lightLabelSecondary;

    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final children = <TaskFilter, Widget>{
            for (final filter in TaskFilter.values)
              filter: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  _labelFor(filter),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: currentFilter == filter
                        ? FontWeight.w600
                        : FontWeight.w500,
                    letterSpacing: -0.2,
                    color: currentFilter == filter
                        ? activeTextColor
                        : inactiveTextColor,
                  ),
                ),
              ),
          };

          return SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<TaskFilter>(
              groupValue: currentFilter,
              backgroundColor: backgroundColor,
              thumbColor: thumbColor,
              children: children,
              onValueChanged: (val) {
                if (val != null && val != currentFilter) {
                  HapticFeedback.selectionClick();
                  onFilterChanged(val);
                }
              },
            ),
          );
        },
      ),
    );
  }
}

// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class PlanTaskHelper {
  static final DateTime clearReminderSentinel =
      DateTime.fromMillisecondsSinceEpoch(0);

  static DateTime plusOneHour({DateTime? from}) {
    final base = from ?? DateTime.now();
    return base.add(const Duration(hours: 1));
  }

  static DateTime tonight({DateTime? from}) {
    final base = from ?? DateTime.now();
    return DateTime(base.year, base.month, base.day, 20, 0);
  }

  static DateTime tomorrowMorning({DateTime? from}) {
    final base = from ?? DateTime.now();
    final tomorrow = base.add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
  }

  static bool isValidPlannedTime(DateTime time, {DateTime? now}) {
    final current = now ?? DateTime.now();
    return time.isAfter(current);
  }
}

class PlanTaskPromptData {
  DateTime? selectedTime;

  PlanTaskPromptData({this.selectedTime});

  void setShortcut(DateTime time) {
    selectedTime = time;
  }
}

/// Authentic iOS Cupertino modal bottom sheet for scheduling task reminders.
Future<DateTime?> showPlanTaskDialog({
  required BuildContext context,
  DateTime? initialTime,
}) {
  DateTime chosen = initialTime ?? PlanTaskHelper.plusOneHour();

  return showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (ctx) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final sheetBg = isDark
          ? AppTheme.darkSecondaryGroupedBackground
          : AppTheme.lightSecondaryGroupedBackground;

      final pillBg = isDark
          ? AppTheme.darkTertiaryGroupedBackground
          : AppTheme.systemGray5Light;

      final textPrimary =
          isDark ? AppTheme.darkLabelPrimary : AppTheme.lightLabelPrimary;

      return StatefulBuilder(
        builder: (context, setState) {
          return SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 32,
                          onPressed: () => Navigator.of(ctx).pop(null),
                          child: const Text('Cancel'),
                        ),
                        Text(
                          'Schedule Reminder',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                            color: textPrimary,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 32,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(ctx).pop(chosen);
                          },
                          child: const Text(
                            'Done',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 0.5, thickness: 0.5),

                  // Quick shortcut pills
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ShortcutPill(
                          label: '+1 Hour',
                          backgroundColor: pillBg,
                          textColor: textPrimary,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              chosen = PlanTaskHelper.plusOneHour();
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _ShortcutPill(
                          label: 'Tonight',
                          backgroundColor: pillBg,
                          textColor: textPrimary,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              chosen = PlanTaskHelper.tonight();
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _ShortcutPill(
                          label: 'Tomorrow',
                          backgroundColor: pillBg,
                          textColor: textPrimary,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              chosen = PlanTaskHelper.tomorrowMorning();
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // Cupertino Date & Time Wheel Picker
                  SizedBox(
                    height: 216,
                    child: CupertinoDatePicker(
                      key: ValueKey(
                        'cupertino_picker_${chosen.millisecondsSinceEpoch}',
                      ),
                      mode: CupertinoDatePickerMode.dateAndTime,
                      initialDateTime: chosen.isAfter(DateTime.now())
                          ? chosen
                          : DateTime.now().add(const Duration(minutes: 5)),
                      minimumDate:
                          DateTime.now().subtract(const Duration(minutes: 2)),
                      maximumDate:
                          DateTime.now().add(const Duration(days: 365)),
                      use24hFormat: false,
                      onDateTimeChanged: (DateTime newDateTime) {
                        chosen = newDateTime;
                      },
                    ),
                  ),

                  if (initialTime != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: CupertinoButton(
                        minSize: 36,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(ctx)
                              .pop(PlanTaskHelper.clearReminderSentinel);
                        },
                        child: Text(
                          'Remove Reminder',
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.darkSystemRed
                                : AppTheme.systemRed,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _ShortcutPill extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  const _ShortcutPill({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class PlanTaskHelper {
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

Future<DateTime?> showPlanTaskDialog({
  required BuildContext context,
  DateTime? initialTime,
}) {
  DateTime? chosen = initialTime;

  return showDialog<DateTime>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Schedule Reminder'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quick shortcuts:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    ActionChip(
                      label: const Text('+1 Hour'),
                      onPressed: () {
                        setState(() {
                          chosen = PlanTaskHelper.plusOneHour();
                        });
                        Navigator.of(ctx).pop(chosen);
                      },
                    ),
                    ActionChip(
                      label: const Text('Tonight (8 PM)'),
                      onPressed: () {
                        setState(() {
                          chosen = PlanTaskHelper.tonight();
                        });
                        Navigator.of(ctx).pop(chosen);
                      },
                    ),
                    ActionChip(
                      label: const Text('Tomorrow (9 AM)'),
                      onPressed: () {
                        setState(() {
                          chosen = PlanTaskHelper.tomorrowMorning();
                        });
                        Navigator.of(ctx).pop(chosen);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month),
                  title: Text(
                    chosen != null
                        ? '${chosen!.toLocal().year}-${chosen!.toLocal().month.toString().padLeft(2, '0')}-${chosen!.toLocal().day.toString().padLeft(2, '0')} ${chosen!.toLocal().hour.toString().padLeft(2, '0')}:${chosen!.toLocal().minute.toString().padLeft(2, '0')}'
                        : 'Pick custom date & time',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: chosen ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null && context.mounted) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(chosen ?? DateTime.now()),
                      );
                      if (time != null) {
                        setState(() {
                          chosen = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Clear'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(chosen),
                child: const Text('Set Reminder'),
              ),
            ],
          );
        },
      );
    },
  );
}

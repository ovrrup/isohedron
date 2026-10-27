import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/task_item.dart';
import '../theme/app_theme.dart';

class CancelReasonController {
  static const List<String> presetReasons = [
    'Ran out of time',
    'Deprioritized',
    'Waiting on something',
    'No longer needed',
  ];

  String? _selectedPreset;
  String _customText = '';

  String? get selectedPreset => _selectedPreset;
  String get customText => _customText;

  void selectPreset(String? preset) {
    _selectedPreset = preset;
  }

  void setCustomText(String text) {
    _customText = text;
  }

  String get resolvedReason {
    final trimmedCustom = _customText.trim();
    if (trimmedCustom.isNotEmpty) {
      return trimmedCustom;
    }
    if (_selectedPreset != null && _selectedPreset!.trim().isNotEmpty) {
      return _selectedPreset!.trim();
    }
    return 'No reason provided';
  }
}

class CancelReasonPromptData {
  final TaskItem task;
  final CancelReasonController controller;

  CancelReasonPromptData({
    required this.task,
    CancelReasonController? controller,
  }) : controller = controller ?? CancelReasonController();

  String submit() => controller.resolvedReason;
}

/// Authentic iOS Cupertino dialog for task cancellation reflection.
Future<String?> showCancelReasonDialog({
  required BuildContext context,
  required TaskItem task,
}) {
  final controller = CancelReasonController();

  return showCupertinoDialog<String>(
    context: context,
    builder: (ctx) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final textSecondary =
          isDark ? AppTheme.darkLabelSecondary : AppTheme.lightLabelSecondary;

      final inputBg = isDark
          ? AppTheme.darkTertiaryGroupedBackground
          : AppTheme.systemGray6Light;

      return StatefulBuilder(
        builder: (context, setState) {
          return CupertinoAlertDialog(
            title: const Text('Why cancel this task?'),
            content: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '"${task.title}"',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Preset reason pills
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children:
                        CancelReasonController.presetReasons.map((preset) {
                      final isSelected = controller.selectedPreset == preset;
                      final primaryColor = isDark
                          ? AppTheme.darkSystemBlue
                          : AppTheme.systemBlue;

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            controller.selectPreset(isSelected ? null : preset);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor.withValues(alpha: 0.15)
                                : inputBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? primaryColor
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            preset,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? primaryColor
                                  : (isDark
                                      ? AppTheme.darkLabelPrimary
                                      : AppTheme.lightLabelPrimary),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    placeholder: 'Or enter custom reason...',
                    placeholderStyle: TextStyle(
                      color: textSecondary,
                      fontSize: 13,
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.darkLabelPrimary
                          : AppTheme.lightLabelPrimary,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onChanged: (text) {
                      controller.setCustomText(text);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              CupertinoDialogAction(
                isDestructiveAction: false,
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Back'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(ctx).pop(controller.resolvedReason);
                },
                child: const Text('Cancel Task'),
              ),
            ],
          );
        },
      );
    },
  );
}

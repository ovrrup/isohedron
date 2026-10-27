import 'package:flutter/material.dart';
import '../models/task_item.dart';

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

Future<String?> showCancelReasonDialog({
  required BuildContext context,
  required TaskItem task,
}) {
  final controller = CancelReasonController();

  return showDialog<String>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Reflection: Why cancel?'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Task: "${task.title}"',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Select a reason:'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: CancelReasonController.presetReasons.map((preset) {
                      final isSelected = controller.selectedPreset == preset;
                      return ChoiceChip(
                        label: Text(preset),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            controller.selectPreset(selected ? preset : null);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Or enter custom reason',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (text) {
                      controller.setCustomText(text);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Back'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop(controller.resolvedReason);
                },
                child: const Text('Confirm Cancel'),
              ),
            ],
          );
        },
      );
    },
  );
}

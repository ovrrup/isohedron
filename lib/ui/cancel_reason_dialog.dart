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

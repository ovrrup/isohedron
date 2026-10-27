import 'package:test/test.dart';
import 'package:isohedron/models/task_list.dart';
import 'package:isohedron/ui/cancel_reason_dialog.dart';
import 'package:isohedron/ui/plan_task_dialog.dart';
import 'package:isohedron/ui/task_list_switcher.dart';

void main() {
  group('CancelReasonController', () {
    test('provides preset standard reflection reasons', () {
      expect(
          CancelReasonController.presetReasons,
          containsAll([
            'Ran out of time',
            'Deprioritized',
            'Waiting on something',
            'No longer needed',
          ]));
    });

    test('resolves selected preset chip', () {
      final controller = CancelReasonController();
      controller.selectPreset('Deprioritized');
      expect(controller.resolvedReason, 'Deprioritized');
    });

    test('custom text overrides or supplies reason', () {
      final controller = CancelReasonController();
      controller.setCustomText('Unexpected flight delay');
      expect(controller.resolvedReason, 'Unexpected flight delay');
    });

    test('Review Focus: resolves blank input to fallback reason', () {
      final controller = CancelReasonController();
      controller.setCustomText('   ');
      expect(controller.resolvedReason, 'No reason provided');
    });
  });

  group('PlanTaskHelper', () {
    test('computes plusOneHour shortcut accurately', () {
      final now = DateTime(2026, 10, 27, 14, 0);
      final plusOne = PlanTaskHelper.plusOneHour(from: now);
      expect(plusOne.hour, 15);
      expect(plusOne.day, 27);
    });

    test('computes tonight shortcut accurately (8:00 PM)', () {
      final now = DateTime(2026, 10, 27, 10, 0);
      final tonight = PlanTaskHelper.tonight(from: now);
      expect(tonight.hour, 20);
      expect(tonight.minute, 0);
      expect(tonight.day, 27);
    });

    test('computes tomorrowMorning shortcut accurately (9:00 AM)', () {
      final now = DateTime(2026, 10, 27, 10, 0);
      final tomorrow = PlanTaskHelper.tomorrowMorning(from: now);
      expect(tomorrow.hour, 9);
      expect(tomorrow.minute, 0);
      expect(tomorrow.day, 28);
    });
  });

  group('TaskListSwitcherHelper', () {
    test('formats list label with list title', () {
      const list = TaskList(
        id: 'list_1',
        title: 'Personal Sanctuary',
        isDefault: true,
        isLocal: true,
      );

      expect(
        TaskListSwitcherHelper.formatLabel(list),
        'Personal Sanctuary',
      );
    });
  });
}

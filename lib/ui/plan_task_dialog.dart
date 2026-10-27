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

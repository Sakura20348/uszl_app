import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signlang/services/statistics_service.dart';

void main() {
  test('activity calendar puts minutes under their time of day and weekday', () async {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    SharedPreferences.setMockInitialValues({'stat_sessions': [
      '${monday.add(const Duration(hours: 9)).toIso8601String()}|10', // Monday 07:00 row
      '${monday.add(const Duration(hours: 23)).toIso8601String()}|4', // Monday 22:00 row
      '${monday.subtract(const Duration(days: 3, hours: -14)).toIso8601String()}|7', // last week
    ]});
    await StatisticsService.instance.init();

    final week = StatisticsService.instance.activityCalendar('week');
    expect(week.weeks, 1);
    expect(week.cells[5 * 7 + 0], 10); // row 5 = 07:00, column 0 = Monday
    expect(week.cells[0 * 7 + 0], 4); // row 0 = 22:00
    expect(week.cells.fold(0.0, (a, b) => a + b), 14); // last week's session isn't in this week

    final month = StatisticsService.instance.activityCalendar('month');
    expect(month.weeks, 4);
    expect(month.cells.fold(0.0, (a, b) => a + b), 21);
  });

  test('a new user starts with an empty calendar', () async {
    SharedPreferences.setMockInitialValues({});
    await StatisticsService.instance.init();
    expect(StatisticsService.instance.activityCalendar('year').cells.every((m) => m == 0), isTrue);
  });
}

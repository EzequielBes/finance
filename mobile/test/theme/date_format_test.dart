import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/settings/app_settings.dart';
import 'package:mobile/theme/date_format.dart';

void main() {
  final date = DateTime(2026, 3, 5);

  test('formatFullDate respects AppDateFormat', () {
    expect(formatFullDate(date, AppDateFormat.dmy), '05/03/2026');
    expect(formatFullDate(date, AppDateFormat.mdy), '03/05/2026');
    expect(formatFullDate(date, AppDateFormat.ymd), '2026/03/05');
  });

  test('formatShortDate ignores order preference (day + month name only)', () {
    expect(formatShortDate(date), '5 mar');
  });

  test('formatMonthYear respects AppDateFormat for ordering', () {
    expect(formatMonthYear(date, AppDateFormat.ymd), '2026/mar');
    expect(formatMonthYear(date, AppDateFormat.dmy), 'mar/2026');
    expect(formatMonthYear(date, AppDateFormat.mdy), 'mar/2026');
  });
}

// mobile/lib/theme/date_format.dart
import 'package:mobile/settings/app_settings.dart';

const _shortMonths = [
  'jan',
  'fev',
  'mar',
  'abr',
  'mai',
  'jun',
  'jul',
  'ago',
  'set',
  'out',
  'nov',
  'dez',
];

/// "5 mar" — day plus abbreviated month name. Order-independent (no
/// day/month ambiguity to resolve), so it doesn't take an AppDateFormat.
String formatShortDate(DateTime date) =>
    '${date.day} ${_shortMonths[date.month - 1]}';

/// "mar/2026" (dmy/mdy) or "2026/mar" (ymd) — abbreviated month and year.
String formatMonthYear(DateTime date, AppDateFormat format) {
  final month = _shortMonths[date.month - 1];
  return format == AppDateFormat.ymd
      ? '${date.year}/$month'
      : '$month/${date.year}';
}

/// Zero-padded numeric date in the given order.
String formatFullDate(DateTime date, AppDateFormat format) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  final y = date.year.toString();
  return switch (format) {
    AppDateFormat.dmy => '$d/$m/$y',
    AppDateFormat.mdy => '$m/$d/$y',
    AppDateFormat.ymd => '$y/$m/$d',
  };
}

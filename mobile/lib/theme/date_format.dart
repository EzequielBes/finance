// mobile/lib/theme/date_format.dart

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

/// "5 mar" — day plus abbreviated month name, no zero-padding needed.
String formatShortDate(DateTime date) =>
    '${date.day} ${_shortMonths[date.month - 1]}';

/// "mar/2026" — abbreviated month and year, for deadlines and estimates.
String formatMonthYear(DateTime date) =>
    '${_shortMonths[date.month - 1]}/${date.year}';

/// "05/03/2026" — zero-padded numeric date, for form fields.
String formatFullDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

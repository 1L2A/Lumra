// Small formatting used by the view/widgets.
String monthName(int m) => const [
  '',
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
][m];

String weekdayName(int w) =>
    const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][w % 7];

String twoDigit(int n) => n.toString().padLeft(2, '0');

import 'package:flutter/material.dart';

class ChatTimeFormatter {
  const ChatTimeFormatter._();

  static const _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String summary(BuildContext context, DateTime value, {DateTime? now}) {
    final local = value.toLocal();
    final localNow = (now ?? DateTime.now()).toLocal();
    if (isSameDay(local, localNow)) {
      return TimeOfDay.fromDateTime(local).format(context);
    }
    if (isSameDay(local, localNow.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return local.year == localNow.year
        ? '${_months[local.month - 1]} ${local.day}'
        : '${_months[local.month - 1]} ${local.day}, ${local.year}';
  }

  static String dayLabel(DateTime value, {DateTime? now}) {
    final local = value.toLocal();
    final localNow = (now ?? DateTime.now()).toLocal();
    if (isSameDay(local, localNow)) return 'Today';
    if (isSameDay(local, localNow.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return local.year == localNow.year
        ? '${_months[local.month - 1]} ${local.day}'
        : '${_months[local.month - 1]} ${local.day}, ${local.year}';
  }

  static String messageTime(BuildContext context, DateTime value) =>
      TimeOfDay.fromDateTime(value.toLocal()).format(context);

  static bool isSameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

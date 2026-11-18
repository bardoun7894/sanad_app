import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Asks for the report period before generating. Defaults to the last 30
/// days ending today. Returns null if cancelled.
Future<DateTimeRange?> pickReportPeriod(BuildContext context, String helpText) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return showDateRangePicker(
    context: context,
    firstDate: DateTime(2024, 1, 1),
    lastDate: today,
    initialDateRange: DateTimeRange(
      start: today.subtract(const Duration(days: 29)),
      end: today,
    ),
    helpText: helpText,
  );
}

/// Callable payload fields for a picked period (inclusive YYYY-MM-DD days).
Map<String, String> reportPeriodPayload(DateTimeRange range) {
  final f = DateFormat('yyyy-MM-dd');
  return {'startDate': f.format(range.start), 'endDate': f.format(range.end)};
}

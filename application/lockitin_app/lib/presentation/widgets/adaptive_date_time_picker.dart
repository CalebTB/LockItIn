import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/utils/timezone_utils.dart';

/// Platform-adaptive date picker
/// iOS: CupertinoDatePicker (wheel-style)
/// Android: Material DatePicker (calendar grid)
Future<DateTime?> showAdaptiveDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
}) async {
  if (Platform.isIOS) {
    DateTime selectedDate = initialDate;
    bool confirmed = false;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => Container(
        height: 320,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Header with Cancel/Done buttons
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: CupertinoColors.systemBlue.resolveFrom(context),
                        ),
                      ),
                    ),
                    if (helpText != null)
                      Text(
                        helpText,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      onPressed: () {
                        confirmed = true;
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Done',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.systemBlue.resolveFrom(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Date picker
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: initialDate.isBefore(firstDate) ? firstDate : initialDate,
                  minimumDate: firstDate,
                  maximumDate: lastDate,
                  onDateTimeChanged: (date) => selectedDate = date,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return confirmed ? selectedDate : null;
  } else {
    return showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: helpText,
    );
  }
}

/// Platform-adaptive time picker
/// iOS: CupertinoDatePicker in time mode (wheel-style)
/// Android: Material TimePicker (clock/input)
Future<TimeOfDay?> showAdaptiveTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  String? helpText,
}) async {
  if (Platform.isIOS) {
    TimeOfDay selectedTime = initialTime;
    bool confirmed = false;
    final now = DateTime.now();
    final initialDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      initialTime.hour,
      initialTime.minute,
    );

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => Container(
        height: 320,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Header with Cancel/Done buttons
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: CupertinoColors.systemBlue.resolveFrom(context),
                        ),
                      ),
                    ),
                    if (helpText != null)
                      Text(
                        helpText,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      onPressed: () {
                        confirmed = true;
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Done',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.systemBlue.resolveFrom(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Time picker
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: initialDateTime,
                  onDateTimeChanged: (date) {
                    selectedTime = TimeOfDay(hour: date.hour, minute: date.minute);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return confirmed ? selectedTime : null;
  } else {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: helpText,
    );
  }
}

/// Platform-adaptive combined date and time picker
/// Shows date picker first, then time picker
/// Note: Caller must check context.mounted between calls
Future<DateTime?> showAdaptiveDateTimePicker({
  required BuildContext context,
  required DateTime initialDateTime,
  required DateTime firstDate,
  required DateTime lastDate,
  String? dateHelpText,
  String? timeHelpText,
}) async {
  // First pick date
  final date = await showAdaptiveDatePicker(
    context: context,
    initialDate: initialDateTime,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: dateHelpText,
  );

  if (date == null) return null;

  // Caller should check mounted before calling this function again
  // Then pick time
  final time = await showAdaptiveTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initialDateTime),
    helpText: timeHelpText,
  );

  if (time == null) return null;

  // Combine date and time (in local timezone)
  final combined = DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );

  // Check for DST transition and warn user if needed
  if (TimezoneUtils.isDSTTransition(combined)) {
    final shouldContinue = await _showDSTWarning(context, combined);
    if (!shouldContinue) return null;
  }

  // Return local DateTime - caller must convert to UTC before storage
  return combined;
}

/// Show warning dialog when user picks a time during DST transition
Future<bool> _showDSTWarning(BuildContext context, DateTime pickedTime) async {
  // Get the adjusted time after DST conversion
  final safeTime = TimezoneUtils.validateDSTSafe(pickedTime);

  // Create warning message
  final pickedFormatted = TimezoneUtils.formatLocal(pickedTime, 'h:mm a');
  final safeFormatted = TimezoneUtils.formatLocal(safeTime, 'h:mm a');
  final warningMessage = 'The time $pickedFormatted falls during a daylight saving time transition. '
      'It will be adjusted to $safeFormatted when saved. Choose a different time or continue with the adjusted time.';

  if (Platform.isIOS) {
    // iOS-style alert
    return await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Time Change Warning'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(warningMessage),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Choose Different Time'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue Anyway'),
          ),
        ],
      ),
    ) ?? false;
  } else {
    // Android-style alert
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Time Change Warning'),
        content: Text(warningMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Choose Different Time'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue Anyway'),
          ),
        ],
      ),
    ) ?? false;
  }
}

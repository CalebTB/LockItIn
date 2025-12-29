import 'package:flutter/material.dart';
import '../../../theme/sunset_coral_theme.dart';

/// Shows a custom time range picker modal
void showCustomTimePickerModal({
  required BuildContext context,
  required TimeOfDay currentStartTime,
  required TimeOfDay currentEndTime,
  required void Function(TimeOfDay startTime, TimeOfDay endTime) onTimeSelected,
}) {
  const rose950 = SunsetCoralTheme.rose950;
  const rose900 = SunsetCoralTheme.rose900;
  const rose500 = SunsetCoralTheme.rose500;
  const rose400 = SunsetCoralTheme.rose400;
  const rose200 = SunsetCoralTheme.rose200;
  const rose50 = SunsetCoralTheme.rose50;
  const orange500 = SunsetCoralTheme.orange500;

  // Convert TimeOfDay to dropdown values
  int startHour = currentStartTime.hourOfPeriod == 0 ? 12 : currentStartTime.hourOfPeriod;
  int startMinute = (currentStartTime.minute ~/ 15) * 15; // Round to nearest 15
  String startPeriod = currentStartTime.period == DayPeriod.am ? 'AM' : 'PM';

  int endHour = currentEndTime.hourOfPeriod == 0 ? 12 : currentEndTime.hourOfPeriod;
  int endMinute = (currentEndTime.minute ~/ 15) * 15;
  String endPeriod = currentEndTime.period == DayPeriod.am ? 'AM' : 'PM';

  final hours = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  final minutes = [0, 15, 30, 45];
  final periods = ['AM', 'PM'];

  showModalBottomSheet(
    context: context,
    backgroundColor: rose950,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) {
        // Dropdown builder widget
        Widget buildDropdown({
          required String label,
          required dynamic value,
          required List<dynamic> options,
          required Function(dynamic) onChanged,
        }) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: rose400,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  color: rose900.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: rose500.withValues(alpha: 0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<dynamic>(
                    value: value,
                    isExpanded: true,
                    dropdownColor: rose900,
                    borderRadius: BorderRadius.circular(12),
                    menuMaxHeight: 200,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    icon: Icon(Icons.keyboard_arrow_down, color: rose400, size: 20),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: rose50,
                    ),
                    items: options.map((option) {
                      final display = option is int
                          ? option.toString().padLeft(2, '0')
                          : option.toString();
                      return DropdownMenuItem(
                        value: option,
                        child: Text(display),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) onChanged(val);
                    },
                  ),
                ),
              ),
            ],
          );
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: rose500.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  'Select Time Range',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: rose50,
                  ),
                ),
                const SizedBox(height: 24),

                // Start Time Section
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: rose500,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Start Time',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: rose200,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: buildDropdown(
                        label: 'HOUR',
                        value: startHour,
                        options: hours,
                        onChanged: (val) => setSheetState(() => startHour = val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: buildDropdown(
                        label: 'MIN',
                        value: startMinute,
                        options: minutes,
                        onChanged: (val) => setSheetState(() => startMinute = val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: buildDropdown(
                        label: '',
                        value: startPeriod,
                        options: periods,
                        onChanged: (val) => setSheetState(() => startPeriod = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Divider with "to"
                Row(
                  children: [
                    Expanded(child: Divider(color: rose500.withValues(alpha: 0.3))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'to',
                        style: TextStyle(color: rose400, fontSize: 14),
                      ),
                    ),
                    Expanded(child: Divider(color: rose500.withValues(alpha: 0.3))),
                  ],
                ),
                const SizedBox(height: 16),

                // End Time Section
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: orange500,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'End Time',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: rose200,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: buildDropdown(
                        label: 'HOUR',
                        value: endHour,
                        options: hours,
                        onChanged: (val) => setSheetState(() => endHour = val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: buildDropdown(
                        label: 'MIN',
                        value: endMinute,
                        options: minutes,
                        onChanged: (val) => setSheetState(() => endMinute = val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: buildDropdown(
                        label: '',
                        value: endPeriod,
                        options: periods,
                        onChanged: (val) => setSheetState(() => endPeriod = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Done Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Convert dropdown values back to TimeOfDay
                      final startHour24 = startPeriod == 'AM'
                          ? (startHour == 12 ? 0 : startHour)
                          : (startHour == 12 ? 12 : startHour + 12);
                      final endHour24 = endPeriod == 'AM'
                          ? (endHour == 12 ? 0 : endHour)
                          : (endHour == 12 ? 12 : endHour + 12);

                      onTimeSelected(
                        TimeOfDay(hour: startHour24, minute: startMinute),
                        TimeOfDay(hour: endHour24, minute: endMinute),
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ).copyWith(
                      backgroundColor: WidgetStateProperty.all(Colors.transparent),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [rose500, orange500],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    ),
  );
}

import 'package:flutter/material.dart';
import '../../../theme/sunset_coral_theme.dart';

/// Shows a date range picker modal for selecting a date range filter
void showDateRangePickerModal({
  required BuildContext context,
  required DateTimeRange? currentRange,
  required void Function(DateTimeRange range) onRangeSelected,
}) {
  const rose950 = SunsetCoralTheme.rose950;
  const rose900 = SunsetCoralTheme.rose900;
  const rose500 = SunsetCoralTheme.rose500;
  const rose400 = SunsetCoralTheme.rose400;
  const rose200 = SunsetCoralTheme.rose200;
  const rose50 = SunsetCoralTheme.rose50;
  const orange500 = SunsetCoralTheme.orange500;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Start date selection (defaults to today)
  DateTime selectedStartDate = currentRange?.start ?? today;
  // End date selection (defaults to 7 days out)
  DateTime selectedEndDate = currentRange?.end ?? today.add(const Duration(days: 7));

  final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final months = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  // Show current year through 5 years out
  final years = List.generate(6, (i) => now.year + i);

  // Get days in a month
  int daysInMonth(int month, int year) {
    return DateTime(year, month + 1, 0).day;
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: rose950,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) {
        // Get days for start date
        final startDays = List.generate(
          daysInMonth(selectedStartDate.month, selectedStartDate.year),
          (i) => i + 1,
        );
        // Get days for end date
        final endDays = List.generate(
          daysInMonth(selectedEndDate.month, selectedEndDate.year),
          (i) => i + 1,
        );

        // Dropdown builder widget
        Widget buildDropdown({
          required String label,
          required dynamic value,
          required List<dynamic> options,
          required Function(dynamic) onChanged,
          String Function(dynamic)? displayFn,
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
                      final display = displayFn != null
                          ? displayFn(option)
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
                  'Select Date Range',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: rose50,
                  ),
                ),
                const SizedBox(height: 24),

                // Start Date Section
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
                      'Start Date',
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
                        label: 'MONTH',
                        value: selectedStartDate.month,
                        options: months,
                        displayFn: (m) => monthNames[m - 1],
                        onChanged: (val) {
                          setSheetState(() {
                            final maxDay = daysInMonth(val, selectedStartDate.year);
                            final newDay = selectedStartDate.day > maxDay ? maxDay : selectedStartDate.day;
                            selectedStartDate = DateTime(selectedStartDate.year, val, newDay);
                            // If start is now after end, update end to match start
                            if (selectedStartDate.isAfter(selectedEndDate)) {
                              selectedEndDate = selectedStartDate;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: buildDropdown(
                        label: 'DAY',
                        value: selectedStartDate.day,
                        options: startDays,
                        displayFn: (d) => d.toString().padLeft(2, '0'),
                        onChanged: (val) {
                          setSheetState(() {
                            selectedStartDate = DateTime(selectedStartDate.year, selectedStartDate.month, val);
                            // If start is now after end, update end to match start
                            if (selectedStartDate.isAfter(selectedEndDate)) {
                              selectedEndDate = selectedStartDate;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: buildDropdown(
                        label: 'YEAR',
                        value: selectedStartDate.year,
                        options: years,
                        onChanged: (val) {
                          setSheetState(() {
                            final maxDay = daysInMonth(selectedStartDate.month, val);
                            final newDay = selectedStartDate.day > maxDay ? maxDay : selectedStartDate.day;
                            selectedStartDate = DateTime(val, selectedStartDate.month, newDay);
                            // If start is now after end, update end to match start
                            if (selectedStartDate.isAfter(selectedEndDate)) {
                              selectedEndDate = selectedStartDate;
                            }
                          });
                        },
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

                // End Date Section
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
                      'End Date',
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
                        label: 'MONTH',
                        value: selectedEndDate.month,
                        options: months,
                        displayFn: (m) => monthNames[m - 1],
                        onChanged: (val) {
                          setSheetState(() {
                            final maxDay = daysInMonth(val, selectedEndDate.year);
                            final newDay = selectedEndDate.day > maxDay ? maxDay : selectedEndDate.day;
                            selectedEndDate = DateTime(selectedEndDate.year, val, newDay);
                            // If end is now before start, update start to match end
                            if (selectedEndDate.isBefore(selectedStartDate)) {
                              selectedStartDate = selectedEndDate;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: buildDropdown(
                        label: 'DAY',
                        value: selectedEndDate.day,
                        options: endDays,
                        displayFn: (d) => d.toString().padLeft(2, '0'),
                        onChanged: (val) {
                          setSheetState(() {
                            selectedEndDate = DateTime(selectedEndDate.year, selectedEndDate.month, val);
                            // If end is now before start, update start to match end
                            if (selectedEndDate.isBefore(selectedStartDate)) {
                              selectedStartDate = selectedEndDate;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: buildDropdown(
                        label: 'YEAR',
                        value: selectedEndDate.year,
                        options: years,
                        onChanged: (val) {
                          setSheetState(() {
                            final maxDay = daysInMonth(selectedEndDate.month, val);
                            final newDay = selectedEndDate.day > maxDay ? maxDay : selectedEndDate.day;
                            selectedEndDate = DateTime(val, selectedEndDate.month, newDay);
                            // If end is now before start, update start to match end
                            if (selectedEndDate.isBefore(selectedStartDate)) {
                              selectedStartDate = selectedEndDate;
                            }
                          });
                        },
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
                      onRangeSelected(DateTimeRange(
                        start: selectedStartDate,
                        end: selectedEndDate,
                      ));
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

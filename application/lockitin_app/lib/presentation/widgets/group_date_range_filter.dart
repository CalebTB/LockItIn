import 'package:flutter/material.dart';
import '../theme/sunset_coral_theme.dart';

/// Date range filter row with tap-to-select picker
///
/// Shows:
/// - Current date range or "All dates" when no range set
/// - Gradient highlight when range is active
/// - Clear button to remove filter
class GroupDateRangeFilter extends StatelessWidget {
  final DateTimeRange? selectedDateRange;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const GroupDateRangeFilter({
    super.key,
    required this.selectedDateRange,
    required this.onTap,
    required this.onClear,
  });

  String _formatDateRange() {
    if (selectedDateRange == null) return 'All dates';
    final start = selectedDateRange!.start;
    final end = selectedDateRange!.end;
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    if (start.year != end.year) {
      // Format with year when crossing years: Dec 29 '25 - Jan 3 '26
      final startYr = start.year.toString().substring(2);
      final endYr = end.year.toString().substring(2);
      return "${monthNames[start.month - 1]} ${start.day} '$startYr - ${monthNames[end.month - 1]} ${end.day} '$endYr";
    } else {
      // Format without year: Dec 27 - Jan 3
      return '${monthNames[start.month - 1]} ${start.day} - ${monthNames[end.month - 1]} ${end.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRange = selectedDateRange != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: hasRange
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      SunsetCoralTheme.rose500,
                      SunsetCoralTheme.orange500,
                    ],
                  )
                : null,
            color: hasRange
                ? null
                : SunsetCoralTheme.rose900.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasRange
                  ? Colors.transparent
                  : SunsetCoralTheme.rose500.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.date_range_rounded,
                size: 18,
                color: hasRange ? Colors.white : SunsetCoralTheme.rose300,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _formatDateRange(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: hasRange ? FontWeight.w600 : FontWeight.w500,
                    color: hasRange ? Colors.white : SunsetCoralTheme.rose300,
                  ),
                ),
              ),
              if (hasRange)
                GestureDetector(
                  onTap: onClear,
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                )
              else
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: SunsetCoralTheme.rose300,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show the date range picker bottom sheet
  ///
  /// Call this from the parent widget's onTap handler
  static void showDateRangePicker({
    required BuildContext context,
    required DateTimeRange? currentRange,
    required ValueChanged<DateTimeRange> onRangeSelected,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Start date selection (defaults to today)
    DateTime selectedStartDate = currentRange?.start ?? today;
    // End date selection (defaults to 7 days out)
    DateTime selectedEndDate = currentRange?.end ?? today.add(const Duration(days: 7));

    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final months = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
    // Show current year through 5 years out
    final years = List.generate(6, (i) => now.year + i);

    // Get days in a month
    int daysInMonth(int month, int year) {
      return DateTime(year, month + 1, 0).day;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: SunsetCoralTheme.rose950,
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
                      color: SunsetCoralTheme.rose500.withValues(alpha: 0.4),
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
                      color: SunsetCoralTheme.rose50,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Start Date Section
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: SunsetCoralTheme.rose500,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Start Date',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: SunsetCoralTheme.rose200,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _DateDropdown(
                          label: 'MONTH',
                          value: selectedStartDate.month,
                          options: months,
                          displayFn: (m) => monthNames[m - 1],
                          onChanged: (val) {
                            setSheetState(() {
                              final maxDay = daysInMonth(val, selectedStartDate.year);
                              final newDay = selectedStartDate.day > maxDay
                                  ? maxDay
                                  : selectedStartDate.day;
                              selectedStartDate = DateTime(
                                selectedStartDate.year,
                                val,
                                newDay,
                              );
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
                        child: _DateDropdown(
                          label: 'DAY',
                          value: selectedStartDate.day,
                          options: startDays,
                          displayFn: (d) => d.toString().padLeft(2, '0'),
                          onChanged: (val) {
                            setSheetState(() {
                              selectedStartDate = DateTime(
                                selectedStartDate.year,
                                selectedStartDate.month,
                                val,
                              );
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
                        child: _DateDropdown(
                          label: 'YEAR',
                          value: selectedStartDate.year,
                          options: years,
                          onChanged: (val) {
                            setSheetState(() {
                              final maxDay = daysInMonth(
                                selectedStartDate.month,
                                val,
                              );
                              final newDay = selectedStartDate.day > maxDay
                                  ? maxDay
                                  : selectedStartDate.day;
                              selectedStartDate = DateTime(
                                val,
                                selectedStartDate.month,
                                newDay,
                              );
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
                      Expanded(
                        child: Divider(
                          color: SunsetCoralTheme.rose500.withValues(alpha: 0.3),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'to',
                          style: TextStyle(
                            color: SunsetCoralTheme.rose400,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: SunsetCoralTheme.rose500.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // End Date Section
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: SunsetCoralTheme.orange500,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'End Date',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: SunsetCoralTheme.rose200,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _DateDropdown(
                          label: 'MONTH',
                          value: selectedEndDate.month,
                          options: months,
                          displayFn: (m) => monthNames[m - 1],
                          onChanged: (val) {
                            setSheetState(() {
                              final maxDay = daysInMonth(val, selectedEndDate.year);
                              final newDay = selectedEndDate.day > maxDay
                                  ? maxDay
                                  : selectedEndDate.day;
                              selectedEndDate = DateTime(
                                selectedEndDate.year,
                                val,
                                newDay,
                              );
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
                        child: _DateDropdown(
                          label: 'DAY',
                          value: selectedEndDate.day,
                          options: endDays,
                          displayFn: (d) => d.toString().padLeft(2, '0'),
                          onChanged: (val) {
                            setSheetState(() {
                              selectedEndDate = DateTime(
                                selectedEndDate.year,
                                selectedEndDate.month,
                                val,
                              );
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
                        child: _DateDropdown(
                          label: 'YEAR',
                          value: selectedEndDate.year,
                          options: years,
                          onChanged: (val) {
                            setSheetState(() {
                              final maxDay = daysInMonth(
                                selectedEndDate.month,
                                val,
                              );
                              final newDay = selectedEndDate.day > maxDay
                                  ? maxDay
                                  : selectedEndDate.day;
                              selectedEndDate = DateTime(
                                val,
                                selectedEndDate.month,
                                newDay,
                              );
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
                          gradient: const LinearGradient(
                            colors: [
                              SunsetCoralTheme.rose500,
                              SunsetCoralTheme.orange500,
                            ],
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
}

/// Dropdown widget for date selection
class _DateDropdown extends StatelessWidget {
  final String label;
  final int value;
  final List<int> options;
  final String Function(int)? displayFn;
  final ValueChanged<int> onChanged;

  const _DateDropdown({
    required this.label,
    required this.value,
    required this.options,
    this.displayFn,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: SunsetCoralTheme.rose400,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: SunsetCoralTheme.rose900.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: SunsetCoralTheme.rose500.withValues(alpha: 0.3),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              dropdownColor: SunsetCoralTheme.rose900,
              borderRadius: BorderRadius.circular(12),
              menuMaxHeight: 200,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: SunsetCoralTheme.rose400,
                size: 20,
              ),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: SunsetCoralTheme.rose50,
              ),
              items: options.map((option) {
                final display = displayFn != null
                    ? displayFn!(option)
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
}

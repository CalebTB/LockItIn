import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../providers/calendar_provider.dart';
import '../widgets/mini_calendar_widget.dart';
import '../widgets/upcoming_event_card.dart';
import '../widgets/new_event_bottom_sheet.dart';
import 'event_detail_screen.dart';

/// Card-based calendar view with modern UI
/// Features mini calendar, upcoming events, and single FAB for event creation
/// Uses theme-based colors from the Minimal theme design system
class CardCalendarScreen extends StatefulWidget {
  const CardCalendarScreen({super.key});

  @override
  State<CardCalendarScreen> createState() => _CardCalendarScreenState();
}

class _CardCalendarScreenState extends State<CardCalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  void _showNewEventSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => NewEventBottomSheet(
        onClose: () => Navigator.of(context).pop(),
        initialDate: _selectedDate,
      ),
    );
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _focusedMonth = DateTime(date.year, date.month);
    });
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final provider = context.watch<CalendarProvider>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // Header
          _buildHeader(context, colorScheme, appColors),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mini Calendar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: MiniCalendarWidget(
                      selectedDate: _selectedDate,
                      focusedMonth: _focusedMonth,
                      eventIndicators: provider.getEventIndicatorsForMonth(_focusedMonth),
                      onDateSelected: _selectDate,
                    ),
                  ),

                  // Selected Day Events Section
                  _buildSelectedDayEventsSection(context, provider, colorScheme, appColors),

                  // Upcoming Events Section
                  _buildUpcomingEventsSection(context, provider, colorScheme, appColors),

                  // Bottom padding for FAB
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      // Single FAB for creating events (per design system single-action principle)
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewEventSheet,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme, AppColorsExtension appColors) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Month/Year with navigation - centered
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(Icons.chevron_left_rounded),
                color: appColors.textTertiary,
                iconSize: 28,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('MMMM yyyy').format(_focusedMonth),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
                color: appColors.textTertiary,
                iconSize: 28,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDayEventsSection(
    BuildContext context,
    CalendarProvider provider,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    final selectedDayEvents = provider.getEventsForDay(_selectedDate);
    final dateFormat = DateFormat('EEEE, MMMM d');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateFormat.format(_selectedDate).toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: appColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),

          if (selectedDayEvents.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: appColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: appColors.cardBorder,
                  width: 1,
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_busy_outlined,
                      size: 40,
                      color: appColors.textDisabled,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No events this day',
                      style: TextStyle(
                        fontSize: 15,
                        color: appColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...selectedDayEvents.map((event) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: UpcomingEventCard(
                    event: event,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EventDetailScreen(event: event),
                        ),
                      );
                    },
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventsSection(
    BuildContext context,
    CalendarProvider provider,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    final upcomingEvents = provider.getUpcomingEvents();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UPCOMING EVENTS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: appColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),

          if (upcomingEvents.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: appColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: appColors.cardBorder,
                  width: 1,
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available_outlined,
                      size: 48,
                      color: appColors.textDisabled,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No upcoming events',
                      style: TextStyle(
                        fontSize: 16,
                        color: appColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap + to create one',
                      style: TextStyle(
                        fontSize: 14,
                        color: appColors.textDisabled,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...upcomingEvents.map((event) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: UpcomingEventCard(
                    event: event,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EventDetailScreen(event: event),
                        ),
                      );
                    },
                    attendeeInitials: ['SC', 'MJ'], // Placeholder
                    additionalAttendees: 3, // Placeholder
                  ),
                )),
        ],
      ),
    );
  }

}

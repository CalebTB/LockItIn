import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/event_model.dart';
import '../providers/calendar_provider.dart';
import '../widgets/agenda_list_view.dart';
import '../widgets/month_grid_view.dart';
import '../widgets/week_grid_view.dart';
import 'day_detail_screen.dart';
import 'event_creation_screen.dart';
import 'event_detail_screen.dart';

/// Calendar view modes
enum CalendarViewMode { agenda, week, month }

/// Calendar screen with switchable views (Agenda/Week/Month)
/// Features day-grouped events with sticky headers and single FAB for event creation
/// Uses theme-based colors from the Minimal theme design system
class CardCalendarScreen extends StatefulWidget {
  const CardCalendarScreen({super.key});

  @override
  State<CardCalendarScreen> createState() => _CardCalendarScreenState();
}

class _CardCalendarScreenState extends State<CardCalendarScreen> {
  CalendarViewMode _currentView = CalendarViewMode.agenda;
  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;

  void _showNewEventSheet() async {
    // Navigate directly to EventCreationScreen (skip bottom sheet for personal events)
    final result = await Navigator.of(context).push<EventModel>(
      MaterialPageRoute(
        builder: (context) => EventCreationScreen(
          initialDate: _selectedDate ?? DateTime.now(),
        ),
      ),
    );

    // If event was created, save it
    if (result != null && mounted) {
      final provider = context.read<CalendarProvider>();
      provider.addEvent(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final provider = context.watch<CalendarProvider>();

    // Get all events for the agenda view
    final allEvents = provider.getAllEvents();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // Header with current date
          _buildHeader(context, colorScheme, appColors),

          // View mode switcher
          _buildViewSwitcher(context, colorScheme, appColors),

          // Calendar content based on current view
          Expanded(
            child: _buildCalendarContent(
              context,
              colorScheme,
              appColors,
              allEvents,
            ),
          ),
        ],
      ),
      // Single FAB for creating events (per design system single-action principle)
      floatingActionButton: Semantics(
        button: true,
        label: 'Create new event',
        child: FloatingActionButton(
          heroTag: 'calendar_fab',
          onPressed: _showNewEventSheet,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 4,
          tooltip: 'Create new event',
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme, AppColorsExtension appColors) {
    // Get header title based on current view mode
    final headerTitle = _getHeaderTitle();

    return Container(
      height: 44,
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Month/Year title
              Semantics(
                header: true,
                label: 'Calendar showing $headerTitle',
                child: Text(
                  headerTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const Spacer(),
              // Today button
              Semantics(
                button: true,
                label: 'Jump to today',
                child: TextButton(
                  onPressed: _goToToday,
                  child: Text(
                    'Today',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getHeaderTitle() {
    switch (_currentView) {
      case CalendarViewMode.agenda:
        return DateFormat('MMMM yyyy').format(DateTime.now());
      case CalendarViewMode.week:
        return DateFormat('MMMM yyyy').format(_focusedDate);
      case CalendarViewMode.month:
        return DateFormat('MMMM yyyy').format(_focusedDate);
    }
  }

  void _goToToday() {
    setState(() {
      _focusedDate = DateTime.now();
      _selectedDate = DateTime.now();
    });
  }

  Widget _buildViewSwitcher(
    BuildContext context,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Platform.isIOS
          ? _buildCupertinoSegmentedControl(colorScheme)
          : _buildMaterialSegmentedButton(colorScheme, appColors),
    );
  }

  Widget _buildCupertinoSegmentedControl(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<CalendarViewMode>(
        groupValue: _currentView,
        backgroundColor: colorScheme.surfaceContainerHigh,
        thumbColor: colorScheme.surface,
        onValueChanged: (value) {
          if (value != null) {
            setState(() => _currentView = value);
          }
        },
        children: {
          CalendarViewMode.agenda: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Agenda',
              style: TextStyle(
                fontSize: 14,
                fontWeight: _currentView == CalendarViewMode.agenda
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          CalendarViewMode.week: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Week',
              style: TextStyle(
                fontSize: 14,
                fontWeight: _currentView == CalendarViewMode.week
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          CalendarViewMode.month: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Month',
              style: TextStyle(
                fontSize: 14,
                fontWeight: _currentView == CalendarViewMode.month
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        },
      ),
    );
  }

  Widget _buildMaterialSegmentedButton(
    ColorScheme colorScheme,
    AppColorsExtension appColors,
  ) {
    return SegmentedButton<CalendarViewMode>(
      segments: const [
        ButtonSegment<CalendarViewMode>(
          value: CalendarViewMode.agenda,
          label: Text('Agenda'),
          icon: Icon(Icons.list_rounded, size: 18),
        ),
        ButtonSegment<CalendarViewMode>(
          value: CalendarViewMode.week,
          label: Text('Week'),
          icon: Icon(Icons.view_week_rounded, size: 18),
        ),
        ButtonSegment<CalendarViewMode>(
          value: CalendarViewMode.month,
          label: Text('Month'),
          icon: Icon(Icons.calendar_view_month_rounded, size: 18),
        ),
      ],
      selected: {_currentView},
      onSelectionChanged: (selection) {
        setState(() => _currentView = selection.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildCalendarContent(
    BuildContext context,
    ColorScheme colorScheme,
    AppColorsExtension appColors,
    List<EventModel> allEvents,
  ) {
    switch (_currentView) {
      case CalendarViewMode.agenda:
        return AgendaListView(
          events: allEvents,
          daysToShow: 14, // Show 2 weeks
          startDate: _selectedDate,
          onEventTap: (event) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EventDetailScreen(event: event),
              ),
            );
          },
        );
      case CalendarViewMode.week:
        return WeekGridView(
          events: allEvents,
          focusedDate: _focusedDate,
          onEventTap: (event) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EventDetailScreen(event: event),
              ),
            );
          },
          onDayTap: (date) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DayDetailScreen(selectedDate: date),
              ),
            );
          },
        );
      case CalendarViewMode.month:
        return MonthGridView(
          events: allEvents,
          focusedMonth: DateTime(_focusedDate.year, _focusedDate.month, 1),
          selectedDate: _selectedDate,
          onDateSelected: (date) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DayDetailScreen(selectedDate: date),
              ),
            );
          },
          onMonthChanged: (month) {
            setState(() {
              _focusedDate = month;
            });
          },
        );
    }
  }
}

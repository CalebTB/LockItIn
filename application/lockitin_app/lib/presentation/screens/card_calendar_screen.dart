import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../providers/calendar_provider.dart';
import '../widgets/agenda_list_view.dart';
import '../widgets/new_event_bottom_sheet.dart';
import 'event_detail_screen.dart';

/// Calendar screen with agenda list view
/// Features day-grouped events with sticky headers and single FAB for event creation
/// Uses theme-based colors from the Minimal theme design system
class CardCalendarScreen extends StatefulWidget {
  const CardCalendarScreen({super.key});

  @override
  State<CardCalendarScreen> createState() => _CardCalendarScreenState();
}

class _CardCalendarScreenState extends State<CardCalendarScreen> {
  void _showNewEventSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => NewEventBottomSheet(
        onClose: () => Navigator.of(context).pop(),
        initialDate: DateTime.now(),
      ),
    );
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

          // Agenda list view (76% of screen for events)
          Expanded(
            child: AgendaListView(
              events: allEvents,
              daysToShow: 14, // Show 2 weeks
              onEventTap: (event) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EventDetailScreen(event: event),
                  ),
                );
              },
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
    final now = DateTime.now();

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
            children: [
              // Calendar icon
              Icon(
                Icons.calendar_today_rounded,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              // Date display
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agenda',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    DateFormat('EEEE, MMMM d').format(now),
                    style: TextStyle(
                      fontSize: 13,
                      color: appColors.textMuted,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Today button (jump to today if scrolled away)
              TextButton.icon(
                onPressed: () {
                  // Will implement scroll-to-today in future
                },
                icon: Icon(
                  Icons.today_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                label: Text(
                  'Today',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

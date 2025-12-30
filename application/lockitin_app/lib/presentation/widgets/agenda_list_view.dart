import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/event_model.dart';
import 'day_header.dart';
import 'agenda_event_card.dart';
import 'empty_state.dart';

/// Day group containing date and its events
class DayGroup {
  final DateTime date;
  final List<EventModel> events;

  const DayGroup({
    required this.date,
    required this.events,
  });
}

/// Agenda list view showing events grouped by day
/// Features sticky day headers and smooth scrolling
/// Shows today + next 7 days by default
class AgendaListView extends StatelessWidget {
  final List<EventModel> events;
  final int daysToShow;
  final DateTime? startDate;
  final void Function(EventModel event)? onEventTap;
  final Widget? emptyWidget;
  final VoidCallback? onCreateEvent;
  final VoidCallback? onImportCalendar;
  final VoidCallback? onViewGroups;

  const AgendaListView({
    super.key,
    required this.events,
    this.daysToShow = 8, // Today + 7 days
    this.startDate,
    this.onEventTap,
    this.emptyWidget,
    this.onCreateEvent,
    this.onImportCalendar,
    this.onViewGroups,
  });

  @override
  Widget build(BuildContext context) {
    final dayGroups = _buildDayGroups();

    if (dayGroups.isEmpty) {
      return emptyWidget ?? _buildDefaultEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100), // Space for FAB
      itemCount: _countTotalItems(dayGroups),
      itemBuilder: (context, index) {
        return _buildItem(context, dayGroups, index);
      },
    );
  }

  /// Build day groups from events
  List<DayGroup> _buildDayGroups() {
    final start = startDate ?? DateTime.now();
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final groups = <DayGroup>[];

    for (int i = 0; i < daysToShow; i++) {
      final date = normalizedStart.add(Duration(days: i));
      final dayEvents = events.where((event) {
        final eventDate = DateTime(
          event.startTime.year,
          event.startTime.month,
          event.startTime.day,
        );
        return eventDate.isAtSameMomentAs(date);
      }).toList();

      // Sort events by start time
      dayEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

      groups.add(DayGroup(date: date, events: dayEvents));
    }

    return groups;
  }

  /// Count total items (headers + events + empty states)
  int _countTotalItems(List<DayGroup> groups) {
    int count = 0;
    for (final group in groups) {
      count++; // Header
      count += group.events.isEmpty ? 1 : group.events.length; // Events or empty
    }
    return count;
  }

  /// Build item at index (could be header, event, or empty state)
  Widget _buildItem(BuildContext context, List<DayGroup> groups, int index) {
    int currentIndex = 0;

    for (final group in groups) {
      // Check if this is the header
      if (currentIndex == index) {
        return DayHeader(
          date: group.date,
          eventCount: group.events.length,
        );
      }
      currentIndex++;

      // Check if this is an event or empty state
      if (group.events.isEmpty) {
        if (currentIndex == index) {
          return _buildEmptyDayMessage(context);
        }
        currentIndex++;
      } else {
        for (final event in group.events) {
          if (currentIndex == index) {
            return AgendaEventCard(
              event: event,
              onTap: onEventTap != null ? () => onEventTap!(event) : null,
            );
          }
          currentIndex++;
        }
      }
    }

    return const SizedBox.shrink();
  }

  Widget _buildEmptyDayMessage(BuildContext context) {
    final appColors = context.appColors;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: appColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: appColors.cardBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 20,
            color: appColors.textDisabled,
          ),
          const SizedBox(width: 12),
          Text(
            'No events scheduled',
            style: TextStyle(
              fontSize: 14,
              color: appColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultEmptyState(BuildContext context) {
    // Determine the appropriate empty state type
    final hasAnyEvents = events.isNotEmpty;

    if (!hasAnyEvents) {
      // New user or no events at all
      return EmptyState(
        type: EmptyStateType.noEventsNewUser,
        onCreateEvent: onCreateEvent,
        onImportCalendar: onImportCalendar,
      );
    } else {
      // Has events but nothing in the current view period
      return EmptyState(
        type: EmptyStateType.noEventsThisWeek,
        onCreateEvent: onCreateEvent,
        onViewGroups: onViewGroups,
      );
    }
  }
}

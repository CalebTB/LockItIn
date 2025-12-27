import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/event_model.dart';
import '../../core/services/event_service.dart';
import '../providers/calendar_provider.dart';
import 'event_creation_screen.dart';

/// Event detail screen showing complete information for a single event
/// Displays title, date/time, location, notes, privacy settings
/// Includes Edit and Delete buttons with full sync functionality
class EventDetailScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final EventService _eventService = EventService();
  late EventModel _currentEvent;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Event Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          // Edit button
          IconButton(
            icon: Icon(Icons.edit_outlined, color: colorScheme.primary),
            onPressed: _isLoading ? null : _handleEdit,
            tooltip: 'Edit event',
          ),
          // Delete button
          IconButton(
            icon: Icon(Icons.delete_outline, color: colorScheme.error),
            onPressed: _isLoading ? null : _handleDelete,
            tooltip: 'Delete event',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Title
            Text(
              _currentEvent.title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 24),

            // Privacy Badge
            _buildPrivacyBadge(context, colorScheme),

            const SizedBox(height: 24),

            // Location (if available) - Left aligned, no box
            if (_currentEvent.location != null && _currentEvent.location!.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _currentEvent.location!,
                      style: TextStyle(
                        fontSize: 15,
                        color: colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),

            if (_currentEvent.location != null && _currentEvent.location!.isNotEmpty)
              const SizedBox(height: 12),

            // Date & Time Section
            _buildInfoSection(
              context,
              colorScheme,
              icon: Icons.calendar_today,
              title: 'Date & Time',
              content: _buildDateTimeContent(context, colorScheme),
            ),

            const SizedBox(height: 20),

            // Notes/Description Section (if available)
            if (_currentEvent.description != null && _currentEvent.description!.isNotEmpty)
              _buildInfoSection(
                context,
                colorScheme,
                icon: Icons.notes,
                title: 'Notes',
                content: Text(
                  _currentEvent.description!,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
              ),

            if (_currentEvent.description != null && _currentEvent.description!.isNotEmpty)
              const SizedBox(height: 20),

            // Metadata Section
            _buildMetadataSection(context, colorScheme),
          ],
        ),
      ),
    );
  }

  /// Build privacy badge showing event visibility setting
  Widget _buildPrivacyBadge(BuildContext context, ColorScheme colorScheme) {
    final privacyInfo = _getPrivacyInfo(_currentEvent.visibility);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: privacyInfo['color'] as Color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            privacyInfo['icon'] as IconData,
            size: 18,
            color: colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            privacyInfo['label'] as String,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  /// Get privacy badge icon, label, and color based on visibility
  Map<String, dynamic> _getPrivacyInfo(EventVisibility visibility) {
    switch (visibility) {
      case EventVisibility.private:
        return {
          'icon': Icons.lock,
          'label': 'Private',
          'color': Colors.red.shade100,
        };
      case EventVisibility.sharedWithName:
        return {
          'icon': Icons.people,
          'label': 'Shared with Details',
          'color': Colors.green.shade100,
        };
      case EventVisibility.busyOnly:
        return {
          'icon': Icons.visibility_off,
          'label': 'Busy Only',
          'color': Colors.orange.shade100,
        };
    }
  }

  /// Build an information section with icon, title, and content
  Widget _buildInfoSection(
    BuildContext context,
    ColorScheme colorScheme, {
    required IconData icon,
    required String title,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  /// Build date and time content with formatting
  Widget _buildDateTimeContent(BuildContext context, ColorScheme colorScheme) {
    final isAllDay = _isAllDayEvent(_currentEvent);
    final isSameDay = _isSameDay(_currentEvent.startTime, _currentEvent.endTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Start date and time
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start:',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isAllDay
                    ? DateFormat('EEEE, MMMM d, yyyy').format(_currentEvent.startTime)
                    : DateFormat('EEEE, MMMM d, yyyy · h:mm a').format(_currentEvent.startTime),
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ],
          ),

        if (!isAllDay || !isSameDay) ...[
          const SizedBox(height: 8),
          // End date and time
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'End:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAllDay
                      ? DateFormat('EEEE, MMMM d, yyyy').format(_currentEvent.endTime)
                      : DateFormat('EEEE, MMMM d, yyyy · h:mm a').format(_currentEvent.endTime),
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],

        if (isAllDay) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'All-day event',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Build metadata section showing creation/update timestamps
  Widget _buildMetadataSection(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetadataRow(
            colorScheme,
            'Created',
            DateFormat('MMM d, yyyy · h:mm a').format(_currentEvent.createdAt),
          ),
          if (_currentEvent.updatedAt != null) ...[
            const SizedBox(height: 6),
            _buildMetadataRow(
              colorScheme,
              'Last Updated',
              DateFormat('MMM d, yyyy · h:mm a').format(_currentEvent.updatedAt!),
            ),
          ],
        ],
      ),
    );
  }

  /// Build a single metadata row
  Widget _buildMetadataRow(ColorScheme colorScheme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  /// Check if event is all-day (spans exactly 24 hours or midnight to midnight)
  bool _isAllDayEvent(EventModel event) {
    final duration = event.endTime.difference(event.startTime);
    final isExactly24Hours = duration.inHours == 24 || duration.inDays >= 1;
    final startsMidnight = event.startTime.hour == 0 && event.startTime.minute == 0;
    final endsMidnight = event.endTime.hour == 0 && event.endTime.minute == 0;

    return isExactly24Hours || (startsMidnight && endsMidnight);
  }

  /// Check if two dates are on the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Handle edit button press - navigate to edit screen
  Future<void> _handleEdit() async {
    // Capture provider reference before async gap
    final calendarProvider = context.read<CalendarProvider>();

    final updatedEvent = await Navigator.of(context).push<EventModel>(
      MaterialPageRoute(
        builder: (context) => EventCreationScreen(
          eventToEdit: _currentEvent,
        ),
      ),
    );

    if (updatedEvent == null || !mounted) return;

    setState(() => _isLoading = true);

    try {
      // Update in both native calendar and Supabase
      // EventService handles the case where native calendar sync fails gracefully
      final savedEvent = await _eventService.updateEvent(updatedEvent);

      // Update local state
      calendarProvider.updateEvent(_currentEvent, savedEvent);

      setState(() {
        _currentEvent = savedEvent;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on EventServiceException catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update event: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Handle delete button press - show confirmation and delete
  Future<void> _handleDelete() async {
    final colorScheme = Theme.of(context).colorScheme;
    // Capture provider reference before async gap
    final calendarProvider = context.read<CalendarProvider>();

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text(
          'Are you sure you want to delete "${_currentEvent.title}"?\n\n'
          'This will remove the event from your calendar and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);

    try {
      // Delete from both native calendar and Supabase
      await _eventService.deleteEvent(_currentEvent);

      // Remove from calendar provider
      calendarProvider.removeEvent(_currentEvent.id, _currentEvent.startTime);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event deleted successfully'),
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate back to calendar
        Navigator.of(context).pop();
      }
    } on EventServiceException catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete event: $e'),
            backgroundColor: colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

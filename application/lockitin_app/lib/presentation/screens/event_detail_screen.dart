import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/event_model.dart';

/// Event detail screen showing complete information for a single event
/// Displays title, date/time, location, notes, privacy settings
/// Includes Edit and Delete buttons (UI only for now)
class EventDetailScreen extends StatelessWidget {
  final EventModel event;

  const EventDetailScreen({
    super.key,
    required this.event,
  });

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
            onPressed: () {
              // TODO: Navigate to edit screen when implemented
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edit functionality coming soon'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Edit event',
          ),
          // Delete button
          IconButton(
            icon: Icon(Icons.delete_outline, color: colorScheme.error),
            onPressed: () {
              // TODO: Show delete confirmation dialog when implemented
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delete functionality coming soon'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Delete event',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Title
            Text(
              event.title,
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

            // Location (if available) - Top right, no box
            if (event.location != null && event.location!.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Row(
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
                        event.location!,
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
              ),

            if (event.location != null && event.location!.isNotEmpty)
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
            if (event.description != null && event.description!.isNotEmpty)
              _buildInfoSection(
                context,
                colorScheme,
                icon: Icons.notes,
                title: 'Notes',
                content: Text(
                  event.description!,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
              ),

            if (event.description != null && event.description!.isNotEmpty)
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
    final privacyInfo = _getPrivacyInfo(event.visibility);

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
    final isAllDay = _isAllDayEvent(event);
    final isSameDay = _isSameDay(event.startTime, event.endTime);

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
                    ? DateFormat('EEEE, MMMM d, yyyy').format(event.startTime)
                    : DateFormat('EEEE, MMMM d, yyyy · h:mm a').format(event.startTime),
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
                      ? DateFormat('EEEE, MMMM d, yyyy').format(event.endTime)
                      : DateFormat('EEEE, MMMM d, yyyy · h:mm a').format(event.endTime),
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
            DateFormat('MMM d, yyyy · h:mm a').format(event.createdAt),
          ),
          if (event.updatedAt != null) ...[
            const SizedBox(height: 6),
            _buildMetadataRow(
              colorScheme,
              'Last Updated',
              DateFormat('MMM d, yyyy · h:mm a').format(event.updatedAt!),
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
}

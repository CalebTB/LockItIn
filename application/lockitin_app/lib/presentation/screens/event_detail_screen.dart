import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/event_model.dart';
import '../../data/models/event_template_model.dart';
import '../../core/network/supabase_client.dart';
import '../../core/services/event_service.dart';
import '../../core/utils/route_transitions.dart';
import '../../core/utils/timezone_utils.dart';
import '../../core/utils/rsvp_status_utils.dart';
import '../../core/utils/surprise_party_utils.dart';
import '../../core/theme/app_colors.dart';
import '../../utils/calendar_utils.dart';
import '../../utils/privacy_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/calendar_provider.dart';
import '../widgets/rsvp_response_sheet.dart';
import 'event_creation_screen.dart';
import 'surprise_party_dashboard_screen.dart';

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
  String? _userRsvpStatus; // User's RSVP status for this event
  bool _isLoadingRsvp = false;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    _fetchUserRsvpStatus();
  }

  Future<void> _fetchUserRsvpStatus() async {
    final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
    if (currentUserId == null) return;

    try {
      setState(() {
        _isLoadingRsvp = true;
      });

      final response = await SupabaseClientManager.client
          .from('event_invitations')
          .select('rsvp_status')
          .eq('event_id', _currentEvent.id)
          .eq('user_id', currentUserId)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _userRsvpStatus = response?['rsvp_status'];
        _isLoadingRsvp = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingRsvp = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id;
    final userRole = _currentEvent.getUserRole(currentUserId);
    final displayTitle = _currentEvent.getDisplayTitle(currentUserId);

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
              displayTitle,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 24),

            // SECRET badge for coordinators
            if (_isSurpriseParty && userRole == 'coordinator')
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock,
                      size: 16,
                      color: colorScheme.onPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'SECRET EVENT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),

            // Party Coordinator Hub button for coordinators
            if (_isSurpriseParty && userRole == 'coordinator')
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SurprisePartyDashboard(
                          event: _currentEvent,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.dashboard_outlined, size: 20),
                  label: const Text(
                    'Party Coordinator Hub',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            // RSVP button for invited members (non-coordinators, non-guest-of-honor)
            if (_isSurpriseParty && userRole == 'member' && _userRsvpStatus != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                child: OutlinedButton.icon(
                  onPressed: _isLoadingRsvp
                      ? null
                      : () async {
                          final newStatus = await showModalBottomSheet<String>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => RsvpResponseSheet(
                              eventId: _currentEvent.id,
                              userId: currentUserId!,
                              currentStatus: _userRsvpStatus,
                            ),
                          );

                          if (newStatus != null && mounted) {
                            setState(() {
                              _userRsvpStatus = newStatus;
                            });
                          }
                        },
                  icon: Icon(RSVPStatusUtils.getIcon(_userRsvpStatus ?? 'pending'), size: 20),
                  label: Text(
                    RSVPStatusUtils.getButtonLabel(_userRsvpStatus ?? 'pending'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: RSVPStatusUtils.getColor(_userRsvpStatus ?? 'pending', colorScheme, appColors),
                    side: BorderSide(
                      color: RSVPStatusUtils.getColor(_userRsvpStatus ?? 'pending', colorScheme, appColors),
                      width: 2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

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
    final visibility = _currentEvent.visibility;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: PrivacyColors.getPrivacyBackgroundColor(visibility),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PrivacyColors.getPrivacyIcon(visibility),
            size: 18,
            color: colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            PrivacyColors.getPrivacyLabel(visibility),
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
    final isAllDay = CalendarUtils.isAllDayEvent(_currentEvent);
    final isSameDay = CalendarUtils.isSameDay(_currentEvent.startTime, _currentEvent.endTime);

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
                    ? TimezoneUtils.formatLocal(_currentEvent.startTime, 'EEEE, MMMM d, yyyy')
                    : TimezoneUtils.formatLocal(_currentEvent.startTime, 'EEEE, MMMM d, yyyy · h:mm a'),
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
                      ? TimezoneUtils.formatLocal(_currentEvent.endTime, 'EEEE, MMMM d, yyyy')
                      : TimezoneUtils.formatLocal(_currentEvent.endTime, 'EEEE, MMMM d, yyyy · h:mm a'),
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
            TimezoneUtils.formatLocal(_currentEvent.createdAt, 'MMM d, yyyy · h:mm a'),
          ),
          if (_currentEvent.updatedAt != null) ...[
            const SizedBox(height: 6),
            _buildMetadataRow(
              colorScheme,
              'Last Updated',
              TimezoneUtils.formatLocal(_currentEvent.updatedAt!, 'MMM d, yyyy · h:mm a'),
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

  /// Handle edit button press - navigate to edit screen
  Future<void> _handleEdit() async {
    // Capture provider reference before async gap
    final calendarProvider = context.read<CalendarProvider>();

    final updatedEvent = await Navigator.of(context).push<EventModel>(
      SlideRoute(
        page: EventCreationScreen(
          mode: EventCreationMode.editPersonalEvent,
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

  /// Check if this event is a surprise party
  bool get _isSurpriseParty =>
      _currentEvent.surprisePartyTemplate != null;

}

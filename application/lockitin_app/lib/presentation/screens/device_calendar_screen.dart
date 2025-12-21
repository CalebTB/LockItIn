import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/services/calendar_manager.dart';
import '../../core/theme/app_colors.dart';
import '../providers/device_calendar_provider.dart';

/// Screen to display device calendar events
/// Tests platform channel integration with iOS EventKit / Android CalendarContract
class DeviceCalendarScreen extends StatefulWidget {
  const DeviceCalendarScreen({super.key});

  @override
  State<DeviceCalendarScreen> createState() => _DeviceCalendarScreenState();
}

class _DeviceCalendarScreenState extends State<DeviceCalendarScreen> {
  @override
  void initState() {
    super.initState();
    // Check permission on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceCalendarProvider>().checkPermission();
    });
  }

  Future<void> _requestPermissionAndFetch() async {
    final provider = context.read<DeviceCalendarProvider>();
    final granted = await provider.requestPermission();

    if (granted && mounted) {
      // Fetch events for the next 30 days
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 7));
      final endDate = now.add(const Duration(days: 30));

      await provider.fetchEvents(
        startDate: startDate,
        endDate: endDate,
      );
    }
  }

  Future<void> _refreshEvents() async {
    final provider = context.read<DeviceCalendarProvider>();

    if (!provider.hasPermission) {
      await _requestPermissionAndFetch();
      return;
    }

    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 7));
    final endDate = now.add(const Duration(days: 30));

    await provider.fetchEvents(
      startDate: startDate,
      endDate: endDate,
      forceRefresh: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshEvents,
            tooltip: 'Refresh events',
          ),
        ],
      ),
      body: Consumer<DeviceCalendarProvider>(
        builder: (context, provider, child) {
          // Show error message if any
          if (provider.errorMessage != null) {
            return _buildErrorState(provider);
          }

          // Show permission request screen
          if (!provider.hasPermission) {
            return _buildPermissionRequestScreen(provider);
          }

          // Show loading indicator
          if (provider.isLoading && provider.events.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Show empty state
          if (provider.events.isEmpty) {
            return _buildEmptyState();
          }

          // Show event list
          return _buildEventList(provider);
        },
      ),
    );
  }

  Widget _buildPermissionRequestScreen(DeviceCalendarProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 80,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Calendar Access Required',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'LockItIn needs access to your calendar to sync events and show your availability to groups.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              provider.permissionStatusText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _requestPermissionAndFetch,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('Grant Calendar Access'),
            ),
            if (provider.permissionStatus == CalendarPermissionStatus.denied)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: TextButton(
                  onPressed: () {
                    // TODO: Open app settings
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please enable calendar access in Settings',
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Settings'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(DeviceCalendarProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Events',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage ?? 'An unknown error occurred',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                provider.clearError();
                _refreshEvents();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Events Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'You don\'t have any events in your calendar for the next 30 days.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _refreshEvents,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventList(DeviceCalendarProvider provider) {
    return RefreshIndicator(
      onRefresh: _refreshEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.events.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) {
            // Header with event count
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${provider.events.length} Events',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (provider.isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            );
          }

          final event = provider.events[index - 1];
          final dateFormat = DateFormat('MMM dd, yyyy');
          final timeFormat = DateFormat('h:mm a');

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: Icon(
                  Icons.event,
                  color: AppColors.primary,
                ),
              ),
              title: Text(
                event.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${dateFormat.format(event.startTime)} • ${timeFormat.format(event.startTime)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (event.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (event.description != null &&
                      event.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
              onTap: () {
                // TODO: Navigate to event details
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Event: ${event.title}'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

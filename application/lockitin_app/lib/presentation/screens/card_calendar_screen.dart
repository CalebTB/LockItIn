import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../providers/calendar_provider.dart';
import '../providers/friend_provider.dart';
import '../widgets/mini_calendar_widget.dart';
import '../widgets/upcoming_event_card.dart';
import '../widgets/expandable_fab.dart';
import '../widgets/groups_bottom_sheet.dart';
import '../widgets/friends_bottom_sheet.dart';
import '../widgets/new_event_bottom_sheet.dart';
import 'event_detail_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'device_calendar_screen.dart';
import 'friends_screen.dart';

/// Redesigned card-based calendar view with modern UI
/// Features mini calendar, upcoming events, and expandable FAB navigation
/// Uses theme-based colors from the Minimal theme design system
class CardCalendarScreen extends StatefulWidget {
  const CardCalendarScreen({super.key});

  @override
  State<CardCalendarScreen> createState() => _CardCalendarScreenState();
}

class _CardCalendarScreenState extends State<CardCalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _focusedMonth;
  bool _fabOpen = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month);

    // Initialize FriendProvider for notification badge
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendProvider>().initialize();
    });
  }

  void _toggleFab() {
    setState(() {
      _fabOpen = !_fabOpen;
    });
  }

  void _closeFab() {
    setState(() {
      _fabOpen = false;
    });
  }

  void _showSheet(String sheet) {
    setState(() {
      _fabOpen = false;
    });

    // Use modal bottom sheet with animations and swipe-to-dismiss
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => _buildSheetContent(sheet),
    );
  }

  Widget _buildSheetContent(String sheet) {
    switch (sheet) {
      case 'groups':
        return GroupsBottomSheet(
          onClose: () => Navigator.of(context).pop(),
          onCreateGroup: () {
            Navigator.of(context).pop();
            // TODO: Navigate to group creation
          },
        );
      case 'friends':
        return FriendsBottomSheet(
          onClose: () => Navigator.of(context).pop(),
        );
      case 'newEvent':
        return NewEventBottomSheet(
          onClose: () => Navigator.of(context).pop(),
          initialDate: _selectedDate,
        );
      default:
        return const SizedBox.shrink();
    }
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

  void _showNavigationMenu(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            // Menu title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Text(
                    'Menu',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            // Menu items
            _buildMenuItem(
              context: context,
              icon: Icons.home_rounded,
              label: 'Home',
              subtitle: 'Feature overview',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              },
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.calendar_today_rounded,
              label: 'Calendar',
              subtitle: 'Current view',
              isActive: true,
              onTap: () => Navigator.pop(context),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.sync_rounded,
              label: 'Device Calendar',
              subtitle: 'Sync native events',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DeviceCalendarScreen()),
                );
              },
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.people_rounded,
              label: 'Friends',
              subtitle: 'Manage connections',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FriendsScreen()),
                );
              },
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.person_rounded,
              label: 'Profile',
              subtitle: 'Account settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? colorScheme.primary.withValues(alpha: 0.1) : null,
            border: Border(
              left: BorderSide(
                color: isActive ? colorScheme.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isActive
                      ? colorScheme.primary.withValues(alpha: 0.2)
                      : colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isActive ? colorScheme.primary : appColors.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isActive
                            ? colorScheme.onSurface
                            : appColors.textSecondary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: appColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: appColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final provider = context.watch<CalendarProvider>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Main content
          Column(
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

          // FAB backdrop
          if (_fabOpen)
            GestureDetector(
              onTap: _closeFab,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                color: Colors.black.withValues(alpha: _fabOpen ? 0.6 : 0),
              ),
            ),

          // Expandable FAB
          Positioned(
            right: 16,
            bottom: 24,
            // Use Selector to only rebuild when badge count changes
            child: Selector<FriendProvider, int>(
              selector: (_, provider) => provider.pendingRequests.length,
              builder: (context, pendingCount, _) {
                return ExpandableFab(
                  isOpen: _fabOpen,
                  onToggle: _toggleFab,
                  onGroupsPressed: () => _showSheet('groups'),
                  onFriendsPressed: () => _showSheet('friends'),
                  onNewEventPressed: () => _showSheet('newEvent'),
                  pendingFriendRequests: pendingCount,
                );
              },
            ),
          ),
        ],
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              // Menu button (for settings/profile)
              IconButton(
                onPressed: () => _showNavigationMenu(context),
                icon: const Icon(Icons.menu_rounded),
                color: appColors.textSecondary,
              ),

              const Spacer(),

              // Month/Year with navigation
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _previousMonth,
                    icon: const Icon(Icons.chevron_left_rounded),
                    color: appColors.textTertiary,
                    iconSize: 28,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMMM yyyy').format(_focusedMonth),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
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

              const Spacer(),

              // Notification bell with badge
              Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      // TODO: Navigate to notifications
                    },
                    icon: const Icon(Icons.notifications_outlined),
                    color: appColors.textSecondary,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colorScheme.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.surface, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.secondary.withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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

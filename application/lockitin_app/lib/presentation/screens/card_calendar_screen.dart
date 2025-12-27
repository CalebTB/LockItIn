import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../../data/models/event_model.dart';
import '../../utils/calendar_utils.dart';
import '../widgets/mini_calendar_widget.dart';
import '../widgets/upcoming_event_card.dart';
import '../widgets/expandable_fab.dart';
import '../widgets/groups_bottom_sheet.dart';
import '../widgets/friends_bottom_sheet.dart';
import '../widgets/new_event_bottom_sheet.dart';
import 'event_detail_screen.dart';

/// Redesigned card-based calendar view with modern UI
/// Features mini calendar, upcoming events, and expandable FAB navigation
class CardCalendarScreen extends StatefulWidget {
  const CardCalendarScreen({super.key});

  @override
  State<CardCalendarScreen> createState() => _CardCalendarScreenState();
}

class _CardCalendarScreenState extends State<CardCalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _focusedMonth;
  bool _fabOpen = false;
  String? _activeSheet; // 'groups' | 'friends' | 'newEvent' | null

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month);
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
      _activeSheet = sheet;
    });
  }

  void _closeSheet() {
    setState(() {
      _activeSheet = null;
    });
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

  /// Get event indicators for the mini calendar
  Map<int, List<Color>> _getEventIndicators(CalendarProvider provider) {
    final indicators = <int, List<Color>>{};
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final events = provider.getEventsForDay(date);
      if (events.isNotEmpty) {
        indicators[day] = events
            .map((e) => CalendarUtils.getCategoryColor(e.category))
            .take(3)
            .toList();
      }
    }
    return indicators;
  }

  /// Get upcoming events (next 7 days)
  List<EventModel> _getUpcomingEvents(CalendarProvider provider) {
    final upcoming = <EventModel>[];
    final now = DateTime.now();

    for (int i = 0; i < 14; i++) {
      final date = DateTime(now.year, now.month, now.day + i);
      final events = provider.getEventsForDay(date);
      upcoming.addAll(events);
    }

    // Sort by start time and take top 5
    upcoming.sort((a, b) => a.startTime.compareTo(b.startTime));
    return upcoming.take(5).toList();
  }

  // Sunset Coral Dark Theme Colors
  static const Color _rose950 = Color(0xFF4C0519);
  static const Color _rose500 = Color(0xFFF43F5E);
  static const Color _rose300 = Color(0xFFFDA4AF);
  static const Color _rose200 = Color(0xFFFECDD3);
  static const Color _orange500 = Color(0xFFF97316);
  static const Color _rose900 = Color(0xFF881337);
  static const Color _slate950 = Color(0xFF020617);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.watch<CalendarProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_rose950, _slate950],
          ),
        ),
        child: Stack(
          children: [
            // Main content
            Column(
            children: [
              // Header
              _buildHeader(context, colorScheme),

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
                          eventIndicators: _getEventIndicators(provider),
                          onDateSelected: _selectDate,
                        ),
                      ),

                      // Selected Day Events Section
                      _buildSelectedDayEventsSection(context, provider),

                      // Upcoming Events Section
                      _buildUpcomingEventsSection(context, provider),

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
            child: ExpandableFab(
              isOpen: _fabOpen,
              onToggle: _toggleFab,
              onGroupsPressed: () => _showSheet('groups'),
              onFriendsPressed: () => _showSheet('friends'),
              onNewEventPressed: () => _showSheet('newEvent'),
            ),
          ),

          // Bottom sheets
          if (_activeSheet != null) ...[
            // Backdrop
            GestureDetector(
              onTap: _closeSheet,
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),

            // Sheet content
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildActiveSheet(),
            ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        // Transparent to blend with the gradient background
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: _rose500.withValues(alpha: 0.1),
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
                onPressed: () {
                  // TODO: Open settings or profile menu
                },
                icon: const Icon(Icons.menu_rounded),
                color: _rose200,
              ),

              const Spacer(),

              // Month/Year with navigation
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _previousMonth,
                    icon: const Icon(Icons.chevron_left_rounded),
                    color: _rose200.withValues(alpha: 0.8),
                    iconSize: 28,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [_rose200, Color(0xFFFED7AA)], // rose-200 to orange-200
                    ).createShader(bounds),
                    child: Text(
                      DateFormat('MMMM yyyy').format(_focusedMonth),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _nextMonth,
                    icon: const Icon(Icons.chevron_right_rounded),
                    color: _rose200.withValues(alpha: 0.8),
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
                    color: _rose200,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _orange500,
                        shape: BoxShape.circle,
                        border: Border.all(color: _rose950, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: _orange500.withValues(alpha: 0.5),
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

  Widget _buildSelectedDayEventsSection(BuildContext context, CalendarProvider provider) {
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
              color: _rose300.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),

          if (selectedDayEvents.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _rose900.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _rose500.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_busy_outlined,
                      size: 40,
                      color: _rose300.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No events this day',
                      style: TextStyle(
                        fontSize: 15,
                        color: _rose300.withValues(alpha: 0.5),
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

  Widget _buildUpcomingEventsSection(BuildContext context, CalendarProvider provider) {
    final upcomingEvents = _getUpcomingEvents(provider);

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
              color: _rose300.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),

          if (upcomingEvents.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: _rose900.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _rose500.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available_outlined,
                      size: 48,
                      color: _rose300.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No upcoming events',
                      style: TextStyle(
                        fontSize: 16,
                        color: _rose300.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap + to create one',
                      style: TextStyle(
                        fontSize: 14,
                        color: _rose300.withValues(alpha: 0.4),
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

  Widget _buildActiveSheet() {
    switch (_activeSheet) {
      case 'groups':
        return GroupsBottomSheet(
          onClose: _closeSheet,
          onCreateGroup: () {
            _closeSheet();
            // TODO: Navigate to group creation
          },
        );
      case 'friends':
        return FriendsBottomSheet(
          onClose: _closeSheet,
        );
      case 'newEvent':
        return NewEventBottomSheet(
          onClose: _closeSheet,
          initialDate: _selectedDate,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

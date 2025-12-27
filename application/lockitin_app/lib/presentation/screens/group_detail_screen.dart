import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/group_model.dart';
import '../providers/group_provider.dart';
import '../providers/calendar_provider.dart';

/// Group detail screen showing group calendar with availability heatmap
/// Adapted from CalendarScreen with Sunset Coral Dark theme
class GroupDetailScreen extends StatefulWidget {
  final GroupModel group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  // Sunset Coral Dark Theme Colors
  static const Color _rose950 = Color(0xFF4C0519);
  static const Color _rose900 = Color(0xFF881337);
  static const Color _rose800 = Color(0xFF9F1239);
  static const Color _rose700 = Color(0xFFBE123C);
  static const Color _rose600 = Color(0xFFE11D48);
  static const Color _rose500 = Color(0xFFF43F5E);
  static const Color _rose400 = Color(0xFFFB7185);
  static const Color _rose300 = Color(0xFFFDA4AF);
  static const Color _rose200 = Color(0xFFFECDD3);
  static const Color _rose50 = Color(0xFFFFF1F2);
  static const Color _orange400 = Color(0xFFFB923C);
  static const Color _orange500 = Color(0xFFF97316);
  static const Color _orange600 = Color(0xFFEA580C);
  static const Color _amber500 = Color(0xFFF59E0B);
  static const Color _emerald500 = Color(0xFF10B981);
  static const Color _slate950 = Color(0xFF020617);

  late DateTime _focusedMonth;
  int? _selectedDay;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
    _pageController = PageController(initialPage: 12); // Start at current month

    // Load group members
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().selectGroup(widget.group.id);
    });
  }

  /// Check if user has any events on a specific date
  /// Returns 0 if busy (has events), 1 if available (no events)
  int _getAvailabilityForDay(CalendarProvider calendarProvider, DateTime date) {
    final events = calendarProvider.getEventsForDay(date);
    return events.isEmpty ? 1 : 0; // 1 = available, 0 = busy
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Get heatmap color based on availability ratio
  Color _getHeatmapColor(int available, int total) {
    if (total == 0) return _rose950;
    final ratio = available / total;
    if (ratio >= 1.0) return _orange400; // 100% - Perfect (gradient effect handled separately)
    if (ratio >= 0.875) return _rose400;
    if (ratio >= 0.75) return _rose500;
    if (ratio >= 0.625) return _rose600;
    if (ratio >= 0.5) return _rose700;
    if (ratio >= 0.375) return _rose800;
    if (ratio >= 0.25) return _rose900;
    return _rose950;
  }

  /// Get text color for heatmap cell - always white for readability
  Color _getHeatmapTextColor(int available, int total) {
    return Colors.white;
  }

  void _previousMonth() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextMonth() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_rose950, _slate950],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Header with group info
                  _buildHeader(context),

                  // Month navigation
                  _buildMonthNavigation(),

                  // Availability legend
                  _buildLegend(),

                  // Calendar grid
                  Expanded(
                    child: _buildCalendarPageView(),
                  ),

                  // Group members section
                  _buildMembersSection(),

                  // Best days section
                  _buildBestDaysSection(),

                  const SizedBox(height: 16),
                ],
              ),

              // Day detail bottom sheet
              if (_selectedDay != null) ...[
                // Backdrop
                GestureDetector(
                  onTap: () => setState(() => _selectedDay = null),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                ),
                // Bottom sheet
                _buildDayDetailSheet(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _rose500.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.chevron_left, size: 28),
            color: Colors.white,
          ),

          // Group emoji
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_amber500, _orange600],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _orange500.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.group.emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Group name and member count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_rose200, Color(0xFFFED7AA)], // rose-200 to orange-200
                  ).createShader(bounds),
                  child: Text(
                    widget.group.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  '${widget.group.memberCount} members',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Members button
          IconButton(
            onPressed: () => _showMembersSheet(context),
            icon: const Icon(Icons.people_rounded, size: 22),
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _previousMonth,
            icon: const Icon(Icons.chevron_left, size: 24),
            color: _rose400.withValues(alpha: 0.6),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [_rose200, Color(0xFFFED7AA)],
            ).createShader(bounds),
            child: Text(
              DateFormat('MMMM yyyy').format(_focusedMonth),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: _nextMonth,
            icon: const Icon(Icons.chevron_right, size: 24),
            color: _rose400.withValues(alpha: 0.6),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _rose500.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Availability',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              Text(
                'Less',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              ...[_rose950, _rose900, _rose800, _rose700, _rose600, _rose500, _rose400]
                  .map((color) => Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      )),
              const SizedBox(width: 4),
              Text(
                'More',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarPageView() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        final monthOffset = index - 12;
        setState(() {
          _focusedMonth = DateTime(
            DateTime.now().year,
            DateTime.now().month + monthOffset,
          );
        });
      },
      itemCount: 24, // 12 months before + 12 months after
      itemBuilder: (context, pageIndex) {
        final monthOffset = pageIndex - 12;
        final month = DateTime(
          DateTime.now().year,
          DateTime.now().month + monthOffset,
        );
        return _buildCalendarGrid(month);
      },
    );
  }

  Widget _buildCalendarGrid(DateTime month) {
    // For now, show 0/1 based on current user's events only
    // In the future, this will aggregate availability from all group members
    const totalMembers = 1; // Just the current user for now
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    // Calculate first day offset and days in month
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final startWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday
    final daysInMonth = lastDayOfMonth.day;

    return Consumer<CalendarProvider>(
      builder: (context, calendarProvider, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              // Day headers
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: days
                      .map((day) => Expanded(
                            child: Center(
                              child: Text(
                                day,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),

              // Calendar cells
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: 42, // 6 rows * 7 days
                  itemBuilder: (context, index) {
                    final dayNumber = index - startWeekday + 1;

                    // Empty cell for days outside current month
                    if (dayNumber < 1 || dayNumber > daysInMonth) {
                      return const SizedBox.shrink();
                    }

                    // Get availability based on real events
                    final date = DateTime(month.year, month.month, dayNumber);
                    final available = _getAvailabilityForDay(calendarProvider, date);
                    final isSelected = _selectedDay == dayNumber &&
                        month.month == _focusedMonth.month;
                    final bgColor = _getHeatmapColor(available, totalMembers);
                    final textColor = _getHeatmapTextColor(available, totalMembers);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDay = dayNumber;
                          _focusedMonth = month;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: _orange400, width: 2)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: _orange400.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$dayNumber',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                            Text(
                              '$available/$totalMembers',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMembersSection() {
    return Consumer<GroupProvider>(
      builder: (context, provider, _) {
        final members = provider.selectedGroupMembers;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: _rose500.withValues(alpha: 0.2)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GROUP MEMBERS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${widget.group.memberCount} people',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Member avatars (stacked)
                  if (provider.isLoadingMembers)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _rose400,
                      ),
                    )
                  else
                    SizedBox(
                      width: (members.length.clamp(0, 6) * 28.0) + 8,
                      height: 36,
                      child: Stack(
                        children: [
                          ...members.take(6).toList().asMap().entries.map((entry) {
                            final index = entry.key;
                            final member = entry.value;
                            return Positioned(
                              left: index * 28.0,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: index == 0
                                      ? null
                                      : _rose900.withValues(alpha: 0.8),
                                  gradient: index == 0
                                      ? const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [_rose400, _orange400],
                                        )
                                      : null,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _rose950, width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    member.initials,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: index == 0 ? Colors.white : _rose200,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                  if (members.length > 6)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        '+${members.length - 6}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),

                  const Spacer(),

                  // Invite button
                  TextButton.icon(
                    onPressed: () => _showInviteFlow(context),
                    icon: Icon(Icons.person_add_rounded, size: 18, color: Colors.white),
                    label: Text(
                      'Invite',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: _rose500.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBestDaysSection() {
    return Consumer<CalendarProvider>(
      builder: (context, calendarProvider, _) {
        // Find days in current month where user has no events (is available)
        final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
        final daysInMonth = lastDayOfMonth.day;

        final bestDays = <int>[];
        for (int day = 1; day <= daysInMonth && bestDays.length < 4; day++) {
          final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
          // Only consider today or future days
          if (date.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
            final events = calendarProvider.getEventsForDay(date);
            if (events.isEmpty) {
              bestDays.add(day);
            }
          }
        }

        if (bestDays.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: _rose500.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BEST DAYS THIS MONTH',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: bestDays.map((day) {
                final monthName = DateFormat('MMM').format(_focusedMonth);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDay = day),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_rose500, _orange500],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: _rose500.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '$monthName $day',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildDayDetailSheet() {
    // For now, just user's availability (0 = busy, 1 = available)
    const totalMembers = 1;
    final monthName = DateFormat('MMMM').format(_focusedMonth);

    return Consumer<CalendarProvider>(
      builder: (context, calendarProvider, _) {
        final date = DateTime(_focusedMonth.year, _focusedMonth.month, _selectedDay ?? 1);
        final available = _getAvailabilityForDay(calendarProvider, date);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_rose950, _slate950],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: _rose500.withValues(alpha: 0.2)),
          ),
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
                color: _rose500.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [_rose200, Color(0xFFFED7AA)],
                        ).createShader(bounds),
                        child: Text(
                          '$monthName $_selectedDay',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        '$available/$totalMembers members available',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => setState(() => _selectedDay = null),
                    icon: const Icon(Icons.close, size: 22),
                    color: _rose300,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Member availability list
            Consumer<GroupProvider>(
              builder: (context, provider, _) {
                final members = provider.selectedGroupMembers;

                return Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.35,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      // Mock availability status
                      final isAvailable = index < available;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isAvailable
                                ? [
                                    _rose900.withValues(alpha: 0.5),
                                    _rose900.withValues(alpha: 0.3),
                                  ]
                                : [
                                    _rose950.withValues(alpha: 0.5),
                                    _rose950.withValues(alpha: 0.3),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isAvailable
                                ? _rose500.withValues(alpha: 0.2)
                                : _rose500.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: index == 0
                                    ? null
                                    : _rose800,
                                gradient: index == 0
                                    ? const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [_rose400, _orange400],
                                      )
                                    : null,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  member.initials,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: index == 0 ? Colors.white : _rose200,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Name and time
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.displayName,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: isAvailable
                                          ? _rose50
                                          : _rose400.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  if (isAvailable)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'All day', // Placeholder
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),

                            // Status icon
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isAvailable
                                    ? _emerald500.withValues(alpha: 0.2)
                                    : _rose500.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isAvailable ? Icons.check : Icons.close,
                                size: 16,
                                color: isAvailable ? _emerald500 : _rose400,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            // Propose event button
            if (available >= (totalMembers * 0.5).ceil())
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to event proposal flow
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Event proposals coming in Sprint 3!',
                          ),
                          backgroundColor: _rose500,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _rose500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      'Propose Event for ${DateFormat('MMM').format(_focusedMonth)} $_selectedDay',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 20),
          ],
        ),
      ),
    );
      },
    );
  }

  void _showMembersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _MembersBottomSheet(group: widget.group),
    );
  }

  void _showInviteFlow(BuildContext context) {
    // TODO: Implement invite flow (Issue #21 or later)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Invite flow coming soon!'),
        backgroundColor: _rose500,
      ),
    );
  }
}

/// Full members list bottom sheet
class _MembersBottomSheet extends StatelessWidget {
  final GroupModel group;

  const _MembersBottomSheet({required this.group});

  static const Color _rose950 = Color(0xFF4C0519);
  static const Color _rose900 = Color(0xFF881337);
  static const Color _rose500 = Color(0xFFF43F5E);
  static const Color _rose400 = Color(0xFFFB7185);
  static const Color _rose300 = Color(0xFFFDA4AF);
  static const Color _rose200 = Color(0xFFFECDD3);
  static const Color _rose50 = Color(0xFFFFF1F2);
  static const Color _orange400 = Color(0xFFFB923C);
  static const Color _slate950 = Color(0xFF020617);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_rose950, _slate950],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: _rose500.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_rose200, Color(0xFFFED7AA)],
                  ).createShader(bounds),
                  child: Text(
                    'Members (${group.memberCount})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: _rose300,
                ),
              ],
            ),
          ),

          // Members list
          Expanded(
            child: Consumer<GroupProvider>(
              builder: (context, provider, _) {
                if (provider.isLoadingMembers) {
                  return Center(
                    child: CircularProgressIndicator(color: _rose400),
                  );
                }

                final members = provider.selectedGroupMembers;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _rose900.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _rose500.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: index == 0
                                  ? const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [_rose400, _orange400],
                                    )
                                  : null,
                              color: index == 0 ? null : _rose900,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                member.initials,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: index == 0 ? Colors.white : _rose200,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Name and role
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.displayName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: _rose50,
                                  ),
                                ),
                                Text(
                                  member.roleDisplayName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: member.role == GroupMemberRole.owner
                                        ? _orange400
                                        : _rose300.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Role badge
                          if (member.role == GroupMemberRole.owner)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_rose500, _orange400],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Owner',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          else if (member.role == GroupMemberRole.admin)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _rose500.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _rose300,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

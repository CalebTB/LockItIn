import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/availability_calculator_service.dart';
import '../../../../core/utils/time_filter_utils.dart';
import '../../../../data/models/event_model.dart';
import '../../../providers/group_provider.dart';
import '../../../theme/sunset_coral_theme.dart';
import '../../../widgets/suggested_time_slots_card.dart';

/// Bottom sheet showing detailed availability for a selected day
class DayDetailSheet extends StatelessWidget {
  final DateTime date;
  final DateTime focusedMonth;
  final int? selectedDay;
  final VoidCallback onClose;
  final Map<String, List<EventModel>> memberEvents;
  final Set<TimeFilter> selectedTimeFilters;
  final TimeOfDay customStartTime;
  final TimeOfDay customEndTime;
  final AvailabilityCalculatorService availabilityService;

  const DayDetailSheet({
    super.key,
    required this.date,
    required this.focusedMonth,
    required this.selectedDay,
    required this.onClose,
    required this.memberEvents,
    required this.selectedTimeFilters,
    required this.customStartTime,
    required this.customEndTime,
    required this.availabilityService,
  });

  static const Color _rose950 = SunsetCoralTheme.rose950;
  static const Color _rose900 = SunsetCoralTheme.rose900;
  static const Color _rose500 = SunsetCoralTheme.rose500;
  static const Color _rose400 = SunsetCoralTheme.rose400;
  static const Color _rose300 = SunsetCoralTheme.rose300;
  static const Color _rose200 = SunsetCoralTheme.rose200;
  static const Color _rose50 = SunsetCoralTheme.rose50;
  static const Color _orange400 = SunsetCoralTheme.orange400;
  static const Color _slate950 = SunsetCoralTheme.slate950;
  static const Color _emerald500 = SunsetCoralTheme.emerald500;

  /// Calculate how many group members are available on this date
  int _getAvailabilityForDay() {
    return availabilityService.calculateGroupAvailability(
      memberEvents: memberEvents,
      date: date,
      timeFilters: selectedTimeFilters,
      customStartTime: customStartTime,
      customEndTime: customEndTime,
    );
  }

  /// Check if a specific member is available on the date
  bool _isMemberAvailableOnDate(String memberId) {
    final memberEventsList = memberEvents[memberId] ?? [];
    final dayStart = DateTime(date.year, date.month, date.day, 0, 0);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final eventsOnDate = memberEventsList
        .where((e) {
          final localStart = e.startTime.toLocal();
          final localEnd = e.endTime.toLocal();
          return localStart.isBefore(dayEnd) && localEnd.isAfter(dayStart);
        })
        .where((e) => e.category != EventCategory.holiday)
        .toList();

    return availabilityService.isMemberAvailable(
      events: eventsOnDate,
      date: date,
      timeFilters: selectedTimeFilters,
      customStartTime: customStartTime,
      customEndTime: customEndTime,
    );
  }

  /// Get a human-readable description of availability for a specific member
  String _getMemberAvailabilityDescription(String memberId, TimeFilter filter) {
    final memberEventsList = memberEvents[memberId] ?? [];
    final dayStart = DateTime(date.year, date.month, date.day, 0, 0);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final eventsOnDate = memberEventsList
        .where((e) {
          final localStart = e.startTime.toLocal();
          final localEnd = e.endTime.toLocal();
          return localStart.isBefore(dayEnd) && localEnd.isAfter(dayStart);
        })
        .where((e) => e.category != EventCategory.holiday)
        .toList();

    return availabilityService.getAvailabilityDescription(
      events: eventsOnDate,
      date: date,
      filter: filter,
      customStartTime: customStartTime,
      customEndTime: customEndTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM').format(focusedMonth);
    final groupProvider = context.read<GroupProvider>();
    final totalMembers = groupProvider.selectedGroupMembers.isNotEmpty
        ? groupProvider.selectedGroupMembers.length
        : memberEvents.length;
    final available = _getAvailabilityForDay();

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
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
            // Handle bar - tap to close (FIXED at top)
            GestureDetector(
              onTap: onClose,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: Colors.transparent,
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _rose500.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to close',
                        style: TextStyle(
                          fontSize: 10,
                          color: _rose400.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                                  '$monthName $selectedDay',
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
                            onPressed: onClose,
                            icon: const Icon(Icons.close, size: 22),
                            color: _rose300,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Suggested time slots section
                    _buildSuggestedTimeSlots(context),

                    const SizedBox(height: 8),

                    // Member availability list
                    _buildMemberAvailabilityList(context),

                    // Propose event button
                    if (available >= (totalMembers * 0.5).ceil())
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
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
                              'Propose Event for ${DateFormat('MMM').format(focusedMonth)} $selectedDay',
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedTimeSlots(BuildContext context) {
    final groupProvider = context.read<GroupProvider>();
    final members = groupProvider.selectedGroupMembers;

    // Calculate time range from selected filters
    int startHour = 8;
    int endHour = 22;

    if (selectedTimeFilters.contains(TimeFilter.allDay)) {
      startHour = customStartTime.hour;
      endHour = customEndTime.hour;
    } else if (selectedTimeFilters.isNotEmpty) {
      startHour = selectedTimeFilters
          .map((f) => f.startHour)
          .reduce((a, b) => a < b ? a : b);
      endHour = selectedTimeFilters
          .map((f) => f.endHour)
          .reduce((a, b) => a > b ? a : b);
      if (endHour < startHour) {
        endHour = 24;
      }
    }

    // Compute best time slots for this date
    final timeSlots = availabilityService.findBestTimeSlots(
      memberEvents: memberEvents,
      date: date,
      startHour: startHour,
      endHour: endHour,
    );

    return SuggestedTimeSlotsCard(
      date: date,
      timeSlots: timeSlots,
      members: members,
      onSlotSelected: (slot) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Selected ${slot.formattedTimeRange} - Event proposals coming in Sprint 3!',
            ),
            backgroundColor: _rose500,
          ),
        );
      },
    );
  }

  Widget _buildMemberAvailabilityList(BuildContext context) {
    return Consumer<GroupProvider>(
      builder: (context, provider, _) {
        final members = provider.selectedGroupMembers;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            final isAvailable = _isMemberAvailableOnDate(member.userId);

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
                      color: index == 0 ? null : _rose900.withValues(alpha: 0.8),
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

                  // Name and availability time
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
                        _buildAvailabilityDescription(member.userId),
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
        );
      },
    );
  }

  Widget _buildAvailabilityDescription(String memberId) {
    final descriptions = <String>[];

    if (selectedTimeFilters.contains(TimeFilter.allDay)) {
      final desc = _getMemberAvailabilityDescription(memberId, TimeFilter.allDay);
      descriptions.add(desc);
    } else {
      for (final filter in selectedTimeFilters) {
        final desc = _getMemberAvailabilityDescription(memberId, filter);
        if (selectedTimeFilters.length > 1) {
          descriptions.add('${filter.label}: $desc');
        } else {
          descriptions.add(desc);
        }
      }
    }

    if (descriptions.length == 1) {
      final desc = descriptions.first;
      final isFree = desc == 'Free';

      return Row(
        children: [
          Icon(
            isFree ? Icons.check_circle_outline : Icons.event_busy_rounded,
            size: 12,
            color: isFree ? _emerald500 : _orange400,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              desc,
              style: TextStyle(
                fontSize: 12,
                color: isFree ? _emerald500 : _orange400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    // Multiple filters - show each on its own line
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: descriptions.map((desc) {
        final isFree = desc == 'Free' || desc.endsWith('Free');

        return Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            children: [
              Icon(
                isFree ? Icons.check_circle_outline : Icons.event_busy_rounded,
                size: 11,
                color: isFree ? _emerald500 : _orange400,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  desc,
                  style: TextStyle(
                    fontSize: 11,
                    color: isFree ? _emerald500 : _orange400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

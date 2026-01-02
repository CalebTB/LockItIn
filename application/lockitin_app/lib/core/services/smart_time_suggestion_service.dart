import '../../data/models/event_model.dart';
import '../../data/models/proposal_time_option.dart';
import 'availability_calculator_service.dart';

/// Service for generating smart time suggestions based on group availability
///
/// Uses the AvailabilityCalculatorService to find the best available time slots
/// and suggests options that maximize group participation.
///
/// Algorithm weights:
/// - 50% availability (percentage of group members free)
/// - 20% time of day (prefer evening > afternoon > morning)
/// - 20% proximity to existing options (spread out suggestions)
/// - 10% duration match (prefer similar duration to existing options)
class SmartTimeSuggestionService {
  final AvailabilityCalculatorService _availabilityService;

  SmartTimeSuggestionService({
    AvailabilityCalculatorService? availabilityService,
  }) : _availabilityService =
            availabilityService ?? AvailabilityCalculatorService();

  /// Suggest the next best time option based on group availability
  ///
  /// This is used when the user clicks "Add Another Option" in the proposal wizard.
  /// It finds the best available slot that:
  /// 1. Has high group availability
  /// 2. Doesn't overlap with existing options
  /// 3. Has good time-of-day preference (evening > afternoon > morning)
  /// 4. Is within a reasonable search window (7 days by default)
  ///
  /// [memberEvents] - Map of userId to their events for availability calculation
  /// [existingOptions] - Already added time options (to avoid duplicates)
  /// [preferredDuration] - Duration in minutes for the suggested slot (default 120)
  /// [searchDays] - Number of days to search ahead (default 7)
  ProposalTimeOption? suggestNextBestOption({
    required Map<String, List<EventModel>> memberEvents,
    required List<ProposalTimeOption> existingOptions,
    int preferredDuration = 120,
    int searchDays = 7,
  }) {
    if (memberEvents.isEmpty) {
      return _fallbackSuggestion(existingOptions, preferredDuration);
    }

    // Get the starting point for search (day after last option, or tomorrow)
    final searchStart = _getSearchStartDate(existingOptions);

    // Collect all candidate slots across the search window
    final candidates = <_ScoredSlot>[];

    for (int dayOffset = 0; dayOffset < searchDays; dayOffset++) {
      final date = searchStart.add(Duration(days: dayOffset));

      // Skip weekends if they have lower availability
      // (optional: can make this configurable)

      // Find best slots for this day
      final daySlots = _findSlotsForDay(
        memberEvents: memberEvents,
        date: date,
        preferredDuration: preferredDuration,
        existingOptions: existingOptions,
      );

      candidates.addAll(daySlots);
    }

    if (candidates.isEmpty) {
      return _fallbackSuggestion(existingOptions, preferredDuration);
    }

    // Sort by score (highest first) and return the best
    candidates.sort((a, b) => b.score.compareTo(a.score));

    final best = candidates.first;
    return ProposalTimeOption(
      startTime: best.slot.startTime,
      endTime: best.slot.endTime,
    );
  }

  /// Find and score all candidate slots for a given day
  List<_ScoredSlot> _findSlotsForDay({
    required Map<String, List<EventModel>> memberEvents,
    required DateTime date,
    required int preferredDuration,
    required List<ProposalTimeOption> existingOptions,
  }) {
    // Find consolidated time slots (merged hours with same availability)
    final slots = _availabilityService.findConsolidatedTimeSlots(
      memberEvents: memberEvents,
      date: date,
      startHour: 8, // Search 8am - 10pm
      endHour: 22,
    );

    final scoredSlots = <_ScoredSlot>[];

    for (final slot in slots) {
      // Skip slots that overlap with existing options
      if (_overlapsWithExisting(slot, existingOptions)) {
        continue;
      }

      // Skip slots that are too short
      if (slot.duration.inMinutes < 60) {
        continue;
      }

      // Calculate the score
      final score = _calculateSlotScore(
        slot: slot,
        preferredDuration: preferredDuration,
        existingOptions: existingOptions,
      );

      // Only consider slots with some availability
      if (slot.availableCount > 0) {
        scoredSlots.add(_ScoredSlot(slot: slot, score: score));
      }
    }

    return scoredSlots;
  }

  /// Calculate a score for a slot based on multiple factors
  ///
  /// Score components:
  /// - Availability (50%): Higher when more members are free
  /// - Time of day (20%): Evening > Afternoon > Morning
  /// - Proximity (20%): Prefer slots spread out from existing options
  /// - Duration match (10%): Prefer matching the preferred duration
  double _calculateSlotScore({
    required TimeSlotAvailability slot,
    required int preferredDuration,
    required List<ProposalTimeOption> existingOptions,
  }) {
    // Availability score (0-1)
    final availabilityScore = slot.availabilityRatio;

    // Time of day score (0-1)
    // Evening (5pm-9pm) = 1.0, Afternoon (12pm-5pm) = 0.7, Morning (8am-12pm) = 0.5
    final hour = slot.startTime.hour;
    double timeOfDayScore;
    if (hour >= 17 && hour <= 21) {
      timeOfDayScore = 1.0; // Evening - most preferred
    } else if (hour >= 12 && hour < 17) {
      timeOfDayScore = 0.7; // Afternoon
    } else {
      timeOfDayScore = 0.5; // Morning
    }

    // Proximity score (0-1)
    // Prefer slots that are spread out from existing options
    final proximityScore = _calculateProximityScore(slot, existingOptions);

    // Duration match score (0-1)
    // Perfect match = 1.0, deviates = lower
    final actualDuration = slot.duration.inMinutes;
    final durationDiff = (actualDuration - preferredDuration).abs();
    final durationScore = 1.0 - (durationDiff / 240).clamp(0.0, 1.0);

    // Weighted combination
    return (availabilityScore * 0.5) +
        (timeOfDayScore * 0.2) +
        (proximityScore * 0.2) +
        (durationScore * 0.1);
  }

  /// Calculate how spread out this slot is from existing options
  double _calculateProximityScore(
    TimeSlotAvailability slot,
    List<ProposalTimeOption> existingOptions,
  ) {
    if (existingOptions.isEmpty) {
      return 1.0; // No existing options, any slot is fine
    }

    // Find minimum distance to any existing option (in hours)
    double minDistanceHours = double.infinity;

    for (final existing in existingOptions) {
      final startDiff =
          slot.startTime.difference(existing.startTime).inHours.abs();
      final endDiff = slot.endTime.difference(existing.endTime).inHours.abs();
      final distance = (startDiff + endDiff) / 2;

      if (distance < minDistanceHours) {
        minDistanceHours = distance.toDouble();
      }
    }

    // Score based on distance (prefer at least 24 hours apart)
    // 0 hours = 0.0, 24+ hours = 1.0
    return (minDistanceHours / 24).clamp(0.0, 1.0);
  }

  /// Check if a slot overlaps with any existing option
  bool _overlapsWithExisting(
    TimeSlotAvailability slot,
    List<ProposalTimeOption> existingOptions,
  ) {
    for (final existing in existingOptions) {
      // Check if the date and time overlap
      if (slot.startTime.isBefore(existing.endTime) &&
          slot.endTime.isAfter(existing.startTime)) {
        return true;
      }
    }
    return false;
  }

  /// Get the starting date for the search
  DateTime _getSearchStartDate(List<ProposalTimeOption> existingOptions) {
    if (existingOptions.isEmpty) {
      // Start from tomorrow
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day + 1);
    }

    // Find the latest existing option and start from there
    DateTime latest = existingOptions.first.startTime;
    for (final option in existingOptions) {
      if (option.startTime.isAfter(latest)) {
        latest = option.startTime;
      }
    }

    // Start from the same day as the latest option
    // (we'll skip overlapping slots in the scoring)
    return DateTime(latest.year, latest.month, latest.day);
  }

  /// Fallback suggestion when no member events are available
  ProposalTimeOption _fallbackSuggestion(
    List<ProposalTimeOption> existingOptions,
    int preferredDuration,
  ) {
    final DateTime startTime;
    final DateTime endTime;

    if (existingOptions.isEmpty) {
      // Default to tomorrow at 7pm
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      startTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 19, 0);
      endTime = startTime.add(Duration(minutes: preferredDuration));
    } else {
      // Add one day to the last option (original behavior)
      final lastOption = existingOptions.last;
      startTime = lastOption.startTime.add(const Duration(days: 1));
      endTime = lastOption.endTime.add(const Duration(days: 1));
    }

    return ProposalTimeOption(
      startTime: startTime,
      endTime: endTime,
    );
  }

  /// Suggest multiple best time options at once
  ///
  /// Useful for initially populating the wizard with smart suggestions.
  /// Returns up to [count] options, sorted by score.
  List<ProposalTimeOption> suggestMultipleOptions({
    required Map<String, List<EventModel>> memberEvents,
    int count = 3,
    int preferredDuration = 120,
    int searchDays = 14,
  }) {
    final suggestions = <ProposalTimeOption>[];

    for (int i = 0; i < count; i++) {
      final suggestion = suggestNextBestOption(
        memberEvents: memberEvents,
        existingOptions: suggestions,
        preferredDuration: preferredDuration,
        searchDays: searchDays,
      );

      if (suggestion != null) {
        suggestions.add(suggestion);
      }
    }

    return suggestions;
  }
}

/// Helper class to hold a slot with its calculated score
class _ScoredSlot {
  final TimeSlotAvailability slot;
  final double score;

  const _ScoredSlot({required this.slot, required this.score});
}

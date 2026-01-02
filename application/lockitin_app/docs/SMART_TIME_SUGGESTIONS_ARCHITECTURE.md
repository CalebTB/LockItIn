# Smart Time Suggestions Architecture Guide

**Last Updated:** January 1, 2026
**Author:** Flutter Architect Agent
**Sprint:** 3 (Proposals & Voting)

## Executive Summary

This document provides the complete architecture for implementing three smart time suggestion features:

1. **Smart "Add Another Option"** - Suggest next best available time slot instead of hardcoded "next day same time"
2. **Multi-select from timeline** - Allow selecting multiple free slots from day view which become proposal time options
3. **Quick event creation** - Create events directly from a time slot without the proposal/voting flow

## Table of Contents

- [1. Current State Analysis](#1-current-state-analysis)
- [2. Feature 1: Smart "Add Another Option"](#2-feature-1-smart-add-another-option)
- [3. Feature 2: Multi-Select from Timeline](#3-feature-2-multi-select-from-timeline)
- [4. Feature 3: Quick Event Creation](#4-feature-3-quick-event-creation)
- [5. Performance Optimization](#5-performance-optimization)
- [6. Implementation Checklist](#6-implementation-checklist)

---

## 1. Current State Analysis

### Existing Infrastructure (Already Built)

✅ **Data Layer:**
- `shadow_calendar` table with RLS policies for group member access
- `get_group_shadow_calendar()` RPC function for efficient queries
- Trigger-based sync from `events` to `shadow_calendar`

✅ **Business Logic Layer:**
- `AvailabilityCalculatorService` with comprehensive methods:
  - `findBestTimeSlots()` - Find time slots sorted by availability
  - `findConsolidatedTimeSlots()` - Merge adjacent hours with same availability
  - `findAvailableWindows()` - Find contiguous free blocks
  - `getHourlyAvailability()` - Hour-by-hour breakdown

✅ **UI Layer:**
- `GroupDayTimelineView` - Shows free slots ("Everyone free" green blocks)
- `GroupProposalWizard` - 3-step wizard for creating proposals
- Timeline visualization with hour-by-hour display (7am-11pm)

### Current Limitations

❌ **Problem 1:** "Add Another Option" uses hardcoded logic:
```dart
// group_proposal_wizard.dart line 1004-1018
void _addTimeOption() {
  final lastOption = _timeOptions.last;
  setState(() {
    _timeOptions.add(ProposalTimeOption(
      startTime: lastOption.startTime.add(const Duration(days: 1)), // Always next day
      endTime: lastOption.endTime.add(const Duration(days: 1)),     // Same time
    ));
  });
}
```

❌ **Problem 2:** Timeline free slots are read-only - can't select multiple

❌ **Problem 3:** No quick event creation path (always requires proposal wizard)

---

## 2. Feature 1: Smart "Add Another Option"

### 2.1 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                  GroupProposalWizard (UI)                        │
│  User taps "Add Another Option"                                 │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│          ProposalTimeOptionSuggestionService (NEW)              │
│  - Analyzes existing time options                               │
│  - Calls AvailabilityCalculatorService to find next best slot   │
│  - Returns suggested ProposalTimeOption                         │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│         AvailabilityCalculatorService (Existing)                │
│  - findConsolidatedTimeSlots() - Get merged free blocks         │
│  - Returns TimeSlotAvailability objects sorted by quality       │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│              GroupProvider (Existing)                           │
│  - memberEvents: Map<String, List<EventModel>>                  │
│  - Shadow calendar data already loaded                          │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 New Service: ProposalTimeOptionSuggestionService

**File:** `/lib/core/services/proposal_time_option_suggestion_service.dart`

**Responsibilities:**
- Analyze existing time options to understand constraints (day range, duration, time of day)
- Find next best available time slot using `AvailabilityCalculatorService`
- Rank suggestions based on:
  1. **Availability count** (most members free)
  2. **Preferred times** (evenings 6pm-9pm > afternoons > mornings)
  3. **Proximity** (next 7 days > next 14 days > next 30 days)
  4. **Duration match** (similar to existing options)

**Key Methods:**

```dart
class ProposalTimeOptionSuggestionService {
  final AvailabilityCalculatorService _availabilityService;

  /// Suggest the next best time option for a proposal
  ///
  /// Algorithm:
  /// 1. Analyze existing options to determine patterns
  ///    - Average duration (e.g., 2 hours)
  ///    - Time of day preference (e.g., evenings)
  ///    - Date range (e.g., within next 2 weeks)
  /// 2. Search upcoming dates for free slots
  /// 3. Filter by minimum availability threshold (e.g., 80% of members)
  /// 4. Rank by scoring algorithm
  /// 5. Return top suggestion
  ProposalTimeOption? suggestNextTimeOption({
    required List<ProposalTimeOption> existingOptions,
    required Map<String, List<EventModel>> memberEvents,
    required int totalMembers,
  });

  /// Find multiple time option suggestions for a date range
  ///
  /// Used for "Find Best Times" feature (future)
  List<ProposalTimeOption> findBestTimeOptions({
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, List<EventModel>> memberEvents,
    required int totalMembers,
    required Duration preferredDuration,
    int maxOptions = 5,
  });

  /// Score a time slot based on multiple factors
  ///
  /// Returns 0.0-1.0 score, where 1.0 is perfect
  double _scoreTimeSlot(
    TimeSlotAvailability slot,
    int totalMembers,
    DateTime referenceDate,
  );

  /// Determine preferred time of day from existing options
  _TimeOfDayPreference _analyzeTimePreferences(
    List<ProposalTimeOption> options,
  );
}

enum _TimeOfDayPreference {
  morning,    // 7am-12pm
  afternoon,  // 12pm-6pm
  evening,    // 6pm-11pm
  mixed,      // No clear pattern
}
```

### 2.3 Scoring Algorithm Details

**Availability Score (Weight: 50%)**
```dart
double availabilityScore = slot.availableCount / totalMembers;
// Example: 7/8 members free = 0.875
```

**Time of Day Score (Weight: 20%)**
```dart
double timeOfDayScore = _getTimeOfDayScore(slot.startTime, preference);
// Evening preference:
//   6pm-9pm: 1.0
//   9pm-11pm: 0.8
//   12pm-6pm: 0.6
//   7am-12pm: 0.4
```

**Proximity Score (Weight: 20%)**
```dart
int daysOut = slot.startTime.difference(referenceDate).inDays;
double proximityScore = 1.0 - (daysOut / 30.0).clamp(0.0, 1.0);
// Tomorrow: 1.0 - (1/30) = 0.97
// 1 week: 1.0 - (7/30) = 0.77
// 2 weeks: 1.0 - (14/30) = 0.53
```

**Duration Match Score (Weight: 10%)**
```dart
Duration avgDuration = _averageDuration(existingOptions);
double durationDiff = (slot.duration.inMinutes - avgDuration.inMinutes).abs();
double durationScore = 1.0 - (durationDiff / 120.0).clamp(0.0, 1.0);
// Exact match: 1.0
// 1 hour off: 0.5
// 2+ hours off: 0.0
```

**Final Score:**
```dart
double finalScore = (availabilityScore * 0.5) +
                    (timeOfDayScore * 0.2) +
                    (proximityScore * 0.2) +
                    (durationScore * 0.1);
```

### 2.4 Integration with GroupProposalWizard

**Changes to `/lib/presentation/screens/group_proposal_wizard.dart`:**

```dart
class _GroupProposalWizardState extends State<GroupProposalWizard> {
  // Add suggestion service
  final _suggestionService = ProposalTimeOptionSuggestionService(
    AvailabilityCalculatorService(),
  );

  // Add loading state for suggestions
  bool _isLoadingSuggestion = false;

  /// Add a new time option (with smart suggestion)
  Future<void> _addTimeOption() async {
    setState(() => _isLoadingSuggestion = true);

    try {
      // Get member events from GroupProvider
      final provider = context.read<GroupProvider>();
      final memberEvents = provider.selectedGroupMemberEvents;
      final totalMembers = provider.selectedGroupMembers.length;

      // Get suggestion
      final suggestion = _suggestionService.suggestNextTimeOption(
        existingOptions: _timeOptions,
        memberEvents: memberEvents,
        totalMembers: totalMembers,
      );

      setState(() {
        _isLoadingSuggestion = false;
        if (suggestion != null) {
          _timeOptions.add(suggestion);
        } else {
          // Fallback to old behavior
          final lastOption = _timeOptions.last;
          _timeOptions.add(ProposalTimeOption(
            startTime: lastOption.startTime.add(const Duration(days: 1)),
            endTime: lastOption.endTime.add(const Duration(days: 1)),
          ));
        }
      });
    } catch (e) {
      // Error handling - fallback to old behavior
      Logger.error('GroupProposalWizard', 'Failed to get suggestion: $e');
      setState(() {
        _isLoadingSuggestion = false;
        final lastOption = _timeOptions.last;
        _timeOptions.add(ProposalTimeOption(
          startTime: lastOption.startTime.add(const Duration(days: 1)),
          endTime: lastOption.endTime.add(const Duration(days: 1)),
        ));
      });
    }
  }

  // Update "Add Another Option" button to show loading state
  Widget _buildAddOptionButton() {
    return OutlinedButton.icon(
      onPressed: _isLoadingSuggestion ? null : _addTimeOption,
      icon: _isLoadingSuggestion
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.auto_awesome, size: 20), // Magic wand icon
      label: Text(_isLoadingSuggestion ? 'Finding best time...' : 'Add Another Option'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        side: BorderSide(color: colorScheme.primary),
      ),
    );
  }
}
```

### 2.5 Client-Side vs Server-Side Decision

**Recommendation: CLIENT-SIDE CALCULATION**

**Why Client-Side:**
- ✅ Member events already loaded in `GroupProvider` (cached in memory)
- ✅ `AvailabilityCalculatorService` is highly optimized for this
- ✅ No network latency - instant suggestions
- ✅ Works offline if member events cached
- ✅ Reduces server load

**Why NOT Server-Side:**
- ❌ Requires new Supabase RPC function
- ❌ Network round-trip adds 200-500ms latency
- ❌ Shadow calendar data already on client
- ❌ Adds complexity without clear benefit

**Exception:** For "Find Best Times" feature across 30+ days, consider server-side with caching.

---

## 3. Feature 2: Multi-Select from Timeline

### 3.1 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│           GroupDayTimelineView (UI - Modified)                   │
│  User taps free slot → Toggle selection (visual highlight)      │
│  User taps "Create Proposal with N Slots" FAB                   │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼ Navigator.push(selectedSlots)
┌─────────────────────────────────────────────────────────────────┐
│          GroupProposalWizard (Modified)                         │
│  - Skip Step 2 (Time Options) if pre-filled                     │
│  - Show "N time options selected" summary                       │
│  - Allow editing/removing options                               │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 State Management for Multi-Select

**Option A: Local Widget State (Recommended)**

Simple, self-contained, no provider pollution.

```dart
class _GroupDayTimelineViewState extends State<GroupDayTimelineView> {
  // Multi-select state
  bool _isMultiSelectMode = false;
  Set<_TimeSlot> _selectedSlots = {};

  void _toggleSlotSelection(_TimeSlot slot) {
    setState(() {
      if (_selectedSlots.contains(slot)) {
        _selectedSlots.remove(slot);
        // Exit multi-select if no selections
        if (_selectedSlots.isEmpty) {
          _isMultiSelectMode = false;
        }
      } else {
        _selectedSlots.add(slot);
        _isMultiSelectMode = true; // Enter multi-select mode
      }
    });
  }

  void _createProposalWithSelectedSlots() {
    if (_selectedSlots.isEmpty) return;

    // Convert selected slots to ProposalTimeOptions
    final timeOptions = _selectedSlots.map((slot) {
      final date = widget.selectedDate;
      final startTime = DateTime(
        date.year, date.month, date.day,
        slot.startHour.toInt(),
        ((slot.startHour % 1) * 60).toInt(),
      );
      final endTime = DateTime(
        date.year, date.month, date.day,
        slot.endHour.toInt(),
        ((slot.endHour % 1) * 60).toInt(),
      );
      return ProposalTimeOption(
        startTime: startTime,
        endTime: endTime,
      );
    }).toList();

    // Navigate to proposal wizard with pre-filled options
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupProposalWizard(
          groupId: widget.groupId,
          groupName: widget.groupName,
          groupMemberCount: _getMemberCount(),
          prefilledTimeOptions: timeOptions, // NEW parameter
        ),
      ),
    ).then((_) {
      // Clear selection after returning
      setState(() {
        _selectedSlots.clear();
        _isMultiSelectMode = false;
      });
    });
  }
}
```

**Option B: CalendarProvider (NOT Recommended)**

Adds unnecessary complexity to provider for UI-only state.

### 3.3 UI Changes to GroupDayTimelineView

**3.3.1 Update Free Slot Rendering**

```dart
Widget _buildFreeSlot(_TimeSlot slot, ColorScheme colorScheme, AppColorsExtension appColors) {
  final top = (slot.startHour - _startHour) * _hourHeight + 2;
  final height = (slot.endHour - slot.startHour) * _hourHeight - 4;
  if (height < 30) return const SizedBox.shrink();

  final isSelected = _selectedSlots.contains(slot);
  final startStr = _formatHourShort(slot.startHour);
  final endStr = _formatHourShort(slot.endHour);

  return Positioned(
    top: top,
    left: 52,
    right: 8,
    height: height,
    child: GestureDetector(
      // Long press to enter multi-select mode
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _toggleSlotSelection(slot);
      },
      // Tap behavior depends on mode
      onTap: () {
        if (_isMultiSelectMode) {
          // In multi-select mode: toggle selection
          HapticFeedback.selectionClick();
          _toggleSlotSelection(slot);
        } else {
          // In normal mode: show propose event sheet
          _showProposeEventSheet(slot);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.15) // Highlight selected
              : AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : AppColors.success.withValues(alpha: 0.4),
            width: isSelected ? 3 : 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Stack(
          children: [
            // Existing content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : Icons.auto_awesome,
                        size: 14,
                        color: isSelected ? colorScheme.primary : AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSelected ? 'Selected' : 'Everyone free',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? colorScheme.primary : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$startStr - $endStr',
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.8)
                          : AppColors.success.withValues(alpha: 0.8),
                    ),
                  ),
                  if (height > 70 && !isSelected)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Tap to propose',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.success.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Selection badge (top-right corner)
            if (isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 12,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
```

**3.3.2 Add Floating Action Button for Multi-Select**

```dart
Widget build(BuildContext context) {
  return Stack(
    children: [
      // Existing timeline UI
      Column(
        children: [
          _buildDateNavigationBar(colorScheme, appColors),
          _buildToggleRow(colorScheme, appColors),
          Expanded(child: _buildTimeline(colorScheme, appColors)),
        ],
      ),

      // Multi-select FAB
      if (_isMultiSelectMode && _selectedSlots.isNotEmpty)
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: _createProposalWithSelectedSlots,
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            icon: const Icon(Icons.add_task),
            label: Text('Create Proposal (${_selectedSlots.length})'),
          ),
        ),

      // Cancel multi-select button
      if (_isMultiSelectMode)
        Positioned(
          bottom: 16,
          left: 16,
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                _selectedSlots.clear();
                _isMultiSelectMode = false;
              });
            },
            backgroundColor: colorScheme.surfaceContainerHigh,
            foregroundColor: colorScheme.onSurface,
            mini: true,
            child: const Icon(Icons.close),
          ),
        ),
    ],
  );
}
```

### 3.4 Update GroupProposalWizard to Support Pre-filled Options

```dart
class GroupProposalWizard extends StatefulWidget {
  final String groupId;
  final String groupName;
  final int groupMemberCount;
  final DateTime? initialDate;
  final DateTime? initialStartTime;
  final DateTime? initialEndTime;
  final List<ProposalTimeOption>? prefilledTimeOptions; // NEW

  const GroupProposalWizard({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groupMemberCount,
    this.initialDate,
    this.initialStartTime,
    this.initialEndTime,
    this.prefilledTimeOptions, // NEW
  });
}

class _GroupProposalWizardState extends State<GroupProposalWizard> {
  @override
  void initState() {
    super.initState();

    // Initialize time options
    if (widget.prefilledTimeOptions != null && widget.prefilledTimeOptions!.isNotEmpty) {
      // Use pre-filled options from timeline multi-select
      _timeOptions = widget.prefilledTimeOptions!;
    } else if (widget.initialStartTime != null && widget.initialEndTime != null) {
      // Single slot from timeline tap
      _timeOptions = [
        ProposalTimeOption(
          startTime: widget.initialStartTime!,
          endTime: widget.initialEndTime!,
        ),
      ];
    } else {
      // Default behavior
      final initialDate = widget.initialDate ?? DateTime.now().add(const Duration(days: 1));
      final startTime = DateTime(initialDate.year, initialDate.month, initialDate.day, 19, 0);
      final endTime = DateTime(initialDate.year, initialDate.month, initialDate.day, 21, 0);
      _timeOptions = [
        ProposalTimeOption(startTime: startTime, endTime: endTime),
      ];
    }
  }
}
```

### 3.5 Accessibility Considerations

**Voiceover/TalkBack Announcements:**
```dart
Semantics(
  button: true,
  label: isSelected
      ? 'Selected time slot from $startStr to $endStr. Tap to deselect.'
      : 'Everyone free from $startStr to $endStr. Long press to select for proposal.',
  onLongPress: () => _toggleSlotSelection(slot),
  onTap: () {
    if (_isMultiSelectMode) {
      _toggleSlotSelection(slot);
    } else {
      _showProposeEventSheet(slot);
    }
  },
  child: /* Container */,
)
```

**Multi-select mode announcement:**
```dart
void _toggleSlotSelection(_TimeSlot slot) {
  setState(() {
    if (_selectedSlots.contains(slot)) {
      _selectedSlots.remove(slot);
      if (_selectedSlots.isEmpty) {
        _isMultiSelectMode = false;
        // Announce exit from multi-select
        SemanticsService.announce(
          'Multi-select mode disabled',
          TextDirection.ltr,
        );
      }
    } else {
      _selectedSlots.add(slot);
      if (!_isMultiSelectMode) {
        _isMultiSelectMode = true;
        // Announce entry to multi-select
        SemanticsService.announce(
          'Multi-select mode enabled. ${_selectedSlots.length} slot selected.',
          TextDirection.ltr,
        );
      }
    }
  });
}
```

---

## 4. Feature 3: Quick Event Creation

### 4.1 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│           GroupDayTimelineView (Modified)                        │
│  User taps free slot → Bottom sheet with 2 options:             │
│    1. "Create Event Proposal" (existing behavior)               │
│    2. "Create Direct Event" (NEW - skip voting)                 │
└────────────────────┬────────────────────────────────────────────┘
                     │ Option 1               │ Option 2
                     ▼                        ▼
        ┌────────────────────────┐  ┌─────────────────────────────┐
        │  GroupProposalWizard   │  │  QuickEventCreationSheet    │
        │  (existing)            │  │  (NEW - simple form)        │
        └────────────────────────┘  └────────┬────────────────────┘
                                             │
                                             ▼
                                    ┌─────────────────────────────┐
                                    │   EventService              │
                                    │   .createEvent()            │
                                    │   - Creates event in events │
                                    │   - Auto-syncs to shadow    │
                                    │   - Sends notifications     │
                                    └─────────────────────────────┘
```

### 4.2 Update Bottom Sheet in GroupDayTimelineView

**Replace `_showProposeEventSheet()` method:**

```dart
void _showProposeEventSheet(_TimeSlot slot) {
  final colorScheme = Theme.of(context).colorScheme;
  final appColors = context.appColors;
  final provider = context.read<GroupProvider>();
  final members = provider.selectedGroupMembers;

  HapticFeedback.mediumImpact();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Text(
              'Everyone's Available!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All ${members.length} members are free ${_formatHour(slot.startHour.toInt())} – ${_formatHour(slot.endHour.toInt())}',
              style: TextStyle(
                fontSize: 14,
                color: appColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),

            // Option 1: Create Proposal (existing)
            _buildSheetOption(
              context: context,
              icon: Icons.how_to_vote,
              iconColor: colorScheme.primary,
              title: 'Create Event Proposal',
              subtitle: 'Group votes on this time + other options',
              onTap: () {
                Navigator.pop(context);
                _navigateToProposalWizard(slot);
              },
            ),

            const SizedBox(height: 12),

            // Option 2: Quick Event Creation (NEW)
            _buildSheetOption(
              context: context,
              icon: Icons.event_available,
              iconColor: AppColors.success,
              title: 'Create Event Now',
              subtitle: 'Skip voting, create event immediately',
              onTap: () {
                Navigator.pop(context);
                _showQuickEventCreationSheet(slot);
              },
            ),

            const SizedBox(height: 12),

            // Cancel
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildSheetOption({
  required BuildContext context,
  required IconData icon,
  required Color iconColor,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final appColors = context.appColors;

  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: appColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: appColors.textMuted),
        ],
      ),
    ),
  );
}
```

### 4.3 New Widget: QuickEventCreationSheet

**File:** `/lib/presentation/widgets/quick_event_creation_sheet.dart`

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/services/event_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/logger.dart';
import '../providers/calendar_provider.dart';
import '../providers/group_provider.dart';

/// Quick event creation sheet for creating events without voting
///
/// Minimal form: Title + optional description
/// Time slot is pre-filled from the timeline selection
/// Event is created directly (no proposal/voting)
class QuickEventCreationSheet extends StatefulWidget {
  final String groupId;
  final String groupName;
  final DateTime startTime;
  final DateTime endTime;

  const QuickEventCreationSheet({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.startTime,
    required this.endTime,
  });

  @override
  State<QuickEventCreationSheet> createState() => _QuickEventCreationSheetState();
}

class _QuickEventCreationSheetState extends State<QuickEventCreationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Text(
                'Create Event for ${widget.groupName}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, MMM d • h:mm a').format(widget.startTime) +
                    ' - ' +
                    DateFormat('h:mm a').format(widget.endTime),
                style: TextStyle(
                  fontSize: 14,
                  color: appColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),

              // Title field
              TextFormField(
                controller: _titleController,
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Event Title',
                  hintText: 'What are you planning?',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description field (optional)
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Add details',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Info box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Event will be created for all group members',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isCreating ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _createEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        minimumSize: const Size(0, 48),
                      ),
                      child: _isCreating
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : const Text('Create Event'),
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

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      // Get group members
      final groupProvider = context.read<GroupProvider>();
      final members = groupProvider.selectedGroupMembers;

      // Create event via EventService
      await EventService.instance.createEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        startTime: widget.startTime,
        endTime: widget.endTime,
        visibility: EventVisibility.sharedWithName, // Shared with group
        category: EventCategory.friend,
        // Note: Current EventService doesn't have groupId parameter
        // This may need to be added, or handle via group_events table
      );

      if (!mounted) return;

      // Refresh calendar
      context.read<CalendarProvider>().refreshEvents();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Event created for ${widget.groupName}!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Close sheet
      Navigator.pop(context);
    } catch (e) {
      Logger.error('QuickEventCreationSheet', 'Failed to create event: $e');

      if (!mounted) return;

      setState(() => _isCreating = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create event: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
```

### 4.4 Database Implications

**Current Architecture:**
- `events` table: Personal events (user's own calendar)
- `event_proposals` table: Group proposals with voting
- `shadow_calendar` table: Synced availability from events

**Question:** How to associate a "quick event" with a group?

**Option A: Use existing `events` table + new `group_events` junction table**

```sql
-- New table to link events to groups
CREATE TABLE group_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),

  UNIQUE(event_id, group_id)
);

-- RLS: Group members can see group events
CREATE POLICY "Group members can view group events"
ON group_events FOR SELECT TO authenticated
USING (auth_is_group_member(group_id, auth.uid()));
```

**Workflow:**
1. Create event in `events` table (visibility = sharedWithName)
2. Insert record in `group_events` table
3. Send notification to group members
4. Event syncs to `shadow_calendar` automatically (trigger)

**Option B: Add `group_id` column to `events` table (NOT recommended)**

Mixes personal and group events in same table, complicates queries.

**Recommendation: Option A** (junction table pattern)

### 4.5 Update EventService for Group Events

**Add method to `/lib/core/services/event_service.dart`:**

```dart
/// Create an event associated with a group
///
/// This creates a "quick event" without the proposal/voting flow.
/// The event is added to the group and all members are notified.
Future<String> createGroupEvent({
  required String groupId,
  required String title,
  String? description,
  String? location,
  required DateTime startTime,
  required DateTime endTime,
  EventCategory category = EventCategory.friend,
}) async {
  try {
    Logger.info('EventService', 'Creating group event for group: $groupId');

    // 1. Create the event
    final eventId = await createEvent(
      title: title,
      description: description,
      location: location,
      startTime: startTime,
      endTime: endTime,
      visibility: EventVisibility.sharedWithName, // Always shared for group events
      category: category,
    );

    // 2. Link event to group
    await _supabase.from('group_events').insert({
      'event_id': eventId,
      'group_id': groupId,
    });

    // 3. Send notifications to group members
    // TODO: Implement notification service call
    // await NotificationService.instance.notifyGroupOfNewEvent(groupId, eventId);

    Logger.info('EventService', 'Group event created: $eventId');
    return eventId;
  } catch (e) {
    Logger.error('EventService', 'Failed to create group event: $e');
    rethrow;
  }
}
```

### 4.6 Migration Required

**Create new migration: `supabase/migrations/013_add_group_events_table.sql`**

```sql
-- Add group_events table for linking events to groups
-- This enables "quick event creation" where events are created directly
-- for a group without the proposal/voting flow

CREATE TABLE IF NOT EXISTS group_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Event reference
  event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,

  -- Group reference
  group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),

  -- Constraints
  UNIQUE(event_id, group_id)
);

-- Indexes
CREATE INDEX idx_group_events_event_id ON group_events(event_id);
CREATE INDEX idx_group_events_group_id ON group_events(group_id);

-- RLS
ALTER TABLE group_events ENABLE ROW LEVEL SECURITY;

-- Group members can view group events
CREATE POLICY "Group members can view group events"
ON group_events FOR SELECT TO authenticated
USING (auth_is_group_member(group_id, auth.uid()));

-- Only event creator can link their event to a group
CREATE POLICY "Event creators can link events to groups"
ON group_events FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM events
    WHERE events.id = event_id
    AND events.user_id = auth.uid()
  )
  AND auth_is_group_member(group_id, auth.uid())
);

-- Only event creator can unlink
CREATE POLICY "Event creators can unlink events from groups"
ON group_events FOR DELETE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM events
    WHERE events.id = event_id
    AND events.user_id = auth.uid()
  )
);
```

---

## 5. Performance Optimization

### 5.1 Caching Strategy

**Problem:** Calculating best time slots across 30 days can be expensive.

**Solution:** Multi-level caching

```dart
class ProposalTimeOptionSuggestionService {
  // In-memory cache: groupId -> date range -> suggestions
  final Map<String, Map<String, List<ProposalTimeOption>>> _cache = {};
  final Duration _cacheExpiration = const Duration(minutes: 5);
  final Map<String, DateTime> _cacheTimestamps = {};

  ProposalTimeOption? suggestNextTimeOption({
    required List<ProposalTimeOption> existingOptions,
    required Map<String, List<EventModel>> memberEvents,
    required int totalMembers,
    String? groupId, // For caching
  }) {
    // Check cache if groupId provided
    if (groupId != null) {
      final cacheKey = _generateCacheKey(existingOptions);
      final cached = _getCached(groupId, cacheKey);
      if (cached != null) {
        Logger.info('SuggestionService', 'Cache hit for group: $groupId');
        return cached.first;
      }
    }

    // Calculate suggestions
    final suggestions = _findSuggestions(
      existingOptions: existingOptions,
      memberEvents: memberEvents,
      totalMembers: totalMembers,
    );

    // Store in cache
    if (groupId != null && suggestions.isNotEmpty) {
      final cacheKey = _generateCacheKey(existingOptions);
      _setCached(groupId, cacheKey, suggestions);
    }

    return suggestions.isNotEmpty ? suggestions.first : null;
  }

  String _generateCacheKey(List<ProposalTimeOption> options) {
    // Hash based on date range and duration
    if (options.isEmpty) return 'empty';
    final firstDate = options.first.startTime;
    final lastDate = options.last.startTime;
    final avgDuration = _averageDuration(options);
    return '${firstDate.day}_${lastDate.day}_${avgDuration.inMinutes}';
  }

  List<ProposalTimeOption>? _getCached(String groupId, String key) {
    final timestamp = _cacheTimestamps['$groupId:$key'];
    if (timestamp == null) return null;

    // Check expiration
    if (DateTime.now().difference(timestamp) > _cacheExpiration) {
      _cache[groupId]?.remove(key);
      _cacheTimestamps.remove('$groupId:$key');
      return null;
    }

    return _cache[groupId]?[key];
  }

  void _setCached(String groupId, String key, List<ProposalTimeOption> suggestions) {
    _cache.putIfAbsent(groupId, () => {});
    _cache[groupId]![key] = suggestions;
    _cacheTimestamps['$groupId:$key'] = DateTime.now();
  }

  /// Clear cache for a group (call when member events change)
  void clearCache(String groupId) {
    _cache.remove(groupId);
    _cacheTimestamps.removeWhere((key, _) => key.startsWith('$groupId:'));
  }
}
```

### 5.2 Incremental Search Window

**Problem:** Searching 30 days ahead is slow.

**Solution:** Incremental search with early exit.

```dart
List<ProposalTimeOption> _findSuggestions({
  required List<ProposalTimeOption> existingOptions,
  required Map<String, List<EventModel>> memberEvents,
  required int totalMembers,
}) {
  // Start with small search window, expand if needed
  const searchWindows = [7, 14, 30]; // days
  final minAvailability = (totalMembers * 0.8).ceil(); // 80% threshold

  for (final windowDays in searchWindows) {
    final startDate = DateTime.now();
    final endDate = startDate.add(Duration(days: windowDays));

    final suggestions = _searchDateRange(
      startDate: startDate,
      endDate: endDate,
      memberEvents: memberEvents,
      totalMembers: totalMembers,
      minAvailability: minAvailability,
      maxResults: 5,
    );

    // If we found enough good suggestions, return early
    if (suggestions.length >= 3) {
      Logger.info('SuggestionService', 'Found ${suggestions.length} suggestions in $windowDays days');
      return suggestions;
    }
  }

  // Fallback: return whatever we found
  return [];
}
```

### 5.3 Background Computation (Advanced)

**For future optimization:** Use Dart isolates for heavy computation.

```dart
import 'dart:isolate';

Future<List<ProposalTimeOption>> _findSuggestionsInIsolate({
  required List<ProposalTimeOption> existingOptions,
  required Map<String, List<EventModel>> memberEvents,
  required int totalMembers,
}) async {
  // Spawn isolate for computation
  final receivePort = ReceivePort();

  await Isolate.spawn(
    _isolateComputeSuggestions,
    _IsolateParams(
      sendPort: receivePort.sendPort,
      existingOptions: existingOptions,
      memberEvents: memberEvents,
      totalMembers: totalMembers,
    ),
  );

  // Wait for result
  final result = await receivePort.first as List<ProposalTimeOption>;
  return result;
}

// Top-level function for isolate
void _isolateComputeSuggestions(_IsolateParams params) {
  // Perform heavy computation
  final suggestions = /* calculation logic */;
  params.sendPort.send(suggestions);
}
```

**Note:** Only use isolates if profiling shows UI jank (>16ms frame time).

---

## 6. Implementation Checklist

### Phase 1: Smart "Add Another Option" (Easiest - 1 day)

- [ ] Create `ProposalTimeOptionSuggestionService` class
  - [ ] Implement `suggestNextTimeOption()` method
  - [ ] Implement scoring algorithm (availability, time of day, proximity, duration)
  - [ ] Add in-memory caching
- [ ] Update `GroupProposalWizard`
  - [ ] Add `_isLoadingSuggestion` state
  - [ ] Update `_addTimeOption()` to call suggestion service
  - [ ] Update button UI to show loading state + magic wand icon
- [ ] Add unit tests for scoring algorithm
- [ ] Manual testing with real group data

### Phase 2: Multi-Select from Timeline (Medium - 2 days)

- [ ] Update `GroupDayTimelineView`
  - [ ] Add `_isMultiSelectMode` and `_selectedSlots` state
  - [ ] Update `_buildFreeSlot()` to support selection highlighting
  - [ ] Add long-press gesture to enter multi-select mode
  - [ ] Add FAB for "Create Proposal (N)" button
  - [ ] Add cancel button to exit multi-select
  - [ ] Add semantic labels for accessibility
- [ ] Update `GroupProposalWizard`
  - [ ] Add `prefilledTimeOptions` parameter
  - [ ] Update `initState()` to use pre-filled options
  - [ ] Show summary of pre-filled options in Step 2
- [ ] Test on both iOS and Android (gesture differences)
- [ ] Test with VoiceOver/TalkBack

### Phase 3: Quick Event Creation (Complex - 3 days)

- [ ] **Database Migration**
  - [ ] Create `supabase/migrations/013_add_group_events_table.sql`
  - [ ] Apply migration to Supabase project
  - [ ] Test RLS policies with group members
- [ ] **Backend Service**
  - [ ] Add `createGroupEvent()` method to `EventService`
  - [ ] Test event creation + group_events insert
- [ ] **UI Implementation**
  - [ ] Create `QuickEventCreationSheet` widget
  - [ ] Update `_showProposeEventSheet()` in `GroupDayTimelineView`
  - [ ] Add two-option bottom sheet (Proposal vs Quick Event)
- [ ] **Integration**
  - [ ] Wire up quick event creation flow
  - [ ] Test event appears in group timeline
  - [ ] Test shadow calendar sync
  - [ ] Verify notifications sent to group members
- [ ] **Edge Cases**
  - [ ] Test with group member who has conflicting event
  - [ ] Test with large groups (10+ members)
  - [ ] Test offline behavior

### Phase 4: Performance & Polish (1 day)

- [ ] Profile timeline view with Flutter DevTools
- [ ] Add caching to suggestion service
- [ ] Implement incremental search window
- [ ] Add loading states and error handling
- [ ] Test with 30-day search window
- [ ] Test with large groups (20+ members)

### Phase 5: Documentation & Testing (1 day)

- [ ] Update `TESTING_GUIDE.md` with new features
- [ ] Add widget tests for multi-select behavior
- [ ] Add integration tests for suggestion service
- [ ] Update user documentation
- [ ] Create demo video for beta testers

---

## Estimated Timeline

**Total: 8 days** (1.6 weeks)

| Phase | Days | Deliverable |
|-------|------|-------------|
| Phase 1 | 1 | Smart "Add Another Option" working |
| Phase 2 | 2 | Multi-select timeline working |
| Phase 3 | 3 | Quick event creation working |
| Phase 4 | 1 | Performance optimized |
| Phase 5 | 1 | Fully tested & documented |

**Priority Order (if time-constrained):**
1. **Must-Have:** Smart "Add Another Option" (biggest UX win)
2. **Should-Have:** Multi-select from timeline (power user feature)
3. **Nice-to-Have:** Quick event creation (can defer to post-MVP)

---

## Risk Mitigation

### Risk 1: Suggestion algorithm produces poor results

**Mitigation:**
- Implement fallback to "next day same time" if no good suggestion found
- Add logging to track suggestion quality
- A/B test with beta users (smart vs. hardcoded)

### Risk 2: Multi-select UX is confusing

**Mitigation:**
- Add onboarding tooltip on first use
- Show clear visual feedback (checkmarks, color changes)
- Provide "Cancel" button to exit mode easily

### Risk 3: Quick event creation disrupts group flow

**Mitigation:**
- Require confirmation ("Create event for all members?")
- Send notification to group about new event
- Allow members to decline/remove event from their calendar

### Risk 4: Performance degrades with large groups

**Mitigation:**
- Implement caching (done in Phase 4)
- Limit search window to 7 days initially
- Use Flutter DevTools to profile and optimize
- Consider Dart isolates if UI jank detected

---

## Future Enhancements (Post-MVP)

1. **"Find Best Times" button** - Automatically suggest top 5 time slots across next 2 weeks
2. **Smart duration detection** - Suggest different durations (1hr, 2hr, 4hr) based on event type
3. **Recurring event suggestions** - "Every Tuesday at 7pm for next 4 weeks"
4. **Location-aware suggestions** - Factor in travel time from previous events
5. **Weather integration** - Avoid suggesting outdoor events on rainy days
6. **Historical analysis** - Learn which times this group prefers over time

---

## Questions for Product Owner

1. **Quick Event Creation:** Should quick events require confirmation from all members, or is it organizer's discretion?
2. **Multi-Select:** Max number of slots selectable at once? (Suggest: 5)
3. **Availability Threshold:** What % of members must be free for a "good" suggestion? (Suggest: 80%)
4. **Search Window:** How far ahead should we search for suggestions? (Suggest: 7 days default, expand to 14/30 if needed)
5. **Notifications:** Should group members be notified when a quick event is created? (Suggest: Yes)

---

## Conclusion

This architecture provides a complete blueprint for implementing smart time suggestions in the LockItIn app. The design prioritizes:

- **Developer Experience:** Clear separation of concerns, reusable services, clean architecture
- **User Experience:** Instant suggestions, intuitive multi-select, minimal friction
- **Performance:** Client-side calculation, caching, incremental search
- **Maintainability:** Well-documented, testable, extensible for future features

The phased implementation plan allows for incremental delivery, with Phase 1 (Smart "Add Another Option") delivering immediate value in just 1 day of work.

**Next Steps:**
1. Review this architecture with the team
2. Create GitHub issues for each phase
3. Start with Phase 1 implementation
4. Gather beta tester feedback after Phase 1 before proceeding to Phase 2/3

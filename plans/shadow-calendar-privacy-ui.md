# Shadow Calendar Privacy UI - Implementation Plan

**Issue:** #138
**Version:** v0.2.5
**Priority:** Critical
**Estimated Effort:** 8-12 hours
**Plan Date:** January 7, 2026

---

## Overview

Complete the Shadow Calendar Privacy UI by adding frontend controls for the existing privacy backend. This is the **core differentiator** feature ("Lock in plans, not details") that enables users to share availability without revealing event details.

**What exists:**
- ✅ Backend: `sync_event_to_shadow_calendar()` trigger function
- ✅ Backend: `get_group_shadow_calendar()` RPC function with optimized RLS
- ✅ Model: `EventVisibility` enum (private, sharedWithName, busyOnly)
- ✅ Basic privacy UI in event creation screen

**What's missing:**
- ❌ Inconsistent privacy indicators across calendar views
- ❌ Per-group privacy settings UI
- ❌ Privacy change warnings and confirmations
- ❌ Accessibility (VoiceOver labels, colorblind toggle)
- ❌ User education (tooltips, inline help)

---

## Problem Statement

### Current State

**Event Creation Screen** (`event_creation_screen.dart:270-357`):
- Has radio-style privacy cards with icon, title, description, example ✅
- Defaults to `sharedWithName` ✅
- Shows live example preview ✅
- Marks "Shared with Details" as RECOMMENDED ✅

**Privacy Indicators:**
- `AgendaEventCard` has privacy badge (icon + label) ✅
- `UpcomingEventCard` does NOT have privacy badge ❌
- Month calendar grid has no privacy indicators ❌
- Inconsistent across views

**Backend:**
- Shadow calendar sync works perfectly ✅
- RLS policies enforce privacy at DB level ✅
- Integration tests pass ✅

**Critical Gaps:**
1. **No per-group privacy settings** - Documentation promises this, but no UI exists
2. **No accessibility** - VoiceOver labels missing, colorblind palette not exposed
3. **No user education** - First-time users won't understand privacy system
4. **No warnings** - User can change Shared → Private without confirmation
5. **No template protection** - Surprise Party can be accidentally exposed

### Why This Matters

**From Product Vision:**
> "Lock in plans, not details" - Shadow Calendar is THE unique selling point

**From Privacy Documentation:**
> "Privacy is enforced at the database level through a dual-table architecture"

**User Impact:**
- **Without privacy indicators:** Users don't know what groups can see
- **Without per-group settings:** Can't have different privacy per group (work vs friends)
- **Without warnings:** Accidental privacy leaks (expose surprise party)
- **Without accessibility:** VoiceOver users can't use privacy controls

---

## Proposed Solution

### High-Level Approach

**Phase 1: Fix Inconsistencies (2-3 hours)**
1. Add privacy badge to `UpcomingEventCard`
2. Add privacy colors to month calendar grid
3. Ensure consistent icons/colors across all views
4. Add VoiceOver labels to all privacy options

**Phase 2: Add Per-Group Privacy Settings (3-4 hours)**
1. Extend `GroupSettingsSheet` with privacy section
2. Add default visibility dropdown per group
3. Store per-group defaults in local storage (Shared Preferences)
4. Apply per-group default when creating events

**Phase 3: Add Warnings & Confirmations (2-3 hours)**
1. Confirmation dialog when changing Shared → Private
2. Warning when overriding template privacy (Surprise Party)
3. Warning when privacy change affects active proposals
4. Feedback animations after privacy change

**Phase 4: Accessibility & Polish (1-2 hours)**
1. Add colorblind palette toggle to Settings
2. Add first-time user tooltip on Privacy field
3. Add info icon with inline help sheet
4. Test with VoiceOver and TalkBack

---

## Technical Approach

### Architecture

```
┌─────────────────────────────────────────────┐
│  Event Creation Screen                      │
│  - Radio-style privacy cards (EXISTS ✅)    │
│  - Per-group default applied (NEW)          │
│  - Info icon → help sheet (NEW)             │
│  - First-time tooltip (NEW)                 │
└─────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────┐
│  Privacy Change Handler                     │
│  - Validate: Template override? (NEW)       │
│  - Validate: Affects proposal? (NEW)        │
│  - Show confirmation if Shared→Private (NEW)│
│  - Update event.visibility                  │
└─────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────┐
│  EventService.updateEvent()                 │
│  - Calls Supabase update                    │
│  - Trigger: sync_event_to_shadow_calendar() │
│  - Shadow calendar updates automatically ✅  │
└─────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────┐
│  Calendar Views Update                      │
│  - AgendaEventCard shows badge ✅           │
│  - UpcomingEventCard shows badge (NEW)      │
│  - Month grid shows colored dot (NEW)       │
└─────────────────────────────────────────────┘
```

### Data Flow

**Per-Group Privacy Defaults:**
```dart
// Storage: SharedPreferences
{
  "group_123_default_visibility": "busyOnly",
  "group_456_default_visibility": "sharedWithName"
}

// Usage in EventCreationScreen
@override
void initState() {
  super.initState();
  _visibility = _getDefaultVisibilityForGroup() ?? EventVisibility.sharedWithName;
}

EventVisibility? _getDefaultVisibilityForGroup() {
  if (widget.group == null) return null;
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString('group_${widget.group!.id}_default_visibility');
  return EventVisibility.values.firstWhereOrNull((e) => e.name == stored);
}
```

**Privacy Change Validation:**
```dart
Future<bool> _validatePrivacyChange(EventVisibility newVisibility) async {
  // Check 1: Template override?
  if (_isTemplateEvent && newVisibility != _templateDefaultPrivacy) {
    return await _showTemplateOverrideWarning();
  }

  // Check 2: Shared → Private?
  if (_currentVisibility == EventVisibility.sharedWithName &&
      newVisibility == EventVisibility.private) {
    return await _showPrivacyDowngradeConfirmation();
  }

  // Check 3: Affects active proposals?
  if (_hasActiveProposals && _currentVisibility != newVisibility) {
    await _showProposalImpactWarning();
  }

  return true;
}
```

---

## Implementation Phases

### Phase 1: Fix Inconsistencies (2-3 hours)

#### Task 1.1: Add Privacy Badge to UpcomingEventCard
**File:** `application/lockitin_app/lib/presentation/widgets/upcoming_event_card.dart`

**Current code** (line 45-80):
```dart
// No privacy badge - just title, time, location
```

**Add privacy badge** (similar to AgendaEventCard:147-173):
```dart
// In _buildContent(), after location row
if (event.visibility != EventVisibility.sharedWithName) {
  SizedBox(height: 4),
  _buildPrivacyBadge(colorScheme, appColors),
}

Widget _buildPrivacyBadge(ColorScheme colorScheme, AppColorsExtension appColors) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: PrivacyColors.getPrivacyBackgroundColor(event.visibility),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          PrivacyColors.getPrivacyIcon(event.visibility),
          size: 12,
          color: colorScheme.onPrimaryContainer,
        ),
        SizedBox(width: 4),
        Text(
          PrivacyColors.getPrivacyLabel(event.visibility),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    ),
  );
}
```

**Acceptance:** UpcomingEventCard shows privacy badge matching AgendaEventCard style.

---

#### Task 1.2: Add Privacy Indicators to Month Calendar
**File:** `application/lockitin_app/lib/presentation/widgets/month_grid_view.dart` (lines 200-250)

**Current code:** Uses colored dots for event indicators, no privacy distinction.

**Add privacy color coding:**
```dart
// In _buildDayEventIndicators()
List<Widget> _buildDayEventIndicators(List<EventModel> events) {
  return events.take(3).map((event) {
    final privacyColor = PrivacyColors.getPrivacyColor(
      event.visibility,
      useColorBlindPalette: _useColorBlindPalette, // From settings
    );

    return Container(
      width: 6,
      height: 6,
      margin: EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: privacyColor,
        // Add subtle border for Private events
        border: event.visibility == EventVisibility.private
            ? Border.all(color: colorScheme.onSurface, width: 0.5)
            : null,
      ),
    );
  }).toList();
}
```

**Acceptance:** Month calendar dots use privacy colors (red/green/orange by default, color-blind palette when enabled).

---

#### Task 1.3: Add VoiceOver Labels
**Files:**
- `event_creation_screen.dart:270-357` (privacy picker)
- `agenda_event_card.dart:147-173` (privacy badge)
- `upcoming_event_card.dart` (new privacy badge)

**Add Semantics wrapper:**
```dart
// In _buildPrivacyCard()
Semantics(
  label: '${_getPrivacyLabel(visibility)} privacy level. '
         '${_getPrivacyDescription(visibility)}. '
         '${visibility == _visibility ? "Currently selected" : "Tap to select"}',
  selected: visibility == _visibility,
  button: true,
  child: GestureDetector(
    onTap: () => _updateVisibility(visibility),
    child: _buildCard(...),
  ),
)

// In _buildPrivacyBadge()
Semantics(
  label: 'Privacy level: ${PrivacyColors.getPrivacyLabel(event.visibility)}',
  child: Container(...),
)
```

**Acceptance:** VoiceOver reads "Private privacy level. Only you see this event. Currently selected" for each option.

---

### Phase 2: Per-Group Privacy Settings (3-4 hours)

#### Task 2.1: Extend Group Settings Sheet
**File:** `application/lockitin_app/lib/presentation/screens/group_detail/widgets/group_settings_sheet.dart`

**Current structure:**
```dart
// Lines 40-120: Group name, emoji, member management
// Lines 121-180: Leave group, delete group buttons
```

**Add new section** (insert after line 120):
```dart
// Privacy & Sharing Section
const SizedBox(height: 24),
_buildSectionHeader(context, colorScheme, 'Privacy & Sharing'),
const SizedBox(height: 12),
_buildPrivacySettingsCard(context, colorScheme, appColors),

Widget _buildPrivacySettingsCard(BuildContext context, ColorScheme colorScheme, AppColorsExtension appColors) {
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: appColors.cardBackground,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: appColors.cardBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Default Event Visibility Dropdown
        _buildDefaultVisibilityRow(context, colorScheme, appColors),

        SizedBox(height: 12),

        // Explanation text
        Text(
          'New events will default to this privacy level when creating from this group.',
          style: TextStyle(
            fontSize: 13,
            color: appColors.textSecondary,
            height: 1.4,
          ),
        ),

        SizedBox(height: 12),

        // Help button
        TextButton.icon(
          icon: Icon(Icons.help_outline, size: 16),
          label: Text('What can this group see?'),
          onPressed: () => _showPrivacyExplanation(context),
        ),
      ],
    ),
  );
}

Widget _buildDefaultVisibilityRow(BuildContext context, ColorScheme colorScheme, AppColorsExtension appColors) {
  return Row(
    children: [
      Icon(Icons.visibility_outlined, size: 20, color: colorScheme.primary),
      SizedBox(width: 8),
      Expanded(
        child: Text(
          'Default Event Visibility',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      DropdownButton<EventVisibility>(
        value: _defaultVisibility,
        underline: SizedBox.shrink(),
        items: [
          DropdownMenuItem(
            value: EventVisibility.private,
            child: Row(
              children: [
                Icon(Icons.lock, size: 16),
                SizedBox(width: 6),
                Text('Private'),
              ],
            ),
          ),
          DropdownMenuItem(
            value: EventVisibility.busyOnly,
            child: Row(
              children: [
                Icon(Icons.remove_red_eye_outlined, size: 16),
                SizedBox(width: 6),
                Text('Busy Only'),
              ],
            ),
          ),
          DropdownMenuItem(
            value: EventVisibility.sharedWithName,
            child: Row(
              children: [
                Icon(Icons.group, size: 16),
                SizedBox(width: 6),
                Text('Shared'),
              ],
            ),
          ),
        ],
        onChanged: (EventVisibility? newValue) async {
          if (newValue == null) return;
          await _updateDefaultVisibility(newValue);
        },
      ),
    ],
  );
}

Future<void> _updateDefaultVisibility(EventVisibility newValue) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    'group_${widget.group.id}_default_visibility',
    newValue.name,
  );

  setState(() {
    _defaultVisibility = newValue;
  });

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Default visibility updated to ${PrivacyColors.getPrivacyLabel(newValue)}'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
```

**Acceptance:** Group settings sheet has "Privacy & Sharing" section with default visibility dropdown.

---

#### Task 2.2: Apply Per-Group Defaults in Event Creation
**File:** `event_creation_screen.dart:45-80` (initState)

**Current code:**
```dart
EventVisibility _visibility = EventVisibility.sharedWithName; // Hard-coded default
```

**Apply per-group default:**
```dart
EventVisibility _visibility = EventVisibility.sharedWithName;

@override
void initState() {
  super.initState();
  _loadGroupPrivacyDefault();
  // ... existing code
}

Future<void> _loadGroupPrivacyDefault() async {
  if (widget.initialGroup == null) return;

  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString('group_${widget.initialGroup!.id}_default_visibility');

  if (stored != null) {
    final groupDefault = EventVisibility.values.firstWhereOrNull(
      (e) => e.name == stored,
    );

    if (groupDefault != null && mounted) {
      setState(() {
        _visibility = groupDefault;
      });
    }
  }
}
```

**Acceptance:** Creating event from group uses that group's default privacy (if set).

---

### Phase 3: Warnings & Confirmations (2-3 hours)

#### Task 3.1: Add Shared → Private Confirmation Dialog
**File:** `event_creation_screen.dart` (in `_updateVisibility()` method)

**Add validation before setState:**
```dart
void _updateVisibility(EventVisibility newVisibility) async {
  // If downgrading from Shared → Private, confirm
  if (_visibility == EventVisibility.sharedWithName &&
      newVisibility == EventVisibility.private) {
    final confirmed = await _showPrivacyDowngradeConfirmation();
    if (!confirmed) return;
  }

  setState(() {
    _visibility = newVisibility;
  });
}

Future<bool> _showPrivacyDowngradeConfirmation() async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber, color: colorScheme.error),
          SizedBox(width: 8),
          Text('Make Event Private?'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your groups will no longer see:'),
          SizedBox(height: 8),
          _buildBulletPoint('Event name: "${_titleController.text}"'),
          _buildBulletPoint('That you\'re busy at this time'),
          SizedBox(height: 12),
          Text(
            'This may affect group planning.',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: appColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
          ),
          child: Text('Make Private'),
        ),
      ],
    ),
  ) ?? false;
}

Widget _buildBulletPoint(String text) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('• ', style: TextStyle(fontSize: 16)),
      Expanded(child: Text(text)),
    ],
  );
}
```

**Acceptance:** Changing Shared → Private shows confirmation dialog with clear impact explanation.

---

#### Task 3.2: Add Template Privacy Override Warning
**File:** `event_creation_screen.dart`

**Detect template events:**
```dart
bool _isTemplateEvent = false;
EventVisibility? _templateDefaultPrivacy;

// In initState(), if widget.mode == EventCreationMode.surprisePartyTemplate
_isTemplateEvent = true;
_templateDefaultPrivacy = EventVisibility.busyOnly;
_visibility = EventVisibility.busyOnly;

// In _updateVisibility()
void _updateVisibility(EventVisibility newVisibility) async {
  // Check template override
  if (_isTemplateEvent &&
      _templateDefaultPrivacy != null &&
      newVisibility != _templateDefaultPrivacy) {
    final confirmed = await _showTemplateOverrideWarning(newVisibility);
    if (!confirmed) return;
  }

  // ... rest of validation
}

Future<bool> _showTemplateOverrideWarning(EventVisibility newVisibility) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.error),
          SizedBox(width: 8),
          Text('Surprise Party Exposed!'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Changing this to "${PrivacyColors.getPrivacyLabel(newVisibility)}" means:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 12),
          _buildBulletPoint('Birthday person will see "Surprise Birthday Party" on calendar'),
          _buildBulletPoint('The surprise will be ruined!'),
          SizedBox(height: 16),
          Text(
            'Keep as "Busy Only"?',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Keep Busy Only'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: colorScheme.error),
          child: Text('Change Anyway'),
        ),
      ],
    ),
  ) ?? false;
}
```

**Acceptance:** Changing Surprise Party template privacy shows dramatic warning.

---

### Phase 4: Accessibility & Polish (1-2 hours)

#### Task 4.1: Add Colorblind Palette Toggle
**File:** `application/lockitin_app/lib/presentation/screens/profile_screen.dart` (Settings section)

**Add toggle in Settings:**
```dart
// In _buildSettingsSection()
SwitchListTile(
  title: Text('Color-Blind Friendly Colors'),
  subtitle: Text('Use patterns and high-contrast colors'),
  value: _useColorBlindPalette,
  onChanged: (bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_colorblind_palette', value);
    setState(() {
      _useColorBlindPalette = value;
    });
  },
)
```

**Update PrivacyColors usage everywhere:**
```dart
// In all privacy badge calls
PrivacyColors.getPrivacyColor(
  event.visibility,
  useColorBlindPalette: _useColorBlindPalette,
)
```

**Acceptance:** Settings has colorblind toggle, privacy colors change when enabled.

---

#### Task 4.2: Add First-Time User Tooltip
**File:** `event_creation_screen.dart`

**Show tooltip for first 3 events:**
```dart
bool _shouldShowPrivacyTooltip = false;

@override
void initState() {
  super.initState();
  _checkIfFirstTimeUser();
}

Future<void> _checkIfFirstTimeUser() async {
  final prefs = await SharedPreferences.getInstance();
  final eventCount = prefs.getInt('total_events_created') ?? 0;

  if (eventCount < 3 && mounted) {
    setState(() {
      _shouldShowPrivacyTooltip = true;
    });

    // Show tooltip after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _shouldShowPrivacyTooltip) {
        _showPrivacyTooltip();
      }
    });
  }
}

void _showPrivacyTooltip() {
  final RenderBox? renderBox = _privacyFieldKey.currentContext?.findRenderObject() as RenderBox?;
  if (renderBox == null) return;

  final position = renderBox.localToGlobal(Offset.zero);

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => Stack(
      children: [
        Positioned(
          left: position.dx,
          top: position.dy - 80,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.waving_hand, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'New! Control who sees this event',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  // Auto-dismiss after 3 seconds
  Future.delayed(Duration(seconds: 3), () {
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  });
}
```

**Acceptance:** First 3 events show tooltip above Privacy field, auto-dismisses after 3 seconds.

---

#### Task 4.3: Add Info Icon with Help Sheet
**File:** `event_creation_screen.dart:270` (privacy section header)

**Add info icon:**
```dart
// In _buildPrivacyCard() header
Row(
  children: [
    Text(
      'Privacy',
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
    ),
    SizedBox(width: 8),
    GestureDetector(
      onTap: () => _showPrivacyHelp(),
      child: Icon(
        Icons.help_outline,
        size: 18,
        color: colorScheme.primary,
      ),
    ),
  ],
)

void _showPrivacyHelp() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How Privacy Works',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 16),

          _buildPrivacyHelpRow(
            Icons.lock,
            'Private',
            'Only you see this event. Groups don\'t even know you\'re busy.',
            'Example: Doctor appointments, therapy, personal time',
            colorScheme.primary,
          ),

          SizedBox(height: 16),

          _buildPrivacyHelpRow(
            Icons.remove_red_eye_outlined,
            'Shared as Busy',
            'Groups see you\'re busy, but not why.',
            'Example: Work meetings, family commitments',
            appColors.warning,
          ),

          SizedBox(height: 16),

          _buildPrivacyHelpRow(
            Icons.group,
            'Shared with Details',
            'Groups see the full event name and details.',
            'Example: Group dinners, friend hangouts',
            colorScheme.secondary,
          ),

          SizedBox(height: 24),

          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it'),
          ),
        ],
      ),
    ),
  );
}

Widget _buildPrivacyHelpRow(IconData icon, String title, String description, String example, Color color) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      SizedBox(height: 4),
      Text(
        description,
        style: TextStyle(fontSize: 14, height: 1.4),
      ),
      SizedBox(height: 4),
      Text(
        example,
        style: TextStyle(
          fontSize: 13,
          color: appColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      ),
    ],
  );
}
```

**Acceptance:** Info icon opens bottom sheet with clear privacy explanations.

---

## Acceptance Criteria

### Functional Requirements

- [ ] **Privacy Badge Consistency**
  - AgendaEventCard shows privacy badge (lock/eye/people icon + label) ✅ Already exists
  - UpcomingEventCard shows privacy badge
  - Month calendar dots use privacy colors
  - All views use same PrivacyColors utility

- [ ] **Per-Group Privacy Settings**
  - Group Settings Sheet has "Privacy & Sharing" section
  - Dropdown allows setting default visibility (Private/Busy/Shared)
  - Setting persists in SharedPreferences
  - Event creation applies group default when creating from group context
  - Help button explains what group can see

- [ ] **Privacy Change Warnings**
  - Changing Shared → Private shows confirmation dialog
  - Dialog lists what groups will no longer see
  - Changing Surprise Party privacy shows dramatic warning
  - User can cancel or proceed with change

- [ ] **Accessibility**
  - All privacy options have VoiceOver labels
  - Privacy badges have semantic labels
  - Settings has "Color-Blind Friendly Colors" toggle
  - Colorblind palette changes privacy colors globally
  - VoiceOver reads "Private privacy level. Only you see this event. Currently selected"

- [ ] **User Education**
  - First 3 events show tooltip above Privacy field
  - Tooltip auto-dismisses after 3 seconds
  - Info icon (ℹ️) next to Privacy label
  - Tapping info icon opens help bottom sheet
  - Help sheet explains all 3 privacy levels with examples

### Non-Functional Requirements

- [ ] **Performance**
  - Privacy default load time <50ms
  - Privacy change updates UI within 100ms
  - Month calendar privacy colors render smoothly

- [ ] **Consistency**
  - Privacy colors match across all views (agenda, upcoming, month)
  - Privacy icons consistent (lock, eye-slash, people)
  - Privacy labels consistent ("Private", "Busy Only", "Shared with Details")

- [ ] **Reliability**
  - Per-group settings persist across app restarts
  - Colorblind palette persists across app restarts
  - Privacy changes sync to shadow_calendar (existing backend ✅)

### Quality Gates

- [ ] **Widget Tests**
  - Test UpcomingEventCard privacy badge renders correctly
  - Test month calendar privacy colors
  - Test privacy help sheet displays all 3 options
  - Test colorblind palette toggle changes colors

- [ ] **Integration Tests**
  - Test per-group default applies when creating event (existing test: `shadow_calendar_privacy_test.dart`)
  - Test privacy transitions update shadow_calendar ✅ Already exists
  - Test confirmation dialogs appear when expected

- [ ] **Manual Testing**
  - Test with VoiceOver on iOS
  - Test with TalkBack on Android
  - Test colorblind palette is distinguishable
  - Test first-time tooltip appears correctly

---

## Testing Strategy

### Unit Tests

**File:** `test/utils/privacy_colors_test.dart`

```dart
group('PrivacyColors', () {
  test('getPrivacyColor returns correct colors', () {
    expect(
      PrivacyColors.getPrivacyColor(EventVisibility.private),
      equals(Color(0xFFEF4444)), // Red
    );
    expect(
      PrivacyColors.getPrivacyColor(EventVisibility.sharedWithName),
      equals(Color(0xFF10B981)), // Green
    );
  });

  test('colorblind palette uses distinct colors', () {
    final privateColor = PrivacyColors.getPrivacyColor(
      EventVisibility.private,
      useColorBlindPalette: true,
    );
    final sharedColor = PrivacyColors.getPrivacyColor(
      EventVisibility.sharedWithName,
      useColorBlindPalette: true,
    );

    expect(privateColor, isNot(equals(sharedColor)));
  });
});
```

### Widget Tests

**File:** `test/widgets/upcoming_event_card_test.dart`

```dart
testWidgets('UpcomingEventCard shows privacy badge for private events', (tester) async {
  final event = EventModel(
    id: 'test',
    title: 'Doctor Appointment',
    visibility: EventVisibility.private,
    // ... other fields
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: UpcomingEventCard(event: event),
      ),
    ),
  );

  // Privacy badge should be visible
  expect(find.byIcon(Icons.lock), findsOneWidget);
  expect(find.text('Private'), findsOneWidget);
});

testWidgets('UpcomingEventCard does not show badge for shared events', (tester) async {
  final event = EventModel(
    id: 'test',
    title: 'Team Meeting',
    visibility: EventVisibility.sharedWithName,
    // ... other fields
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: UpcomingEventCard(event: event),
      ),
    ),
  );

  // Privacy badge should NOT be visible for shared events
  expect(find.byIcon(Icons.lock), findsNothing);
  expect(find.text('Private'), findsNothing);
});
```

### Integration Tests

**File:** `integration_test/privacy_per_group_test.dart` (NEW)

```dart
testWidgets('Per-group privacy default applies when creating event', (tester) async {
  // 1. Set group default to "Busy Only"
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('group_123_default_visibility', 'busyOnly');

  // 2. Navigate to event creation from group context
  await tester.pumpWidget(MyApp());
  await tester.tap(find.byIcon(Icons.group));
  await tester.pumpAndSettle();
  await tester.tap(find.text('College Friends'));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();

  // 3. Verify privacy defaults to "Busy Only"
  expect(
    find.text('Shared as Busy'),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: find.text('Shared as Busy'),
      matching: find.byType(Container), // Selected card
    ),
    findsOneWidget,
  );
});
```

**Existing integration tests** (already pass ✅):
- `shadow_calendar_privacy_test.dart:20-45` - BusyOnly entries hide title
- `shadow_calendar_privacy_test.dart:47-72` - SharedWithName entries show title
- `shadow_calendar_privacy_test.dart:74-99` - Private events never sync

### Manual Testing Checklist

**Privacy Badge Consistency:**
- [ ] Create private event, verify badge shows in AgendaEventCard
- [ ] Create private event, verify badge shows in UpcomingEventCard
- [ ] Create private event, verify red dot shows in month calendar
- [ ] Create shared event, verify NO badge shows (default)
- [ ] Create busy-only event, verify orange badge/dot shows

**Per-Group Privacy:**
- [ ] Open group settings, set default to "Busy Only"
- [ ] Create event from that group, verify privacy defaults to "Busy Only"
- [ ] Open different group settings, set default to "Private"
- [ ] Create event from that group, verify privacy defaults to "Private"
- [ ] Settings persist after app restart

**Privacy Change Warnings:**
- [ ] Create shared event with title "Birthday Party"
- [ ] Change privacy to Private
- [ ] Verify confirmation dialog lists event name
- [ ] Tap "Cancel", verify privacy stays Shared
- [ ] Tap "Make Private", verify privacy changes to Private

**Template Privacy:**
- [ ] Start Surprise Party template
- [ ] Verify privacy defaults to "Busy Only"
- [ ] Try to change to "Shared with Details"
- [ ] Verify warning says "Birthday person will see..."
- [ ] Tap "Keep Busy Only", verify privacy stays Busy

**Accessibility:**
- [ ] Enable VoiceOver (iOS) or TalkBack (Android)
- [ ] Navigate to event creation
- [ ] Focus on Private option, verify VoiceOver reads full description
- [ ] Enable "Color-Blind Friendly Colors" in settings
- [ ] Create events with different privacy levels
- [ ] Verify colors change to rose/cyan/orange palette
- [ ] Verify colors are distinguishable for colorblind users

**User Education:**
- [ ] Delete app, reinstall (or clear SharedPreferences)
- [ ] Create first event
- [ ] Verify tooltip appears above Privacy field
- [ ] Verify tooltip says "New! Control who sees this event"
- [ ] Verify tooltip auto-dismisses after 3 seconds
- [ ] Create 2nd event, verify tooltip still appears
- [ ] Create 4th event, verify tooltip does NOT appear
- [ ] Tap info icon (ℹ️) next to Privacy label
- [ ] Verify bottom sheet shows 3 privacy levels with examples

---

## Dependencies & Risks

### Dependencies

**External Packages:**
- `shared_preferences: ^2.2.2` - For storing per-group privacy defaults ✅ Already in pubspec.yaml
- No new dependencies required

**Backend Dependencies:**
- `sync_event_to_shadow_calendar()` trigger ✅ Already exists and works
- `get_group_shadow_calendar()` RPC ✅ Already exists and works
- Shadow calendar RLS policies ✅ Already exists and works

**Code Dependencies:**
- `EventModel` with `visibility` field ✅ Already exists
- `PrivacyColors` utility class ✅ Already exists
- `AgendaEventCard` privacy badge ✅ Already implemented
- Event creation screen privacy picker ✅ Already implemented

### Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| **Performance:** Loading per-group defaults on every event creation | Low | Cache defaults in memory after first load |
| **UX:** Too many confirmation dialogs annoy users | Medium | Only show confirmations for high-risk changes (Shared→Private, Template override) |
| **Accessibility:** Colorblind users can't distinguish privacy levels | High | ✅ Mitigated: Colorblind palette + icons + text labels |
| **Data:** Per-group defaults lost if user clears app data | Low | Acceptable - rare event, can be reset in settings |
| **Backend:** Shadow calendar sync fails silently | Low | ✅ Already handled: EventService logs errors |
| **Template:** User exposes Surprise Party accidentally | High | ✅ Mitigated: Dramatic warning dialog with "Keep Busy Only" as primary action |

---

## Success Metrics

**Completion Criteria:**
- [ ] All 4 phases complete (inconsistencies fixed, per-group settings, warnings, accessibility)
- [ ] All acceptance criteria met (22 functional + 6 non-functional requirements)
- [ ] All tests pass (unit, widget, integration, manual)
- [ ] VoiceOver and TalkBack tested successfully
- [ ] Colorblind palette tested with actual colorblind users (or simulation tool)

**User Impact:**
- Users can set different privacy defaults for work vs friends groups
- Users understand what each privacy level means (first-time tooltip + help sheet)
- Users protected from accidental privacy leaks (confirmation dialogs)
- Colorblind users can distinguish privacy levels
- VoiceOver users can use privacy controls independently

**Technical Quality:**
- Privacy indicators consistent across all calendar views
- Per-group settings persist reliably
- No performance degradation from privacy checks
- Backend sync continues to work perfectly (no changes needed)

---

## Future Considerations

**Not in Scope for v0.2.5 (Defer to v1.0.0+):**

1. **Smart Privacy Suggestions**
   - Suggest "Busy Only" for work events
   - Suggest "Private" for medical events
   - Requires ML/heuristics

2. **Bulk Privacy Change**
   - Select multiple events → change privacy
   - Requires multi-select UI

3. **Privacy Analytics**
   - Settings → Privacy → "40% private, 30% busy, 30% shared"
   - Requires event counting

4. **Long-Press Privacy Change**
   - Long-press event → context menu → privacy options
   - Reduces taps from 4 to 2
   - Requires gesture detection

5. **Privacy Preview**
   - "College Friends will see: Holiday Dinner at 7:00 PM"
   - Shows exactly what groups see
   - Requires rendering preview

---

## References

### Internal Documentation

**Architecture:**
- CLAUDE.md (lines 83-145) - Shadow Calendar dual-table architecture
- lockitin-privacy-security.md - Complete privacy system documentation
- lockitin-features.md (lines 99-106) - Shadow Calendar feature description

**Code:**
- `data/models/event_model.dart` - EventVisibility enum, EventModel
- `presentation/screens/event_creation_screen.dart:270-357` - Privacy picker UI
- `presentation/widgets/agenda_event_card.dart:147-173` - Privacy badge implementation
- `utils/privacy_colors.dart` - PrivacyColors utility with colorblind palette
- `supabase/shadow_calendar_schema.sql` - Sync trigger and RLS policies

**Tests:**
- `integration_test/shadow_calendar_privacy_test.dart` - Privacy enforcement tests ✅

### External Documentation

**Flutter Widgets:**
- [DropdownButton - Flutter API](https://api.flutter.dev/flutter/material/DropdownButton-class.html)
- [CupertinoActionSheet - Flutter API](https://api.flutter.dev/flutter/cupertino/CupertinoActionSheet-class.html)
- [Semantics - Flutter API](https://api.flutter.dev/flutter/widgets/Semantics-class.html)
- [Badge - Flutter API](https://api.flutter.dev/flutter/material/Badge-class.html)

**Accessibility:**
- [iOS Human Interface Guidelines - Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [Material Design - Accessibility](https://m3.material.io/foundations/accessible-design/overview)
- [WCAG 2.1 AA - Color Contrast](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html)

**Privacy UI Patterns:**
- [Privacy UX - Smashing Magazine](https://www.smashingmagazine.com/2019/04/privacy-ux-aware-design-framework/)
- [Privacy theory in practice - Taylor & Francis](https://www.tandfonline.com/doi/full/10.1080/17489725.2018.1511839)

---

## Implementation Timeline

| Phase | Tasks | Effort | Completion Date |
|-------|-------|--------|-----------------|
| **Phase 1** | Fix inconsistencies (3 tasks) | 2-3 hours | Day 1 |
| **Phase 2** | Per-group settings (2 tasks) | 3-4 hours | Day 1-2 |
| **Phase 3** | Warnings & confirmations (2 tasks) | 2-3 hours | Day 2 |
| **Phase 4** | Accessibility & polish (3 tasks) | 1-2 hours | Day 2 |
| **Testing** | Unit, widget, integration, manual | 1-2 hours | Day 2-3 |
| **TOTAL** | **10 tasks + testing** | **9-14 hours** | **2-3 days** |

**Estimated Completion:** January 9-10, 2026 (if starting January 7)

---

**Last Updated:** January 7, 2026
**Status:** Ready for Implementation
**Approved By:** Pending user approval

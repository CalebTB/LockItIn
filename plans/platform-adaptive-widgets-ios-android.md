# Platform-Adaptive Widgets (iOS/Android) Implementation Plan

**Issue:** #136
**Sprint:** 2
**Priority:** Critical
**Type:** Feature
**Estimated Effort:** 2-3 days

---

## Overview

Implement platform-adaptive widgets to make the LockItIn app feel native on both iOS and Android platforms. Currently, the app uses Material-only widgets, making it feel like "an Android app on iOS" and violating iOS Human Interface Guidelines (HIG).

This implementation will follow the project's core design principle: **"Platform-Native Feel - Follows Apple HIG on iOS (Cupertino widgets, SF Pro) and Material Design on Android (Material widgets, Roboto), uses system colors, feels native to each platform"** (CLAUDE.md:236)

---

## Problem Statement

### Current State

The app exclusively uses Material Design widgets across all UI elements:
- **128+ Material buttons** (`ElevatedButton`, `OutlinedButton`, `TextButton`) across 33 files
- **18 Material dialogs** (`showDialog` with `AlertDialog`)
- **17 Material bottom sheets** (`showModalBottomSheet`)
- **15+ Material text fields** (`TextField`, `TextFormField`)
- No platform-specific navigation patterns
- No iOS-specific gestures or interactions

**Impact:** iOS users experience an Android-like interface that:
- Violates Apple HIG standards
- Looks unprofessional and non-native
- Uses wrong interaction patterns (tap vs swipe, Android back button vs iOS swipe-back)
- Degrades user trust and retention on iOS

### Existing Adaptive Widgets (Limited)

The codebase has **3 existing adaptive examples** that demonstrate the correct pattern:

1. **`platform_dialog.dart`** - Adaptive alert dialogs and action sheets
2. **`adaptive_date_time_picker.dart`** - Platform-specific date/time pickers
3. **`view_mode_toggle.dart`** - Uses `CupertinoSlidingSegmentedControl` on iOS

These provide excellent reference implementations to follow.

---

## Proposed Solution

### Architecture Pattern

Follow the established pattern from `view_mode_toggle.dart` and Flutter best practices:

```dart
// lib/presentation/widgets/adaptive/adaptive_button.dart
class AdaptiveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isPrimary;
  final bool isDestructive;

  const AdaptiveButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    return platform == TargetPlatform.iOS
      ? _buildCupertinoButton(context)
      : _buildMaterialButton(context);
  }

  Widget _buildCupertinoButton(BuildContext context) {
    if (isPrimary) {
      return CupertinoButton.filled(
        onPressed: onPressed,
        child: child,
      );
    }

    return CupertinoButton(
      onPressed: onPressed,
      color: isDestructive ? CupertinoColors.destructiveRed : null,
      child: child,
    );
  }

  Widget _buildMaterialButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isPrimary) {
      return ElevatedButton(
        onPressed: onPressed,
        child: child,
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: isDestructive
        ? OutlinedButton.styleFrom(foregroundColor: colorScheme.error)
        : null,
      child: child,
    );
  }
}
```

**Key Principles:**
- Use `Theme.of(context).platform` (NOT `dart:io Platform.isIOS`) for UI-level checks
- Maintain consistent behavior across platforms
- Leverage existing theme system (`app_colors.dart`, `app_theme.dart`)
- Create convenience static methods for common use cases

---

## Technical Approach

### Implementation Phases

#### Phase 1: Foundation (4-6 hours)

**Create core adaptive widget library**

**Files to create:**
```
lib/presentation/widgets/adaptive/
  ├── adaptive_button.dart            # Primary, secondary, destructive buttons
  ├── adaptive_text_button.dart       # Text-only buttons
  ├── adaptive_dialog.dart            # Alert dialogs
  ├── adaptive_action_sheet.dart      # Bottom sheets / action menus
  ├── adaptive_text_field.dart        # Text input fields
  ├── adaptive_scaffold.dart          # Page scaffolds (optional)
  └── adaptive.dart                   # Barrel file exports
```

**Platform detection utility:**
```dart
// lib/core/utils/platform_utils.dart
class PlatformUtils {
  static bool isIOS(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.iOS;
  }

  static bool isAndroid(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.android;
  }
}
```

**Widget Mapping Reference:**

| Component | iOS (Cupertino) | Android (Material) |
|-----------|----------------|-------------------|
| Primary Button | `CupertinoButton.filled` | `ElevatedButton` |
| Secondary Button | `CupertinoButton` | `OutlinedButton` |
| Text Button | `CupertinoButton` (no background) | `TextButton` |
| Alert Dialog | `CupertinoAlertDialog` | `AlertDialog` |
| Action Sheet | `CupertinoActionSheet` | `showModalBottomSheet` |
| Text Field | `CupertinoTextField` | `TextField` |
| Loading Indicator | `CupertinoActivityIndicator` | `CircularProgressIndicator` |

#### Phase 2: High-Impact Screen Migration (6-8 hours)

**Priority order (by visibility and user impact):**

1. **Authentication Screens** (`auth/login_screen.dart`)
   - Replace 1 `ElevatedButton` (Log In)
   - Replace 1 `OutlinedButton` (Create Account)
   - Replace 1 `TextButton` (Forgot Password)
   - Replace 2 `TextFormField` (email, password)
   - **Impact:** First impression for all new users

2. **Profile Screen** (`profile_screen.dart`)
   - Replace 1 `ElevatedButton` (Save)
   - Replace 1 `OutlinedButton` (View Friends)
   - Replace 2 `TextFormField` (name, bio)
   - Update settings list items with adaptive styling
   - **Impact:** High-frequency screen, user expectations of native feel

3. **Event Creation Screen** (`event_creation_screen.dart`)
   - Replace 7+ `ElevatedButton` instances
   - Replace 12+ `TextFormField` instances
   - Update dialogs (confirmation, discard changes)
   - **Impact:** Core workflow, most complex form in app

**Migration script for bulk replacements:**
```bash
# Find and mark files for manual review
grep -r "ElevatedButton\|OutlinedButton\|TextButton" lib/presentation/screens/ \
  | cut -d: -f1 | sort -u > migration_checklist.txt
```

#### Phase 3: Dialogs & Modals (3-4 hours)

**Enhance `platform_dialog.dart`** with missing variants:
- Loading dialogs
- Confirmation dialogs with custom actions
- Multi-choice selection dialogs

**Update all `showDialog` calls** to use platform utilities:
```dart
// Before
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Delete Event'),
    content: Text('Are you sure?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
      TextButton(onPressed: deleteEvent, child: Text('Delete')),
    ],
  ),
);

// After
PlatformDialog.showConfirmation(
  context: context,
  title: 'Delete Event',
  message: 'Are you sure?',
  destructiveActionLabel: 'Delete',
  onConfirm: deleteEvent,
);
```

**Extend `adaptive_bottom_sheet.dart`:**
- Add iOS-style drag handle behavior
- Add action sheet variant (replaces `showModalBottomSheet` for simple choices)
- Ensure proper SafeArea handling on iOS

#### Phase 4: Testing & Polish (4-5 hours)

**Test matrix:**

| Screen | iOS Simulator | Android Emulator | Notes |
|--------|--------------|------------------|-------|
| Login | ✅ | ✅ | Verify keyboard interactions |
| Sign Up | ✅ | ✅ | Test form validation |
| Profile | ✅ | ✅ | Check settings list tiles |
| Event Creation | ✅ | ✅ | Test date/time pickers |
| Event Detail | ✅ | ✅ | Test delete confirmation |
| Groups | ✅ | ✅ | Test bottom sheets |

**iOS-specific validations:**
- ✅ Swipe-back gesture works on all screens
- ✅ SafeArea properly handles notch and home indicator
- ✅ CupertinoButton padding doesn't cause layout issues
- ✅ Modal sheets use correct iOS presentation style

**Android-specific validations:**
- ✅ System back button handled correctly
- ✅ Material ripple effects present
- ✅ Elevation and shadows match Material 3 spec

**Widget test updates:**
```dart
// lib/presentation/screens/auth/login_screen_test.dart
testWidgets('Login button adapts to platform', (tester) async {
  // Test Material on Android
  debugDefaultTargetPlatformOverride = TargetPlatform.android;
  await tester.pumpWidget(buildLoginScreen());
  expect(find.byType(ElevatedButton), findsOneWidget);

  // Test Cupertino on iOS
  debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  await tester.pumpWidget(buildLoginScreen());
  expect(find.byType(CupertinoButton), findsOneWidget);

  debugDefaultTargetPlatformOverride = null;
});
```

---

## Alternative Approaches Considered

### Option 1: Use `flutter_platform_widgets` Package ❌

**Pros:**
- Pre-built adaptive widgets
- Reduces boilerplate code
- Active community support

**Cons:**
- Adds external dependency
- Less control over styling
- Package updates may break existing UI
- Overkill for project needs (only ~5 widget types to adapt)

**Decision:** Build our own adaptive widgets for full control and maintainability

### Option 2: Separate iOS and Android Codebases ❌

**Pros:**
- Maximum platform fidelity
- No conditional logic

**Cons:**
- 2x development time
- Code duplication
- Harder to maintain feature parity
- Against cross-platform philosophy

**Decision:** Single codebase with adaptive UI layer

### Option 3: Use Only Material Widgets with iOS Theme ❌

**Pros:**
- Simpler implementation
- Consistent across platforms

**Cons:**
- Still violates iOS HIG
- Doesn't provide truly native feel
- Users can tell it's not native

**Decision:** Platform-adaptive approach per design principles

---

## Acceptance Criteria

### Functional Requirements

- [ ] **Adaptive buttons** work on both iOS and Android
  - [ ] Primary buttons use `CupertinoButton.filled` on iOS, `ElevatedButton` on Android
  - [ ] Secondary buttons use `CupertinoButton` on iOS, `OutlinedButton` on Android
  - [ ] Destructive buttons show red color on both platforms

- [ ] **Adaptive dialogs** display correctly
  - [ ] Alert dialogs use `CupertinoAlertDialog` on iOS, `AlertDialog` on Android
  - [ ] Action sheets use `CupertinoActionSheet` on iOS, bottom sheet on Android

- [ ] **Adaptive text fields** function properly
  - [ ] Use `CupertinoTextField` on iOS with correct placeholder styling
  - [ ] Use `TextField` on Android with Material decoration
  - [ ] Keyboard types match platform conventions

- [ ] **All authentication screens** use adaptive widgets
  - [ ] Login screen
  - [ ] Sign up screen
  - [ ] Forgot password flow

- [ ] **Profile screen** uses adaptive widgets
  - [ ] Edit profile buttons
  - [ ] Text input fields
  - [ ] Settings list items

- [ ] **Event creation screen** uses adaptive widgets
  - [ ] All form fields
  - [ ] Save/cancel buttons
  - [ ] Confirmation dialogs

### Non-Functional Requirements

- [ ] **iOS compliance**
  - [ ] Passes iOS Human Interface Guidelines review
  - [ ] Swipe-back gesture works on all screens
  - [ ] SafeArea properly handles notch and home indicator
  - [ ] Uses San Francisco font (system default)

- [ ] **Android compliance**
  - [ ] Follows Material Design 3 guidelines
  - [ ] System back button handled correctly
  - [ ] Material ripple effects present
  - [ ] Uses Roboto font (system default)

- [ ] **Performance**
  - [ ] No performance regression from platform checks
  - [ ] Widget builds cached where possible
  - [ ] No janky animations or transitions

- [ ] **Accessibility**
  - [ ] Screen readers work on both platforms
  - [ ] Keyboard navigation functional
  - [ ] Touch targets meet platform minimums (44pt iOS, 48dp Android)

- [ ] **Testing**
  - [ ] Widget tests pass for both platforms
  - [ ] Manual testing completed on iOS and Android
  - [ ] Edge cases handled (rotation, dark mode, large text)

### Quality Gates

- [ ] Code review approved by Flutter Architect agent
- [ ] All existing widget tests updated and passing
- [ ] New adaptive widget tests added
- [ ] Visual QA completed on:
  - [ ] iOS Simulator (iPhone 15, iPhone SE)
  - [ ] Android Emulator (Pixel 6, small phone)
- [ ] No console warnings or errors
- [ ] Documentation updated (widget catalog, migration guide)

---

## Success Metrics

**User Experience:**
- iOS users can't tell it's a cross-platform app
- Android users see familiar Material Design
- No user reports of "feels like an Android app" on iOS

**Code Quality:**
- 100% of screens use adaptive widgets (no direct Material widget usage in UI layer)
- All new widgets have unit tests
- Widget tests cover both iOS and Android rendering

**Performance:**
- No measurable performance impact from platform checks
- Build time remains under 2 minutes for debug builds

---

## Dependencies & Prerequisites

### Required Before Starting

- [x] Flutter 3.16+ installed
- [x] iOS Simulator configured (Xcode installed)
- [x] Android Emulator configured
- [x] Existing theme system (`app_colors.dart`, `app_theme.dart`)

### Blocking Dependencies

- None - this work is independent

### Dependent Features

- **Issue #138:** Shadow Calendar Privacy UI - will benefit from adaptive dialogs
- **Issue #198:** Back navigation - requires iOS swipe-back support
- **All future UI work** - will use new adaptive widget library

---

## Risk Analysis & Mitigation

### Risk 1: Breaking Existing UI

**Likelihood:** Medium
**Impact:** High
**Mitigation:**
- Migrate screens one at a time
- Keep Material widgets alongside adaptive (gradual replacement)
- Extensive widget testing before and after migration
- Feature flag for rollback if needed

### Risk 2: Theme Inconsistencies

**Likelihood:** Medium
**Impact:** Medium
**Mitigation:**
- Use existing `Theme.of(context).colorScheme` for all colors
- Create shared constants for border radius, padding
- Visual comparison screenshots (before/after)

### Risk 3: Platform-Specific Bugs

**Likelihood:** High (expected)
**Impact:** Medium
**Mitigation:**
- Test on both platforms frequently during development
- Use `debugDefaultTargetPlatformOverride` for quick platform switching
- Widget tests for both platforms
- Beta testing on real devices before release

### Risk 4: Timeline Overrun

**Likelihood:** Medium
**Impact:** Medium
**Mitigation:**
- Prioritize high-impact screens (auth, profile) first
- Can ship partial implementation (Phase 1-2 only)
- Defer event creation screen if needed (most complex)

---

## Resource Requirements

**Developer Time:** 18-24 hours (2-3 days)

**Phase breakdown:**
- Phase 1 (Foundation): 4-6 hours
- Phase 2 (Screen Migration): 6-8 hours
- Phase 3 (Dialogs): 3-4 hours
- Phase 4 (Testing): 4-5 hours
- Buffer: 1-1.5 hours

**Tools & Infrastructure:**
- Xcode (iOS Simulator)
- Android Studio (Android Emulator)
- Flutter DevTools (debugging)
- VS Code / Android Studio IDE

**Expertise Required:**
- Flutter/Dart development
- iOS Human Interface Guidelines knowledge
- Material Design 3 familiarity
- Cross-platform best practices

---

## Future Considerations

### Post-MVP Enhancements (v1.1.0+)

- **Adaptive navigation** - `CupertinoTabScaffold` vs `BottomNavigationBar`
- **Adaptive loading indicators** - Match platform spinners
- **Adaptive switches/checkboxes** - Already have `.adaptive()` constructors
- **Platform-specific animations** - Spring physics (iOS) vs Material motion (Android)
- **Haptic feedback patterns** - Different intensity levels per platform

### Extensibility

- **Design system documentation** - Widget catalog with examples
- **Contribution guidelines** - How to add new adaptive widgets
- **Automated visual regression testing** - Screenshot comparisons
- **Performance monitoring** - Track widget build times

---

## Documentation Plan

### Code Documentation

- [ ] Inline comments for platform-specific behavior
- [ ] DartDoc comments for all public APIs
- [ ] Code examples in widget headers

### Architecture Documentation

- [ ] Update CLAUDE.md with adaptive widget patterns
- [ ] Create `docs/adaptive-widgets-guide.md`
- [ ] Document migration path for future widgets

### Testing Documentation

- [ ] Widget test examples for adaptive widgets
- [ ] Manual testing checklist for QA
- [ ] Platform-specific gotchas and solutions

---

## References & Research

### Internal References

**Existing adaptive examples to follow:**
- `lib/core/utils/platform_dialog.dart` - Alert dialogs and action sheets pattern
- `lib/presentation/widgets/adaptive_date_time_picker.dart` - Date/time picker implementation
- `lib/presentation/screens/group_detail/widgets/view_mode_toggle.dart` - Segmented control example
- `lib/presentation/widgets/adaptive_bottom_sheet.dart` - Bottom sheet base component

**Theme system:**
- `lib/core/theme/app_theme.dart` - Central theme configuration
- `lib/core/theme/app_colors.dart` - Color system and extensions

**High-impact screens for migration:**
- `lib/presentation/screens/auth/login_screen.dart:230-270` - Login button, form fields
- `lib/presentation/screens/profile_screen.dart:360-390` - Save button, edit fields
- `lib/presentation/screens/event_creation_screen.dart:1530-1570` - Multiple buttons and fields

### External References

**Official Flutter Documentation:**
- [Automatic platform adaptations](https://docs.flutter.dev/ui/adaptive-responsive/platform-adaptations)
- [Best practices for adaptive design](https://docs.flutter.dev/ui/adaptive-responsive/best-practices)
- [Cupertino Widgets Catalog](https://docs.flutter.dev/ui/widgets/cupertino)
- [Material Design 3](https://m3.material.io/)

**Flutter API Documentation:**
- [CupertinoButton class](https://api.flutter.dev/flutter/cupertino/CupertinoButton-class.html)
- [CupertinoTextField class](https://api.flutter.dev/flutter/cupertino/CupertinoTextField-class.html)
- [CupertinoAlertDialog class](https://api.flutter.dev/flutter/cupertino/CupertinoAlertDialog-class.html)
- [Switch.adaptive constructor](https://api.flutter.dev/flutter/material/Switch/Switch.adaptive.html)
- [PopScope class](https://api.flutter.dev/flutter/widgets/PopScope-class.html) - For handling both Android back and iOS swipe

**Best Practices & Tutorials:**
- [Designing for Both Worlds: Adaptive UIs with Material and Cupertino](https://maxim-gorin.medium.com/designing-for-both-worlds-adaptive-uis-with-material-and-cupertino-in-flutter-b17591dc17d2)
- [Smart UI Design in Flutter: Adaptive Widgets](https://medium.com/@deepanshurawat125/smart-ui-design-in-flutter-how-adaptive-widgets-enhance-user-experience-489f3bc08c9f)
- [Adaptive Apps in Flutter - Google Codelabs](https://codelabs.developers.google.com/codelabs/flutter-adaptive-app)

**Platform Guidelines:**
- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Material Design Guidelines](https://m3.material.io/foundations/design-principles)

### Related Issues & PRs

- **#138** - Shadow Calendar Privacy UI (will use adaptive dialogs)
- **#198** - Back navigation (requires iOS swipe-back support)
- **Sprint 2 UX Review** - Identified platform-adaptive design gap

---

## Usage Statistics (Current State)

**Widget count across codebase:**

| Widget Type | Occurrences | Files | Platform-Adaptive? |
|-------------|-------------|-------|-------------------|
| `ElevatedButton` | 128+ | 33 | ❌ Material-only |
| `OutlinedButton` | ~15 | 12 | ❌ Material-only |
| `TextButton` | ~20 | 18 | ❌ Material-only |
| `TextFormField` | ~15 | 12 | ❌ Material-only |
| `showDialog` | 18 | 13 | ✅ Partially (platform_dialog.dart exists) |
| `showModalBottomSheet` | 17 | 17 | ❌ Material-only |
| Date/Time Pickers | N/A | N/A | ✅ Yes (adaptive_date_time_picker.dart) |
| Segmented Control | 1 | 1 | ✅ Yes (view_mode_toggle.dart) |

**Platform detection usage:**
- 9 files currently use `Platform.isIOS` or `Platform.isAndroid`
- Cupertino widgets used in only 5 files
- No platform-specific theming currently implemented

---

## Definition of Done

- ✅ All adaptive widget classes created and tested
- ✅ Authentication screens fully migrated
- ✅ Profile screen fully migrated
- ✅ Event creation screen fully migrated
- ✅ All dialogs use platform-appropriate styles
- ✅ Widget tests pass on both iOS and Android
- ✅ Manual testing completed on iOS Simulator and Android Emulator
- ✅ No visual regressions in existing screens
- ✅ Code review approved
- ✅ Documentation updated
- ✅ CLAUDE.md updated with adaptive widget patterns
- ✅ App feels native on both iOS and Android
- ✅ Passes iOS HIG and Material Design compliance checks

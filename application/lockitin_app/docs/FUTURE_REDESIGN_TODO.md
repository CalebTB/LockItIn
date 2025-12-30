# Future UX/UI Redesign Todo List

**Created:** December 30, 2025
**Status:** Planning document for systematic UI improvement

---

## Completed Analyses

| Screen | Analysis Doc | Main Issue | Sub-Issues |
|--------|--------------|------------|------------|
| CardCalendarScreen | `HOME_SCREEN_UX_ANALYSIS.md` | #160 | #161-#171 (11) |
| GroupDetailScreen | `GROUP_DETAIL_SCREEN_UX_ANALYSIS.md` | #172 | #173-#179 (7) |
| EventCreationScreen | `EVENT_CREATION_SCREEN_UX_ANALYSIS.md` | #180 | #181-#186 (6) |

---

## Priority 1: Core User Flows (Analyze Next)

These screens are critical to the main user journey and should be analyzed soon.

### 1. FriendsScreen
- **File:** `lib/presentation/screens/friends_screen.dart`
- **Size:** ~22KB (significant)
- **Why:** Core social feature - friend management, requests, search
- **Analyze For:**
  - Friend list layout and search UX
  - Friend request handling flow
  - Add friend interaction pattern
  - Empty states
  - Color system compliance

### 2. ProfileScreen
- **File:** `lib/presentation/screens/profile_screen.dart`
- **Size:** ~18KB
- **Why:** User settings, account management, privacy controls
- **Analyze For:**
  - Settings organization and hierarchy
  - Privacy settings prominence (Shadow Calendar defaults)
  - Account actions (logout, delete)
  - Notification preferences
  - Theme/appearance settings

### 3. EventDetailScreen
- **File:** `lib/presentation/screens/event_detail_screen.dart`
- **Size:** ~16KB
- **Why:** Viewing event details, editing, sharing
- **Analyze For:**
  - Information hierarchy
  - Edit/delete actions placement
  - Privacy indicator visibility
  - Share to group flow
  - Calendar integration status

---

## Priority 2: Authentication Flow

### 4. LoginScreen
- **File:** `lib/presentation/screens/auth/login_screen.dart`
- **Why:** First impression, conversion critical
- **Analyze For:**
  - Form layout and validation
  - Error state handling
  - Social login options (future)
  - "Forgot password" flow
  - Transition to signup

### 5. SignupScreen
- **File:** `lib/presentation/screens/auth/signup_screen.dart`
- **Why:** User acquisition, onboarding start
- **Analyze For:**
  - Progressive form disclosure
  - Password requirements display
  - Terms/privacy acceptance
  - Calendar permission explanation
  - Transition to main app

### 6. SplashScreen
- **File:** `lib/presentation/screens/splash_screen.dart`
- **Size:** ~2.5KB (small)
- **Why:** App launch experience, routing logic
- **Analyze For:**
  - Loading state design
  - Brand presentation
  - Auth state handling
  - Deep link handling (future)

---

## Priority 3: Secondary Screens

### 7. DeviceCalendarScreen
- **File:** `lib/presentation/screens/device_calendar_screen.dart`
- **Size:** ~12KB
- **Why:** Native calendar sync management
- **Analyze For:**
  - Calendar list display
  - Sync status indicators
  - Permission request flow
  - Conflict resolution UI
  - Per-calendar toggle UX

### 8. DayDetailScreen
- **File:** `lib/presentation/screens/day_detail_screen.dart`
- **Size:** ~3KB (small)
- **Why:** Daily agenda view
- **Analyze For:**
  - Event list layout
  - Time slot visualization
  - Quick actions (add event)
  - Empty day state

---

## Priority 4: Deprecation Candidates

### 9. HomeScreen (Feature Menu)
- **File:** `lib/presentation/screens/home_screen.dart`
- **Size:** ~15KB
- **Status:** LIKELY DEPRECATED by CardCalendarScreen redesign
- **Action:** Verify if still needed after bottom tab navigation implemented
- **Note:** CardCalendarScreen redesign (#160) replaces this with tab-based navigation

### 10. CalendarScreen (Original)
- **File:** `lib/presentation/screens/calendar_screen.dart`
- **Size:** ~25KB
- **Status:** May be superseded by CardCalendarScreen
- **Action:** Determine if this is legacy code to remove

---

## Priority 5: Reusable Widgets

These widgets appear across multiple screens and should be analyzed for consistency.

### Bottom Sheets
| Widget | File | Used By |
|--------|------|---------|
| NewEventBottomSheet | `widgets/new_event_bottom_sheet.dart` | CardCalendarScreen |
| GroupsBottomSheet | `widgets/groups_bottom_sheet.dart` | Multiple |
| FriendsBottomSheet | `widgets/friends_bottom_sheet.dart` | FriendsScreen |
| DayEventsBottomSheet | `widgets/day_events_bottom_sheet.dart` | Calendar views |

### Calendar Components
| Widget | File | Notes |
|--------|------|-------|
| MiniCalendarWidget | `widgets/mini_calendar_widget.dart` | Header calendar |
| DayTimelineView | `widgets/day_timeline_view.dart` | Agenda view |
| UpcomingEventCard | `widgets/upcoming_event_card.dart` | Event preview |

### Group Components (Covered in GroupDetailScreen redesign)
| Widget | File | Notes |
|--------|------|-------|
| GroupBestDaysSection | `widgets/group_best_days_section.dart` | Part of #172 |
| GroupMembersSection | `widgets/group_members_section.dart` | Part of #172 |
| GroupTimeFilterChips | `widgets/group_time_filter_chips.dart` | Part of #172 |
| GroupDateRangeFilter | `widgets/group_date_range_filter.dart` | Part of #172 |
| GroupCalendarLegend | `widgets/group_calendar_legend.dart` | Part of #172 |

### Friend Components
| Widget | File | Notes |
|--------|------|-------|
| FriendListTile | `widgets/friend_list_tile.dart` | Friend display |
| FriendRequestTile | `widgets/friend_request_tile.dart` | Request handling |
| FriendSearchDelegate | `widgets/friend_search_delegate.dart` | Search UX |

---

## Priority 6: Theme System

### SunsetCoralTheme (REPLACE)
- **File:** `lib/presentation/theme/sunset_coral_theme.dart`
- **Status:** TO BE REPLACED
- **Action:** Create new theme file with documented colors:
  - Deep Blue: #2563EB (Primary)
  - Purple: #8B5CF6 (Secondary)
  - Coral: #FB923C (Tertiary)
- **Note:** All three redesign analyses identify this as critical

---

## Recommended Analysis Order

```
Week 1-2: FriendsScreen → ProfileScreen
Week 3:   Auth Flow (Login → Signup → Splash)
Week 4:   EventDetailScreen → DeviceCalendarScreen
Week 5:   Widget audit (Bottom Sheets, Calendar Components)
Week 6:   Theme system overhaul
```

---

## Analysis Template

When analyzing each screen, cover:

1. **Color System Compliance** - Hardcoded colors vs theme
2. **Information Hierarchy** - What's most important?
3. **User Flow** - Entry points, exit points, actions
4. **Platform Patterns** - iOS HIG vs Material Design
5. **Accessibility** - VoiceOver/TalkBack, WCAG AA
6. **Empty States** - What happens with no data?
7. **Error States** - How are errors shown?
8. **Loading States** - Skeleton screens, spinners
9. **Consistency** - Matches other redesigned screens?

---

## Notes

- Each analysis should produce a `[SCREEN]_UX_ANALYSIS.md` document
- Each analysis should result in 1 main issue + sub-issues
- Reference existing analyses for consistency
- Use mobile-ux-designer agent for all analyses

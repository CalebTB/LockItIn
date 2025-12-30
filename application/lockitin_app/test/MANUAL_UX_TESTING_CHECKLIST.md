# Manual Testing Checklist - Sprint 2 (Phase 5 & 6)

**Issue:** #28 - v0.2.0 Testing: Sprint 2 Bug Fixes
**Created:** December 29, 2025
**Tester:** _________________________
**Device(s):** _________________________
**App Version:** _________________________

---

## Pre-Test Setup

- [ ] Fresh install of the app (uninstall previous version)
- [ ] Device connected to stable network
- [ ] Test accounts created (at least 2 for friend/group testing)
- [ ] Supabase backend verified running

---

## Section 1: Friend System

### 1.1 Friend Search & Request
| # | Test Case | Expected Result | Pass/Fail | Notes |
|---|-----------|-----------------|-----------|-------|
| 1.1.1 | Search for user by email | Search results appear | [ ] | |
| 1.1.2 | Search for non-existent email | "No users found" message | [ ] | |
| 1.1.3 | Tap on search result | Friend request button visible | [ ] | |
| 1.1.4 | Send friend request | Success toast, button changes to "Request Sent" | [ ] | |
| 1.1.5 | Try to send duplicate request | Prevented or shows existing state | [ ] | |

### 1.2 Friend Requests Tab
| # | Test Case | Expected Result | Pass/Fail | Notes |
|---|-----------|-----------------|-----------|-------|
| 1.2.1 | Switch to "Requests" tab | Tab navigation works | [ ] | |
| 1.2.2 | View pending request | Requester name, avatar, Accept/Decline buttons | [ ] | |
| 1.2.3 | Accept friend request | Moved to Friends tab, success feedback | [ ] | |
| 1.2.4 | Decline friend request | Removed from list, no error | [ ] | |
| 1.2.5 | Pull to refresh | Spinner, list updates | [ ] | |

### 1.3 Friends List
| # | Test Case | Expected Result | Pass/Fail | Notes |
|---|-----------|-----------------|-----------|-------|
| 1.3.1 | View friends list | All accepted friends shown | [ ] | |
| 1.3.2 | Tap on friend | Profile/action sheet appears | [ ] | |
| 1.3.3 | Remove friend | Confirmation dialog, friend removed | [ ] | |
| 1.3.4 | Empty state (no friends) | "No Friends Yet" message | [ ] | |

---

## Section 2: Group Management

### 2.1 Create Group
| # | Test Case | Expected Result | Pass/Fail | Notes |
|---|-----------|-----------------|-----------|-------|
| 2.1.1 | Tap "Create Group" button | Creation dialog/screen appears | [ ] | |
| 2.1.2 | Enter group name | Text field accepts input | [ ] | |
| 2.1.3 | Select emoji | Emoji picker works | [ ] | |
| 2.1.4 | Submit with valid data | Group created, visible immediately (Issue #106) | [ ] | |
| 2.1.5 | Submit with empty name | Validation error shown | [ ] | |

### 2.2 Group Detail View
| # | Test Case | Expected Result | Pass/Fail | Notes |
|---|-----------|-----------------|-----------|-------|
| 2.2.1 | Tap on group in list | Group detail screen opens | [ ] | |
| 2.2.2 | Group header shows | Name, emoji, back button visible | [ ] | |
| 2.2.3 | Tap members icon | Members sheet opens | [ ] | |
| 2.2.4 | View member list | All members with roles shown | [ ] | |

### 2.3 Group Settings (Owner/Co-Owner)
| # | Test Case | Expected Result | Pass/Fail | Notes |
|---|-----------|-----------------|-----------|-------|
| 2.3.1 | Edit group name | Name updates in header | [ ] | |
| 2.3.2 | Change group emoji | Emoji updates in header | [ ] | |
| 2.3.3 | Invite friend to group | Friend receives invite | [ ] | |
| 2.3.4 | Promote member to co-owner | Role updates | [ ] | |
| 2.3.5 | Demote co-owner to member | Role updates | [ ] | |
| 2.3.6 | Remove member | Member removed from list | [ ] | |
| 2.3.7 | Transfer ownership | New owner assigned (atomic) | [ ] | |
| 2.3.8 | Delete group | Group removed, navigates back | [ ] | |

### 2.4 Group Invites
| # | Test Case | Expected Result | Pass/Fail | Notes |
|---|-----------|-----------------|-----------|-------|
| 2.4.1 | View pending invite | Invite appears in invites section | [ ] | |
| 2.4.2 | Accept group invite | Become member, group appears | [ ] | |
| 2.4.3 | Decline group invite | Invite removed | [ ] | |

### 2.5 Leave Group (Non-Owner)
| # | Test Case | Expected Result | Pass/Fail | Notes |
|---|-----------|-----------------|-----------|-------|
| 2.5.1 | Tap "Leave Group" | Confirmation dialog | [ ] | |
| 2.5.2 | Confirm leave | Removed from group, navigates back | [ ] | |

---

## Section 3: Availability Heatmap

### 3.1 Calendar Navigation
| # | Test Case | Expected Result | Pass/Fail | Notes |
|---|-----------|-----------------|-----------|-------|
| 3.1.1 | View current month | Correct month/year displayed | [ ] | |
| 3.1.2 | Swipe left | Next month shown | [ ] | |
| 3.1.3 | Swipe right | Previous month shown | [ ] | |
| 3.1.4 | Tap left arrow | Previous month shown | [ ] | |
| 3.1.5 | Tap right arrow | Next month shown | [ ] | |

### 3.2 Heatmap Grid
| # | Test Case | Expected Result | Pass/Fail | Notes |
|---|-----------|-----------------|-----------|-------|
| 3.2.1 | 42 cells visible (6x7 grid) | Complete month view | [ ] | |
| 3.2.2 | Day of week headers | Sun-Sat labels visible | [ ] | |
| 3.2.3 | Today highlighted | Current day has distinct style | [ ] | |
| 3.2.4 | Colors reflect availability | Green = free, Red = busy | [ ] | |

### 3.3 Time Filters
| # | Test Case | Expected Result | Pass/Fail | Notes |
|---|-----------|-----------------|-----------|-------|
| 3.3.1 | Tap "Morning" chip | Filter applied, heatmap updates | [ ] | |
| 3.3.2 | Tap "Afternoon" chip | Filter applied, heatmap updates | [ ] | |
| 3.3.3 | Tap "Evening" chip | Filter applied, heatmap updates | [ ] | |
| 3.3.4 | Tap "Custom" chip | Custom time picker opens | [ ] | |
| 3.3.5 | Multiple filters selected | Combined filter works | [ ] | |
| 3.3.6 | Deselect all filters | Shows all-day availability | [ ] | |

### 3.4 Day Detail Sheet
| # | Test Case | Expected Result | Pass/Fail | Notes |
|---|-----------|-----------------|-----------|-------|
| 3.4.1 | Tap on calendar day | Day detail sheet opens | [ ] | |
| 3.4.2 | Sheet shows member availability | Who's free/busy listed | [ ] | |
| 3.4.3 | BusyOnly shows as "Busy" | No event title revealed | [ ] | |
| 3.4.4 | SharedWithName shows title | Event title visible | [ ] | |
| 3.4.5 | Swipe down to dismiss | Sheet closes | [ ] | |

### 3.5 Best Days Section
| # | Test Case | Expected Result | Pass/Fail | Notes |
|---|-----------|-----------------|-----------|-------|
| 3.5.1 | Best days displayed | Top 4 future days shown | [ ] | |
| 3.5.2 | Tap on best day | Day detail sheet opens | [ ] | |
| 3.5.3 | Shows availability count | "X/Y members free" | [ ] | |

---

## Section 4: Privacy Validation (Critical)

### 4.1 Event Visibility
| # | Test Case | Expected Result | Pass/Fail | Notes |
|---|-----------|-----------------|-----------|-------|
| 4.1.1 | Create Private event | NOT visible to group members | [ ] | |
| 4.1.2 | Create BusyOnly event | Shows as "Busy" to group, no title | [ ] | |
| 4.1.3 | Create SharedWithName event | Title visible to group members | [ ] | |
| 4.1.4 | Change Private → BusyOnly | Now visible in group heatmap | [ ] | |
| 4.1.5 | Change BusyOnly → Private | Removed from group heatmap | [ ] | |

### 4.2 Group Isolation
| # | Test Case | Expected Result | Pass/Fail | Notes |
|---|-----------|-----------------|-----------|-------|
| 4.2.1 | Non-member cannot see group | 404 or access denied | [ ] | |
| 4.2.2 | Non-member cannot see member events | RLS blocks access | [ ] | |

---

## Section 5: Edge Cases

### 5.1 Text/Layout
| # | Test Case | Expected Result | Pass/Fail | Notes |
|---|-----------|-----------------|-----------|-------|
| 5.1.1 | Long group name (20+ chars) | Truncated with ellipsis | [ ] | |
| 5.1.2 | Long friend name | Truncated appropriately | [ ] | |
| 5.1.3 | Empty groups list | "No groups yet" message | [ ] | |
| 5.1.4 | Large member count (10+) | Scrollable member list | [ ] | |

### 5.2 Loading States
| # | Test Case | Expected Result | Pass/Fail | Notes |
|---|-----------|-----------------|-----------|-------|
| 5.2.1 | Initial load | Spinner shown | [ ] | |
| 5.2.2 | Pull-to-refresh | Refresh indicator, data reloads | [ ] | |
| 5.2.3 | Heatmap loading | Cell spinners or skeleton | [ ] | |

### 5.3 Error Handling
| # | Test Case | Expected Result | Pass/Fail | Notes |
|---|-----------|-----------------|-----------|-------|
| 5.3.1 | Network failure | Error banner with retry | [ ] | |
| 5.3.2 | Retry button tap | Attempts to reload | [ ] | |
| 5.3.3 | Invalid operation | User-friendly error message | [ ] | |

---

## Section 6: Platform-Specific (iOS)

| # | Test Case | Expected Result | Pass/Fail | Notes |
|---|-----------|-----------------|-----------|-------|
| 6.1 | Swipe back gesture | Navigates to previous screen | [ ] | |
| 6.2 | Haptic feedback on accept/decline | Tactile feedback | [ ] | |
| 6.3 | Safe area respected | Content not under notch | [ ] | |
| 6.4 | Tab bar height | 50pt + safe area | [ ] | |
| 6.5 | SF Symbols icons | Native iOS icons | [ ] | |

---

## Section 7: Platform-Specific (Android)

| # | Test Case | Expected Result | Pass/Fail | Notes |
|---|-----------|-----------------|-----------|-------|
| 7.1 | System back button | Navigates correctly | [ ] | |
| 7.2 | Material Design elements | Native Android feel | [ ] | |
| 7.3 | Status bar theming | Matches app theme | [ ] | |
| 7.4 | Tab bar height | 56dp | [ ] | |
| 7.5 | Material Icons | Native Android icons | [ ] | |

---

## Section 8: Accessibility

| # | Test Case | Expected Result | Pass/Fail | Notes |
|---|-----------|-----------------|-----------|-------|
| 8.1 | VoiceOver/TalkBack reads elements | All interactive elements labeled | [ ] | |
| 8.2 | Heatmap cells have semantic labels | "Monday January 15, 5 of 8 members free" | [ ] | |
| 8.3 | Touch targets >= 44pt (iOS) | Easy to tap | [ ] | |
| 8.4 | Touch targets >= 48dp (Android) | Easy to tap | [ ] | |
| 8.5 | Dynamic Type (iOS) | Text scales with system | [ ] | |
| 8.6 | Font scaling (Android) | Text scales with system | [ ] | |
| 8.7 | Color contrast (4.5:1 min) | WCAG AA compliant | [ ] | |
| 8.8 | Focus order logical | Tab order makes sense | [ ] | |

---

## Section 9: Logout Flow (Issue #130)

| # | Test Case | Expected Result | Pass/Fail | Notes |
|---|-----------|-----------------|-----------|-------|
| 9.1 | Logout clears all state | No data from previous user | [ ] | |
| 9.2 | Login with different user | New user's data loads | [ ] | |
| 9.3 | Groups list is fresh | Previous user's groups not visible | [ ] | |
| 9.4 | Friends list is fresh | Previous user's friends not visible | [ ] | |

---

## Section 10: Performance Testing (Phase 6)

### 10.1 Query Performance
| # | Test Case | Target | Actual | Pass/Fail | Notes |
|---|-----------|--------|--------|-----------|-------|
| 10.1.1 | `getUserGroups()` query time | < 50ms | ___ms | [ ] | Use DevTools |
| 10.1.2 | `getGroupMembers()` query time | < 50ms | ___ms | [ ] | |
| 10.1.3 | `get_group_shadow_calendar()` RPC | < 100ms | ___ms | [ ] | |
| 10.1.4 | Friend search query | < 100ms | ___ms | [ ] | |

### 10.2 UI Rendering Performance
| # | Test Case | Target | Actual | Pass/Fail | Notes |
|---|-----------|--------|--------|-----------|-------|
| 10.2.1 | Heatmap render (42 cells) | < 100ms | ___ms | [ ] | First load |
| 10.2.2 | Heatmap month swipe | < 50ms | ___ms | [ ] | Smooth 60fps |
| 10.2.3 | Day detail sheet open | < 100ms | ___ms | [ ] | |
| 10.2.4 | Groups list render (10+ groups) | < 100ms | ___ms | [ ] | |
| 10.2.5 | Friends list render (20+ friends) | < 100ms | ___ms | [ ] | |

### 10.3 Cache Performance (Issue #100)
| # | Test Case | Expected Result | Pass/Fail | Notes |
|---|-----------|-----------------|-----------|-------|
| 10.3.1 | Availability cache hit on rebuild | 100% cache hit rate | [ ] | Check logs |
| 10.3.2 | Cache invalidation on filter change | Cache clears, recalculates | [ ] | |
| 10.3.3 | Cache invalidation on event change | Cache clears for affected days | [ ] | |
| 10.3.4 | Event indicators cache per month | Cached on first load | [ ] | |

### 10.4 Real-Time Performance
| # | Test Case | Target | Actual | Pass/Fail | Notes |
|---|-----------|--------|--------|-----------|-------|
| 10.4.1 | WebSocket subscription latency | < 500ms | ___ms | [ ] | Vote update |
| 10.4.2 | Shadow calendar sync after event change | < 100ms | ___ms | [ ] | |
| 10.4.3 | Group member list real-time update | < 500ms | ___ms | [ ] | |

### 10.5 Optimization Verification (Issues #95, #96, #100)
| # | Test Case | Expected Result | Pass/Fail | Notes |
|---|-----------|-----------------|-----------|-------|
| 10.5.1 | Issue #95: Single notifyListeners() | No duplicate rebuilds | [ ] | Check DevTools |
| 10.5.2 | Issue #96: Single query for groups+counts | 1 RPC call, not N+1 | [ ] | Check network |
| 10.5.3 | Issue #100: Availability cache working | No recalculation on scroll | [ ] | |

### 10.6 Memory & Battery
| # | Test Case | Expected Result | Pass/Fail | Notes |
|---|-----------|-----------------|-----------|-------|
| 10.6.1 | No memory leaks on navigation | Memory stable | [ ] | Use profiler |
| 10.6.2 | WebSocket cleanup on screen exit | Subscriptions closed | [ ] | |
| 10.6.3 | Background sync battery impact | Minimal drain | [ ] | 15min sync |

---

## Test Summary

| Section | Total | Passed | Failed | Skipped |
|---------|-------|--------|--------|---------|
| 1. Friend System | 14 | | | |
| 2. Group Management | 20 | | | |
| 3. Availability Heatmap | 17 | | | |
| 4. Privacy Validation | 7 | | | |
| 5. Edge Cases | 8 | | | |
| 6. Platform (iOS) | 5 | | | |
| 7. Platform (Android) | 5 | | | |
| 8. Accessibility | 8 | | | |
| 9. Logout Flow | 4 | | | |
| 10. Performance (Phase 6) | 20 | | | |
| **TOTAL** | **108** | | | |

---

## Critical Bugs Found

| # | Description | Severity | Steps to Reproduce |
|---|-------------|----------|-------------------|
| 1 | | | |
| 2 | | | |
| 3 | | | |

---

## Non-Critical Issues

| # | Description | Priority | Notes |
|---|-------------|----------|-------|
| 1 | | | |
| 2 | | | |
| 3 | | | |

---

## Sign-off

**Testing Complete:** [ ] Yes [ ] No

**Overall Status:** [ ] Pass [ ] Fail with Critical Bugs [ ] Fail with Minor Issues

**Tester Signature:** _________________________

**Date:** _________________________

---

*Sprint 2 Testing Plan - Issue #28*

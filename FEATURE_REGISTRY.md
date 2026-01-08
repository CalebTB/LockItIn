# LockItIn Feature Registry

**Last Updated:** January 7, 2026

**Purpose:** Single source of truth for all features (implemented, in-progress, backlog). Prevents duplicate issues and tracks completion status across the entire roadmap.

---

## Status Legend

- ✅ **Complete**: Merged to main, shipped
- 🚧 **In Progress**: Assigned to current sprint, actively being developed
- 📦 **Backlog**: Approved, waiting for capacity/sprint assignment
- 💡 **Proposed**: Needs evaluation by Feature Values Advisor + Feature Orchestrator
- 🚫 **Rejected**: Not aligned with roadmap or values

---

## TIER 1: Absolute Must-Haves (MVP)

Cannot launch without these. Target: April 30, 2026

| Feature | Status | GitHub Issue(s) | Sprint | Version | Notes |
|---------|--------|-----------------|--------|---------|-------|
| **1. Personal Calendar Foundation** | ✅ Complete | #1-14 | Sprint 1 | v0.1.0 | EventKit/CalendarContract sync |
| - Apple Calendar sync (read) | ✅ Complete | #8 | Sprint 1 | v0.1.0 | EventKit integration |
| - Display events in app | ✅ Complete | #9 | Sprint 1 | v0.1.0 | Calendar grid view |
| - Event detail view | ✅ Complete | #10 | Sprint 1 | v0.1.0 | Full event information |
| - Create/edit/delete events | ✅ Complete | #11-13 | Sprint 1 | v0.1.0 | Bidirectional sync |
| - Calendar views (agenda/week/month) | ✅ Complete | #164-166 | Sprint 3 | v0.3.0 | View switcher, all views |
| **2. Shadow Calendar System** | ✅ Complete | #15-30 | Sprint 2 | v0.2.0 | RLS-enforced privacy |
| - Privacy controls (Private/Busy/Shared) | ✅ Complete | #22 | Sprint 2 | v0.2.0 | Per-event settings |
| - Groups see busy blocks without titles | ✅ Complete | #23 | Sprint 2 | v0.2.0 | Shadow calendar RLS |
| **3. Friend System** | ✅ Complete | #15-16, #31-45 | Sprint 2 | v0.2.0 | Request/accept/decline |
| - Add friends by phone/email | ✅ Complete | #15 | Sprint 2 | v0.2.0 | Database + API |
| - Accept/decline requests | ✅ Complete | #16 | Sprint 2 | v0.2.0 | Friend system UI |
| - Create friend groups | ✅ Complete | #17-19 | Sprint 2 | v0.2.0 | Group creation/management |
| - Choose which groups see availability | ✅ Complete | #20-21 | Sprint 2 | v0.2.0 | Group permissions |
| **4. Group Availability Heatmap** | ✅ Complete | #24, #46-60, #175 | Sprint 2-3 | v0.2.0 | Visual killer feature |
| - Visual free/busy display | ✅ Complete | #24 | Sprint 2 | v0.2.0 | Heatmap UI |
| - Privacy-preserving (counts, not names) | ✅ Complete | #24 | Sprint 2 | v0.2.0 | Tap to reveal |
| - Filter by time range | ✅ Complete | #175 | Sprint 3 | v0.3.0 | Redesigned in Sprint 3 |
| **5. Event Proposals with Voting** | ✅ Complete | #29-43, #61-75 | Sprint 3 | v0.3.0 | Core coordination feature |
| - Create proposal with time options | ✅ Complete | #31 | Sprint 3 | v0.3.0 | Proposal creation UI |
| - Send to group | ✅ Complete | #32 | Sprint 3 | v0.3.0 | Proposal list view |
| - Vote (Can/Maybe/Can't) | ✅ Complete | #34 | Sprint 3 | v0.3.0 | Voting UI |
| - Real-time vote tallies | ✅ Complete | #36 | Sprint 3 | v0.3.0 | WebSocket updates |
| - Confirm and auto-add to calendars | ✅ Complete | #39 | Sprint 3 | v0.3.0 | Event creation from votes |
| **6. Basic Notifications** | 🚧 In Progress | #37-38, #85-92 | Sprint 5 | v0.5.0 | APNs + FCM integration |
| - New proposal notification | 🚧 Sprint 5 | #37 | Sprint 5 | v0.5.0 | Push notification setup |
| - Voting deadline reminder | 🚧 Sprint 5 | #195 | Sprint 5 | v0.5.0 | Expiration reminders |
| - Event confirmed notification | 🚧 Sprint 5 | #38 | Sprint 5 | v0.5.0 | Confirmation alerts |
| - Event starting soon reminder | 🚧 Sprint 5 | #38 | Sprint 5 | v0.5.0 | Pre-event notifications |
| **7. Surprise Birthday Party Template** | 🚧 In Progress | #68-70 | Sprint 4 | v0.4.0 | Privacy-first special event |
| - Create in "Surprise Mode" | 🚧 Sprint 4 | #68 | Sprint 4 | v0.4.0 | Database schema |
| - Birthday person auto-excluded | 🚧 Sprint 4 | #69 | Sprint 4 | v0.4.0 | UI implementation |
| - Decoy event shown to target | 🚧 Sprint 4 | #70 | Sprint 4 | v0.4.0 | Privacy logic |
| - Task assignments | 🚧 Sprint 4 | #70 | Sprint 4 | v0.4.0 | Coordin task tracking |

---

## TIER 2: Strong Differentiators

Include if time permits - makes app noticeably better than competitors

| Feature | Status | GitHub Issue(s) | Sprint | Version | Notes |
|---------|--------|-----------------|--------|---------|-------|
| **8. Smart Time Suggestions** | 📦 Backlog | #26-27 | Post-MVP | v1.0.0 | "Find best times" algorithm |
| - Analyze group availability | 📦 v1.0.0 | #26 | - | v1.0.0 | Algorithm design |
| - Suggest top 3 slots | 📦 v1.0.0 | #27 | - | v1.0.0 | UI for suggestions |
| - Show availability count | 📦 v1.0.0 | #27 | - | v1.0.0 | "7/8 people free" display |
| **9. Travel Time + Departure Alerts** | 🚧 In Progress | #71-74 | Sprint 4 | v0.4.0 | MapKit integration |
| - Add location to events | 🚧 Sprint 4 | #71 | Sprint 4 | v0.4.0 | Location picker |
| - Calculate travel time | 🚧 Sprint 4 | #72 | Sprint 4 | v0.4.0 | Google Maps API |
| - "Leave by" time display | 🚧 Sprint 4 | #73 | Sprint 4 | v0.4.0 | Travel time calc |
| - "Time to leave" notification | 🚧 Sprint 4 | #74 | Sprint 4 | v0.4.0 | Real-time traffic alerts |
| **10. Potluck/Friendsgiving Template** | 🚧 In Progress | #75-77 | Sprint 4 | v0.4.0 | Dish coordination |
| - Host assignment | 🚧 Sprint 4 | #75 | Sprint 4 | v0.4.0 | Template framework |
| - Dish signup categories | 🚧 Sprint 4 | #76 | Sprint 4 | v0.4.0 | Category system |
| - Dietary restrictions | 🚧 Sprint 4 | #77 | Sprint 4 | v0.4.0 | Restrictions display |
| - Duplicate prevention | 🚧 Sprint 4 | #77 | Sprint 4 | v0.4.0 | Warning system |

---

## TIER 3: Post-Launch Features (v1.0.0 - v1.1.0)

Save for updates after validating core concept

### v1.0.0 Features (Launch+)

| Feature | Status | GitHub Issue | Priority | Notes |
|---------|--------|--------------|----------|-------|
| 24-hour timeline view | 💡 Proposed | #227 | Medium | UI enhancement for day view |
| Show group name for proposal events | 💡 Proposed | #226 | Medium | Calendar display clarity |
| Forgot password flow | 💡 Proposed | #199 | Medium | Auth improvement |
| "If Needed" vote option | 💡 Proposed | #197 | Low | Additional voting flexibility |
| Groups: Description/bio fields | 💡 Proposed | #194 | Low | Group customization |
| Event search and filtering | 💡 Proposed | #187 | High | Calendar usability |
| In-app notification center | 💡 Proposed | #189 | Medium | Centralized notifications |
| Enable editing active proposals | 💡 Proposed | #190 | Medium | Flexibility improvement |
| Proposal templates library | 💡 Proposed | #185 | Medium | Reusable proposal types |
| Live arrival status | 📦 Backlog | - | Low | "I'm on my way" feature |
| Conflict detection | 📦 Backlog | - | Medium | Alert when calendar changes create conflicts |
| Group insights/analytics | 📦 Backlog | - | Low | Dashboard of group activity |
| Recurring events | 📦 Backlog | - | Medium | Weekly/monthly repeat |

### v1.1.0 Features (Future Updates)

| Feature | Status | GitHub Issue | Priority | Notes |
|---------|--------|--------------|----------|-------|
| Week number display | 💡 Proposed | #196 | Low | Calendar header enhancement |
| Drag-and-drop event rescheduling | 💡 Proposed | #193 | Medium | Advanced calendar interaction |
| Year view calendar | 💡 Proposed | #184 | Low | Long-range planning |
| Social login (Google, Apple) | 💡 Proposed | #183 | Medium | Onboarding ease |
| Groups: Privacy settings (public/private) | 💡 Proposed | #188 | Low | Group access control |
| Multi-calendar color customization | 💡 Proposed | #191 | Low | Visual organization |
| Riverpod 2.x migration | 💡 Proposed | #222 | Medium | Performance: State management upgrade |
| Flutter widget optimizations | 💡 Proposed | #221 | High | Performance: Build time reduction |
| Memory profiling | 💡 Proposed | #225 | Low | Performance: Memory management |
| Stale-while-revalidate caching | 💡 Proposed | #224 | Medium | Backend: Offline experience |
| Enhanced RLS and indexing | 💡 Proposed | #223 | Medium | Backend: Query optimization |
| Emoji support for events | 🚧 Sprint 5 | #200 | Low | User delight feature |
| Multi-select time slots from timeline | 🚧 Sprint 5 | #201 | Medium | Proposals: UI improvement |

---

## TIER 4: Retention & Engagement (v1.2+)

Features that build long-term loyalty and keep users coming back

| Feature | Status | Version | Notes |
|---------|--------|---------|-------|
| BeReal-style event capture | 📦 Backlog | v1.2 | Photo prompt after events |
| Year-end Wrapped | 📦 Backlog | v1.2 | "You attended 47 events" recap |
| "Haven't seen this group" nudges | 📦 Backlog | v1.2 | Gentle reconnection prompts |
| Real-time departure alerts | 📦 Backlog | v1.2 | Live traffic-based notifications |
| Spontaneous "Who's Free" check | 📦 Backlog | v1.2 | Quick heatmap for tonight |

---

## Seasonal Event Templates (v1.1 - v1.5)

Release schedule aligned with seasonal events

### Summer Update (v1.1 - June 2026)

| Template | Status | Version | Notes |
|----------|--------|---------|-------|
| 🏖️ Beach Day / Pool Party | 📦 Backlog | v1.1 | Weather monitoring, outdoor gear |
| 🎆 4th of July BBQ | 📦 Backlog | v1.1 | Grill master, food signups |
| ✈️ Group Trip / Weekend Getaway | 📦 Backlog | v1.1 | Multi-day itinerary |

### Fall Update (v1.2 - October 2026)

| Template | Status | Version | Notes |
|----------|--------|---------|-------|
| 🎃 Halloween Party | 📦 Backlog | v1.2 | Costume theme voting |
| 🏈 Game Watch Party | 📦 Backlog | v1.2 | Team allegiance, snack assignments |
| 🍂 Oktoberfest / Fall Festival | 📦 Backlog | v1.2 | Activity voting |

### Holiday Update (v1.3 - November 2026)

| Template | Status | Version | Notes |
|----------|--------|---------|-------|
| 🦃 Enhanced Friendsgiving | 📦 Backlog | v1.3 | Seating arrangements, gratitude prompts |
| 🎅 Secret Santa | 📦 Backlog | v1.3 | Auto-assign recipients, wishlist |
| 🕎 Hanukkah Party | 📦 Backlog | v1.3 | 8-night tracking |
| 🎄 Holiday Party | 📦 Backlog | v1.3 | Ugly sweater contest, white elephant |

### New Year Update (v1.4 - December 2026)

| Template | Status | Version | Notes |
|----------|--------|---------|-------|
| 🎊 New Year's Eve Party | 📦 Backlog | v1.4 | Countdown timer, resolution sharing |
| ❄️ Ski Trip / Winter Getaway | 📦 Backlog | v1.4 | Ski level tracking, equipment rental |
| 💝 Valentine's Day Group Dinner | 📦 Backlog | v1.4 | Singles vs couples coordination |

### Spring Update (v1.5 - March 2027)

| Template | Status | Version | Notes |
|----------|--------|---------|-------|
| 🌸 Spring Break Trip | 📦 Backlog | v1.5 | Week-long itinerary |
| 🥚 Easter Brunch / Egg Hunt | 📦 Backlog | v1.5 | Egg hunt organization |
| 🎓 Graduation Party | 📦 Backlog | v1.5 | Photo slideshow, gift pooling |
| 🌮 Cinco de Mayo Party | 📦 Backlog | v1.5 | Food signups, margarita ingredients |

---

## Sprint 4 Features (Feb 6-19, 2026)

Current sprint in progress

| Feature | Status | GitHub Issue | Effort | Notes |
|---------|--------|--------------|--------|-------|
| **Timezone Support Epic** | 🚧 In Progress | #211 | XL | Critical for cross-timezone users |
| - Core timezone utilities | 🚧 Sprint 4 | #204 | M | UTC conversion helpers |
| - Data model updates | 🚧 Sprint 4 | #205 | M | Store events in UTC |
| - Service layer updates | 🚧 Sprint 4 | #206 | M | DateTime.now() → UTC |
| - UI display layer fixes | 🚧 Sprint 4 | #207 | M | DateFormat with timezones |
| - Date picker updates | 🚧 Sprint 4 | #208 | M | Convert selections to UTC |
| - Native calendar sync review | 🚧 Sprint 4 | #209 | M | EventKit/CalendarContract timezone handling |
| - Integration testing | 🚧 Sprint 4 | #210 | S | Manual validation |
| **Templates Framework** | 🚧 Sprint 4 | #67-70, #75-77 | L | Special event templates |
| **Travel Features** | 🚧 Sprint 4 | #71-74 | M | Location + departure alerts |

---

## Sprint 5 Features (Feb 20-26, 2026)

Final MVP sprint - polish and notifications

| Feature | Status | GitHub Issue | Effort | Notes |
|---------|--------|--------------|--------|-------|
| Push Notifications | 🚧 Sprint 5 | #85-92 | L | APNs + FCM |
| Proposal expiration reminders | 🚧 Sprint 5 | #195 | S | Voting deadlines |
| Emoji support for events | 🚧 Sprint 5 | #200 | S | User delight |
| Multi-select time slots | 🚧 Sprint 5 | #201 | M | Proposal creation UX |
| MVP Polish | 🚧 Sprint 5 | - | M | Final bug fixes |

---

## Explicitly NOT in Roadmap

Features considered but rejected or deferred to Year 2+

### Year 1 (Post-MVP):
- ✅ Android app → CHANGED: Now using Flutter (cross-platform from start)
- Google Calendar / Outlook integration → v1.0.0+
- Recurring availability patterns → v1.1.0+
- Calendar widgets → v1.1.0+

### Year 2+ (Growth Phase):
- Public event discovery (concerts, shows, restaurants)
- Business-posted events (venues can post events)
- Event sharing to friend groups (vote on public events)
- Ticketing integration
- Advanced event discovery features

### Rejected Features:
- Real-time presence & micro-location → Conflicts with privacy-first positioning
- Calendar gamification → Conflicts with "calm, not chaotic" philosophy
- Habit tracking integration → Out of scope, different product category
- Task ↔ calendar integration → Out of scope, different product category

---

## Feature Request Process

**For New Feature Ideas:**

1. Check this registry first - is it already listed?
2. If duplicate, comment on existing issue
3. If new, create issue with template: `.github/ISSUE_TEMPLATE/new-feature-request.md`
4. Apply `status: proposed` label
5. Feature Values Advisor + Feature Orchestrator will evaluate
6. Approved features get `status: approved` + `parking-lot: approved` labels
7. Monthly grooming session assigns to sprint or keeps in backlog

**For Existing Features:**

- ✅ Complete: Feature shipped, merged to main
- 🚧 In Progress: Actively being developed in current sprint
- 📦 Backlog: Approved and ready, waiting for sprint assignment
- 💡 Proposed: Needs agent evaluation (Feature Values Advisor + Feature Orchestrator)
- 🚫 Rejected: Not aligned with roadmap, values, or timeline

---

## Quick Links

- **Feature Philosophy:** `/lockitin_docs/lockitin-features.md`
- **Roadmap Timeline:** `/lockitin_docs/lockitin-roadmap-development.md`
- **Versioning Scheme:** `/lockitin_docs/versioning-and-issue-categories.md`
- **Feature Values Advisor:** `/.claude/agents/feature-values-advisor.md`
- **Feature Orchestrator:** `/.claude/agents/feature-orchestrator.md`
- **Feature Intake Process:** `/plans/new-feature-intake-process.md`

---

## Maintenance

**Update this file when:**
- New feature is proposed (add row with 💡 status)
- Feature is approved (update to 📦 status + add GitHub issue link)
- Sprint begins (update to 🚧 status + add sprint number)
- Feature completes (update to ✅ status)
- Feature is rejected (update to 🚫 status + add reason)

**Monthly Review (First Monday):**
- Verify all GitHub issues are cross-referenced
- Archive low-confidence parking-lot items
- Merge duplicate features
- Update sprint assignments based on capacity

---

**Last Verified:** January 7, 2026
**Next Review:** February 3, 2026 (First Monday of month)

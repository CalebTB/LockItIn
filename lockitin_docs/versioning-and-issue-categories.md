# Versioning & Issue Categorization Proposal

## Product Versioning Strategy

### Semantic Versioning (SemVer)
Use **MAJOR.MINOR.PATCH** format: `v1.2.3`

| Component | When to Increment | Example |
|-----------|------------------|---------|
| **MAJOR** | Breaking changes, major redesigns, or annual releases | v1.0.0 → v2.0.0 |
| **MINOR** | New features, significant improvements | v1.0.0 → v1.1.0 |
| **PATCH** | Bug fixes, small improvements | v1.0.0 → v1.0.1 |

### Version Milestones

```
v0.1.0  - Alpha (internal testing only)
v0.5.0  - Beta (TestFlight/Internal Testing)
v0.9.0  - Release Candidate
v1.0.0  - Public Launch (App Store)
v1.1.0  - First feature update
v1.2.0  - Second feature update
v2.0.0  - Major redesign or breaking change
```

### Pre-Release Tags

For development builds:
```
v1.0.0-alpha.1   - First alpha build
v1.0.0-alpha.2   - Second alpha build
v1.0.0-beta.1    - First beta build
v1.0.0-beta.2    - Second beta build
v1.0.0-rc.1      - Release candidate 1
v1.0.0           - Final release
```

---

## Issue Categorization System

### Category Labels (by Type)

| Label | Color | Description |
|-------|-------|-------------|
| `type: feature` | Purple (#a371f7) | New functionality |
| `type: bug` | Red (#d73a4a) | Something broken |
| `type: task` | Blue (#0075ca) | General work item |
| `type: design` | Pink (#e91e63) | UI/UX design work |
| `type: refactor` | Yellow (#fbca04) | Code improvement |
| `type: docs` | Green (#0e8a16) | Documentation |
| `type: test` | Orange (#f9a825) | Testing related |
| `type: chore` | Gray (#cccccc) | Maintenance tasks |

### Category Labels (by Area)

| Label | Color | Description |
|-------|-------|-------------|
| `area: auth` | Blue (#1d76db) | Authentication |
| `area: calendar` | Teal (#008672) | Calendar views/sync |
| `area: groups` | Orange (#ff9800) | Groups & members |
| `area: proposals` | Yellow (#ffc107) | Event proposals/voting |
| `area: notifications` | Red (#d73a4a) | Push/local notifications |
| `area: templates` | Purple (#9c27b0) | Special event templates |
| `area: location` | Green (#4caf50) | Location & travel |
| `area: premium` | Gold (#ffd700) | Premium features |
| `area: ui` | Light Blue (#0075ca) | General UI work |
| `area: backend` | Violet (#7057ff) | Backend/Supabase |

### Priority Labels

| Label | Color | Description |
|-------|-------|-------------|
| `priority: critical` | Dark Red (#b60205) | Must be done ASAP |
| `priority: high` | Orange (#ff9800) | Important, do soon |
| `priority: medium` | Yellow (#ffc107) | Normal priority |
| `priority: low` | Gray (#cccccc) | Nice to have |

### Sprint Labels

| Label | Color | Description |
|-------|-------|-------------|
| `sprint: 1` | Light Blue (#c5def5) | Foundation & Auth |
| `sprint: 2` | Light Purple (#d4c5f9) | Groups & Shadow Calendar |
| `sprint: 3` | Light Yellow (#fef2c0) | Proposals & Voting |
| `sprint: 4` | Light Blue (#bfd4f2) | Templates & Travel |
| `sprint: 5` | Light Pink (#f9d0c4) | Polish & Completion |

---

## Proposed GitHub Project Structure

### Milestones (by Sprint)

```
├── Sprint 1: Foundation & Auth (Dec 26 - Jan 8)
├── Sprint 2: Groups & Shadow Calendar (Jan 9 - Jan 22)
├── Sprint 3: Proposals & Voting (Jan 23 - Feb 5)
├── Sprint 4: Templates & Travel (Feb 6 - Feb 19)
├── Sprint 5: Polish & Completion (Feb 20 - Feb 26)
├── Beta Testing (Feb 27 - Apr 8)
└── Launch (Apr 9 - Apr 30)
```

### Project Board Columns

```
📋 Backlog     → Issues not yet scheduled
📅 Sprint     → Current sprint issues
🔄 In Progress → Actively being worked
👀 Review     → PR submitted, awaiting review
✅ Done       → Completed this sprint
```

---

## Version Release Schedule

### MVP Development (v0.x)

| Version | Date | Content |
|---------|------|---------|
| v0.1.0 | Jan 8 | Sprint 1 complete (Auth + Calendar) |
| v0.2.0 | Jan 22 | Sprint 2 complete (Groups + Shadow Calendar) |
| v0.3.0 | Feb 5 | Sprint 3 complete (Proposals + Voting) |
| v0.4.0 | Feb 19 | Sprint 4 complete (Templates + Travel) |
| v0.5.0-beta.1 | Feb 26 | MVP complete, first beta |

### Beta Testing (v0.5.x - v0.9.x)

| Version | Date | Content |
|---------|------|---------|
| v0.5.0-beta.1 | Feb 27 | Alpha testing (5-10 friends) |
| v0.6.0-beta.1 | Mar 6 | Closed beta (50-100 testers) |
| v0.7.0-beta.1 | Mar 20 | Bug fixes from feedback |
| v0.8.0-beta.1 | Mar 27 | Public beta (TestFlight public) |
| v0.9.0-rc.1 | Apr 1 | Release candidate |

### Launch (v1.x)

| Version | Date | Content |
|---------|------|---------|
| v1.0.0 | Apr 9-15 | App Store launch |
| v1.0.1 | Apr 20 | Bug fixes from launch |
| v1.1.0 | May | First feature update |

---

## Issue Naming Convention

### Format
```
[version] - [Category]: [Title]
```

### Categories
- **Auth** - Authentication & session management
- **Calendar** - Calendar views, sync, events
- **Groups** - Groups, friends, memberships
- **Proposals** - Event proposals & voting
- **Notifications** - Push & local notifications
- **Templates** - Special event templates (Surprise Birthday, Potluck)
- **Location** - Maps, travel time, directions
- **Premium** - Premium features & payments
- **UI** - General UI polish & design
- **Backend** - Database, API, Supabase
- **Settings** - User preferences & settings
- **Testing** - Testing & QA tasks
- **Launch** - Launch prep & onboarding

### Examples
```
v0.1.0 - Auth: Login & Signup UI
v0.1.0 - Calendar: Basic Grid View
v0.2.0 - Groups: Backend Database
v0.2.0 - Groups: List UI
v0.3.0 - Proposals: Voting API Backend
v0.3.0 - Proposals: Real-time Updates
v0.4.0 - Templates: Surprise Birthday Database
v0.4.0 - Location: MapKit Integration
v0.5.0 - UI: Calendar Polish
v0.5.0 - Premium: Stripe Integration
v1.0.1 - Bug: Calendar sync fails on iOS 17
v1.1.0 - Feature: Dark mode support
```

---

## Complete Issue List by Version

### v0.1.0 - Foundation & Auth (Sprint 1)

| # | Title |
|---|-------|
| 2 | v0.1.0 - Backend: MVVM Architecture & Supabase Setup |
| 3 | v0.1.0 - Auth: Login & Signup UI |
| 4 | v0.1.0 - Auth: Supabase Authentication Flows |
| 5 | v0.1.0 - Auth: Session Persistence |
| 6 | v0.1.0 - UI: Profile View & Editing |
| 7 | v0.1.0 - Calendar: Basic Grid View |
| 8 | v0.1.0 - Review: Sprint 1 Week 1 |
| 9 | v0.1.0 - Calendar: Platform Channel Integration |
| 10 | v0.1.0 - Calendar: Event Indicators |
| 11 | v0.1.0 - Calendar: Event Detail View |
| 12 | v0.1.0 - Calendar: Event Creation UI |
| 13 | v0.1.0 - Calendar: Event Creation & Sync |
| 14 | v0.1.0 - Calendar: Edit & Delete Operations |
| 15 | v0.1.0 - Testing: Sprint 1 Final Review |

### v0.2.0 - Groups & Shadow Calendar (Sprint 2)

| # | Title |
|---|-------|
| 16 | v0.2.0 - Groups: Friend System Database |
| 17 | v0.2.0 - Groups: Friend System UI |
| 18 | v0.2.0 - Groups: Backend Database |
| 19 | v0.2.0 - Groups: List UI |
| 20 | v0.2.0 - Groups: Detail View |
| 21 | v0.2.0 - Groups: Permissions & Roles |
| 22 | v0.2.0 - Review: Sprint 2 Week 3 |
| 23 | v0.2.0 - Calendar: Shadow Calendar Backend |
| 24 | v0.2.0 - Groups: Availability Algorithm |
| 25 | v0.2.0 - Groups: Availability Heatmap UI |
| 26 | v0.2.0 - Groups: Smart Time Suggestions Algorithm |
| 27 | v0.2.0 - Groups: Smart Time Suggestions UI |
| 28 | v0.2.0 - Testing: Sprint 2 Bug Fixes |
| 29 | v0.2.0 - Review: Sprint 2 Final Demo |

### v0.3.0 - Proposals & Voting (Sprint 3)

| # | Title |
|---|-------|
| 30 | v0.3.0 - Proposals: Database Schema |
| 31 | v0.3.0 - Proposals: API Endpoints |
| 32 | v0.3.0 - Proposals: Creation UI |
| 33 | v0.3.0 - Proposals: List View |
| 34 | v0.3.0 - Review: Sprint 3 Week 5 |
| 35 | v0.3.0 - Proposals: Voting API Backend |
| 36 | v0.3.0 - Proposals: Detail & Voting UI |
| 37 | v0.3.0 - Proposals: Real-time Vote Updates |
| 38 | v0.3.0 - Notifications: Push Setup (FCM + APNs) |
| 39 | v0.3.0 - Notifications: Proposal Notifications |
| 40 | v0.3.0 - Proposals: Auto Event Creation |
| 41 | v0.3.0 - Testing: Sprint 3 Bug Fixes |
| 42 | v0.3.0 - Review: Sprint 3 Polish |
| 43 | v0.3.0 - Review: Sprint 3 Final Demo |

### v0.4.0 - Templates & Travel (Sprint 4)

| # | Title |
|---|-------|
| 67 | v0.4.0 - Templates: Framework |
| 68 | v0.4.0 - Templates: Surprise Birthday Database |
| 69 | v0.4.0 - Templates: Surprise Birthday UI |
| 70 | v0.4.0 - Templates: Surprise Birthday Privacy |
| 71 | v0.4.0 - Templates: Potluck Backend |
| 72 | v0.4.0 - Templates: Potluck UI |
| 73 | v0.4.0 - Location: MapKit Integration |
| 74 | v0.4.0 - Location: Travel Time Calculation |
| 75 | v0.4.0 - Location: Travel Time UI |
| 76 | v0.4.0 - Location: Travel Notifications |
| 77 | v0.4.0 - Location: Group Travel Awareness |
| 78 | v0.4.0 - Templates: Polish & Animations |
| 79 | v0.4.0 - Testing: Sprint 4 Integration |
| 80 | v0.4.0 - Review: Checkpoint 4 |

### v0.5.0 - Polish & Completion (Sprint 5)

| # | Title |
|---|-------|
| 81 | v0.5.0 - UI: Calendar Polish |
| 82 | v0.5.0 - UI: Groups & Friends Polish |
| 83 | v0.5.0 - UI: Proposals & Templates Polish |
| 84 | v0.5.0 - Settings: Preferences Screen |
| 85 | v0.5.0 - Premium: Feature UI |
| 86 | v0.5.0 - Premium: Stripe Integration |
| 87 | v0.5.0 - Launch: MVP Complete & Onboarding |

---

## Branch Naming Convention

### Format
```
[type]/[issue-number]-[short-description]
```

### Types
- `feature/` - New features
- `fix/` - Bug fixes
- `refactor/` - Code improvements
- `docs/` - Documentation
- `chore/` - Maintenance

### Examples
```
feature/67-template-framework
fix/99-calendar-sync-crash
refactor/100-group-service-cleanup
```

---

## Commit Message Convention

### Format
```
type(scope): description

[optional body]

[optional footer]
```

### Types
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation
- `style:` - Formatting (no code change)
- `refactor:` - Code refactoring
- `test:` - Adding tests
- `chore:` - Maintenance

### Examples
```
feat(groups): add pull-to-refresh for groups list
fix(calendar): resolve sync crash on iOS 17
docs(readme): update installation instructions
refactor(auth): simplify session management logic
```

---

## Quick Reference

### Creating an Issue
```bash
gh issue create \
  --title "v0.4.0 - Templates: Feature Name" \
  --label "type: feature" \
  --label "area: templates" \
  --label "priority: high" \
  --label "sprint: 4"
```

### Creating a Branch
```bash
git checkout -b feature/67-templates-framework
```

### Creating a PR
```bash
gh pr create \
  --title "v0.4.0 - Templates: Framework" \
  --body "Closes #67"
```

---

## Summary

| Category | System |
|----------|--------|
| **Versioning** | SemVer (MAJOR.MINOR.PATCH) |
| **Issue Types** | feature, bug, task, design, refactor, docs |
| **Issue Areas** | auth, calendar, groups, proposals, notifications, templates, location, premium, ui, backend |
| **Priorities** | critical, high, medium, low |
| **Sprints** | 1-5 + Beta + Launch |
| **Branches** | type/issue-description |
| **Commits** | type(scope): description |

---

*Created: December 27, 2025*

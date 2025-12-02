# LockItIn Documentation Index

**Master Index for Shareless Everything Calendar Planning Documentation**

**Last Updated:** December 2, 2025

---

## Overview

This document serves as the central navigation hub for all LockItIn project documentation. The project uses a consolidated documentation structure with 12 focused markdown files at the repository root, organized by functional domain. This replaces the scattered NotionMD structure with a cleaner, single-source-of-truth approach.

### Quick Stats
- **12 consolidated lockitin-*.md files** (primary documentation)
- **2 retained NotionMD files** (design-specific reference)
- **100+ sprints detailed across 6 months** of development timeline
- **10 complete user flows** with step-by-step journeys
- **12 edge case categories** with resolution patterns

---

## Quick Navigation by Role

### For Product Managers & Leaders
1. **Start here:** `lockitin-product-vision.md` - Vision, strategy, competitive analysis
2. **Then:** `lockitin-features.md` - MVP scope and feature prioritization
3. **Then:** `lockitin-business.md` - Business model and growth strategy
4. **Then:** `lockitin-roadmap-development.md` - Timeline and milestones

### For iOS Developers
1. **Start here:** `lockitin-technical-architecture.md` - Backend, database, API design
2. **Then:** `lockitin-privacy-security.md` - RLS policies and privacy implementation
3. **Then:** `lockitin-notifications.md` - APNs integration and notification system
4. **Reference:** `CLAUDE.md` - Development environment setup and agent usage
5. **Reference:** `.claude/agents/README.md` - Available specialized agents

### For Designers & UX Team
1. **Start here:** `lockitin-designs.md` - Design system, decisions, and UX logic
2. **Then:** `lockitin-complete-user-flows.md` - 10 complete user journeys
3. **Then:** `lockitin-edge-cases.md` - Edge cases and error states
4. **Reference:** `NotionMD/Design System.md` - Component specs and visual details
5. **Reference:** `NotionMD/Detailed Layouts/` - Screen-by-screen detailed layouts

### For Beta Testing & QA
1. **Start here:** `lockitin-beta-testing.md` - Testing phases and feedback strategy
2. **Then:** `lockitin-edge-cases.md` - Test cases and edge scenarios
3. **Then:** `lockitin-complete-user-flows.md` - Critical user flows to test

---

## All Documentation Files

### Product & Strategy

#### 1. `lockitin-product-vision.md`
**Purpose:** Complete product vision and market positioning
**Covers:**
- Vision statement and mission
- Target user personas (Sarah the Organizer, Mike the Participant)
- Core value propositions
- Competitive landscape analysis
- Market positioning
- Product strategy and roadmap
- Business model overview
- Long-term vision (Year 1 & 2+)
- Success metrics
- Key risks and mitigation

**When to reference:** Strategic decisions, competitive analysis, user research, market understanding

**Cross-references:** Links to features, business model, roadmap

#### 2. `lockitin-features.md`
**Purpose:** Complete feature roadmap with tier prioritization
**Covers:**
- TIER 1 features (Must-have for MVP)
- TIER 2 features (Strong differentiators)
- TIER 3 features (Future phases)
- Feature descriptions with implementation details
- Feature relationships and dependencies
- Why certain features were excluded from MVP

**When to reference:** Feature scope, MVP planning, implementation prioritization

**Cross-references:** Roadmap timeline, technical architecture

#### 3. `lockitin-business.md`
**Purpose:** Business model and growth strategy
**Covers:**
- Freemium monetization model ($4.99/month premium)
- Consumer features vs. premium features
- B2B expansion opportunities
- Virality mechanics and network effects
- Growth metrics and KPIs
- Customer acquisition strategy
- Revenue projections

**When to reference:** Business planning, feature prioritization (free vs. paid), marketing strategy

**Cross-references:** Product vision, features, target users

### Technical Architecture

#### 4. `lockitin-technical-architecture.md`
**Purpose:** Complete backend and systems architecture
**Covers:**
- Technology stack (Swift, SwiftUI, Supabase, PostgreSQL)
- System architecture diagram
- Database schema (13 tables with full definitions)
- API endpoints (comprehensive REST API design)
- EventKit integration strategy
- Real-time voting system architecture
- Third-party service integrations
- Code snippets and examples

**When to reference:** Implementation, database queries, API contracts, backend setup

**Cross-references:** Privacy & security, notifications, roadmap

#### 5. `lockitin-privacy-security.md`
**Purpose:** Privacy-first system design and security implementation
**Covers:**
- Shadow Calendar system architecture
- Privacy tiers (Private/Shared-With-Name/Busy-Only)
- Row Level Security (RLS) policies with SQL examples
- Authentication flow
- User privacy controls
- Data residency and compliance (GDPR, CCPA, COPPA)
- Security best practices
- Incident response plan

**When to reference:** Privacy features, RLS policy implementation, compliance, security reviews

**Cross-references:** Technical architecture, features, edge cases

#### 6. `lockitin-notifications.md`
**Purpose:** Complete notification system design
**Covers:**
- Notification types (12+ categories)
- APNs integration strategy
- Delivery mechanics and reliability
- Notification inbox architecture
- User preference and control system
- Deep linking for notification taps
- Timing and frequency guidelines
- Localization strategy

**When to reference:** Notification implementation, APNs setup, user notification preferences

**Cross-references:** Technical architecture, user flows, privacy

### Design & UX

#### 7. `lockitin-designs.md`
**Purpose:** Design system and UX decisions
**Covers:**
- Design philosophy and principles
- Color palette (light/dark modes)
- Typography system
- Spacing and layout grid
- Component library overview
- Animation and interaction patterns
- Accessibility standards
- Design for mobile-first, one-handed use
- Gesture patterns

**When to reference:** Design decisions, component specs, style guide, accessibility requirements

**Cross-references:** Detailed layouts, UI design, user flows

#### 8. `lockitin-ui-design.md`
**Purpose:** Comprehensive UI design system and visual standards
**Covers:**
- Complete color palette with hex codes
- Typography specifications (SF Pro, sizes, weights)
- Spacing system (8pt grid)
- Component library (buttons, inputs, cards, etc.)
- Icon system and SF Symbols usage
- Dark mode implementation
- Animations and transitions
- Accessibility compliance (WCAG 2.1 AA)

**When to reference:** Visual design implementation, component styling, dark mode, icons

**Cross-references:** Design decisions, detailed layouts, component library

#### 9. `lockitin-complete-user-flows.md`
**Purpose:** 10 complete user journey flows with detailed steps
**Covers:**
- Onboarding flow (account creation through first event)
- Calendar sync flow (Apple Calendar integration)
- Creating a personal event
- Creating a group event proposal
- Voting on event proposals
- Managing groups and friends
- Viewing group availability heatmap
- Settings and privacy management
- Special event templates (Surprise Party, Potluck)
- Event confirmation and reminder flows

Each flow includes:
- Prerequisites and entry points
- Step-by-step user actions
- Screen transitions
- Success criteria
- Error handling paths
- Analytics tracking points

**When to reference:** Feature design, user research, testing scenarios, implementation checklist

**Cross-references:** Designs, edge cases, detailed layouts

#### 10. `lockitin-onboarding.md`
**Purpose:** Detailed onboarding and first-time user experience
**Covers:**
- Onboarding strategy and goals
- Permission requests (Calendar, Notifications, Contacts)
- Tutorial and education flow
- Empty states and first-use guidance
- Progressive disclosure strategy
- Premium feature messaging
- Completion metrics and success indicators

**When to reference:** Onboarding implementation, permission handling, first-time UX

**Cross-references:** Complete user flows, designs, privacy

#### 11. `lockitin-edge-cases.md`
**Purpose:** 12 comprehensive edge case categories with resolution patterns
**Covers:**
- Event conflicts and overlaps
- Timezone handling
- Offline mode behavior
- Concurrent modifications (two users editing same event)
- Privacy boundary violations
- Calendar sync failures
- Daylight saving time transitions
- Group member removal/leaving scenarios
- Network disconnection and reconnection
- Invalid/expired proposal states
- Notification delivery failures
- Performance under high load

Each edge case includes:
- Scenario description
- User impact
- System behavior
- Resolution strategy
- Testing approach

**When to reference:** Robust feature design, error handling, QA testing, edge case handling

**Cross-references:** Features, technical architecture, testing

### Development Process

#### 12. `lockitin-roadmap-development.md`
**Purpose:** 6-month development timeline with sprint-by-sprint breakdown
**Covers:**
- Phase 0: Pre-development (Dec 1-25, 2025)
- Phase 1: MVP Development (Dec 26 - Feb 26, 2026, 9 weeks)
- Phase 2: Beta Testing (Feb 27 - Apr 8, 2026, 6 weeks)
- Phase 3: Launch Prep (Apr 9-30, 2026, 4 weeks)

**Detail includes:**
- Sprint-level breakdown (1-5 with specific features)
- Daily standups and checkpoints
- Testing milestones
- Feedback integration points
- Launch preparation
- Success metrics per phase

**When to reference:** Sprint planning, timeline management, milestone tracking, progress monitoring

**Cross-references:** Features, technical architecture, beta testing

#### 13. `lockitin-beta-testing.md`
**Purpose:** Beta testing strategy and execution plan
**Covers:**
- Beta testing phases (Alpha, Beta 1, Beta 2, Release Candidate)
- Recruitment strategy (100+ testers target)
- Feedback collection methods
- Bug reporting and triage
- Metrics to track (retention, DAU, critical issues)
- Iteration cycles
- TestFlight deployment strategy
- Launch readiness criteria

**When to reference:** Beta program management, tester recruitment, feedback analysis

**Cross-references:** Roadmap, edge cases, technical architecture

---

## File Relationships & Cross-References

### Documentation Dependencies

```
lockitin-product-vision.md
├── informs → lockitin-features.md
├── informs → lockitin-business.md
├── informs → lockitin-designs.md
└── informs → lockitin-complete-user-flows.md

lockitin-features.md
├── drives → lockitin-roadmap-development.md
├── requires → lockitin-technical-architecture.md
└── requires → lockitin-privacy-security.md

lockitin-designs.md
├── references → NotionMD/Design System.md
├── references → NotionMD/Detailed Layouts/
├── defines → lockitin-ui-design.md
└── implements → lockitin-complete-user-flows.md

lockitin-complete-user-flows.md
├── tests → lockitin-edge-cases.md
├── implements → lockitin-features.md
├── uses → lockitin-designs.md
└── requires → lockitin-technical-architecture.md

lockitin-technical-architecture.md
├── enables → lockitin-privacy-security.md
├── enables → lockitin-notifications.md
└── implements → lockitin-features.md

lockitin-roadmap-development.md
├── organizes → all features from lockitin-features.md
├── tracks → progress from all domains
└── includes → lockitin-beta-testing.md timeline
```

### By Development Phase

**Pre-Development Phase (Dec 1-25)**
- Reference: `lockitin-product-vision.md`, `lockitin-features.md`
- Design: `lockitin-designs.md`, `lockitin-complete-user-flows.md`
- Setup: `lockitin-technical-architecture.md`, `lockitin-privacy-security.md`

**MVP Development Phase (Dec 26 - Feb 26)**
- Guide: `lockitin-roadmap-development.md` (sprint breakdowns)
- Implement: All lockitin-*.md files (specific by sprint)
- Validate: `lockitin-edge-cases.md`

**Beta Testing Phase (Feb 27 - Apr 8)**
- Execute: `lockitin-beta-testing.md`
- Fix: Cross-reference all domains for issues
- Polish: `lockitin-designs.md`, `lockitin-complete-user-flows.md`

**Launch Phase (Apr 9-30)**
- Prepare: `lockitin-business.md` (growth strategy)
- Final: `lockitin-privacy-security.md` (compliance)
- Monitor: All files for success metrics

---

## How to Use This Documentation

### For New Team Members
1. Read this index (you are here)
2. Read `lockitin-product-vision.md` (understand why we're building this)
3. Read role-specific section above
4. Deep-dive into specific lockitin files as needed
5. Reference `CLAUDE.md` for development setup

### For Feature Implementation
1. Find feature in `lockitin-features.md`
2. Review user flow in `lockitin-complete-user-flows.md`
3. Check edge cases in `lockitin-edge-cases.md`
4. Review design in `lockitin-designs.md` and `NotionMD/Detailed Layouts/`
5. Check technical requirements in `lockitin-technical-architecture.md`
6. Ensure privacy compliance with `lockitin-privacy-security.md`
7. Plan notifications from `lockitin-notifications.md`
8. Track in sprint from `lockitin-roadmap-development.md`

### For Design Reviews
1. Check `lockitin-designs.md` for system principles
2. Compare against `NotionMD/Design System.md` for specs
3. Validate against `lockitin-ui-design.md` for visual standards
4. Cross-check with `lockitin-complete-user-flows.md` for interactions
5. Test edge cases from `lockitin-edge-cases.md`

### For Testing & QA
1. Start with `lockitin-beta-testing.md` (test plan)
2. Use `lockitin-complete-user-flows.md` for test scenarios
3. Add `lockitin-edge-cases.md` for edge case testing
4. Reference `lockitin-notifications.md` for notification testing
5. Validate `lockitin-privacy-security.md` for privacy testing

### For Sprint Planning
1. Review current phase in `lockitin-roadmap-development.md`
2. Pull features from `lockitin-features.md`
3. Check technical dependencies in `lockitin-technical-architecture.md`
4. Validate against team capacity and timeline

---

## Search & Discovery

### Finding Information by Topic

**Authentication & User Management**
- Primary: `lockitin-technical-architecture.md` (Database schema, API endpoints)
- Design: `lockitin-complete-user-flows.md` (Onboarding flow)
- Privacy: `lockitin-privacy-security.md` (Authentication patterns)

**Calendar & Event Management**
- Primary: `lockitin-technical-architecture.md` (EventKit integration)
- Design: `lockitin-complete-user-flows.md` (Calendar sync, event creation)
- Architecture: `lockitin-privacy-security.md` (Privacy tiers)
- Edge cases: `lockitin-edge-cases.md` (Conflicts, timezone)

**Group Coordination & Voting**
- Primary: `lockitin-features.md` (Core feature)
- Design: `lockitin-complete-user-flows.md` (Proposal voting flow)
- Architecture: `lockitin-technical-architecture.md` (Database schema)
- Real-time: `lockitin-notifications.md` (Vote update notifications)

**Privacy & Security**
- Primary: `lockitin-privacy-security.md` (Complete guide)
- Implementation: `lockitin-technical-architecture.md` (RLS policies in appendix)
- UI/UX: `lockitin-designs.md` (Privacy controls design)
- Features: `lockitin-features.md` (Shadow Calendar feature)

**Notifications**
- Primary: `lockitin-notifications.md` (Complete system)
- Flows: `lockitin-complete-user-flows.md` (Notification interactions)
- Architecture: `lockitin-technical-architecture.md` (APNs integration)

**Design & UX**
- Primary: `lockitin-designs.md` (Design system)
- Visual: `lockitin-ui-design.md` (Component specs)
- Detailed: `NotionMD/Detailed Layouts/` (Screen specs)
- Flows: `lockitin-complete-user-flows.md` (User journeys)
- Reference: `NotionMD/Design System.md` (Color/typography specs)

**Business & Monetization**
- Primary: `lockitin-business.md` (Complete guide)
- Strategy: `lockitin-product-vision.md` (Long-term vision)
- Features: `lockitin-features.md` (Premium feature placement)

**Development Timeline**
- Primary: `lockitin-roadmap-development.md` (All phases)
- Testing: `lockitin-beta-testing.md` (Testing timeline)

---

## File Statistics

| Document | Size | Last Updated | Sections |
|----------|------|--------------|----------|
| lockitin-product-vision.md | Large | Dec 1 | 13 sections, 6000+ words |
| lockitin-features.md | Large | Dec 1 | 30+ features, 5000+ words |
| lockitin-business.md | Medium | Dec 1 | 6 sections, 3000+ words |
| lockitin-technical-architecture.md | Large | Dec 1 | 8 sections, 8000+ words, code snippets |
| lockitin-privacy-security.md | Large | Dec 1 | 8 sections, 6000+ words, SQL examples |
| lockitin-notifications.md | Medium | Dec 1 | 6 sections, 4000+ words |
| lockitin-designs.md | Large | Dec 1 | 10 sections, 5000+ words |
| lockitin-ui-design.md | Medium | Dec 2 | 8 sections, 3000+ words |
| lockitin-complete-user-flows.md | Large | Dec 1 | 10 user flows, 7000+ words |
| lockitin-onboarding.md | Medium | Dec 1 | 5 sections, 3000+ words |
| lockitin-edge-cases.md | Large | Dec 1 | 12 categories, 5000+ words |
| lockitin-roadmap-development.md | Large | Dec 1 | 4 phases, 6000+ words |
| lockitin-beta-testing.md | Medium | Dec 1 | 6 sections, 4000+ words |

**Total Documentation:** 60,000+ words across 13 files

---

## Maintenance & Updates

### When to Update Documentation

- **After sprint completion:** Update `lockitin-roadmap-development.md` with actual vs. planned progress
- **New feature decision:** Add to `lockitin-features.md`, check dependencies in `lockitin-technical-architecture.md`
- **Design changes:** Update `lockitin-designs.md` and `NotionMD/Design System.md`
- **User feedback:** Document learnings in `lockitin-edge-cases.md` if they reveal new scenarios
- **Technical architecture changes:** Update `lockitin-technical-architecture.md` and affected dependencies
- **Privacy/security updates:** Update `lockitin-privacy-security.md` immediately

### Documentation Review Schedule

- **Weekly:** Roadmap progress in `lockitin-roadmap-development.md`
- **Monthly:** Cross-document consistency check across all 13 files
- **Phase transitions:** Full review of roadmap and feature status
- **Before launch:** Final audit of all files for completeness and accuracy

---

## Glossary & Key Terms

**Shadow Calendar:** Core privacy system allowing users to share availability (busy/free) without revealing event details.

**Tier 1/2/3 Features:** MVP prioritization system. Tier 1 = must-have, Tier 2 = strong differentiators, Tier 3 = future phases.

**RLS (Row Level Security):** PostgreSQL policies enforcing privacy rules at database level, not just app UI.

**EventKit:** Apple's native calendar framework for syncing with Apple Calendar.

**Proposal:** Group event suggestion created by one user and voted on by group members.

**Heatmap:** Visual representation of group availability across time slots (e.g., "5/8 people free").

---

## Support & Questions

For questions about documentation:
- Check this index first for navigation guidance
- Use the "Search & Discovery" section to find specific topics
- Review file relationships to understand connections
- Reference CLAUDE.md for development environment questions
- Check `.claude/agents/README.md` for available specialized agents

---

**This documentation represents the complete planning specification for LockItIn (LockItIn Calendar). All code development should reference these 13 files and 2 design directories as the source of truth.**

*Last updated: December 2, 2025*

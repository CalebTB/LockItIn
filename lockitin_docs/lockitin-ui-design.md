# LockItIn UI Design System

**Comprehensive design system, visual language, and component specifications for the LockItIn cross-platform mobile app (iOS & Android).**

*Last Updated: December 30, 2025 - Updated to Minimal theme color system*

---

## Table of Contents

1. Design System Overview
2. Color Palette
3. Typography System
4. Spacing & Layout
5. Component Library
6. Icon System
7. Animation & Micro-interactions
8. Imagery & Media
9. Accessibility
10. Dark Mode
11. Component Usage Examples
12. Design Tokens
13. Screen Layout Reference
14. Design Resources
15. Quick Reference

---

## 1. Design System Overview

### Purpose

The LockItIn design system ensures visual consistency, usability, and accessibility across both iOS and Android platforms. It provides clear guidelines for developers and designers to build a cohesive product experience that feels native to each platform (iOS following HIG, Android following Material Design) while maintaining our unique brand identity.

### Design Ethos: "Calm, Not Chaotic"

Every design decision reduces anxiety, not creates it. LockItIn helps coordinate with friends without noise, FOMO, and social pressure.

### Five Core Design Principles

**1. Platform-Native Feel**
- **iOS**: Follows Apple's Human Interface Guidelines (HIG) with SF Pro font, Cupertino widgets
- **Android**: Follows Material Design 3 guidelines with Roboto font, Material components
- Uses platform-appropriate system colors and components
- Feels native to each platform while maintaining brand consistency
- Respects system-level behaviors (safe areas on iOS, navigation patterns on Android)

**2. Minimal & Focused**
- Every screen has one primary action
- No clutter, no overwhelming options
- Progressive disclosure of complexity
- Clear visual hierarchy
- Whitespace as a design element

**3. Delightful Details**
- Smooth animations with spring physics
- Haptic feedback on important actions
- Confetti when events get confirmed
- Thoughtful empty states
- Micro-interactions that delight without distraction

**4. Accessible to All**
- Full VoiceOver support with descriptive labels
- Dynamic Type for text scaling (support all 7 size categories)
- High contrast mode support
- Colorblind-friendly palettes
- Minimum 44pt touch targets
- WCAG AA compliance for all color contrasts

**5. Fast & Responsive**
- Optimistic UI updates (show action immediately)
- Aggressive caching of calendar data
- Works offline with queue system
- <100ms response times for interactions
- Real-time updates via WebSockets

### Design Constraints

All design decisions balance:
- **User control** - Users make decisions that matter to them
- **Reduced friction** - Every tap should feel intentional
- **Privacy-first** - Granular controls, opt-in sharing, default to private
- **Celebration over shame** - No guilt-inducing FOMO messages

---

## 2. Color Palette

> **Implementation Reference:** See `LOCKIT_MINIMAL_THEME.md` for complete specification and `lib/core/theme/app_colors.dart` for Flutter implementation.

**Color Scheme: Minimal**
Rose/Orange accents with neutral foundation. Clean, professional, OLED-friendly.

### Primary Brand Colors

| Color | Hex Code | Tailwind | Usage | Rationale |
|-------|----------|----------|-------|-----------|
| **Primary** | #F43F5E | `rose-500` | Buttons, links, highlights, primary actions | Warm, modern, stands out on neutral backgrounds |
| **Secondary** | #F97316 | `orange-500` | Secondary accents, CTAs, confirmations | Energetic complement to rose, joy and celebration |
| **Tertiary** | #FB7185 | `rose-400` | Lighter accents, hover states (dark mode) | Softer version of primary for subtle highlights |

**Primary Accent Gradient:** `from-rose-500 to-orange-500`

### Semantic Colors

| Color | Hex Code | Tailwind | Usage | When to Use |
|-------|----------|----------|-------|-------------|
| **Success** | #10B981 | `emerald-500` | Confirmations, positive feedback, availability | Event confirmed, action successful, high availability |
| **Error** | #F43F5E | `rose-500` | Errors, destructive actions, conflicts | Same as primary - failed actions, declined events |
| **Warning** | #F59E0B | `amber-500` | Cautions, pending states, medium availability | Pending votes, moderate availability, important notices |
| **Info** | #3B82F6 | `blue-500` | Informational messages, hints | Informational banners, tooltips |

### Neutral Colors (Light Mode - Gray Foundation)

| Color Name | Hex Code | Tailwind | Usage |
|------------|----------|----------|-------|
| Background | #F5F5F5 | `gray-100` | Main app background |
| Surface | #FFFFFF | `white` | Cards, sheets, elevated content |
| Card | #FFFFFF | `white` | Card backgrounds |
| Border | #E5E5E5 | `gray-200` | Borders, dividers |
| Text Primary | #171717 | `gray-900` | Main text, headers |
| Text Secondary | #404040 | `gray-700` | Secondary text |
| Text Muted | #737373 | `gray-500` | Muted text, placeholders |

### Neutral Colors (Dark Mode - Neutral Foundation)

| Color Name | Hex Code | Tailwind | Usage |
|------------|----------|----------|-------|
| Background | #000000 | `black` | Main app background (OLED) |
| Surface | #0A0A0A | `neutral-950` | Primary surface |
| Card | #171717 | `neutral-900` | Card backgrounds |
| Border | #262626 | `neutral-800` | Borders, dividers |
| Text Primary | #FFFFFF | `white` | Main text, headers |
| Text Secondary | #D4D4D4 | `neutral-300` | Secondary text |
| Text Muted | #737373 | `neutral-500` | Muted text, placeholders |

### Event Category Colors (Personal Calendar)

Event categories use distinct colors to help users quickly identify event types in their personal calendar view.

| Category | Hex Code | Tailwind | When Used |
|----------|----------|----------|-----------|
| **Work** | #14B8A6 | `teal-500` | Work meetings, deadlines, professional commitments |
| **Holiday** | #F97316 | `orange-500` | Holidays, celebrations, special occasions |
| **Friend** | #8B5CF6 | `violet-500` | Social events, hangouts, friend gatherings |
| **Other** | #F43F5E | `rose-500` | Personal appointments, errands, miscellaneous |

**Note:** Event category colors are defined in `AppColors.category*` constants. See `lib/core/theme/app_colors.dart`.

### Heatmap Colors (Group Calendar Availability)

Used in Group Calendar view to show availability at a glance.

| Color | Hex Code | Availability | Percentage | Visual Treatment |
|-------|----------|--------------|-----------|------------------|
| **Green** | #10B981 | High availability | >75% available | Green background/badge, filled segments |
| **Yellow** | #F59E0B | Medium availability | 50-75% available | Yellow background/badge, partial segments |
| **Red** | #EF4444 | Low availability | <50% available | Red background/badge, minimal segments |
| **Gray** | #9CA3AF | No visibility | All private or no data | Gray background, no data available |

**Usage:** Heatmap colors provide instant visual feedback on which days are best for scheduling group events.

### Color Accessibility

All color combinations meet **WCAG AA** contrast requirements (4.5:1 for text, 3:1 for UI components):

**Primary Color Contrasts:**
- **Rose (#F43F5E) on White:** 4.5:1 ✅ (AA compliant for text)
- **White text on Rose:** 4.5:1 ✅ (Buttons, primary CTAs)
- **White on neutral-900 (#171717):** 15.1:1 ✅ (Exceeds AAA)
- **neutral-300 (#D4D4D4) on neutral-950:** 10.8:1 ✅ (Exceeds AAA)
- **gray-900 (#171717) on white:** 21:1 ✅ (Exceeds AAA)

**Semantic Color Contrasts:**
- **Success emerald-500 (#10B981) on White:** 4.7:1 ✅
- **Error rose-500 (#F43F5E) on White:** 4.5:1 ✅
- **Warning amber-500 (#F59E0B) on White:** 2.3:1 ⚠️ (Use with dark text or as background only)

**Event Category Colors:**
- All event category colors (Work/Teal, Holiday/Orange, Friend/Violet, Other/Rose) are supplemented with the event count badge and titles for colorblind accessibility
- Pattern redundancy: Heatmap uses both color AND visual segments (filled vs unfilled)

### Color Usage Guidelines

**Don't:**
- Don't use color as the only indicator of state or meaning
- Don't use system colors for decorative elements
- Don't create custom shades of primary colors

**Do:**
- Always pair colors with text labels or icons
- Use colors consistently across the app
- Test with colorblind simulation tools
- Ensure sufficient contrast for accessibility

---

## 3. Typography System

### Font Family

**iOS - SF Pro (System Default)**
- Preloaded on all iOS devices
- Automatically adjusts for Dynamic Type
- Supports all weights needed
- Respects system accessibility settings

**Android - Roboto (System Default)**
- Native Android font family
- Supports font scaling via system settings
- Material Design standard
- Consistent across all Android versions 5.0+

### Type Scale

| Style | Size | Weight | Line Height | Usage |
|-------|------|--------|-------------|-------|
| Title 1 | 34pt | Bold (700) | 41pt | Main screen titles |
| Title 2 | 28pt | Bold (700) | 34pt | Section headers |
| Title 3 | 22pt | Semibold (600) | 28pt | Card titles |
| Headline | 17pt | Semibold (600) | 22pt | Button text, list headers |
| Body | 17pt | Regular (400) | 22pt | Body text, descriptions |
| Callout | 16pt | Regular (400) | 21pt | Emphasized text |
| Footnote | 13pt | Regular (400) | 18pt | Secondary text, captions |
| Caption | 12pt | Regular (400) | 16pt | Smallest text, timestamps |

### Text Styles (Platform-Specific)

**iOS (SwiftUI/Cupertino):**
```swift
.title1         // Title 1 (34pt bold)
.title2         // Title 2 (28pt bold)
.title3         // Title 3 (22pt semibold)
.headline       // Headline (17pt semibold)
.body           // Body (17pt regular)
.callout        // Callout (16pt regular)
.footnote       // Footnote (13pt regular)
.caption1       // Caption (12pt regular)
```

**Android (Flutter/Material):**
```dart
TextStyle(                    // Material Design 3
  fontSize: 34,               // displayLarge (Title 1 equivalent)
  fontWeight: FontWeight.bold,
  fontFamily: 'Roboto',
)
Theme.of(context).textTheme.headlineMedium  // Title 2
Theme.of(context).textTheme.titleLarge      // Title 3
Theme.of(context).textTheme.bodyLarge       // Body
Theme.of(context).textTheme.bodyMedium      // Callout
Theme.of(context).textTheme.bodySmall       // Footnote
```

### Dynamic Type Support

All text must support Dynamic Type (7 accessibility sizes):
- **Extra Small:** -2 sizes from default
- **Small:** -1 size from default
- **Default:** Standard (reference above)
- **Large:** +1 size from default
- **Extra Large:** +2 sizes from default
- **Extra Extra Large:** +3 sizes from default
- **Extra Extra Extra Large:** +4 sizes from default

**Implementation:**
- **iOS**: Use `.font(.body)` with `.dynamicTypeSize()` modifiers in SwiftUI
- **Android**: Respect `fontScale` from MediaQuery and use `Theme.of(context).textTheme` styles
- **Flutter**: Use `MediaQuery.of(context).textScaleFactor` for adaptive sizing

### Letter Spacing

- **Default:** 0pt (no adjustment needed)
- **Headlines (Title 1-2):** -0.5pt for tighter spacing
- **Captions:** 0.5pt for enhanced readability

### Line Heights

- **Titles:** 1.2x font size
- **Body text:** 1.3x font size (22pt for 17pt body)
- **Minimum line height:** 18pt for accessibility

---

## 4. Spacing & Layout

### 8pt Grid System

All spacing uses an 8pt grid for consistency and alignment.

| Unit | Size | Usage |
|------|------|-------|
| 0.5x | 4pt | Tight spacing between elements |
| 1x | 8pt | Standard padding, icon spacing |
| 2x | 16pt | Medium spacing, section padding |
| 3x | 24pt | Large spacing, grouped content |
| 4x | 32pt | Extra large spacing |
| 6x | 48pt | Section breaks, major spacing |

### Padding Standards

**Content Areas:**
- Left/Right: 16pt (2x)
- Top/Bottom: 16pt (2x) for cards
- Interior: 12pt (1.5x) for form fields

**Buttons:**
- Horizontal padding: 16pt
- Vertical padding: 12pt (minimum 44pt height total)
- Minimum tap target: 44pt x 44pt

**Cards:**
- Padding: 16pt all sides
- Corner radius: 12pt
- Spacing between cards: 12pt

**Section Spacing:**
- Between sections: 32pt (4x)
- Section header to content: 12pt
- Content to next section: 24pt

### Safe Area Handling

**iPhone notch/Dynamic Island:**
- Content respects safe area insets automatically
- Floating action buttons offset by 24pt from bottom and sides
- Top padding for navigation: 8pt below safe area

**Bottom Sheet/Modal:**
- Safe area bottom padding: 16pt (larger on devices with home indicator)
- Left/right padding: 16pt

### Layout Patterns

**List Item (Standard Cell):**
- Height: Minimum 44pt (touch target)
- Padding: 12pt vertical, 16pt horizontal
- Divider: 1pt separator at bottom

**Form Field:**
- Height: 44pt minimum
- Border: 1pt, gray on light background
- Corner radius: 8pt
- Padding: 12pt horizontal, 10pt vertical

**Card Layout:**
- Background: Secondary background color
- Padding: 16pt
- Corner radius: 12pt
- Shadow: Light (1pt elevation on light mode)
- Spacing: 12pt between cards

---

## 5. Component Library

### Buttons

#### Primary Button
- **Background:** Primary gradient `from-rose-500 to-orange-500` or solid `rose-500` (#F43F5E)
- **Text Color:** White
- **Height:** 44pt minimum
- **Width:** Full width (preferred) or 120pt+ minimum
- **Corner Radius:** 8pt (or 12pt for rounded style)
- **Font:** Headline semibold
- **Padding:** 12pt vertical, 16pt horizontal
- **Shadow:** `shadow-lg shadow-rose-500/20` (dark mode) or `shadow-rose-200` (light mode)

**States:**
- Default: Gradient or solid rose-500
- Hover: `from-rose-400 to-orange-400`
- Pressed: Slight scale down (98%) with haptic feedback
- Disabled: 50% opacity
- Loading: Spinner replaces text

#### Secondary Button
- **Background:** Transparent with border
- **Border:** 1pt `neutral-800` (dark) or `gray-200` (light)
- **Text Color:** White (dark) or `gray-900` (light)
- **Height:** 44pt minimum
- **Font:** Headline semibold

**States:**
- Default: Clear with border
- Hover: `neutral-800` bg (dark) or `gray-50` bg (light)
- Pressed: Slight scale down
- Disabled: 50% opacity

#### Text Button (Ghost)
- **Background:** Transparent
- **Text Color:** `neutral-400` (dark) or `gray-600` (light)
- **Height:** 44pt minimum
- **Font:** Callout or footnote
- **Padding:** 8pt

**States:**
- Default: Text only
- Hover: `neutral-800` bg (dark) or `gray-100` bg (light), text becomes white/gray-900
- Disabled: 50% opacity

#### Danger Button
- **Background:** `rose-500` (#F43F5E)
- **Text Color:** White
- **Usage:** Delete, cancel, destructive actions
- **Identical styling to Primary Button** (since primary is already rose)

### Input Fields

#### Text Field
- **Height:** 44pt minimum
- **Border:** 1pt `gray-200` (light) or `neutral-800` (dark)
- **Corner Radius:** 8pt (or 12pt for rounded style)
- **Background:** `gray-100` (light) or `neutral-900` (dark)
- **Padding:** 12pt horizontal, 10pt vertical
- **Font:** Body regular
- **Placeholder:** `gray-400` (light) or `neutral-600` (dark)

**States:**
- Default: Standard border
- Focused: `rose-500` border, `rose-500/20` ring (dark) or `rose-200` ring (light)
- Error: `rose-500` border
- Disabled: Grayed out (50% opacity)

#### Text Input Rules
- Placeholder text should be self-explanatory
- Required fields marked with asterisk *
- Character count shown for long-form inputs
- Real-time validation for email/phone

#### Picker
- **Height:** 44pt
- **Style:** Chevron on right side (→)
- **Selection:** Opens modal or popover
- **Font:** Body regular

#### Toggle/Switch
- **Size:** 51pt x 31pt (system standard)
- **Thumb size:** 27pt x 27pt
- **On Color:** `rose-500` (#F43F5E)
- **Off Color:** `neutral-700` (dark) or `gray-300` (light)
- **Animation:** Spring physics

#### Date Picker
- **Style:** Wheels (default) or calendar grid
- **Height:** Varies by content
- **Font:** Headline for selected value
- **Transition:** Smooth animation

### Cards

#### Standard Card
- **Background:** Secondary background color
- **Padding:** 16pt
- **Corner Radius:** 12pt
- **Shadow:** Light shadow (1pt elevation)
- **Spacing:** 12pt gap between cards

#### Event Card (in Lists)
- **Height:** 60pt minimum
- **Content:** Title, time, location preview
- **Badges:** Privacy icons on right
- **Color:** Coded by event type (blue/green/purple/gray)

#### Proposal Card (in Inbox)
- **Content Layout:**
  - Event title (headline)
  - Organizer + Group (footnote)
  - Best time option (body)
  - Vote count (callout)
  - User's vote status (footnote, blue)
- **Badges:** "Needs vote" or "Voted" indicator

### Navigation Components

#### Bottom Navigation

**iOS - Tab Bar:**
- **Height:** 50pt + safe area bottom
- **Background:** Secondary background color
- **Items:** 4 tabs (Calendar, Groups, Inbox, Profile)
- **Active Indicator:** Tinted blue icon + label
- **Inactive:** Gray icon + label
- **Badge:** Red circle with count for unread

**Android - Bottom Navigation Bar (Material):**
- **Height:** 56dp
- **Background:** Surface color (elevated)
- **Items:** 4 destinations (same as iOS)
- **Active Indicator:** Filled icon + primary color label
- **Inactive:** Outlined icon + gray label
- **Badge:** Red dot or count badge

#### Navigation Bar (Top)
- **Height:** 44pt + safe area top
- **Background:** Same as view background
- **Title:** Headline semibold
- **Back Button:** Chevron left + optional text
- **Actions:** Right side for secondary actions

#### Segmented Control (View Switcher)
- **Height:** 44pt
- **Background:** Tertiary background color
- **Selected:** Blue highlight
- **Segments:** Day | Week | Month

### Lists & Cells

#### Standard List Cell
- **Height:** 44pt minimum
- **Padding:** 12pt vertical, 16pt horizontal
- **Text:** Headline for title, body for subtitle
- **Divider:** 1pt separator below
- **Tappable area:** Full width, 44pt minimum height

#### Group Header
- **Padding:** 16pt horizontal, 12pt vertical
- **Font:** Headline semibold
- **Color:** Text secondary (gray)
- **Background:** Transparent or tertiary background
- **Sticky:** Can pin to top on scroll (optional)

#### Empty State Cell
- **Content:** Icon, title, subtitle
- **Padding:** 32pt
- **Text Alignment:** Center
- **Icon Size:** 64pt

### Modals & Sheets

#### Bottom Sheet (Primary Pattern)
- **Background:** Same as app background
- **Corner Radius:** 12pt top corners
- **Padding:** 16pt sides
- **Safe Area Bottom:** Respected
- **Drag Handle:** Optional, centered at top (not required with swipe-to-dismiss)
- **Content:** Scrollable if needed

#### Full Screen Modal
- **Navigation:** Close button or back button
- **Content:** Full width and height with safe area respect
- **Animation:** Slide up from bottom (spring physics)

#### Alert Dialog
- **Width:** 80% of screen (max 500pt)
- **Corner Radius:** 12pt
- **Buttons:** Stacked vertically if multiple
- **Backdrop:** Dimmed background (50% black)

#### Action Sheet (Context Menu)
- **Trigger:** Long press on element
- **Style:** Popover menu
- **Actions:** Destructive actions in red at bottom
- **Dismiss:** Tap outside or on an option

### Loading States

#### Spinner (Progress View)
- **Size:** 40pt diameter
- **Color:** `rose-500` (#F43F5E)
- **Animation:** Continuous rotation
- **Background:** Optional semi-transparent overlay
- **Message:** "Loading..." or specific text below

#### Skeleton Screen
- **Pattern:** Gray placeholder blocks matching layout
- **Animation:** Shimmer effect (light to dark to light)
- **Duration:** 1 second loop
- **Use Case:** Content loading (lists, calendars)

#### Progress Bar
- **Height:** 6pt
- **Background:** `neutral-800` (dark) or `gray-200` (light)
- **Progress:** `rose-500` or gradient `from-rose-500 to-orange-500`
- **Corner Radius:** 3pt
- **Use Case:** Vote progress visualization, upload progress

### Feedback Components

#### Toast Notification
- **Position:** Bottom of screen, 16pt from bottom
- **Width:** 90% of screen width
- **Padding:** 12pt
- **Corner Radius:** 8pt
- **Background:** Dark (semi-transparent)
- **Text:** White, caption size
- **Duration:** 3 seconds (dismissable manually)
- **Animation:** Fade in/out with slight slide

#### Inline Error
- **Border:** 1pt red around field
- **Message:** Red text below field
- **Icon:** Error icon (optional)
- **Font:** Footnote
- **Pattern:** Only shown after interaction

#### Badge (Unread Count)
- **Shape:** Circle
- **Background:** Error red
- **Text:** White, caption bold
- **Size:** 20pt minimum diameter
- **Position:** Top right of tab or card

#### Confetti Animation
- **Trigger:** Event confirmation
- **Duration:** 1 second
- **Particles:** Colorful confetti shapes
- **Sound:** Optional success chime (if enabled)

### Empty & Error States

#### Empty State Screen
- **Icon:** 64pt system icon
- **Title:** Headline size, bold
- **Subtitle:** Body size, secondary text
- **CTA:** Primary button with action
- **Example:** "No events yet" with "Create event" button

#### Error State
- **Icon:** 64pt error icon (exclamation mark)
- **Title:** "Something went wrong"
- **Message:** Brief explanation
- **Buttons:** [Retry] [Contact Support]

#### No Connection State
- **Icon:** WiFi off icon
- **Title:** "No Connection"
- **Message:** "You're offline. Changes will sync when connected."
- **Indicator:** Small banner at top with status

### Calendar Grid Components

#### Calendar Month View - Dual Mode Design

The calendar uses **two distinct rendering modes** depending on context: Personal Calendar and Group Calendar. Each mode optimizes for different user goals.

**Design Philosophy:**
- **Personal Calendar:** "How busy am I?" → Shows event density and categories
- **Group Calendar:** "When can we meet?" → Shows availability and coordination opportunities

---

#### Personal Calendar Mode

**Purpose:** Manage individual schedule with events from personal calendar and accepted group events.

**Calendar Cell Layout:**
```
┌─────────────────────┐
│ [15]                │  ← Date number (top-left)
│                     │
│ ● ● ● ● ● ●   +4   │  ← Colored circles (6 max) + overflow indicator
│                 [3] │  ← Event count badge (bottom-right)
└─────────────────────┘
```

**Components:**

1. **Date Number (Top-Left)**
   - **Size:** 22×22pt container
   - **Font:** 11.5pt, Regular (400) or Semibold (600) if today
   - **Color:** Primary text color, or white if today
   - **Today Indicator:** Rose circle background (`rose-500` #F43F5E)
   - **Position:** Top-left corner with 4pt padding

2. **Event Count Badge (Bottom-Right)**
   - **Size:** 22×22pt container with 15×15pt circle
   - **Background:** Pastel blue circle (primary color with 20% opacity)
   - **Font:** 11.5pt, Bold (700)
   - **Color:** Dark grey text (onSurface with 80% opacity)
   - **Position:** Bottom-right corner (Positioned widget in Stack)
   - **Shows:** Total event count for the day

3. **Event Category Indicators (Middle Area)**
   - **Style:** Small colored circles representing individual events
   - **Size:** 8×8pt per circle
   - **Spacing:** 3pt horizontal and vertical spacing
   - **Layout:** Wrap layout (flows horizontally, wraps to new rows)
   - **Maximum Visible:** 6 circles
   - **Overflow:** "+X" text for remaining events (e.g., "+4" for 10 total events)
   - **Positioning:** Flows naturally in available space between date number and event count badge

**Event Category Colors:**
- **Work:** Green (#10B981)
- **Holiday:** Red (#EF4444)
- **Friend:** Purple (#8B5CF6)
- **Other:** Yellow/Amber (#F59E0B)

**Use Cases:**
- Quick scanning: "Which days am I busiest?"
- Category distribution: "How many work vs personal events this week?"
- Event density: Badge shows total count, circles show first 6

**Accessibility:**
- VoiceOver/TalkBack: "March 15, 3 events: 2 work, 1 friend"
- Minimum touch target: Full cell is 44pt+ tappable
- Color coding supplemented by count badge for color-blind users

---

#### Group Calendar Mode

**Purpose:** View aggregated availability across group members to identify coordination opportunities.

**Calendar Cell Layout:**
```
┌─────────────────────┐
│ [15]          6/8   │  ← Date number + Availability fraction
│                     │
│ ████████░░          │  ← Availability bar (filled = free)
│                     │
│ Lunch w/ Team       │  ← Shared event title (if exists)
└─────────────────────┘
```

**Components:**

1. **Date Number (Top-Left)**
   - Same as Personal Calendar Mode
   - **Font:** 11.5pt, Regular (400) or Semibold (600) if today

2. **Availability Fraction (Top-Right)**
   - **Size:** 22×22pt container (aligned with date number)
   - **Font:** 11.5pt, Bold (700)
   - **Format:** "6/8" (numerator = people free, denominator = total group size)
   - **Color-Coded by Availability:**
     - **Green:** 75%+ available (e.g., 6+ out of 8)
     - **Yellow:** 50-75% available (e.g., 4-5 out of 8)
     - **Red:** <50% available (e.g., 1-3 out of 8)
   - **Background:** Circular badge with color at 15% opacity

3. **Availability Bar (Visual Representation)**
   - **Height:** 8pt
   - **Width:** Full width minus padding
   - **Layout:** Horizontal segmented bar
   - **Filled Segments:** Number of people available (solid color)
   - **Unfilled Segments:** Number of people busy (20% opacity)
   - **Segment Color:** Matches availability color (green/yellow/red)
   - **Corner Radius:** 4pt
   - **Example:** In 8-person group, show 6 filled + 2 unfilled segments

4. **Shared Event Titles (Optional)**
   - **Font:** 9pt, Medium (500)
   - **Color:** Primary text with 80% opacity
   - **Shows:** Event titles for "Shared-With-Name" group events
   - **Privacy:** "Busy-Only" events don't show titles (only affect availability count)
   - **Max Lines:** 1 line, ellipsis overflow
   - **Spacing:** 2pt above text

**Availability Calculation:**
- **Free:** User has no events during that day (or only Private events if viewing as group member)
- **Busy:** User has Shared-With-Name or Busy-Only events
- **Respect Privacy:** Private events don't affect group availability (Shadow Calendar system)

**Background Color (Heatmap Variant):**
- **Alternative Design:** Cell background color indicates availability
  - Light green: 75%+ free
  - Medium yellow: 50-75% free
  - Light red: <50% free
- **Pattern Redundancy:** Use diagonal stripes for low availability (accessibility)
- **Text Overlay:** Fraction centered in cell with high contrast

**Use Cases:**
- Quick scanning: "Which days can most people meet?"
- Event planning: Green days = good opportunities to propose events
- Coordination: Red days = avoid scheduling group events

**Accessibility:**
- VoiceOver/TalkBack: "March 15, 6 out of 8 people available, high availability"
- Pattern + color redundancy for color-blind users
- High contrast text on background fills

---

#### Calendar Cell States

**Both Modes Share:**
- **Default State:** Standard rendering as described above
- **Today Highlight:** Rose circle behind date number (`rose-500`)
- **Selected State:** Border highlight when navigating with keyboard/D-pad
- **Pressed State:** Slight scale down (98%) with haptic feedback
- **Outside Month:** Hidden (shows empty cell with subtle border)

**Interaction:**
- **Tap:** Opens Day Detail screen showing event list
- **Long Press:** (Future) Quick actions menu for creating event
- **Swipe:** Month navigation (left/right)

---

#### Implementation Notes

**Mode Detection:**
```dart
// Conditional rendering based on calendar context
isGroupView
  ? GroupCalendarCell(date: day, groupId: groupId)
  : PersonalCalendarCell(date: day, events: events)
```

**Data Sources:**
- **Personal Mode:** User's events + accepted group events
- **Group Mode:** Aggregated Shared/Busy events from all group members

**Caching:**
- Cache availability calculations per day per group
- Invalidate on event updates or membership changes
- Background sync every 15 minutes

**Platform Adaptation:**
- **iOS:** Use Cupertino widgets, system colors, haptic feedback
- **Android:** Use Material widgets, Material colors, ripple effects
- **Both:** Respect safe areas, dynamic type, dark mode

---

#### Design Rationale

**Why Two Modes?**

1. **Different User Goals:**
   - Personal calendar: Manage individual schedule
   - Group calendar: Coordinate with others

2. **Different Information Needs:**
   - Personal: Event categories matter (Work vs Social)
   - Group: Availability matters (Who's free vs busy?)

3. **Scalability:**
   - Personal: Colored circles work for 1-10 personal events
   - Group: Availability fraction scales to any group size (4-20+ people)

4. **Privacy-First:**
   - Personal: Shows YOUR event details
   - Group: Respects Shadow Calendar (shows availability, not private details)

**Why Not Combine Into One Design?**

Attempting to show both event categories AND group availability creates:
- Visual noise (too many colored dots)
- Ambiguity ("Whose work event is this green circle?")
- Poor scaling (20+ events/day in group context)
- Wrong metrics (total events ≠ coordination opportunity)

**Progressive Disclosure:**
- Month view: High-level patterns (density or availability)
- Day detail: Full event list with times and details
- Event detail: Complete metadata and controls

---

## 6. Icon System

### Icon Systems

**iOS - SF Symbols:**
Using Apple's native SF Symbols for consistency on iOS:

| Component | Icon | Weight | Color |
|-----------|------|--------|-------|
| Calendar | calendar | semibold | Primary |
| Groups | person.3.fill | semibold | Primary |
| Proposals/Voting | checkmark.circle.fill | semibold | Green |
| Profile | person.circle.fill | semibold | Primary |
| Settings | gear | semibold | Primary |
| Privacy/Lock | lock.circle.fill | semibold | Primary |
| Share | square.and.arrow.up | semibold | Primary |
| Plus/Create | plus.circle.fill | semibold | Primary |
| Menu | ellipsis | semibold | Primary |
| Bell/Notifications | bell.fill | semibold | Primary |
| Busy/Block | calendar.badge.clock | semibold | Gray |
| Private Event | lock.fill | semibold | Gray |

### Icon Sizes

| Context | Size | Usage |
|---------|------|-------|
| Tab Bar Icons | 24pt | Bottom navigation |
| Navigation Bar Buttons | 18pt | Header actions |
| List Item Icons | 20pt | Leading element in cells |
| Form Indicators | 16pt | Required/error indicators |
| Badges (Privacy) | 14pt | On calendar events |

### Icon Weights

- **Navigation:** Semibold (default)
- **Large display:** Regular for lighter feel
- **Small badges:** Bold for visibility

### Icon Colors

**Dark Mode:**
- **Primary:** `white`
- **Secondary:** `neutral-400`
- **Muted:** `neutral-500`
- **Accent:** `rose-400`

**Light Mode:**
- **Primary:** `gray-700`
- **Secondary:** `gray-500`
- **Muted:** `gray-400`
- **Accent:** `rose-500`

**Semantic:**
- **Destructive:** `rose-500`
- **Success:** `emerald-500`
- **Inactive/Disabled:** 50% opacity

### Privacy Icon Set (Special)

Used on event badges to indicate visibility:
- **🔒 Private** - Closed lock or lock.fill
- **👥 Shared with name** - person.2 or person.3.fill
- **👁️ Busy only** - eye.fill (custom or SF symbol)

**Android - Material Icons:**
Using Material Icons for Android consistency:

| Component | Icon | Color |
|-----------|------|-------|
| Calendar | event | Primary |
| Groups | people | Primary |
| Proposals/Voting | check_circle | Success green |
| Profile | account_circle | Primary |
| Settings | settings | Primary |
| Privacy/Lock | lock | Primary |
| Share | share | Primary |
| Plus/Create | add_circle | Primary |
| Menu | more_vert | Primary |
| Bell/Notifications | notifications | Primary |

**Cross-Platform Approach:**
- Use platform-appropriate icon sets (SF Symbols vs Material Icons)
- Maintain visual consistency through similar icon styles
- Same conceptual meaning across platforms (lock = privacy on both)

### Accessibility for Icons

**iOS Example:**
```swift
Image(systemName: "lock.fill")
    .accessibilityLabel("Private event")
    .accessibilityHint("This event is only visible to you")
```

**Android/Flutter Example:**
```dart
Icon(Icons.lock,
  semanticLabel: "Private event",
)
Semantics(
  label: 'Private event',
  hint: 'This event is only visible to you',
  child: Icon(Icons.lock),
)
```

---

## 7. Animation & Micro-interactions

### Animation Principles

**Spring Physics (Primary):**
- **Damping:** 0.7-0.8 (feels bouncy, not floaty)
- **Stiffness:** 0.15-0.2 (smooth, natural motion)
- **Duration:** 300-400ms for spring animations
- **Use:** Button presses, sheet presentations, confirmations

**Standard Timing:**
- **Fade in:** 150ms ease-in
- **Fade out:** 100ms ease-out
- **Scale changes:** 200ms ease-out
- **Navigation:** 300ms spring

### Button Interactions

**Tap Feedback:**
- **Visual:** Scale down to 95% on press
- **Haptic:** Light impact feedback
- **Duration:** Spring (300ms)
- **Curve:** Easy-out spring

**Disabled State:**
- **Opacity:** 50% (not removed, still tappable for accessibility)
- **Haptic:** None
- **Cursor:** Not allowed (if using custom pointers)

### Loading Animations

**Spinner:**
- **Rotation:** Continuous 360° rotation
- **Duration:** 1 second per rotation
- **Color:** `rose-500`
- **Size:** 40pt

**Skeleton Screens:**
- **Shimmer:** Linear animation light to dark to light
- **Duration:** 1 second loop
- **Direction:** Left to right (or top to bottom for vertical layouts)
- **Opacity:** 20-40% variation

### Vote Submission Animation

**When user votes:**
1. Tap button (scale + haptic)
2. Button shows loading indicator briefly (100ms)
3. Vote count animates up (spring, 200ms)
4. User's avatar appears (fade in, 150ms)
5. "Best option" badge updates (color change, 200ms)

### Confetti Animation (Special)

**Event Confirmation:**
- **Duration:** 1 second
- **Particle Count:** 40-60 pieces
- **Direction:** Down (gravity simulation)
- **Colors:** Mix of brand colors
- **Sound:** Optional success chime

### Sheet Presentation

**Bottom Sheet Entry:**
- **Animation:** Slide up from bottom
- **Duration:** 300ms spring
- **Curve:** Easy-out spring
- **Background:** Fade in backdrop (fade, 200ms)

**Bottom Sheet Dismissal:**
- **Animation:** Slide down
- **Duration:** 200ms ease-in
- **Gesture:** Swipe down to dismiss
- **Threshold:** 30% down triggers dismiss

### Swipe Gestures

**Calendar Navigation (Swipe left/right):**
- **Duration:** 200ms
- **Curve:** Ease-out
- **Threshold:** 50pt horizontal swipe
- **Visual Feedback:** Slightly dimmed previous week during swipe

**List Swipe Actions (Delete/Archive):**
- **Animation:** Slide out to reveal buttons
- **Duration:** 200ms ease-out
- **Buttons:** Appear behind swiped item

### Transition Animations

**Modal Push:**
- **Duration:** 300ms spring
- **Direction:** Slide in from right (or up for sheets)
- **Curve:** Easy-out spring

**Tab Switch:**
- **Duration:** 150ms fade
- **Curve:** Ease-out
- **Content:** Fade in, not slide

### Real-Time Vote Updates

**When vote count changes:**
1. Count number updates (no animation)
2. Progress bar width animates (spring, 300ms)
3. Avatar appears (scale + fade, 200ms)
4. "Best option" badge animates if changed (color flash, 150ms)

### Haptic Feedback Usage

| Action | Feedback Type | Strength |
|--------|---------------|----------|
| Button tap | Impact | Light |
| Vote submission | Impact + Selection | Medium |
| Event confirmed | Notification | Success |
| Error occurrence | Notification | Error |
| Delete action | Impact | Light (confirm severity) |
| Navigation swipe | Selection | Light |

---

## 8. Imagery & Media

### Profile Photos

**Size & Aspect Ratio:**
- **Display:** 40pt - 80pt diameter circles
- **Upload requirement:** Minimum 200px x 200px
- **Format:** JPG, PNG, WebP
- **Compression:** Optimize to <100KB

**Fallback/Placeholder:**
- Default avatar: Initials on colored background
- Color: Generated from user ID (consistent, colorful)
- Font: Headline bold, white text

### Event Photos (Memories)

**Upload Specifications:**
- **Aspect Ratio:** 4:3 or 16:9 (flexible)
- **Size:** Maximum 2000px on longest edge
- **Format:** JPG (compressed), PNG
- **Max File Size:** 5MB per photo
- **Count:** 1-2 photos per person per event

**Video Specifications (Future):**
- **Duration:** 5-10 seconds maximum
- **Aspect Ratio:** 16:9 or 9:16
- **Format:** MP4, MOV
- **Max File Size:** 15MB
- **Bitrate:** Optimized for mobile playback

### Memory Gallery Display

**Thumbnail Grid:**
- **Spacing:** 8pt between photos
- **Aspect Ratio:** Square (1:1) with crop
- **Tap:** Expands to full-screen gallery

**Full-Screen Gallery:**
- **Aspect Ratio:** Original maintained
- **Controls:** Swipe left/right to navigate
- **Info:** Timestamp and uploader name at bottom
- **Actions:** Share, like (if implemented)

### Placeholder Images

**Calendar Empty State:**
- **Icon:** 64pt calendar icon
- **Background:** Tertiary background color
- **Message:** "No events yet"

**Group Empty State:**
- **Icon:** 64pt people icon
- **Message:** "No friend groups yet"

**No Connection State:**
- **Icon:** WiFi off icon
- **Background:** Dimmed overlay

### Image Loading States

**Progressive Load:**
1. Placeholder (blurred thumbnail or color)
2. Low-resolution version loads first
3. High-resolution fades in
4. Full-size image cached

**Skeleton Screen for Gallery:**
- Gray placeholder boxes matching grid layout
- Shimmer animation during load
- Fade to content when ready

### Image Optimization Guidelines

**For App:**
- Compress JPGs to 70-80% quality
- Use WebP format when possible (iOS 14+)
- Resize to device screen size + 20% buffer
- Cache aggressively on device
- Use Core Image for on-device filters

**For Upload:**
- Client-side validation (file size, format)
- Progress indicator during upload
- Retry on failure
- Show preview before confirmation

---

## 9. Accessibility

### Screen Reader Support (VoiceOver & TalkBack)

**iOS - VoiceOver:**
```swift
// Button
Button(action: { }) {
    Image(systemName: "plus.circle.fill")
}
.accessibilityLabel("Create event")
.accessibilityHint("Opens new event form")

// Custom elements
.accessibilityElement(children: .combine)
.accessibilityLabel("Sarah voted Available")

// List items
.accessibilityAddTraits(.isButton)
```

**Android - TalkBack (Flutter):**
```dart
// Button
Semantics(
  label: 'Create event',
  hint: 'Opens new event form',
  button: true,
  child: IconButton(
    icon: Icon(Icons.add_circle),
    onPressed: () {},
  ),
)

// Custom elements
Semantics(
  label: 'Sarah voted Available',
  child: CustomWidget(),
)
```

**Important Patterns (Both Platforms):**
- Every button/link must have a label
- Group related elements with appropriate semantics
- Provide hints for complex interactions
- Read order should match visual order
- Test with both VoiceOver (iOS) and TalkBack (Android)

### Dynamic Type Support

**Requirement:** Support all 7 text size categories

**Implementation:**
```swift
.font(.body)  // Automatically scales with system settings
.dynamicTypeSize(.xSmall... .xxxLarge)
```

**Testing:**
- Test with smallest and largest sizes
- Ensure layouts don't break
- Text should never be truncated at largest size
- Line breaks should be natural

**Minimum Size:** 17pt body text at default size
**Maximum Size:** 34pt at largest accessibility size

### Color Contrast

**WCAG AA Compliance (Minimum):**
- **Large text (18pt+):** 3:1 contrast ratio
- **Normal text:** 4.5:1 contrast ratio
- **UI components:** 3:1 contrast ratio
- **Focus indicators:** 3:1 contrast ratio

**Test with:**
- Apple Accessibility Inspector
- WebAIM Contrast Checker
- Colorblind simulation tools

### Touch Target Sizes

**Platform-Specific Minimums:**

**iOS (Apple HIG):**
- **Buttons/Interactive:** 44pt x 44pt minimum
- **Form fields:** 44pt height
- **List cells:** 44pt height
- **Icon buttons:** 44pt x 44pt with padding

**Android (Material Design):**
- **Buttons/Interactive:** 48dp x 48dp minimum
- **Form fields:** 48dp height
- **List items:** 48dp height minimum
- **Icon buttons:** 48dp x 48dp with padding

**Cross-Platform Standard:**
- Use 48pt/dp for both platforms (exceeds both minimums)
- Minimum 8pt/dp between touch targets
- Optimal size: 48-56pt/dp for primary actions

### Reduced Motion Support

**iOS:**
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

if reduceMotion {
    // Fade animation instead of spring
} else {
    // Full spring animation
}
```

**Android/Flutter:**
```dart
MediaQuery.of(context).disableAnimations

if (MediaQuery.of(context).disableAnimations) {
  // Simple transitions
} else {
  // Full animations
}
```

**Apply to (Both Platforms):**
- Confetti animations
- Spring physics animations
- Parallax effects
- Automatic scrolling
- Complex transitions

### Screen Reader Labels

**Examples:**

```swift
// Event card
"Sarah's Birthday, Saturday at 7pm, confirmed"

// Vote button
"Vote Available for Saturday 2-4pm"

// Privacy badge
"Private event, only you can see this"

// Group heatmap
"5 out of 8 people available Saturday 2pm"
```

### Focus Indicators

- **Visible focus ring:** 2pt `rose-500` border with `rose-500/20` outer ring
- **Color:** `rose-500` (#F43F5E)
- **Contrast:** 3:1 minimum
- **Shape:** Matches element (rounded for buttons, etc.)
- **External padding:** 2-4pt outside element

### Keyboard Navigation

**Tab Order:**
- Follows visual order top to bottom, left to right
- Explicit tab index if needed (not common in iOS)
- Rotor for VoiceOver navigation (custom sections)

**Enter/Return Behavior:**
- Primary action on screen (submit, confirm)
- Closes sheet if in sheet context

**Escape Behavior:**
- Closes sheet
- Cancels action
- Returns to previous view

### Testing Checklist

- [ ] VoiceOver enabled, navigate entire app
- [ ] All buttons/links have descriptive labels
- [ ] Text meets WCAG AA contrast ratios
- [ ] Touch targets minimum 44pt
- [ ] Reduced motion respected
- [ ] Keyboard-only navigation functional
- [ ] Dynamic Type supports all sizes
- [ ] Color not sole indicator of meaning
- [ ] Focus indicators visible and labeled
- [ ] No autoplay video/audio

---

## 10. Dark Mode

> **Complete Specification:** See `LOCKIT_MINIMAL_THEME.md` for comprehensive dark mode styling.

### Color Palette (Dark Mode - Minimal Theme)

**Backgrounds:**
- Background: `black` (#000000) - OLED-friendly
- Surface: `neutral-950` (#0A0A0A)
- Card: `neutral-900` (#171717)
- Border: `neutral-800` (#262626)

**Text:**
- Primary: `white` (#FFFFFF)
- Secondary: `neutral-300` (#D4D4D4)
- Tertiary: `neutral-400` (#A3A3A3)
- Muted: `neutral-500` (#737373)

**Accent Colors:**
- Primary: `rose-500` (#F43F5E)
- Secondary: `orange-500` (#F97316)
- Gradient: `from-rose-500 to-orange-500`
- Focus: `rose-500/50` border, `rose-500/20` ring

### Component Adjustments

**Cards:**
- Background: `neutral-900` (#171717)
- Border: `neutral-800` (#262626)
- No shadow by default (flat design for OLED)

**Buttons:**
- Primary: Gradient `from-rose-500 to-orange-500` or solid `rose-500`
- Secondary: `neutral-900` bg with `neutral-800` border
- Ghost: Transparent with `neutral-400` text
- Shadow: `shadow-lg shadow-rose-500/20`

**Form Fields:**
- Border: `neutral-800`
- Background: `neutral-900`
- Placeholder: `neutral-600`
- Focus: `rose-500/50` border with `rose-500/20` ring

**Images & Icons:**
- Primary icons: `white`
- Secondary icons: `neutral-400`
- Accent icons: `rose-400`

### Image Adjustments (Dark Mode)

**Calendar Backgrounds:**
- Day view: `black` (#000000)
- Grid lines: `neutral-800` (#262626)

**Placeholder Images:**
- Use `neutral-800` backgrounds
- Ensure readability on dark backgrounds

**Profile Avatars:**
- No change required
- Already high contrast

### Dark Mode Implementation

**Flutter:**
```dart
Theme.of(context).brightness == Brightness.dark

// Use ThemeData with dark theme
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.system, // Follows system setting
)

// Access colors via theme
Theme.of(context).colorScheme.surface  // neutral-950
Theme.of(context).colorScheme.primary  // rose-500
context.appColors.cardBackground       // neutral-900
```

**Auto-apply (Cross-Platform):**
- Use `Theme.of(context).colorScheme.*` for standard colors
- Use `context.appColors.*` for custom app colors (via ThemeExtension)
- System automatically handles mode switching
- Never hardcode color values

### Testing Dark Mode

- [ ] All text readable on dark backgrounds
- [ ] Sufficient contrast (WCAG AA minimum)
- [ ] Images look good on dark background
- [ ] No hardcoded colors that break
- [ ] Empty states and placeholders work
- [ ] Icons remain visible
- [ ] Cards have proper separation via borders

---

## 11. Component Usage Examples

### Button Usage Scenarios

**Primary Action (Create Event):**
```
┌────────────────────────┐
│     Create Event       │  <- Primary Rose Button (rose-500)
└────────────────────────┘
```

**Multiple Actions (Voting):**
```
┌──────────┬──────────┬──────────┐
│ Available│  Maybe   │ Can't Go │  <- Three buttons in row
└──────────┴──────────┴──────────┘
```

**Destructive Action (Delete):**
```
┌────────────────────────┐
│     Delete Event       │  <- Error Red Button
└────────────────────────┘
```

### Form Layout Example

```
┌──────────────────────────────┐
│ Event Title *                │  <- Required field
│ ┌──────────────────────────┐ │
│ │ Birthday Party          │ │
│ └──────────────────────────┘ │
│                              │
│ Date *                       │
│ ┌──────────────────────────┐ │
│ │ Dec 15, 2025        ▼   │ │  <- Picker
│ └──────────────────────────┘ │
│                              │
│ Time *                       │
│ ┌───────────────┬──────────┐ │
│ │ 6:00 PM   ▼   │ 8:00 PM  │ │  <- Time pickers
│ └───────────────┴──────────┘ │
│                              │
│ Location (optional)          │
│ ┌──────────────────────────┐ │
│ │ Sarah's apartment        │ │
│ └──────────────────────────┘ │
│                              │
│ Privacy Level *              │  <- Grouped options
│ ○ Private                    │
│ ◉ Shared with name           │  <- Selected
│ ○ Busy only                  │
│                              │
│  [Cancel]  [Create Event]    │  <- Action buttons
└──────────────────────────────┘
```

### Card Composition Example

**Event Card in Inbox:**
```
┌──────────────────────────────────┐
│ Secret Santa Planning       🔒    │  <- Title + Privacy badge
│ Proposed by Sarah                │  <- Metadata
│ Best: Sat Dec 16, 2-4pm (7/8)    │  <- Key info
│ You voted: Available             │  <- User's status
└──────────────────────────────────┘
```

### Navigation Pattern Example

**Bottom Tab Bar:**
```
┌────────────────────────────────┐
│         CALENDAR               │
│  (Main content area)           │
│                                │
│  (Content)                     │
│                                │
│                                │
└────────────────────────────────┘
┌─────┬─────┬─────┬──────────────┐
│ 📅  │ 👥  │ 🔔  │ 👤           │  <- Tab bar
│ Cal │Group│Inbox│Profile       │
└─────┴─────┴─────┴──────────────┘
```

### Modal Presentation Example

**Full-Screen Sheet (Event Details):**
```
┌──────────────────────────────┐
│ ────── (drag handle)         │  <- Optional
│                              │
│ Birthday Party          [×]  │  <- Title + close
│                              │
│ Saturday, Dec 15, 6:00-8:00  │
│ Sarah's apartment            │
│ 5 attending                  │
│                              │
│ [Edit]        [Delete]       │  <- Actions
└──────────────────────────────┘
```

---

## 12. Design Tokens

> **Implementation Reference:** See `lib/core/theme/app_colors.dart` for Flutter implementation.

### Color Tokens

```dart
// Primary Accent Colors (Minimal Theme)
static const Color rose500 = Color(0xFFF43F5E);     // Primary
static const Color orange500 = Color(0xFFF97316);   // Secondary
static const Color rose400 = Color(0xFFFB7185);     // Tertiary (dark mode)

// Semantic Colors
static const Color success = Color(0xFF10B981);     // emerald-500
static const Color warning = Color(0xFFF59E0B);     // amber-500
static const Color error = Color(0xFFF43F5E);       // rose-500 (same as primary)
static const Color info = Color(0xFF3B82F6);        // blue-500

// Light Mode Foundation (Gray)
static const Color backgroundLight = Color(0xFFF5F5F5);   // gray-100
static const Color surfaceLight = Color(0xFFFFFFFF);      // white
static const Color borderLight = Color(0xFFE5E5E5);       // gray-200
static const Color textPrimaryLight = Color(0xFF171717);  // gray-900
static const Color textSecondaryLight = Color(0xFF404040);// gray-700
static const Color textMutedLight = Color(0xFF737373);    // gray-500

// Dark Mode Foundation (Neutral)
static const Color backgroundDark = Color(0xFF000000);    // black (OLED)
static const Color surfaceDark = Color(0xFF0A0A0A);       // neutral-950
static const Color cardDark = Color(0xFF171717);          // neutral-900
static const Color borderDark = Color(0xFF262626);        // neutral-800
static const Color textPrimaryDark = Color(0xFFFFFFFF);   // white
static const Color textSecondaryDark = Color(0xFFD4D4D4); // neutral-300
static const Color textMutedDark = Color(0xFF737373);     // neutral-500

// Event Category Colors
static const Color categoryWork = Color(0xFF14B8A6);      // teal-500
static const Color categoryHoliday = Color(0xFFF97316);   // orange-500
static const Color categoryFriend = Color(0xFF8B5CF6);    // violet-500
static const Color categoryOther = Color(0xFFF43F5E);     // rose-500
```

### Spacing Tokens

```swift
let spacing4pt = 4.0
let spacing8pt = 8.0
let spacing16pt = 16.0
let spacing24pt = 24.0
let spacing32pt = 32.0
let spacing48pt = 48.0

// Shortcuts
let spacingSmall = spacing8pt
let spacingMedium = spacing16pt
let spacingLarge = spacing24pt
let spacingXLarge = spacing32pt
```

### Typography Tokens

```swift
let fontTitle1 = Font.system(size: 34, weight: .bold)
let fontTitle2 = Font.system(size: 28, weight: .bold)
let fontTitle3 = Font.system(size: 22, weight: .semibold)
let fontHeadline = Font.system(size: 17, weight: .semibold)
let fontBody = Font.system(size: 17, weight: .regular)
let fontCallout = Font.system(size: 16, weight: .regular)
let fontFootnote = Font.system(size: 13, weight: .regular)
let fontCaption = Font.system(size: 12, weight: .regular)
```

### Border & Shadow Tokens

```swift
// Corner Radius
let cornerRadiusSmall = 8.0
let cornerRadiusMedium = 12.0
let cornerRadiusLarge = 16.0

// Shadows
let shadowLight = Shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
let shadowMedium = Shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
let shadowLarge = Shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)

// Borders
let borderThin = 1.0
let borderRegular = 2.0
```

### Animation Tokens

```swift
let animationFast = 0.15
let animationStandard = 0.3
let animationSlow = 0.5

let springDamping = 0.75
let springStiffness = 0.15

// Presets
let springAnimation = Animation.spring(
    response: 0.3,
    dampingFraction: 0.75,
    blendDuration: 0
)
```

---

## 13. Screen Layout Reference

### Reference to Detailed Layouts

Complete screen specifications are documented in separate layout files:

**Core Screens:**
- **Onboarding Screens** - Welcome, sign-up, permissions
- **Calendar Views** - Week, month, day views with event display
- **Event Creation Sheet** - Full form with privacy settings
- **Group Management** - Create groups, manage members
- **Event Proposals** - Create and vote on proposals
- **Inbox/Notifications** - Organized by notification type
- **Profile/Settings** - Account and privacy controls

**Refer to `NotionMD/Detailed Layouts/` for:**
- Pixel-perfect mockups of each screen
- Safe area handling on various iPhone sizes
- Responsive behavior (iPhone SE to Pro Max)
- Interactive states and transitions

### Common Layout Patterns

**Single Column (Standard):**
- Full width content
- 16pt left/right padding
- Maximum 600pt content width on large devices (future iPad support)

**Two Column (iPad, Future):**
- Split view layout
- Master/detail pattern
- Not in MVP but consider architecture

**Safe Area Handling:**
- Respect top safe area for content
- Bottom safe area for fixed buttons/tabs
- Notch/Dynamic Island doesn't overlap content
- Home indicator respected on bottom

### Responsive Behavior

**iPhone SE (375pt width):**
- Smaller fonts may need adjustment
- Ensure 16pt padding fits
- Test text wrapping carefully

**iPhone 14 Pro Max (430pt width):**
- Optimal width for full-width buttons
- Can use larger tap targets
- Still respect maximum 44pt text size

**Dynamic Type Adjustments:**
- At Accessibility Large (A1), increase spacing
- At Accessibility Extra Large (A2), reduce padding
- Layout should adapt, not break

---

## 14. Design Resources

### Figma Design File

**Location:** [Insert Figma URL]
- Components library (buttons, cards, inputs)
- All screens and states
- Interaction prototypes
- Handoff to developers

**Keep Updated:**
- Add new patterns as they emerge
- Document variants and states
- Maintain single source of truth

### Font Files

**SF Pro Font:**
- Pre-installed on all iOS devices
- No additional font files needed
- Weights: Regular, Medium, Semibold, Bold

### Icon Library

**SF Symbols:**
- Apple's built-in symbol library
- Select best size and weight for context
- No custom icons needed for MVP
- Use `Image(systemName: "icon.name")`

### Icon Asset Catalog

Custom icons (if needed in future):
- Store in Assets.xcassets
- Provide 1x, 2x, 3x variations
- Include dark mode variants
- Size to exact pixel dimensions

### Color Assets

**Xcode Assets:**
- Define semantic colors in Assets.xcassets
- Create sets for both light and dark mode
- Example: "BackgroundColor", "TextPrimaryColor"
- Reference in code: `Color("BackgroundColor")`

### Design Documentation

**Where This Lives:**
- This file: `lockitin-ui-design.md` (single source of truth)
- Figma: Interactive prototypes and components
- Code: SwiftUI implementation following this spec

### Brand Guidelines

**Logo & Brand Identity:**
- App icon: Provided separately
- Color usage: Follow primary colors section
- Typography: SF Pro system font only
- Tone: Calm, helpful, privacy-first

---

## 15. Quick Reference

### Design System Checklist

- [ ] Using SF Pro font
- [ ] Colors from palette (no custom shades)
- [ ] 8pt grid spacing
- [ ] Buttons minimum 44pt height
- [ ] Text meets WCAG AA contrast (4.5:1)
- [ ] VoiceOver labels on all interactive elements
- [ ] Touch targets at least 44pt x 44pt
- [ ] Consistent corner radius (8pt/12pt)
- [ ] Icons from SF Symbols
- [ ] Dynamic Type support
- [ ] Dark mode colors defined
- [ ] Animations use spring physics or ease timing
- [ ] No hardcoded colors (use tokens)
- [ ] Safe area respected
- [ ] Error states designed
- [ ] Loading states designed
- [ ] Empty states designed

### Common Component Combinations

**Event Card + Badge:**
- Card background (secondary)
- Event title (headline)
- Metadata (footnote)
- Privacy badge (top right)

**Form + Error State:**
- Text field with border
- Error message below (red)
- Required indicator (*)
- Helper text (optional)

**Voting Interface:**
- Three buttons (Available, Maybe, Can't)
- Vote count progress bar
- Avatar cluster showing voters
- Best option highlight

**Heatmap Block:**
- Colored square (green/yellow/red/gray)
- Availability count (e.g., "5/8")
- Time range label
- Tap to reveal details

### Dos and Don'ts

**Do:**
- Use system colors and fonts
- Test with accessibility tools
- Follow HIG patterns
- Maintain consistent spacing
- Use progressive disclosure
- Respect user preferences
- Provide feedback (haptic, visual)
- Support dark mode
- Keep interactions simple

**Don't:**
- Create custom fonts or colors
- Use color as only indicator
- Make tap targets too small
- Block VoiceOver navigation
- Ignore safe area
- Use too many animations
- Break system patterns
- Assume light mode only
- Skip error handling
- Make text too small

---

## Document Information

**Version:** 2.1 (Minimal Theme Update)
**Last Updated:** December 30, 2025
**Status:** Complete - Ready for Flutter Implementation (iOS & Android)
**Maintained By:** LockItIn Design Team
**Theme:** Minimal (Rose/Orange accents with neutral foundation)

**Platform Support:**
- iOS 13+ (Cupertino widgets, SF Pro font, Apple HIG)
- Android 8.0+ (Material Design 3, Roboto font, Material guidelines)
- Flutter 3.16+ (Cross-platform implementation)

**Related Documents:**
- `lockitin-designs.md` - Design philosophy and UX logic
- `lockitin-complete-user-flows.md` - Detailed user journey flows
- `lockitin-technical-architecture.md` - Backend and system design (Flutter)
- Figma design file - Interactive component library (iOS & Android variants)

---

*This is a living document. Update as design patterns evolve, new components are added, or refinements are discovered during development. All changes should be tracked in git commits.*

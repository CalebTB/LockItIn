# LockItIn UI Design System

**Comprehensive design system, visual language, and component specifications for the LockItIn cross-platform mobile app (iOS & Android).**

*Last Updated: December 6, 2025*

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

### Primary Colors (Brand)

| Color | Hex Code | Usage | Light/Dark |
|-------|----------|-------|-----------|
| Primary Blue | #007AFF | Buttons, links, highlights | Both |
| Success Green | #34C759 | Confirmations, positive actions | Both |
| Warning Yellow | #FFCC00 | Cautions, pending states | Both |
| Error Red | #FF3B30 | Errors, destructive actions | Both |

### Neutral Colors (Light Mode)

| Color Name | Hex Code | Usage |
|------------|----------|-------|
| Background | #FFFFFF | Main app background |
| Secondary Background | #F2F2F7 | Cards, grouped content |
| Tertiary Background | #E5E5EA | Subtle backgrounds, separators |
| Text Primary | #000000 | Main text, headers |
| Text Secondary | #3C3C43 | Secondary text, descriptions |

### Neutral Colors (Dark Mode)

| Color Name | Hex Code | Usage |
|------------|----------|-------|
| Background | #000000 | Main app background |
| Secondary Background | #1C1C1E | Cards, grouped content |
| Tertiary Background | #2C2C2E | Subtle backgrounds, separators |
| Text Primary | #FFFFFF | Main text, headers |
| Text Secondary | #AEAEB2 | Secondary text, descriptions |

### Event Color Coding

| Color | Event Type | Meaning |
|-------|-----------|---------|
| Blue (#007AFF) | Personal events | Your private/personal calendar |
| Green (#34C759) | Group events (confirmed) | Events you're attending with groups |
| Purple (#8B5CF6) | Pending proposals | Events awaiting your vote |
| Gray (#D1D5DB) | Busy-only events | Your busy blocks (no details shared) |
| Red (#FF3B30) | Conflicts/Declined | Declined invites or scheduling conflicts |

### Heatmap Colors (Availability)

| Color | Availability | Percentage |
|-------|--------------|-----------|
| Green | Everyone free | >75% available |
| Yellow | Mixed availability | 50-75% available |
| Red | Most people busy | <50% available |
| Gray | No visibility | All private or no data |

### Color Accessibility

All color combinations meet **WCAG AA** contrast requirements (4.5:1 for text):

- **Text on Background:** Black text on white: 21:1
- **Text on Secondary Background:** Black text on #F2F2F7: 18.5:1
- **Buttons:** Blue on white: 3.9:1 (sufficient for UI components)
- **Status Icons:** Always paired with text labels for colorblind users

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
- **Background:** Primary Blue (#007AFF)
- **Text Color:** White
- **Height:** 44pt minimum
- **Width:** Full width (preferred) or 120pt+ minimum
- **Corner Radius:** 8pt
- **Font:** Headline semibold
- **Padding:** 12pt vertical, 16pt horizontal

**States:**
- Default: Solid blue
- Pressed: Slight scale down (95%) with haptic feedback
- Disabled: 50% opacity
- Loading: Spinner replaces text

#### Secondary Button
- **Background:** Transparent / Light gray border
- **Border:** 1pt gray
- **Text Color:** Primary Blue
- **Height:** 44pt minimum
- **Font:** Headline semibold

**States:**
- Default: Clear with border
- Pressed: Light gray background
- Disabled: 50% opacity

#### Text Button
- **Background:** Transparent
- **Text Color:** Primary Blue
- **Height:** 44pt minimum
- **Font:** Callout or footnote
- **Padding:** 8pt

**States:**
- Default: Text only
- Pressed: Text becomes darker
- Disabled: 50% opacity

#### Danger Button
- **Background:** Error Red (#FF3B30)
- **Text Color:** White
- **Usage:** Delete, cancel, destructive actions
- **Identical styling to Primary Button** but with red background

### Input Fields

#### Text Field
- **Height:** 44pt minimum
- **Border:** 1pt gray (#E5E5EA on light, #2C2C2E on dark)
- **Corner Radius:** 8pt
- **Padding:** 12pt horizontal, 10pt vertical
- **Font:** Body regular
- **Placeholder:** Text Secondary color

**States:**
- Default: Light gray border
- Focused: Blue border (2pt), keyboard open
- Error: Red border (#FF3B30)
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
- **On Color:** Primary Blue
- **Off Color:** Gray
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
- **Color:** Primary Blue
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
- **Background:** Tertiary background color
- **Progress:** Primary blue
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

- **Active/Tappable:** Primary Blue
- **Inactive/Disabled:** Gray (50% opacity)
- **Destructive:** Error red
- **Success:** Success green
- **Neutral:** Text secondary color

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
- **Color:** Primary Blue
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

- **Visible focus ring:** 2pt blue border
- **Color:** Primary Blue (#007AFF)
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

### Color Palette (Dark Mode)

**Backgrounds:**
- Background: #000000
- Secondary: #1C1C1E
- Tertiary: #2C2C2E
- Opposite for light mode reference (provided above)

**Text:**
- Primary: #FFFFFF
- Secondary: #AEAEB2

**Colors (Unchanged):**
- Primary Blue: #007AFF (system automatically inverts if needed)
- Success Green: #34C759
- Warning Yellow: #FFCC00
- Error Red: #FF3B30

### Component Adjustments

**Cards:**
- Background: Secondary background (#1C1C1E)
- Border: Subtle 1pt border if needed (optional)
- Shadow: Darker, more pronounced for depth

**Buttons:**
- Primary: Same blue (#007AFF) works in both modes
- Secondary: Gray border on dark mode
- Text: White on dark backgrounds

**Form Fields:**
- Border: Light gray (#AEAEB2) on dark background
- Background: Tertiary (#2C2C2E)
- Text: White

**Images & Icons:**
- Icon Color: Adjust for contrast (lighter on dark)
- Profile Photos: No adjustment needed
- Event Photos: No adjustment needed

### Image Adjustments (Dark Mode)

**Calendar Backgrounds:**
- Day view: #000000 instead of white
- Grid lines: Lighter gray (#2C2C2E)

**Placeholder Images:**
- Invert bright colors
- Ensure readability on dark backgrounds

**Profile Avatars:**
- No change required
- Already high contrast

### Dark Mode Implementation

**iOS (SwiftUI):**
```swift
@Environment(\.colorScheme) var colorScheme

if colorScheme == .dark {
    // Dark mode specific
} else {
    // Light mode specific
}
```

**Android/Flutter (Material):**
```dart
Theme.of(context).brightness == Brightness.dark

// Or use ThemeData with dark theme
MaterialApp(
  theme: lightTheme,
  darkTheme: darkTheme,
  themeMode: ThemeMode.system, // Follows system setting
)
```

**Auto-apply (Cross-Platform):**
- **iOS**: Use semantic colors (`.background`, `.foreground`)
- **Android**: Use `Theme.of(context).colorScheme.surface`, `.primary`, etc.
- System automatically handles mode switching
- Avoid hardcoding colors on both platforms

### Testing Dark Mode

- [ ] All text readable
- [ ] Sufficient contrast in both modes
- [ ] Images look good on dark background
- [ ] No hardcoded colors that break
- [ ] Empty states and placeholders work
- [ ] Icons remain visible
- [ ] Cards have proper elevation/separation

---

## 11. Component Usage Examples

### Button Usage Scenarios

**Primary Action (Create Event):**
```
┌────────────────────────┐
│     Create Event       │  <- Primary Blue Button
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

### Color Tokens

```swift
// Primary Colors
let primaryBlue = Color(hex: "#007AFF")
let successGreen = Color(hex: "#34C759")
let warningYellow = Color(hex: "#FFCC00")
let errorRed = Color(hex: "#FF3B30")

// Neutral Light Mode
let backgroundLight = Color(hex: "#FFFFFF")
let secondaryBackgroundLight = Color(hex: "#F2F2F7")
let tertiaryBackgroundLight = Color(hex: "#E5E5EA")
let textPrimaryLight = Color(hex: "#000000")
let textSecondaryLight = Color(hex: "#3C3C43")

// Neutral Dark Mode
let backgroundDark = Color(hex: "#000000")
let secondaryBackgroundDark = Color(hex: "#1C1C1E")
let tertiaryBackgroundDark = Color(hex: "#2C2C2E")
let textPrimaryDark = Color(hex: "#FFFFFF")
let textSecondaryDark = Color(hex: "#AEAEB2")

// Event Colors
let eventPersonal = primaryBlue
let eventGroup = successGreen
let eventPending = Color(hex: "#8B5CF6")
let eventBusyOnly = Color(hex: "#D1D5DB")
let eventDeclined = errorRed
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

**Version:** 2.0 (Cross-Platform Update)
**Last Updated:** December 6, 2025
**Status:** Complete - Ready for Flutter Implementation (iOS & Android)
**Maintained By:** LockItIn Design Team

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

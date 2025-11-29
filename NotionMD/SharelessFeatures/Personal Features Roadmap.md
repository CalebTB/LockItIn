# Personal Features Roadmap

**Goal:** Transform Shareless from a "group events app" into a daily-use personal calendar with killer group features.

**Current State:** 80% group coordination, 20% personal calendar

**Target State:** 60% personal daily use, 40% group coordination

---

## 🎯 Why Personal Features Matter

### The Engagement Problem:

```
User who only uses app for group events:
├─ Opens app 2-3 times per month
├─ Only when invited to proposals
├─ Forgets app exists between events
└─ Doesn't form habit, eventually churns

User who uses app daily:
├─ Opens app every morning to check schedule
├─ Uses it for personal planning
├─ Sees group proposals when they come in
├─ Forms habit, stays engaged
└─ Much more likely to upgrade to premium
```

### Success Metrics:

- **Daily Active Users (DAU)** - Target: 40% of MAU
- **Session frequency** - Target: 5+ times per week
- **Time in app** - Target: 3+ minutes per session
- **Feature adoption** - Target: 80% use personal features

---

## 🥇 TIER 1: Quick Wins (High Impact, Low Effort)

### 1. Smart Morning Briefing ⭐⭐⭐⭐⭐

**Development Time:** 2-3 days

**Priority:** V1.1 (June 2025)

**What it is:**

One-screen daily summary shown when opening app in the morning

**Features:**

```
Good morning! ☀️

TODAY - Saturday, Nov 30

📅 YOUR DAY:
• 10:00 AM - Coffee with Sarah
  🚗 Leave by 9:45 AM
  
• 2:00 PM - Game Night (Group)
  🚗 Leave by 1:30 PM
  👥 8 people attending

🗳️ PENDING:
• 2 proposals need your vote
  (Friendsgiving, Movie Night)

☀️ WEATHER:
• Sunny, 68°F
• Perfect day for outdoor events!

📊 THIS WEEK:
• 5 events scheduled
• 3 with friends, 2 personal
```

**Why it's powerful:**

- ✅ One screen tells you everything you need
- ✅ Replaces checking multiple apps
- ✅ Creates morning habit ("check Shareless first")
- ✅ Low development cost (aggregating existing data)

**Technical Requirements:**

- Pull today's events from database
- Calculate "leave by" times from existing travel feature
- Count pending votes
- Optional: Weather API integration (OpenWeather)
- Cache overnight, refresh on app open

**Free vs Premium:**

- Free: Basic briefing (events + votes)
- Premium: Weather, week preview, insights

---

### 2. Quick Add (Natural Language) ⭐⭐⭐⭐⭐

**Development Time:** 3-4 days

**Priority:** V1.1 (June 2025)

**What it is:**

Fast event creation using natural language parsing

**Examples:**

```
User types: "Coffee with Mom tomorrow 2pm"
↓
App creates:
├─ Title: Coffee with Mom
├─ Date: Tomorrow (Dec 1)
├─ Time: 2:00 PM
├─ Duration: 1 hour (default)
└─ [Create Event] or [Edit Details]

"Dentist next Tuesday 9am downtown"
↓
├─ Title: Dentist
├─ Date: Next Tuesday (Dec 3)
├─ Time: 9:00 AM
├─ Location: Search "downtown" dentists
└─ Sets reminder

"Lunch 12:30"
↓
├─ Title: Lunch
├─ Date: Today
├─ Time: 12:30 PM
└─ [Create Event]
```

**Why it's powerful:**

- ✅ Faster than opening Apple Calendar
- ✅ Reduces friction for personal events
- ✅ Makes adding events effortless
- ✅ People use it multiple times per day

**Technical Requirements:**

- Basic NLP parsing (regex patterns)
- Time/date extraction library
- Location search (MapKit)
- Default duration logic (1 hour)

**Parsing patterns to support:**

- Time: "2pm", "14:00", "2:30 PM"
- Date: "tomorrow", "next Tuesday", "Dec 5", "12/5"
- Duration: "2 hours", "30 min", "all day"
- Location: "at [place]", "@ [place]"

**Free vs Premium:**

- Free: All features included
- Premium: None (drives daily use for everyone)

---

### 3. Today Widget ⭐⭐⭐⭐⭐

**Development Time:** 4-5 days

**Priority:** V1.1 (June 2025)

**What it is:**

iOS home screen widget showing schedule at a glance

**Widget Sizes:**

**Small Widget (2x2):**

```
┌─────────────────┐
│ TODAY           │
│                 │
│ 10:00 Coffee    │
│ 2:00 Game Night │
│ 🗳️ 2 votes      │
└─────────────────┘
```

**Medium Widget (4x2):**

```
┌─────────────────────────────────┐
│ TODAY - Sat, Nov 30             │
│                                 │
│ 10:00 AM - Coffee with Sarah    │
│ 🚗 Leave at 9:45                │
│                                 │
│ 2:00 PM - Game Night            │
│ 👥 8 attending                  │
│                                 │
│ 🗳️ 2 proposals need votes       │
└─────────────────────────────────┘
```

**Large Widget (4x4):**

```
┌─────────────────────────────────┐
│ YOUR WEEK                       │
│                                 │
│ TODAY:                          │
│ • 10:00 Coffee                  │
│ • 2:00 Game Night               │
│                                 │
│ TOMORROW:                       │
│ • 11:00 Brunch                  │
│                                 │
│ MONDAY:                         │
│ • No events scheduled           │
│                                 │
│ 🗳️ Pending: 2 votes             │
└─────────────────────────────────┘
```

**Why it's powerful:**

- ✅ Glanceable without opening app
- ✅ iOS 14+ users love widgets
- ✅ Free marketing (visible on home screen)
- ✅ Constant reminder app exists
- ✅ Drive opens when tapping widget

**Technical Requirements:**

- WidgetKit (SwiftUI)
- Timeline provider (updates every 15-60 min)
- Deep linking (tap to open app)
- Handle empty states gracefully

**Free vs Premium:**

- Free: Small + Medium widgets
- Premium: Large widget (week view)

---

### 4. Time Blocking / Focus Modes ⭐⭐⭐⭐

**Development Time:** 3-4 days

**Priority:** V1.1 (June 2025)

**What it is:**

Personal calendar blocks for focused work/activities

**Block Types:**

```
🧠 Deep Work
🏋️ Exercise
🧘 Personal Time
🚗 Commute
🍽️ Meal
😴 Sleep
📚 Study
🎨 Creative Time
✨ Custom...
```

**Creation Flow:**

```
┌─────────────────────────────────────┐
│ Block Time for:                     │
│ ⦿ Deep Work                         │
│ ○ Exercise                          │
│ ○ Personal Time                     │
│ ○ Commute                           │
│ ○ Custom...                         │
│                                     │
│ When: Today, 9 AM - 12 PM           │
│                                     │
│ Show as:                            │
│ ⦿ Busy (friends see busy block)     │
│ ○ Private (invisible to friends)    │
│ ○ Available (can still propose)     │
│                                     │
│ Protect this time:                  │
│ ☑ Block group event proposals       │
│ ☑ Auto-decline if conflicts         │
│ ☐ Set iOS Focus mode                │
│                                     │
│ [Create Block]                      │
└─────────────────────────────────────┘
```

**Calendar view:**

```
9:00 AM  ┌──────────────────────┐
         │ 🧠 Deep Work          │
         │ (Protected)           │
12:00 PM └──────────────────────┘
         ┌──────────────────────┐
1:00 PM  │ 🍽️ Lunch             │
         └──────────────────────┘
```

**Why it's powerful:**

- ✅ Helps people protect personal time
- ✅ Differentiates from basic calendars
- ✅ Ties into privacy/boundary features
- ✅ Useful for daily planning
- ✅ Can integrate with iOS Focus modes

**Technical Requirements:**

- New event type: "time_block"
- Visual distinction in calendar UI
- Conflict prevention logic
- Optional: iOS Focus mode API integration

**Free vs Premium:**

- Free: 3 time blocks per day
- Premium: Unlimited blocks, recurring blocks, iOS Focus integration

---

## 🥈 TIER 2: Strong Value (Medium Impact, Medium Effort)

### 5. Routine Templates ⭐⭐⭐⭐

**Development Time:** 5-6 days

**Priority:** V1.2 (October 2025)

**What it is:**

Pre-built routines that automatically apply to your calendar

**Template Library:**

```
┌─────────────────────────────────────┐
│ 🌅 Morning Routine                  │
│ • 7:00 AM - Wake up                 │
│ • 7:30 AM - Exercise                │
│ • 8:30 AM - Breakfast               │
│ • 9:00 AM - Start work              │
│                                     │
│ Apply to: ⦿ Weekdays ○ All days    │
│ [Apply Routine]                     │
├─────────────────────────────────────┤
│ 🏋️ Workout Schedule                 │
│ • Mon/Wed/Fri: Gym 6 PM (1h)        │
│ • Tue/Thu: Yoga 7 PM (1h)           │
│ • Sat: Long run 8 AM (1.5h)         │
│                                     │
│ Apply to: Next 4 weeks              │
│ [Apply Routine]                     │
├─────────────────────────────────────┤
│ 📚 Study Schedule                   │
│ • Mon-Fri: Study 6-8 PM             │
│ • Sat: Review 10 AM-12 PM           │
│ • Sun: Rest day                     │
│                                     │
│ Apply to: This semester             │
│ [Apply Routine]                     │
└─────────────────────────────────────┘

[+ Create Custom Routine]
```

**Custom Routine Builder:**

```
┌─────────────────────────────────────┐
│ New Routine                         │
│                                     │
│ Name: My Morning Flow               │
│                                     │
│ Events:                             │
│ • 6:30 AM - Meditation (30 min)     │
│ • 7:00 AM - Workout (1 hour)        │
│ • 8:00 AM - Breakfast (30 min)      │
│ [+ Add Event]                       │
│                                     │
│ Repeat:                             │
│ ☑ Mon ☑ Tue ☑ Wed ☑ Thu ☑ Fri     │
│ ☐ Sat ☐ Sun                         │
│                                     │
│ Duration: Next 30 days              │
│                                     │
│ [Create Routine]                    │
└─────────────────────────────────────┘
```

**Why it's powerful:**

- ✅ Natural extension of template system
- ✅ Helps people build better habits
- ✅ Set once, applies automatically
- ✅ Premium upsell opportunity

**Technical Requirements:**

- Routine template data model
- Recurrence logic (extends event system)
- Batch event creation
- Easy pause/resume/modify

**Pre-built Routines to Include:**

- Morning Routine (various wake times)
- Evening Routine
- Workout Schedule (gym, yoga, running)
- Study Schedule (student-focused)
- Work Schedule (9-5, freelance, shifts)
- Sleep Schedule
- Meal Planning

**Free vs Premium:**

- Free: Use 2 pre-built routines
- Premium: Unlimited routines, create custom, share with friends

---

### 6. Smart Suggestions / Auto-Events ⭐⭐⭐⭐

**Development Time:** 1-2 weeks

**Priority:** V1.2 (October 2025)

**What it is:**

App proactively suggests helpful events based on patterns

**Suggestion Types:**

**1. Commute Time:**

```
💡 Add commute time?

You have "Meeting at Office" at 9 AM tomorrow.

Add 30-min commute before?
🚗 Leave home at 8:30 AM

[Add Commute] [No Thanks]
```

**2. Prep Time:**

```
💡 Prep time reminder?

"Surprise Birthday Party" is at 7 PM Saturday.

Add 30-min prep block before?
(Get ready, gather gifts)

[Add Prep Time] [Dismiss]
```

**3. Meal Breaks:**

```
💡 Don't forget to eat!

You have 3 hours free at lunchtime.
Want to block 30 min for lunch?

Suggested: 12:30 PM - 1:00 PM

[Add Lunch Break] [I'm Good]
```

**4. Buffer Time:**

```
💡 Add buffer time?

You have back-to-back events:
• 2:00 PM - Meeting
• 3:00 PM - Coffee

Add 15-min buffer between?

[Add Buffer] [No Thanks]
```

**5. Recovery Time:**

```
💡 You've been busy!

You've had 5 social events this week.
Block some personal time this weekend?

Suggested: Sunday 2-4 PM (Recharge)

[Block Time] [Dismiss]
```

**Why it's powerful:**

- ✅ Feels like a smart assistant
- ✅ Reduces mental load
- ✅ Subtle AI showcase (premium feature)
- ✅ Learns from behavior over time

**Technical Requirements:**

- Pattern detection (event history analysis)
- Suggestion engine (rules + ML basic)
- User preference learning
- Smart notification timing

**Machine Learning Opportunities:**

- Learn typical commute times
- Detect meal patterns
- Identify busy vs light weeks
- Predict event conflicts

**Free vs Premium:**

- Free: 2-3 suggestions per week
- Premium: Unlimited suggestions, smarter AI, custom rules

---

### 7. Daily/Weekly Stats & Insights ⭐⭐⭐⭐

**Development Time:** 4-5 days

**Priority:** V1.2 (October 2025)

**What it is:**

Personal analytics about how you spend your time

**Weekly Summary (Sundays):**

```
┌─────────────────────────────────────┐
│ 📊 YOUR WEEK IN REVIEW              │
├─────────────────────────────────────┤
│ This week you:                      │
│                                     │
│ 🎉 SOCIAL TIME:                     │
│ • 8 hours with friends              │
│ • 3 group events attended           │
│ • Most social day: Saturday (4h)    │
│                                     │
│ 🧘 PERSONAL TIME:                   │
│ • 12 hours of focus time            │
│ • 3 workout sessions                │
│ • 7.5 hours average sleep           │
│                                     │
│ 📅 COORDINATION:                    │
│ • Created 2 events                  │
│ • Voted on 5 proposals              │
│ • 90% on-time arrival rate          │
│                                     │
│ 💡 INSIGHTS:                        │
│ • You're most social on weekends    │
│ • Tuesdays are your most productive │
│ • Try blocking lunch breaks more    │
│                                     │
│ [View Full Report]                  │
└─────────────────────────────────────┘
```

**Monthly Summary:**

```
📊 November in Review

🎉 Social Stats:
• 15 group events attended
• 32 hours with friends
• 4 new people met
• Most active group: College Friends (8 events)

🧘 Personal Stats:
• 48 hours of focus time
• 12 workout sessions
• 3 personal goals completed

📈 Trends:
• 25% more social than October
• Consistent workout routine (3x/week)
• Best attendance record yet!

[Share Your Stats] [View Year]
```

**Year-in-Review (December):**

```
🎊 2025 IN REVIEW

📅 Your Year by the Numbers:
• 156 events organized
• 487 hours with friends
• 42 different people coordinated with
• 8 active groups
• 234 proposals voted on

🏆 Highlights:
• Busiest month: July (28 events)
• Most social day: Saturdays
• Favorite event type: Game Night (24x)
• Perfect attendance: 12 events

🎉 Top Moments:
[Photo collage of event memories]

[Share Your Year] [Download Report]
```

**Why it's powerful:**

- ✅ Emotional connection to data
- ✅ Encourages habit formation
- ✅ Shows value of using app more
- ✅ Shareable (viral marketing)
- ✅ Premium feature opportunity

**Technical Requirements:**

- Event categorization (social vs personal)
- Time tracking per category
- Trend analysis
- Beautiful data visualization
- Export/share functionality

**Metrics to Track:**

- Social time vs personal time
- Events by type/category
- Attendance rate
- On-time arrival rate
- Most active groups
- Busiest days/times
- Workout consistency
- Focus time tracked

**Free vs Premium:**

- Free: Basic weekly summary
- Premium: Detailed stats, monthly reports, year-in-review, export data

---

### 8. Event Memories & Photos ⭐⭐⭐

**Development Time:** 1 week

**Priority:** V1.3 (November 2025)

**What it is:**

Attach photos and notes to past events, creating a personal journal

**Past Event View:**

```
┌─────────────────────────────────────┐
│ Game Night - Nov 23, 2024           │
├─────────────────────────────────────┤
│ 👥 8 people attended                │
│ 📸 12 photos • 3 notes              │
│                                     │
│ [Photo Grid - showing 4 photos]     │
│ [View All 12 Photos]                │
│                                     │
│ 💬 Memories:                        │
│                                     │
│ Sarah: "Best game night ever!       │
│ Jordan finally won at Catan 🎉"     │
│                                     │
│ You: "Can't believe how competitive │
│ we all got. Same time next month?" │
│                                     │
│ Mike: "Already added to calendar!" │
│                                     │
│ [Add Photos] [Add Memory]           │
│ [Share Album with Group]            │
└─────────────────────────────────────┘
```

**Memory Timeline:**

```
📅 Your Memories

┌─────────────────────────────────────┐
│ November 2024                       │
├─────────────────────────────────────┤
│ Nov 23 - Game Night 🎮              │
│ [Thumbnail] 12 photos               │
│ "Best game night ever!"             │
├─────────────────────────────────────┤
│ Nov 15 - Coffee with Sarah ☕       │
│ [Thumbnail] 2 photos                │
│ "Caught up after so long"           │
├─────────────────────────────────────┤
│ Nov 10 - Friendsgiving 🦃           │
│ [Thumbnail] 24 photos               │
│ "Amazing food, even better company" │
├─────────────────────────────────────┤
│ Nov 3 - Movie Night 🎬              │
│ [Thumbnail] 5 photos                │
└─────────────────────────────────────┘

[View All Memories]
```

**Album Sharing:**

```
Share "Game Night" album with:
☑ All attendees (8 people)
☐ College Friends group (10 people)
☐ Make public link

Permissions:
☑ Can view photos
☑ Can add photos
☐ Can download
☑ Can add comments

[Share Album]
```

**Why it's powerful:**

- ✅ Sentimental value (emotional connection)
- ✅ Turns calendar into personal journal
- ✅ Encourages post-event engagement
- ✅ Premium storage limits drive upgrades
- ✅ Social sharing creates viral moments

**Technical Requirements:**

- Photo upload to Supabase Storage
- Image optimization/compression
- Album data model
- Sharing permissions
- Download functionality

**Storage Strategy:**

- Free: 10 photos per event, 50 total
- Premium: 100 photos per event, unlimited total
- Compressed to reasonable size (max 2MB each)
- Original quality download for premium

---

## 🥉 TIER 3: Nice to Have (Lower Priority)

### 9. Task Integration ⭐⭐⭐

**Development Time:** 3-4 days

**Priority:** V2.0 (2026+)

**What it is:**

Simple tasks tied to events (not a full task manager)

**Event with Tasks:**

```
Event: Friendsgiving Prep

┌─────────────────────────────────────┐
│ 🦃 Friendsgiving - Nov 28, 6 PM    │
├─────────────────────────────────────┤
│ ✅ TO-DO BEFORE EVENT:              │
│                                     │
│ ☑ Buy turkey (Nov 25) ✓             │
│ ☑ Prep side dish (Nov 27) ✓         │
│ ☐ Set table (Nov 28, 4 PM)          │
│ ☐ Start cooking (Nov 28, 2 PM)      │
│                                     │
│ [+ Add Task]                        │
└─────────────────────────────────────┘
```

**Task Reminders:**

```
Notification (Nov 28, 1:30 PM):

⏰ Upcoming tasks for Friendsgiving:

• Start cooking (in 30 min)
• Set table (in 2.5 hours)

[View Event] [Mark Complete]
```

**Why it's useful:**

- ✅ Keeps everything in one place
- ✅ Natural extension of events
- ✅ Event-specific context

**Why it's low priority:**

- ❌ Don't build a full task manager (scope creep)
- ❌ Users already have task apps
- ❌ Limited differentiation value

**Technical Requirements:**

- Task data model (linked to events)
- Checkbox UI
- Due date/time per task
- Notifications

**Free vs Premium:**

- Free: 5 tasks per event
- Premium: Unlimited tasks, recurring tasks

---

### 10. Location-Based Suggestions ⭐⭐⭐

**Development Time:** 4-5 days

**Priority:** V2.0 (2026+)

**What it is:**

Smart, helpful suggestions based on your location

**Example Scenarios:**

**1. Running Early:**

```
Notification (location-triggered):

📍 You're near Coffee Shop

You have "Coffee with Sarah" in 30 min.
Running early? Want to:

• Start the event now
• Find a nearby place to wait
• Send Sarah an update

[I'm Here] [Dismiss]
```

**2. Running Late:**

```
Notification (location + time awareness):

⚠️ You might be late

Your event starts in 10 min, but you're
still 15 min away.

Want to notify attendees?

[Send "Running 5 min late"] [Dismiss]
```

**3. Nearby Events:**

```
Notification:

📍 You're near Mike's Apartment

You have "Game Night" here tomorrow
at 6 PM. Want to save this location
for easy navigation?

[Save Location] [Not Now]
```

**Why it's useful:**

- ✅ Contextual and helpful
- ✅ Uses existing location features
- ✅ Reduces "where was that again?" moments

**Why it's low priority:**

- ❌ Battery drain concerns
- ❌ Privacy concerns (location tracking)
- ❌ Requires careful permission handling
- ❌ Limited daily utility

**Technical Requirements:**

- Background location permissions
- Geofencing (monitor event locations)
- Smart notification logic
- Battery optimization

**Privacy Considerations:**

- Opt-in only
- Clear explanation of how location is used
- Never share exact location with others
- Location data stays on device (not sent to server)

**Free vs Premium:**

- Free: Basic location notifications
- Premium: Smart suggestions, traffic-aware alerts

---

## 📅 Implementation Roadmap

### V1.0 - MVP (April 2025)

**Personal Features Included:**

- ✅ Basic personal calendar
- ✅ Apple Calendar sync
- ✅ Event creation/editing
- ✅ Travel time calculations
- ✅ Privacy controls

**Focus:** 100% on group coordination differentiation

**Development Time:** Already planned (9 weeks)

---

### V1.1 - Daily Use Update (June 2025)

**New Personal Features:**

- ✅ Smart Morning Briefing
- ✅ Quick Add (Natural Language)
- ✅ Today Widget (Small + Medium)
- ✅ Time Blocking / Focus Modes

**Goal:** Transform into daily-use app

**Development Time:** 2 weeks

**Release:** Mid-June (2 months post-launch)

**Success Metrics:**

- DAU increases from 20% → 40% of MAU
- Session frequency: 5+ times/week
- Morning Briefing usage: 60%+ of users

---

### V1.2 - Depth Update (October 2025)

**New Personal Features:**

- ✅ Routine Templates
- ✅ Smart Suggestions
- ✅ Weekly Stats & Insights

**Goal:** Deepen engagement, add premium value

**Development Time:** 3-4 weeks

**Release:** Early October

**Success Metrics:**

- Time in app: 5+ min/session
- Premium conversion: 12%+ (from 8%)
- Routine adoption: 40%+ of active users

---

### V1.3 - Emotional Update (November 2025)

**New Personal Features:**

- ✅ Event Memories & Photos
- ✅ Year-in-Review (December)

**Goal:** Emotional connection, viral sharing

**Development Time:** 2 weeks

**Release:** Early November (ready for year-end)

**Success Metrics:**

- Photo uploads: 30%+ of events
- Year-in-Review shares: 20%+ of users
- Viral coefficient: 0.3+ (each share brings 0.3 new users)

---

### V2.0 - Platform Evolution (2026)

**Consider Adding:**

- Task integration (if users request)
- Location-based suggestions
- Advanced AI features
- Cross-platform (web/Android)
- Public group events

**Decision Point:** Based on V1.x performance and user feedback

---

## 💰 Premium Feature Strategy

### Free Tier (Daily Use Drivers):

- ✅ Morning Briefing (basic)
- ✅ Quick Add (unlimited)
- ✅ Today Widget (small + medium)
- ✅ Time Blocking (3 blocks/day)
- ✅ Weekly Stats (basic summary)
- ✅ Event Photos (10 per event, 50 total)

**Goal:** Make free tier genuinely useful for daily planning

---

### Premium Tier (Enhanced Experience):

- ✅ Morning Briefing (weather, week preview, insights)
- ✅ Today Widget (large widget, week view)
- ✅ Time Blocking (unlimited, recurring, iOS Focus)
- ✅ Routine Templates (unlimited, custom, sharing)
- ✅ Smart Suggestions (unlimited, smarter AI)
- ✅ Stats & Insights (detailed, monthly, year-in-review)
- ✅ Event Photos (100 per event, unlimited total, full quality)
- ✅ Export personal data

**Goal:** Premium makes daily planning effortless and delightful

---

## 📊 Success Metrics

### Engagement Metrics:

```
Daily Active Users (DAU):
├─ V1.0 baseline: 20% of MAU
├─ V1.1 target: 40% of MAU
└─ V1.3 target: 50%+ of MAU

Session Frequency:
├─ V1.0 baseline: 2-3x per week
├─ V1.1 target: 5+ times per week
└─ V1.3 target: Daily for 30%+ users

Time in App:
├─ V1.0 baseline: 1-2 min per session
├─ V1.1 target: 3+ min per session
└─ V1.3 target: 5+ min per session

Feature Adoption:
├─ Morning Briefing: 60%+ of daily users
├─ Quick Add: 40%+ of active users
├─ Widget: 30%+ install widget
├─ Time Blocking: 25%+ use weekly
└─ Routines: 40%+ create at least one
```

### Conversion Metrics:

```
Premium Conversion:
├─ V1.0 baseline: 8-10%
├─ V1.2 target: 12-15%
└─ V1.3 target: 15-18%

Conversion Drivers:
├─ Group limit: 40% of conversions
├─ Personal features: 30% of conversions
├─ Advanced features: 20% of conversions
└─ Support indie dev: 10% of conversions
```

### Retention Metrics:

```
Day 7 Retention:
├─ V1.0 baseline: 40%
├─ V1.1 target: 50%
└─ V1.3 target: 60%+

Day 30 Retention:
├─ V1.0 baseline: 25%
├─ V1.2 target: 35%
└─ V1.3 target: 45%+

Reason: Daily personal use creates habit,
group features create stickiness
```

---

## 🎯 Key Principles

**1. Personal ≠ Productivity**

- Don't build a full productivity suite
- Focus on calendar + light personal planning
- Don't compete with Things, Todoist, Notion
- Stay in your lane: time + social coordination

**2. Complement, Don't Replace**

- Work alongside Apple Calendar, not replace it
- Enhance what calendars do, don't rebuild from scratch
- Integrate with existing tools (Focus modes, etc.)

**3. Daily Utility First**

- Personal features must drive daily opens
- Every feature should answer: "Why open today?"
- Avoid features that are used once/month

**4. Free → Premium Path**

- Free tier gets real daily value
- Premium removes friction and adds delight
- Clear upgrade path when hitting limits

**5. Privacy Always**

- Personal data stays private by default
- User controls what groups see
- No selling data, ever

---

**Last Updated:** November 29, 2024

**Status:** Ready for implementation

**Next Review:** After V1.0 launch (April 2025)
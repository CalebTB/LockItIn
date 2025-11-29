# 🎯 Core Features - MVP Feature Tier List

What's gonna separate this app from others

---

**Core Principle:** What's the MINIMUM feature set that:

1. Solves the core problem (group coordination chaos)
2. Proves your unique value (privacy + smart coordination)
3. Can't be replicated by existing apps easily
4. Is technically achievable in 8 weeks

---

## ✅ TIER 1: Absolute Must-Haves

**Can't launch without these**

### 1. Personal Calendar Foundation

- ✅ Sync with Apple Calendar (read-only for MVP)
- ✅ Display your events in the app
- ✅ Create/edit/delete events locally
- ✅ Basic calendar views (day, week, month)

**Why it's core:** Without a working calendar, nothing else matters.

### 2. Shadow Calendar System

- ✅ Mark events as Private / Shared-Busy-Only / Shared-With-Details
- ✅ Groups see your "busy blocks" without titles
- ✅ Per-event privacy controls

**Why it's core:** This IS your differentiation. Without this, you're just another shared calendar.

### 3. Friend System

- ✅ Add friends by phone/email
- ✅ Accept/decline friend requests
- ✅ Create friend groups (College Friends, Roommates, etc.)
- ✅ Choose which groups see your availability

**Why it's core:** Can't coordinate without knowing who to coordinate with.

### 4. Group Availability Heatmap

- ✅ Visual display of when group members are free/busy
- ✅ Privacy-preserving (shows counts, not individual names until tapped)
- ✅ Filter by time range (this weekend, next week, etc.)

**Why it's core:** This is your visual killer feature. The "wow" moment that makes people get it instantly.

### 5. Event Proposals with Voting

- ✅ Create proposal with 2-5 time options
- ✅ Send to a group
- ✅ Members vote: Can make it / Maybe / Can't make it
- ✅ Real-time vote tallies
- ✅ Organizer confirms winning option
- ✅ Event auto-adds to everyone's calendar when confirmed

**Why it's core:** This solves the "30 messages to plan one thing" problem. Your main use case.

### 6. Basic Notifications

- ✅ New proposal notification
- ✅ Voting deadline reminder
- ✅ Event confirmed notification
- ✅ Event starting soon reminder

**Why it's core:** Without notifications, proposals die in the void. People forget to vote.

---

## 🟡 TIER 2: Strong Differentiators

**Include if time permits - these make you noticeably better**

### 7. Smart Time Suggestions

- ✅ "Find best times" button that analyzes group availability
- ✅ Suggests top 3 time slots based on who's free
- ✅ Shows availability count per option (e.g., "7/8 people free")

**Why include:** Reduces cognitive load. Shows your app is smart, not just a container.

**Complexity:** Medium (requires availability analysis algorithm)

### 8. Event Location + Basic Travel Time

- ✅ Add location to events
- ✅ Calculate travel time from "home" location
- ✅ Show "Leave by" time on event details
- ✅ Simple notification when it's time to leave

**Why include:** Highly practical, frequently requested, differentiates from TimeTree/Howbout.

**Complexity:** Low-Medium (MapKit handles most of it)

### 9. 🎂 Surprise Birthday Party Template

- ✅ Create event in "Surprise Mode"
- ✅ Birthday person auto-excluded from seeing event
- ✅ Decoy event shown to birthday person
- ✅ Task assignments (decorations, cake, get them there)
- ✅ Cover story management
- ✅ Timeline coordination (arrive before them)
- ✅ Auto-reveal after surprise happens
- ✅ Planning history shown as keepsake

**Why include:** Year-round relevance, emotionally significant, demonstrates privacy controls, word-of-mouth generator.

**Complexity:** Medium-High (requires complex privacy logic)

### 10. 🍗 Potluck/Friendsgiving Template

- ✅ Host assignment
- ✅ Dish signup categories (mains, sides, desserts, drinks)
- ✅ Serving size tracking
- ✅ Dietary restrictions display
- ✅ Duplicate prevention warnings
- ✅ "What's still needed" view

**Why include:** Highly practical, solves real coordination problem, useful year-round.

**Complexity:** Low-Medium (structured task list)

---

## 🔵 TIER 3: Nice-to-Haves

**Save these for V2 (first update after launch)**

- ⏳ Live arrival status ("I'm on my way")
- ⏳ Conflict detection when calendar changes
- ⏳ Group insights/analytics
- ⏳ Recurring event patterns
- ⏳ Energy/effort meter
- ⏳ Smart rescheduling suggestions
- ⏳ Cross-group conflict warnings
- ⏳ Flexible attendance (drop-in events)
- ⏳ Participation tracking
- ⏳ Fair location picking (minimize total group travel)
- ⏳ Real-time traffic updates

---

# 📋 Recommended MVP Scope

## MUST SHIP (Core MVP):

1. ✅ Personal calendar with Apple Calendar sync
2. ✅ Shadow calendar privacy system
3. ✅ Friend connections & groups
4. ✅ Group availability heatmap
5. ✅ Event proposals with voting
6. ✅ Basic notifications
7. ✅ 🎂 Surprise Birthday Party template
8. ✅ 🍗 Potluck template

## SHOULD SHIP (If time allows):

1. ✅ Smart time suggestions ("Find best times")
2. ✅ Event locations + travel time

## DON'T SHIP YET:

- ❌ Advanced analytics
- ❌ Live status tracking
- ❌ Recurring events (just one-time for now)
- ❌ Energy meters
- ❌ Conflict detection
- ❌ Secret Santa (save for holiday update)

---

# 🎯 What This MVP Proves

If we ship this, we'll have proven:

1. ✅ **Privacy-first coordination works** (shadow calendar)
2. ✅ **Visual availability is useful** (heatmap)
3. ✅ **Voting is faster than group chat** (proposals)
4. ✅ **Smart suggestions save time** (find best times)
5. ✅ **Special event types add real value** (surprise parties, potlucks)

That's enough to validate product-market fit.

---

# 📊 Final MVP Feature Count

```
MVP v1.0 - Launch Features (April 1)
┌─────────────────────────────────────┐
│ CORE CALENDAR                       │
│ ✅ Apple Calendar sync (read)       │
│ ✅ View events (day/week/month)     │
│ ✅ Create/edit/delete events        │
│                                     │
│ PRIVACY & SHARING                   │
│ ✅ Shadow calendar system           │
│ ✅ Per-event privacy controls       │
│ ✅ Add friends                      │
│ ✅ Create groups                    │
│ ✅ Share availability with groups   │
│                                     │
│ GROUP COORDINATION                  │
│ ✅ Availability heatmap             │
│ ✅ Create event proposals           │
│ ✅ Multi-option voting              │
│ ✅ Real-time vote updates           │
│ ✅ Confirm & create event           │
│ ✅ "Find best times" suggestions 🌟 │
│                                     │
│ SPECIAL EVENT TEMPLATES             │
│ ✅ 🎂 Surprise Birthday Party       │
│ ✅ 🍗 Potluck/Friendsgiving         │
│                                     │
│ LOCATION & TRAVEL                   │
│ ✅ Event locations                  │
│ ✅ Travel time calculation          │
│ ✅ "Leave by" notifications         │
│                                     │
│ NOTIFICATIONS                       │
│ ✅ New proposal alert               │
│ ✅ Vote reminder                    │
│ ✅ Event confirmed                  │
│ ✅ Event starting soon              │
│ ✅ Time to leave reminder           │
└─────────────────────────────────────┘

Total core features: 25
Estimated dev time: 7-8 weeks
```

---

# 🎁 Seasonal Update Roadmap

## Summer Update (June - v1.1)

**Focus: Outdoor & Social Events**

### New Event Templates:

- 🏖️ **Beach Day / Pool Party**
    - Weather monitoring
    - Outdoor gear checklist
    - Backup indoor location
    - Sunscreen/supplies assignments
- 🎆 **4th of July BBQ**
    - Grill master assignment
    - Food signups (burgers, hot dogs, sides)
    - Fireworks pooling
    - Outdoor games equipment tracking
- ✈️ **Group Trip / Weekend Getaway**
    - Multi-day itinerary
    - Accommodation room assignments
    - Expense splitting
    - Activity voting
    - Packing list

### Feature Additions:

- ⏳ Weather integration for outdoor events
- ⏳ Photo sharing for trip events
- ⏳ Expense splitting calculator

**Timeline:** Ship mid-June

**Dev time:** 2-3 weeks

---

## Fall Update (October - v1.2)

**Focus: Halloween & Autumn Events**

### New Event Templates:

- 🎃 **Halloween Party**
    - Costume theme voting
    - Costume reveals (what are you wearing?)
    - Decoration assignments
    - Candy/supplies list
    - Spooky playlist collaboration
- 🏈 **Game Watch Party**
    - Team allegiance display
    - Snack assignments
    - Viewing location
    - Group predictions/bracket
- 🍂 **Oktoberfest / Fall Festival**
    - Activity voting (pumpkin patch, corn maze, etc.)
    - Transportation coordination
    - Group photo spots

### Feature Additions:

- ⏳ Costume voting/themes
- ⏳ Photo spot suggestions
- ⏳ Team/bracket management

**Timeline:** Ship late September

**Dev time:** 2 weeks

---

## Holiday Update (November - v1.3)

**Focus: Thanksgiving & Year-End Celebrations**

### New Event Templates:

- 🦃 **Friendsgiving** (enhanced potluck)
    - Traditional Thanksgiving dishes
    - Seating arrangements
    - Gratitude sharing prompts
    - Leftovers distribution
- 🎅 **Secret Santa**
    - Auto-assign gift recipients (private)
    - Budget setting
    - Wishlist submission
    - Exclusion rules (couples, roommates)
    - Name draw with re-draw capability
    - Anonymous gift hints
- 🕎 **Hanukkah Party**
    - 8-night celebration tracking
    - Gift exchange coordination
    - Traditional food signups
- 🎄 **Holiday Party**
    - Ugly sweater contest voting
    - White elephant gift exchange
    - Playlist collaboration
    - Holiday cookie exchange

### Feature Additions:

- ⏳ Gift matching algorithm (Secret Santa)
- ⏳ Anonymous messaging for gift hints
- ⏳ Gift budget tracking
- ⏳ Multi-day event series (Hanukkah)

**Timeline:** Ship early November

**Dev time:** 3-4 weeks (Secret Santa is complex)

---

## New Year Update (December - v1.4)

**Focus: Year-End & Winter Events**

### New Event Templates:

- 🎊 **New Year's Eve Party**
    - Countdown timer
    - Resolution sharing (private/public toggle)
    - Champagne/drinks pooling
    - Transportation/designated driver coordination
    - Morning-after brunch planning
- ❄️ **Ski Trip / Winter Getaway**
    - Multi-day coordination
    - Ski level tracking
    - Equipment rental tracking
    - Slope/activity voting
    - Après-ski planning
- 💝 **Valentine's Day Group Dinner**
    - Singles vs couples coordination
    - Restaurant voting
    - Cost splitting
    - Secret admirer mode (optional)

### Feature Additions:

- ⏳ Countdown timers for events
- ⏳ Resolution tracking year-round
- ⏳ Skill level matching (for sports)

**Timeline:** Ship mid-December

**Dev time:** 2 weeks

---

## Spring Update (March - v1.5)

**Focus: Spring Events & Celebrations**

### New Event Templates:

- 🌸 **Spring Break Trip**
    - Week-long itinerary
    - Flight coordination
    - Beach/resort activities
    - Budget tracking
- 🥚 **Easter Brunch / Egg Hunt**
    - Egg hunt organization
    - Brunch potluck
    - Kid-friendly activity planning
- 🎓 **Graduation Party**
    - Guest list management
    - Photo slideshow coordination
    - Gift pooling
    - Speech/toast signup
- 🌮 **Cinco de Mayo Party**
    - Mexican food signups
    - Margarita ingredients pooling
    - Piñata coordination

### Feature Additions:

- ⏳ Multi-location coordination (spring break)
- ⏳ Kid-friendly event modes
- ⏳ Photo collection/slideshow

**Timeline:** Ship early March

**Dev time:** 2-3 weeks

---

# 🗓️ Seasonal Release Calendar

```
2025 Release Timeline:

📅 April 1 (v1.0) - MVP LAUNCH
├─ Core calendar features
├─ Shadow calendar
├─ Group coordination
├─ Surprise Birthday
└─ Potluck template

☀️ June 15 (v1.1) - SUMMER UPDATE
├─ Beach/Pool Party
├─ 4th of July BBQ
└─ Group Trip template

🍂 September 25 (v1.2) - FALL UPDATE
├─ Halloween Party
├─ Game Watch Party
└─ Fall Festival template

🦃 November 1 (v1.3) - HOLIDAY UPDATE
├─ Enhanced Friendsgiving
├─ Secret Santa ⭐
├─ Hanukkah Party
└─ Holiday Party

🎊 December 15 (v1.4) - NEW YEAR UPDATE
├─ New Year's Eve
├─ Ski Trip
└─ Valentine's Group Dinner

🌸 March 1 (v1.6) - SPRING UPDATE
├─ Spring Break Trip
├─ Easter Brunch
└─ Graduation Party
```

---

# 🎯 Update Strategy

**Each seasonal update includes:**

1. 2-4 new event templates
2. 1-2 feature enhancements
3. Bug fixes & improvements
4. Marketing push for that season

**Benefits:**

- Keeps app fresh year-round
- Natural marketing hooks ("New Halloween features!")
- Users return for seasonal events
- App Store features for seasonal relevance
- Sustained development momentum

**Dev cycle:**

- 2-4 weeks per update
- Released 2-4 weeks before peak season
- Allows time for bugs & user feedback

---

**Current Status:** MVP scope finalized with special event templates

**Last Updated:** November 29, 2024
# 5. NOTIFICATION INTERACTIONS

Scenario: User has notifications off but proposal urgent

```markdown
Voting closes in 1 hour
User has app notifications disabled

In-app banner (when they open app):
┌─────────────────────────────────────┐
│  ⏰ URGENT: VOTING ENDS SOON         │
├─────────────────────────────────────┤
│                                     │
│  Secret Santa Planning              │
│  Voting closes in 47 minutes        │
│                                     │
│  You haven't voted yet!             │
│                                     │
│  [Vote Now]    [Dismiss]            │
│                                     │
│  ───────────────────────────────    │
│                                     │
│  💡 Enable notifications to never   │
│     miss deadlines                  │
│                                     │
│  [Turn On Notifications]            │
│                                     │
└─────────────────────────────────────┘
```

Scenario: Notification clustering

```markdown
5 events updated in 10 minutes

Instead of 5 separate notifications:

┌─────────────────────────────────────┐
│  📬 5 Calendar Updates               │
├─────────────────────────────────────┤
│                                     │
│  • Secret Santa - time confirmed    │
│  • Game night - voting started      │
│  • Friendsgiving - 2 new votes      │
│  • Sarah voted on Coffee meetup     │
│  • Basketball practice - rescheduled│
│                                     │
│  [View All]                         │
│                                     │
└─────────────────────────────────────┘
```

Scenario: Notification action from lock screen

```markdown
Lock screen notification:
┌─────────────────────────────────────┐
│  📅 Calendar App                    │
│  Secret Santa Planning              │
│  Vote on time options               │
│                                     │
│  [✓ Available] [~ Maybe] [✗ No]    │
│                                     │
└─────────────────────────────────────┘

User taps "✓ Available" without unlocking phone

Haptic feedback + micro-notification:
┌─────────────────────────────────────┐
│  ✓ Vote recorded!                   │
└─────────────────────────────────────┘
```
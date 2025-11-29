# 12. EXTREME SCENARIOS

Scenario: 100+ person group (school club, etc.)

```markdown
User in group with 150 members

Availability view changes:
┌─────────────────────────────────────┐
│  🎓 CS Club (150 members)           │
├─────────────────────────────────────┤
│                                     │
│  ⚠️ Large group mode                │
│                                     │
│  Showing aggregate availability:    │
│                                     │
│  Wednesday 2:00 - 3:00 PM           │
│  ████████████░░░░░░ 78% available   │
│  117 free • 23 busy • 10 unknown    │
│                                     │
│  [See individual breakdown]    ›    │
│                                     │
│  💡 For large groups, we recommend: │
│  • Setting RSVP deadline            │
│  • Limiting to 3-5 time options     │
│  • Using "Maybe" sparingly          │
│                                     │
└─────────────────────────────────────┘
```

**Scenario: User in 50+ groups (edge case abuser)**

```markdown
User somehow has 50+ groups (data hoarder)

App implements pagination:
┌─────────────────────────────────────┐
│  👥 Groups                   [+]    │
├─────────────────────────────────────┤
│                                     │
│  🔍 [Search groups...]              │ ← Search required
│                                     │
│  RECENT (10)                        │
│  [Shows last 10 active groups]      │
│                                     │
│  ALL GROUPS (50)                    │
│  [Load more...]                     │
│                                     │
│  💡 Tip: Archive inactive groups    │
│     to improve performance          │
│                                     │
│  [Manage Groups]                ›   │
│                                     │
└─────────────────────────────────────┘
```
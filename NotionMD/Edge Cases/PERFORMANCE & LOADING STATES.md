# 9. PERFORMANCE & LOADING STATES

Scenario: Slow network loading availability

```markdown
Opening group calendar with slow connection

Progressive loading:
┌─────────────────────────────────────┐
│  College Friends Calendar           │
├─────────────────────────────────────┤
│                                     │
│  Loading availability...            │
│                                     │
│  ✓ Your calendar loaded             │
│  ⏳ Loading Sarah's calendar...     │
│  ⏳ Loading Mike's calendar...      │
│  ⏳ Loading 5 more...               │
│                                     │
│  [█████░░░░░] 50%                   │
│                                     │
│  You can start browsing with        │
│  partial data or wait for all.      │
│                                     │
│  [Show Partial]  [Wait]             │
│                                     │
└─────────────────────────────────────┘

After timeout (10 seconds):
┌─────────────────────────────────────┐
│  ⚠️ PARTIAL AVAILABILITY             │
├─────────────────────────────────────┤
│                                     │
│  Showing data for 5/8 people        │
│                                     │
│  Could not load:                    │
│  • Jordan T.                        │
│  • Emma W.                          │
│  • Taylor S.                        │
│                                     │
│  Availability data may be incomplete│
│                                     │
│  [Retry]  [Continue Anyway]         │
│                                     │
└─────────────────────────────────────┘
```
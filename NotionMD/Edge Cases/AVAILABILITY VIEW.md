# 7. AVAILABILITY VIEW - COMPLEX SCENARIOS

Scenario: Privacy-mixed group (some private, some shared)

```markdown
Group of 8 people viewing availability:
- 5 people share full calendar
- 2 people share "busy only"
- 1 person keeps calendar private

Availability view shows:
┌─────────────────────────────────────┐
│  Wednesday 2:00 - 3:00 PM           │
├─────────────────────────────────────┤
│                                     │
│  ✓ AVAILABLE (5/8)                  │
│  • Sarah M.    • Mike J.            │
│  • Jordan T.   • Alex K.            │
│  • You                              │
│                                     │
│  ⚠ BUSY (2/8)                       │
│  • Emma W. (Busy)                   │ ← No event name
│  • Chris P. (Busy)                  │
│                                     │
│  ❓ UNKNOWN (1/8)                    │
│  • Taylor S. (Private calendar)     │ ← Can't see
│                                     │
│  💡 Availability: 62% (5/8 confirmed)│
│     Best to ask Taylor directly     │
│                                     │
│  [Propose Event Here]               │
│                                     │
└─────────────────────────────────────┘
```

Scenario: Recurring availability patterns

```markdown
User opens availability view for "every Friday night"

Smart suggestion appears:
┌─────────────────────────────────────┐
│  💡 PATTERN DETECTED                │
├─────────────────────────────────────┤
│                                     │
│  Most of your group is consistently │
│  free on Friday nights 7-9 PM       │
│                                     │
│  Available 80% of the time:         │
│  • Sarah, Mike, Jordan, Alex, You   │
│                                     │
│  Often busy:                        │
│  • Emma (work shifts)               │
│  • Chris (family dinner)            │
│                                     │
│  ┌───────────────────────────┐     │
│  │ [Set Recurring Event]     │     │ ← Create series
│  │ Every Friday, 7-9 PM      │     │
│  └───────────────────────────┘     │
│  ┌───────────────────────────┐     │
│  │ [Propose Specific Date]   │     │
│  └───────────────────────────┘     │
│                                     │
└─────────────────────────────────────┘
```
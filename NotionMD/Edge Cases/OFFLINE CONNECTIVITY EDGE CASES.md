# 6. OFFLINE/CONNECTIVITY EDGE CASES

Scenario: User votes while offline

```markdown
User votes on 3 proposals with no internet

Visual feedback:
┌─────────────────────────────────────┐
│  Option 2: Sun, Dec 15 • 2:00 PM   │
│                                     │
│  Your response: ✓ Available         │
│  ⏳ Sending...                      │ ← Queued indicator
│                                     │
└─────────────────────────────────────┘

When connection restored:
┌─────────────────────────────────────┐
│  ☁️ SYNCING                         │
├─────────────────────────────────────┤
│                                     │
│  Uploading your votes...            │
│  ✓ Secret Santa                     │
│  ✓ Game night                       │
│  ⏳ Friendsgiving                   │
│                                     │
└─────────────────────────────────────┘
```

Scenario: Conflict during offline sync

```markdown
You voted "Available" offline
Meanwhile, event time changed online

When syncing:
┌─────────────────────────────────────┐
│  ⚠️ EVENT CHANGED                    │
├─────────────────────────────────────┤
│                                     │
│  While you were offline, the time   │
│  options changed:                   │
│                                     │
│  You voted for:                     │
│  Sun, Dec 15 • 2:00 PM (removed)    │
│                                     │
│  New options are:                   │
│  • Sat, Dec 14 • 6:00 PM            │
│  • Mon, Dec 16 • 7:00 PM            │
│                                     │
│  Your vote was not counted.         │
│                                     │
│  ┌───────────────────────────┐     │
│  │ [Vote Again]              │     │
│  └───────────────────────────┘     │
│  ┌───────────────────────────┐     │
│  │ [Skip]                    │     │
│  └───────────────────────────┘     │
│                                     │
└─────────────────────────────────────┘
```
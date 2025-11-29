# Design System

## Colors

### Primary Colors

- **Primary Blue:** #007AFF (iOS default blue)
- **Success Green:** #34C759
- **Warning Yellow:** #FFCC00
- **Error Red:** #FF3B30

### Neutral Colors

- **Background:** #FFFFFF (light) / #000000 (dark)
- **Secondary Background:** #F2F2F7 / #1C1C1E
- **Tertiary Background:** #E5E5EA / #2C2C2E
- **Text Primary:** #000000 / #FFFFFF
- **Text Secondary:** #3C3C43 / #AEAEB2

## Typography

**System Font:** SF Pro (iOS default)

- **Title 1:** 34pt, Bold
- **Title 2:** 28pt, Bold
- **Title 3:** 22pt, Semi bold
- **Headline:** 17pt, Semi bold
- **Body:** 17pt, Regular
- **Callout:** 16pt, Regular
- **Footnote:** 13pt, Regular
- **Caption:** 12pt, Regular

## Spacing

Use 8pt grid system:

- 4pt (0.5x)
- 8pt (1x)
- 16pt (2x)
- 24pt (3x)
- 32pt (4x)
- 48pt (6x)

## Components

[Link to Figma for component library]

## Icons

Using SF Symbols (built into iOS)

Key icons:

- Calendar: calendar
- Groups: person.3.fill
- Proposals: checkmark.circle.fill
- Profile: person.circle.fill

```

---

### **DATABASE 5: Bug Tracker**

**Create it:**
1. New page: "🐛 Bugs & Issues"
2. Add database

```

Properties:
├─ Bug Title (Title)
├─ Status (Select): New, In Progress, Fixed, Won't Fix
├─ Severity (Select): Critical, High, Medium, Low
├─ Area (Select): UI, Backend, Calendar, Groups, Proposals
├─ Steps to Reproduce (Text)
├─ Expected Behavior (Text)
├─ Actual Behavior (Text)
├─ Screenshots (Files)
├─ Reported By (Person)
├─ Reported Date (Date)
└─ Fixed Date (Date)

```

---

### **DATABASE 6: User Feedback**

**Create it:**
1. New page: "💬 User Feedback"
2. Add database

```

Properties:
├─ Feedback (Title)
├─ Type (Select): Feature Request, Bug Report, Praise, Complaint
├─ Source (Select): Beta Tester, Friend, Review, Interview
├─ Priority (Select): High, Medium, Low
├─ Status (Select): New, Planned, In Progress, Implemented, Won't Do
├─ User Name (Text)
├─ Date Received (Date)
└─ Notes (Text)
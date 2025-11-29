# 10. ACCESSIBILITY INTERACTIONS

Scenario: VoiceOver user navigating calendar

```markdown
VoiceOver announces:

"Calendar view. Week of December 8th.
Monday, December 9th. 
Two events. 
Team Meeting, 9:00 AM to 10:00 AM, Private event.
Lunch with Sarah, 12:00 PM to 1:00 PM, Shared with group.
Actions available."

User double-taps on event:
"Event details sheet. Team Meeting. 
Edit button. Delete button. 
Share with groups button."
```

Scenario: Dynamic Type (large text) user

```markdown
User has largest text size enabled

Calendar view adapts:
- Single day view (week view too cramped)
- Event titles truncate with "..."
- Tap to expand full details
- Larger touch targets (60pt minimum)
- Scrollable event cards instead of grid
```
# Applied Migrations Log

This file tracks manual migrations applied via Supabase MCP or SQL Editor.

## 2026-01-15

### Migration 024: Enable Realtime for Events Table
**Applied via:** Supabase MCP (`mcp__supabase__execute_sql`)
**Date:** 2026-01-15
**Status:** ✅ Applied successfully

**SQL:**
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE events;
```

**Verification:**
```sql
SELECT * FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
AND tablename = 'events';
-- Returned: events table IS in publication ✅
```

**Context:**
- Required for Potluck template real-time dish claim/unclaim updates
- Subscriptions were connecting but callbacks weren't firing
- Issue: Real-time updates working but UI performance is clunky (tracked in #247)

**Tables now in realtime publication:**
- event_invitations
- event_proposals
- events (newly added)
- notifications
- proposal_votes

---
module: Event Templates
date: 2026-01-14
problem_type: workflow_issue
component: development_workflow
symptoms:
  - "Dashboard showing 1/12 members instead of all invitations"
  - "RSVP updates only appearing after hot restart, not real-time"
  - "Task assignment sheet overflow with 12+ members"
  - "Built hierarchical access model when collaborative model was needed"
  - "Duplicate RSVP sheet code instead of reusing existing patterns"
root_cause: missing_workflow_step
resolution_type: workflow_improvement
severity: high
tags: [ai-workflow, code-review, duplication, architecture, rls-policies, performance, realtime, flutter]
---

# Troubleshooting: AI Agent Not Consulting Existing Codebase Before Implementation

## Problem

During Sprint 4 implementation of the Surprise Party Template RSVP system, the AI agent implemented features without first reading and understanding existing codebase patterns. This resulted in multiple architectural mistakes, duplicate code, inefficient database queries, missing configurations, and significant rework.

## Environment

- Module: Event Templates (Surprise Party Template)
- Flutter Version: 3.16+
- Supabase Backend with PostgreSQL + Row Level Security
- Sprint: Sprint 4 (Templates + Special Features)
- Date: 2026-01-14

## Symptoms

1. **Wrong Access Model**: Implemented hierarchical coordinator/member roles when the requirement was collaborative access for all non-target users
2. **RLS Policy Incomplete**: Dashboard only showed 1/12 invitations because RLS policy didn't account for coordinators who weren't event creators
3. **Realtime Not Enabled**: RSVP changes only appeared after hot restart because `event_invitations` table wasn't in `supabase_realtime` publication
4. **UI Overflow**: Task assignment sheet overflowed by 432 pixels with 12+ members (not scrollable)
5. **Duplicate Code**: Created `_showRSVPSheet()` method when similar patterns likely already existed
6. **Inefficient Queries**: Re-fetching all invitations on every realtime update instead of updating single record
7. **No Realistic Testing**: Tested with 1-2 members instead of 12+, missing overflow issues
8. **Inefficient RLS Design**: Using expensive JSONB array parsing in RLS policies on every SELECT query

## What Didn't Work

**Attempted Solution 1: Added debug logging to trace why only 1 invitation showing**
- **Why it failed**: This identified the symptom (Supabase returning 1 row) but not the root cause (RLS policy blocking access)
- Required checking database directly to confirm all 12 rows existed

**Attempted Solution 2: Created RLS policy for coordinators**
- **Why it partially failed**: Fixed the immediate issue but user feedback revealed we built the wrong access model entirely
- Wasted time on hierarchical roles when collaborative model was required

**Attempted Solution 3: Added more debug logging for realtime updates**
- **Why it failed**: No logs appeared because the table wasn't in the realtime publication at all
- Should have checked database configuration BEFORE implementing client-side WebSocket code

**Attempted Solution 4: Assumed hot reload would work for realtime changes**
- **Why it failed**: WebSocket subscriptions require full app restart to reconnect with new publication
- Wasted time expecting logs that couldn't appear

## Solution

### Immediate Fixes Applied

**1. RLS Policy Fix (Migration 022)**
```sql
-- Allow surprise party coordinators to view all invitations
CREATE POLICY "Surprise party coordinators can view all invitations"
ON event_invitations FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM events e
    WHERE e.id = event_invitations.event_id
    AND e.template_data->>'type' = 'surprise_party'
    AND auth.uid()::text = ANY(
      SELECT jsonb_array_elements_text(
        COALESCE(
          e.template_data->'in_on_it_user_ids',
          e.template_data->'inOnItUserIds'
        )
      )
    )
  )
);
```

**2. Access Model Refactor**
```dart
// Before: Only coordinators could access
if (_isSurpriseParty && userRole == 'coordinator')

// After: Everyone except guest of honor can access
if (_isSurpriseParty && userRole != 'target')
  Container(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SurprisePartyDashboard(event: _currentEvent),
          ),
        );
      },
      icon: const Icon(Icons.dashboard_outlined, size: 20),
      label: const Text('Party Coordinator Hub'),
    ),
  ),
```

**3. Enable Realtime (Migration 023)**
```sql
-- Enable realtime for event_invitations table
ALTER PUBLICATION supabase_realtime ADD TABLE event_invitations;

COMMENT ON TABLE event_invitations IS
'Event invitations with RSVP status. Realtime enabled for live RSVP updates in Party Coordinator Hub.';
```

**4. Make Task Sheet Scrollable**
```dart
// Wrapped Column in SingleChildScrollView
child: Form(
  key: _formKey,
  child: SingleChildScrollView(  // Added this
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Form fields...
      ],
    ),
  ),
),
```

**5. Self-Service RSVP**
```dart
// User taps their own avatar to change RSVP status
GestureDetector(
  onTap: isCurrentUser
      ? () => _showRSVPSheet(context, invitation)
      : null,
  child: StatusAvatar(
    userId: userId,
    displayName: user?['full_name'] ?? 'Unknown',
    avatarUrl: user?['avatar_url'],
    statusBadge: invitation['rsvp_status'],
  ),
)
```

### Technical Debt Created (Needs Future Fixes)

The following issues are **currently implemented but need refactoring**:

1. **Inefficient RLS Policy**: JSONB array parsing on every SELECT query (should use separate `surprise_party_coordinators` table)
2. **Redundant Database Queries**: Re-fetching all invitations on every realtime update instead of updating single record in state
3. **No Query Caching**: User data fetched with every invitation query (12 invitations = 12 user joins)
4. **Manual State Management**: Using setState() and manual WebSocket subscriptions instead of Provider pattern
5. **No Error Handling**: Assumes WebSocket always works (no reconnection logic or fallback)
6. **No Pagination**: Loads ALL invitations at once (will break with 100+ member groups)
7. **Duplicate Code**: RSVP sheet logic not extracted into reusable utility
8. **No Loading/Empty States**: Jumps from empty to full list, no skeleton loaders
9. **No Input Validation**: JSONB arrays can contain invalid UUIDs or thousands of coordinators
10. **No Rate Limiting**: Users can spam RSVP updates

## Why This Works (Short Term)

The immediate fixes work because:

1. **RLS Policy**: Allows users in `in_on_it_user_ids` JSONB array to view all invitations for their surprise party event
2. **Collaborative Model**: Aligns with user's vision that all participants should have equal access to RSVP and task management
3. **Realtime Publication**: Adding table to `supabase_realtime` enables PostgreSQL to stream changes via WebSocket
4. **Scrollable UI**: Prevents overflow by making member list scrollable when content exceeds screen height
5. **Self-Service**: Users can manage their own RSVP status instead of coordinators doing it for them

## Why This Doesn't Scale (Technical Debt)

The current implementation has serious performance and architecture issues:

**1. Inefficient RLS Policy**
```sql
-- This runs on EVERY SELECT query:
auth.uid()::text = ANY(
  SELECT jsonb_array_elements_text(...)  -- Expensive!
)
```
- **Impact**: Parses JSONB array on every invitation fetch
- **Better**: Separate table with indexed columns

**2. Redundant Queries**
```dart
// Current: Re-fetch everything on every update
_fetchInvitations();

// Better: Update single record in state
final index = _invitations.indexWhere((inv) => inv['id'] == payload.newRecord['id']);
_invitations[index] = payload.newRecord;
```

**3. No Caching**
```dart
// Fetches user data 12 times (one per invitation)
.select('*, users(id, full_name, avatar_url)')

// Better: Cache users in provider, lookup by ID
```

**4. Manual Subscriptions**
- Subscription not cleaned up if widget rebuilds
- State scattered across multiple variables
- Hard to test

## Root Cause Analysis

**Primary Root Cause**: AI agent did not read existing codebase before implementing new features.

**Contributing Factors**:

1. **No Requirements Clarification**: Built coordinator/member distinction without asking user's intent
2. **Didn't Read Existing Code**: Reinvented RSVP patterns that may already exist
3. **No Database Config Check**: Implemented WebSocket client code without verifying publication enabled
4. **Inadequate Testing**: Tested with 1-2 members instead of realistic data (12+, 50+, 100+)
5. **No Architecture Review**: Chose JSONB storage without considering RLS policy complexity
6. **No Performance Consideration**: Designed queries that don't scale (N+1, redundant fetches)
7. **Assumed vs Verified**: Assumed hot reload would work for WebSocket (requires full restart)

**Impact**: ~30% of development time spent on rework and fixes that could have been prevented.

## Prevention

**Required Workflow for AI Agents Before Implementation**:

### 1. Read First, Code Second

**BEFORE implementing ANY feature**:

```bash
# Search for similar patterns
grep -r "RSVP" application/lockitin_app/lib/
grep -r "showModalBottomSheet" application/lockitin_app/lib/

# Read related files
# - How does RSVP work elsewhere?
# - What state management patterns exist?
# - Are there reusable widgets/utilities?
```

**Never write code without reading existing implementations first.**

### 2. Clarify Requirements Upfront

**Ask questions BEFORE building**:
- "Should coordinators have special privileges, or should everyone be equal?"
- "What's the expected group size? (affects UI design)"
- "Are there existing RSVP patterns I should follow?"

**Don't assume - confirm with user.**

### 3. Check Full Stack Configuration

**For realtime features, verify database config FIRST**:

```sql
-- Check if table is in realtime publication
SELECT * FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
AND tablename = 'event_invitations';

-- Check RLS policies
\d+ event_invitations
```

**Don't implement client-side WebSocket code until database is configured.**

### 4. Test with Realistic Data

**Edge cases to test**:
- 1 member (empty state)
- 12 members (typical case)
- 50+ members (stress test)
- 500+ members (pagination needed?)

**Create test data before building UI.**

### 5. Design for Scale from Start

**Performance checklist**:
- [ ] Are queries indexed?
- [ ] Is data cached where possible?
- [ ] Do RLS policies use indexed columns (not JSONB parsing)?
- [ ] Is pagination needed?
- [ ] Are there N+1 queries?

### 6. Use Proper State Management

**Don't use manual setState() and subscriptions for complex features**:

```dart
// Bad: Manual state
class _MyScreenState extends State<MyScreen> {
  List<dynamic> _data = [];
  RealtimeChannel? _channel;

  @override
  void initState() {
    _channel = supabase.channel('my-channel')...
  }
}

// Good: Provider pattern
class DataProvider extends ChangeNotifier {
  List<dynamic> _data = [];
  RealtimeChannel? _channel;

  void subscribe() { ... }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
```

### 7. Read Migration History

**Before creating migrations, check existing patterns**:

```bash
ls -la supabase/migrations/
cat supabase/migrations/*rls*.sql
cat supabase/migrations/*realtime*.sql
```

**Follow established patterns for RLS policies and realtime configuration.**

### 8. Document Why, Not Just What

**Migration comments should explain context**:

```sql
-- CONTEXT: Issue #XXX - Party Hub showing 1/12 members
-- PROBLEM: Original RLS only allowed creator OR own invitation
-- SOLUTION: Allow users in in_on_it_user_ids array to view all
-- PERFORMANCE: This runs on every SELECT - consider separate table
CREATE POLICY ...
```

## Required Workflow Steps

**Mandatory checklist before implementing ANY feature**:

- [ ] **Read existing code** - Search for similar patterns, read related files
- [ ] **Clarify requirements** - Ask questions about user intent and edge cases
- [ ] **Check database config** - Verify RLS, indexes, realtime publications
- [ ] **Create realistic test data** - Test with 1, 10, 50, 100+ items
- [ ] **Review architecture** - Consider performance, scalability, state management
- [ ] **Follow existing patterns** - Match naming conventions, coding standards
- [ ] **Document decisions** - Explain WHY in comments and migrations
- [ ] **Test edge cases** - Empty states, large datasets, error conditions

**If ANY checkbox is unchecked, STOP and complete it before writing code.**

## Related Issues

- GitHub Issue #236: Modularize task system for reuse across templates
- (Technical debt issues to be created below)

## Technical Debt Issues to Create

The following GitHub issues need to be created to fix the implemented technical debt:

1. **Refactor RLS Policy to Use Separate Table** - Replace JSONB array parsing with indexed `surprise_party_coordinators` table
2. **Optimize Realtime Updates** - Update single record in state instead of re-fetching all invitations
3. **Implement User Data Caching** - Cache user profiles in provider instead of fetching with every invitation
4. **Migrate to Provider Pattern for Invitations** - Replace manual setState() with proper state management
5. **Add Error Handling for Realtime** - Implement reconnection logic and fallback to polling
6. **Implement Pagination for Large Groups** - Add virtual scrolling for 100+ member groups
7. **Extract RSVP Sheet to Reusable Utility** - Consolidate duplicate RSVP logic
8. **Add Loading and Empty States** - Implement skeleton loaders and friendly empty messages
9. **Add Input Validation** - Validate JSONB arrays for invalid UUIDs and size limits
10. **Implement Rate Limiting** - Prevent RSVP spam with debouncing and backend limits

---

**Post-Mortem Grade: D+**

The feature works, but with significant technical debt and architectural issues. The biggest lesson: **Clarify requirements and read existing code BEFORE implementing**. Approximately 30% of development time was wasted on rework that could have been prevented by following proper workflow steps.

# New Feature Intake Process for LockItIn

**Plan Date:** January 7, 2026
**Context:** Solo developer, 3-4 hours/day, hard deadline April 30, 2026
**Current Status:** Sprint 3 complete, Sprint 4 starting (Feb 6-19)
**Remaining Capacity:** ~280 hours (7 sprints × 40 hours) until MVP launch

---

## 📋 Executive Summary

This plan establishes a lightweight but rigorous process for evaluating and integrating new feature requests into the LockItIn roadmap without causing scope creep or missing the April 30, 2026 launch deadline.

**Key Principles:**
1. **Default to "Not Now"** - MVP scope is fixed, new features defer to post-launch unless exceptional
2. **MoSCoW Prioritization** - Simple Must/Should/Could/Won't framework for quick decisions
3. **Agent-Assisted Evaluation** - Leverage Feature Orchestrator and Feature Values Advisor for consistency
4. **Version-Based Backlog** - Use v1.0.0/v1.1.0 prefixes for deferred features (existing pattern)
5. **Monthly Grooming** - Review backlog once/month to prevent bloat

---

## 🎯 Problem Statement

**Current Challenges:**
- 16 new v1.x issues created in last 2 weeks with no formal review process
- No distinction between "approved backlog" vs. "random ideas"
- No duplicate detection system (potential overlap between #227, #196, #201)
- Reactive issue creation during implementation (e.g., #198 "Add back navigation")
- Risk of scope creep threatening April 30 launch deadline

**What Success Looks Like:**
- Clear decision criteria for accepting/deferring features
- 5-minute evaluation process for new requests
- Zero scope creep on Sprint 4-5 (MVP must ship)
- Organized backlog of post-MVP features ready for v1.0.0
- Solo developer stays focused on critical path

---

## 🔍 Current State Analysis

### Roadmap Overview

**MVP Timeline (280 hours remaining):**
```
Sprint 4 (Feb 6-19):    Templates + Travel + Timezone [60h]
Sprint 5 (Feb 20-26):   Polish + Notifications         [40h]
Beta Testing (Feb 27 - Apr 8): Iteration + fixes       [120h]
Launch Prep (Apr 9-30): Final polish + marketing       [60h]
```

**Feature Tiers:**
- **Tier 1 (Must-Have):** 7 features - ALL COMPLETE by Sprint 3 ✅
- **Tier 2 (Strong Differentiators):** 3 features - In Sprint 4-5 🚧
- **Tier 3 (Post-Launch):** 10+ features - Deferred to v1.0.0+ 📦

### Existing Issue Management Patterns

**✅ What's Working:**
- Version-based naming: `v[X.X.X] - [Category]: [Title]`
- Rich issue context with acceptance criteria
- Epic → subtask decomposition (e.g., Timezone = 7 issues)
- Comprehensive labeling (type, area, priority, sprint)

**⚠️ Gaps Identified:**
1. No formal approval process for new ideas
2. No "parking lot" labels to distinguish backlog quality
3. No feature registry to prevent duplicates
4. No monthly backlog grooming
5. No clear criteria for "pull forward to MVP" decisions

---

## 💡 Proposed Solution: 3-Tier Feature Intake Process

### Tier 1: Immediate Triage (2 minutes)

**When:** As soon as feature request arrives (Slack message, user feedback, your own idea)

**Decision Tree:**

```
New Feature Request
        ↓
┌───────────────────────────────────────┐
│ Is it a BUG BLOCKING current work?   │
└───────────────────────────────────────┘
        ↓ YES → Create issue, fix immediately (Sprint X label)
        ↓ NO
┌───────────────────────────────────────┐
│ Is it in Tier 1-2 features list?     │
│ (lockitin-features.md)                │
└───────────────────────────────────────┘
        ↓ YES → Already planned, add to existing epic or create subtask
        ↓ NO (New feature, not in roadmap)
┌───────────────────────────────────────┐
│ MoSCoW Quick Assessment:              │
│ - Must Have: Blocks MVP launch        │
│ - Should Have: Strong differentiator  │
│ - Could Have: Nice improvement        │
│ - Won't Have: Post-launch             │
└───────────────────────────────────────┘
        ↓
Must Have? → ESCALATE to Tier 2 (Agent Review)
Should/Could/Won't? → CREATE ISSUE with status: proposed
```

**Triage Questions (30 seconds each):**
1. **Blocking?** Does MVP fail without this? (Yes = Must Have)
2. **Differentiator?** Does this make Shareless unique? (Yes = Should Have)
3. **User-Requested?** Did beta tester ask for it? (Yes = Could Have)
4. **Nice-to-Have?** Just an idea you had? (Yes = Won't Have)

**Output:** GitHub issue created with `status: proposed` label

### Tier 2: Agent-Assisted Evaluation (15 minutes)

**When:** For "Must Have" or "Should Have" requests that might affect MVP scope

**Process:**

1. **Feature Values Advisor Review** (5 min)
   ```bash
   Task feature-values-advisor("Evaluate if [feature] aligns with privacy-first,
   minimal design, and native UX principles. Does it risk scope creep?")
   ```

   **Output:** PROCEED / PROCEED WITH MODIFICATIONS / RECONSIDER / DO NOT IMPLEMENT

2. **Feature Orchestrator Analysis** (10 min)
   ```bash
   Task feature-orchestrator("Analyze [feature] for: duplicate detection,
   effort estimate (S/M/L/XL), sprint capacity fit, timeline impact")
   ```

   **Output:**
   - Duplicate check (is this similar to #X?)
   - Effort estimate (S: 2-4h, M: 4-8h, L: 1-2d, XL: 2-5d)
   - Recommended sprint (Sprint 4/5 or v1.0.0+)
   - Risks to April 30 deadline

**Decision Matrix:**

| Values Advisor | Orchestrator Effort | Capacity Available | Decision |
|----------------|---------------------|-----------------------|----------|
| PROCEED | Small (2-4h) | Sprint 4/5 has slack | ✅ Add to MVP |
| PROCEED | Medium (4-8h) | Sprint 4/5 near capacity | ⚠️ Swap with existing feature OR defer |
| PROCEED | Large (1-2d) | Any | 🚫 Defer to v1.0.0 (too risky) |
| RECONSIDER | Any | Any | 🚫 Reject or heavily modify |

**Output:** Update issue with `status: approved` or `status: rejected` + detailed reasoning

### Tier 3: Monthly Backlog Grooming (60 minutes)

**When:** First Monday of each month (Feb 3, Mar 3, Apr 1)

**Agenda:**

1. **Review Proposed Features** (30 min)
   - All issues with `status: proposed` label
   - Run through Tier 2 evaluation for top 5 ideas
   - Update to `status: approved` or `status: rejected`

2. **Prune Backlog** (15 min)
   - Close duplicate issues (use FEATURE_REGISTRY.md)
   - Merge similar ideas
   - Archive low-value v1.1.0 issues

3. **Promote Opportunities** (15 min)
   - Review `parking-lot: approved` issues
   - If Sprint 4/5 has capacity, can any v1.0.0 feature pull forward?
   - Update sprint labels if promoted

**Output:** Clean backlog, updated FEATURE_REGISTRY.md, sprint plan adjustments

---

## 🏗️ Implementation Plan

### Phase 1: Setup (2 hours) - Do This Week

#### Step 1: Create New Labels (15 min)

```bash
# Approval status
gh label create "status: proposed" --description "New idea, needs evaluation" --color "e1e4e8"
gh label create "status: approved" --description "Validated, ready for backlog" --color "4caf50"
gh label create "status: rejected" --description "Not aligned with roadmap" --color "d73a4a"

# Parking lot quality
gh label create "parking-lot: approved" --description "Will do post-MVP, timing TBD" --color "d4c5f9"
gh label create "parking-lot: under-review" --description "Needs more validation" --color "fef2c0"
gh label create "parking-lot: low-confidence" --description "Probably won't do" --color "f9d0c4"
```

#### Step 2: Create FEATURE_REGISTRY.md (45 min)

**Template:**

```markdown
# LockItIn Feature Registry

Last Updated: [Date]

## Purpose
Single source of truth for all features (implemented, in-progress, backlog).
Prevents duplicate issues and tracks completion status.

## Tier 1: Must-Have Features (MVP)

| Feature | Status | GitHub Issue | Sprint | Notes |
|---------|--------|--------------|--------|-------|
| Personal calendar + native sync | ✅ Complete | #1-14 | Sprint 1 | EventKit/CalendarContract |
| Shadow Calendar privacy | ✅ Complete | #15-30 | Sprint 2 | RLS enforced |
| Friend system + groups | ✅ Complete | #31-45 | Sprint 2 | |
| Group availability heatmap | ✅ Complete | #46-60 | Sprint 3 | |
| Event proposals + voting | ✅ Complete | #61-75 | Sprint 3 | Real-time WebSocket |
| Push notifications | 🚧 Sprint 5 | #85-92 | Sprint 5 | APNs + FCM |
| Surprise Birthday template | 🚧 Sprint 4 | #68-70 | Sprint 4 | Privacy-first |

## Tier 2: Strong Differentiators

| Feature | Status | GitHub Issue | Sprint | Notes |
|---------|--------|--------------|--------|-------|
| Smart time suggestions | 📦 v1.0.0 | #26-27 | Post-MVP | Algorithm-heavy |
| Travel time + departure | 🚧 Sprint 4 | #71-74 | Sprint 4 | Google Maps API |
| Potluck template | 🚧 Sprint 4 | #75-77 | Sprint 4 | Dish coordination |

## Tier 3: Post-Launch (v1.0.0 - v1.1.0)

| Feature | Status | GitHub Issue | Version | Notes |
|---------|--------|--------------|---------|-------|
| 24-hour timeline view | 📦 Backlog | #227 | v1.0.0 | UI enhancement |
| Week number display | 📦 Backlog | #196 | v1.1.0 | Calendar polish |
| Emoji support for events | 📦 Backlog | #200 | v0.5.0 | Nice-to-have |
| Forgot password flow | 📦 Backlog | #199 | v1.0.0 | Auth improvement |
| Social login (Google/Apple) | 📦 Backlog | #183 | v1.1.0 | Onboarding ease |

## Status Legend
- ✅ Complete: Merged to main
- 🚧 In Progress: Assigned to current sprint
- 📦 Backlog: Approved, waiting for capacity
- 💡 Proposed: Needs evaluation
- 🚫 Rejected: Not aligned with roadmap
```

**Populate with all features from `lockitin-features.md`** and cross-reference GitHub issues.

#### Step 3: Tag Existing v1.x Issues (30 min)

```bash
# Review all 16 v1.x issues created recently
gh issue list --search "v1.0.0 in:title OR v1.1.0 in:title" --state open

# For each issue, add appropriate labels:
gh issue edit 227 --add-label "parking-lot: approved"  # 24-hour timelines (good idea)
gh issue edit 196 --add-label "parking-lot: low-confidence"  # Week numbers (niche)
gh issue edit 200 --add-label "parking-lot: approved"  # Emoji support (user delight)
# ... etc.
```

#### Step 4: Create Issue Templates (30 min)

**File:** `.github/ISSUE_TEMPLATE/new-feature-request.md`

```markdown
---
name: New Feature Request
about: Propose a new feature for LockItIn
title: 'v[VERSION] - [CATEGORY]: [Feature Title]'
labels: 'status: proposed, type: feature'
assignees: ''
---

## 🎯 Feature Description

[Clear description of what the feature does]

## 🧑‍💻 User Story

As a [user type], I want [feature], so that [benefit].

## 💎 Value Proposition

**Why this matters:**
- User benefit: [How does this improve UX?]
- Business value: [Does this drive retention/virality/monetization?]
- Competitive edge: [Do competitors have this?]

## 🏗️ Technical Approach (Optional)

[High-level implementation ideas, if known]

## ✅ Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## 📊 MoSCoW Assessment (Required)

**Initial Categorization:**
- [ ] Must Have (Blocks MVP launch)
- [ ] Should Have (Strong differentiator)
- [ ] Could Have (Nice improvement)
- [ ] Won't Have (Post-launch)

**Justification:** [Why this category?]

## 🔗 References

- Related features: [Link to similar features in FEATURE_REGISTRY.md]
- User feedback: [Link to Discord/Twitter/beta tester request]
- Competitive analysis: [Link to competitor doing this]
```

---

### Phase 2: Workflow Integration (Ongoing)

#### Daily Workflow: New Feature Request Arrives

**Time Investment:** 2-5 minutes per request

```bash
# 1. Immediate Triage (2 min)
- Read feature description
- Apply MoSCoW categorization
- If "Must Have" → proceed to Step 2
- If "Should/Could/Won't Have" → create issue with status: proposed

# 2. Create GitHub Issue (3 min)
gh issue create --title "v1.0.0 - [Category]: [Feature]" \
  --body-file feature-description.md \
  --label "status: proposed" \
  --label "type: feature" \
  --label "area: [calendar/groups/proposals/etc]" \
  --label "priority: [low/medium/high]"

# 3. Add to FEATURE_REGISTRY.md (1 min)
# Update the appropriate tier table with new row

# 4. If "Must Have", escalate to Agent Review
Task feature-values-advisor("Evaluate [feature] for alignment...")
Task feature-orchestrator("Analyze [feature] for effort and capacity...")
```

#### Weekly Review: Sprint Planning (30 min)

**Every Friday before new sprint starts:**

```bash
# 1. Review all status: proposed issues from past week
gh issue list --label "status: proposed" --state open

# 2. Run Tier 2 evaluation on top 3 ideas
# (Use agents: feature-values-advisor + feature-orchestrator)

# 3. Promote approved ideas to backlog
gh issue edit [number] --add-label "status: approved" --add-label "parking-lot: approved"

# 4. Update FEATURE_REGISTRY.md with new approved features

# 5. Check if any approved features can fit in upcoming sprint
# (Only if sprint has <50 hours committed and deadline safe)
```

#### Monthly Grooming: First Monday (60 min)

**Example: March 3, 2026 (between Sprint 4 and Beta Testing)**

```bash
# 1. List all proposed features (30 min)
gh issue list --label "status: proposed" --state open --json number,title,labels

# Run agent evaluations on top 5:
Task feature-values-advisor("Batch evaluate these 5 features...")
Task feature-orchestrator("Batch analyze effort for these 5 features...")

# Update labels based on agent output

# 2. Prune backlog (15 min)
# Review FEATURE_REGISTRY.md
# Close duplicates (e.g., #227 + #196 might be one "calendar display settings" feature)
# Archive low-confidence v1.1.0 issues

# 3. Promote opportunities (15 min)
# Check remaining capacity in Sprint 5 or Beta phase
# If safe, promote 1-2 small features from v1.0.0 → v0.5.0
```

---

### Phase 3: Mid-Sprint Handling (Emergency Process)

**Scenario:** During Sprint 4, a critical bug or "must-have" feature is discovered.

**Rules:**
1. **Sprint Goal is Sacred** - Cannot change after Day 1 of sprint
2. **Max 1 Addition** - Only add 1 unplanned item per sprint
3. **Equal Swap Required** - New item must replace equal-effort item

**Process:**

```bash
# 1. Urgent Request Evaluation (10 min)
# Ask: Does this BLOCK MVP launch if not fixed?
# - YES → Proceed to Step 2
# - NO → Defer to next sprint

# 2. Effort Estimation (5 min)
Task feature-orchestrator("Quick effort estimate for [urgent feature]")
# Output: S (2-4h), M (4-8h), L (1-2d)

# 3. Find Swap Candidate (10 min)
# Look at current sprint backlog
# Find item of equal effort that can defer
# Consult FEATURE_REGISTRY.md for priority

# 4. Make the Swap (5 min)
gh issue edit [new-urgent-item] --add-label "sprint: 4"
gh issue edit [deferred-item] --remove-label "sprint: 4" --add-label "sprint: 5"

# 5. Update Sprint Plan (5 min)
# Document swap in sprint retrospective notes
# Update burndown chart estimates
```

**Example:**

```
Mid-Sprint Emergency: "Timezone selector is broken on Android"

Step 1: Blocks MVP? YES (Android users can't set event times)
Step 2: Effort? MEDIUM (6 hours to fix)
Step 3: Swap candidate? "Potluck dish assignment UI polish" (also 6h, Sprint 4)
Step 4: Execute swap
  - #208 (Timezone fix) → Add sprint: 4
  - #77 (Potluck polish) → Remove sprint: 4, add sprint: 5
Step 5: Document in Sprint 4 retrospective
```

---

## 📈 Success Metrics

**Track These Weekly:**

| Metric | Target | Why It Matters |
|--------|--------|----------------|
| New features proposed | <5/week | Too many = scope creep risk |
| Proposed → Approved ratio | <20% | Most ideas defer to post-MVP |
| Mid-sprint swaps | 0-1/sprint | Stability indicator |
| Backlog growth | <10 issues/month | Prevent bloat |
| Duplicate features created | 0 | FEATURE_REGISTRY.md working |

**Monthly Review (at grooming session):**

- **Scope Creep Check:** Did any unapproved features sneak into sprint?
- **Capacity Accuracy:** Were effort estimates within 20% of actual?
- **Deadline Confidence:** Are we still on track for April 30?

**Decision Gates at Checkpoints:**

| Checkpoint | Date | Go/No-Go Criteria |
|------------|------|-------------------|
| Checkpoint 4 | Feb 19 | Sprint 4 complete, <5 v1.0.0 features promoted |
| Checkpoint 5 | Feb 26 | MVP feature-complete, 0 new features in beta phase |
| Beta Start | Feb 27 | Only bug fixes and polish allowed |
| Launch Ready | Apr 8 | Zero P0 bugs, approved backlog for v1.0.1 |

---

## 🚨 Red Flags: When to Say "No"

**Auto-Reject Criteria (Don't Even Create Issue):**

1. **Duplicates Existing Feature** - Check FEATURE_REGISTRY.md first
2. **Contradicts Privacy Principles** - Feature Values Advisor would reject
3. **Adds >1 Day Effort** - Too risky for tight timeline
4. **Not in Tier 1-3** - If it's not in lockitin-features.md, default defer
5. **User Requested Once** - Wait for 3+ requests before considering

**Defer to v1.0.0+ (Create Issue but Park):**

1. **Nice-to-Have Polish** - E.g., "Add week numbers to calendar"
2. **Niche Use Case** - E.g., "Support Hebrew calendar"
3. **Performance Optimization** - E.g., "Riverpod 2.x migration" (unless blocking)
4. **Alternative Approach Exists** - E.g., "If-needed vote option" (can use comments)

**Pull Forward to MVP (Requires Agent Approval + Swap):**

1. **Beta Tester Blocker** - "Can't use app without this"
2. **Competitive Parity** - "Doodle has this, we must too"
3. **Launch Requirement** - "App Store will reject without this"
4. **Technical Dependency** - "Timezone fix unblocks 3 other features"

---

## 🛠️ Tools & Templates

### Quick Commands

```bash
# Create new feature request
gh issue create --template new-feature-request.md

# List proposed features
gh issue list --label "status: proposed" --state open

# List approved backlog
gh issue list --label "parking-lot: approved" --state open

# Find features by version
gh issue list --search "v1.0.0 in:title" --state open

# Check sprint capacity
gh issue list --label "sprint: 4" --json title,labels --jq 'map(select(.labels[].name == "size: medium")) | length'
```

### Agent Workflows

**Feature Values Advisor:**
```bash
Task feature-values-advisor("Evaluate feature: [name].
Check alignment with:
1. Privacy-first architecture
2. Minimal & focused design
3. Native & delightful UX
Output verdict: PROCEED / RECONSIDER / DO NOT IMPLEMENT")
```

**Feature Orchestrator:**
```bash
Task feature-orchestrator("Analyze feature: [name].
Provide:
1. Duplicate check (similar to #X?)
2. Effort estimate (S/M/L/XL)
3. Sprint recommendation (4/5 or v1.0.0+)
4. Timeline risk assessment (high/medium/low)")
```

### Decision Flowchart

```
New Feature Idea
    ↓
Is it a bug? → YES → Fix immediately
    ↓ NO
In Tier 1-2? → YES → Create subtask of existing epic
    ↓ NO
MoSCoW: Must Have? → YES → AGENT REVIEW (Tier 2)
    ↓ NO
MoSCoW: Should/Could? → YES → Create issue (status: proposed)
    ↓ NO
MoSCoW: Won't Have → REJECT or Park in v1.1.0
```

---

## 📚 Reference Documentation

**Internal Docs:**
- `/lockitin_docs/lockitin-features.md` - Feature tiers and philosophy
- `/lockitin_docs/lockitin-roadmap-development.md` - Sprint timeline
- `/lockitin_docs/versioning-and-issue-categories.md` - Naming conventions
- `/.claude/agents/feature-orchestrator.md` - Feature lifecycle agent
- `/.claude/agents/feature-values-advisor.md` - Values alignment agent

**External Resources:**
- [MoSCoW Prioritization](https://www.productplan.com/glossary/moscow-prioritization/) - Simple framework for quick decisions
- [Project Intake Process](https://asana.com/resources/project-intake-process) - Standardized evaluation
- [Managing Scope Creep in Agile](https://www.tempo.io/blog/scope-creep-in-agile) - Prevention strategies

---

## 🎬 Next Steps

### Immediate Actions (This Week):

- [ ] Create new GitHub labels (status: proposed/approved/rejected, parking-lot: *)
- [ ] Create FEATURE_REGISTRY.md from lockitin-features.md
- [ ] Tag existing 16 v1.x issues with parking-lot labels
- [ ] Create `.github/ISSUE_TEMPLATE/new-feature-request.md`
- [ ] Test workflow with next feature idea that comes up

### Monthly Recurring:

- [ ] First Monday: 60-min backlog grooming session
- [ ] Review all `status: proposed` issues
- [ ] Run agent evaluations on top 5 ideas
- [ ] Prune duplicates, archive low-value items
- [ ] Update FEATURE_REGISTRY.md

### At Each Sprint Checkpoint:

- [ ] Review scope creep metrics (new features proposed, swaps made)
- [ ] Validate deadline confidence (still on track for Apr 30?)
- [ ] Adjust process if needed (too many/too few features being accepted?)

---

## ✅ Acceptance Criteria

This process is successful if:

1. **Scope Discipline:** Sprint 4-5 ship with 0 unplanned features (swaps are OK)
2. **Fast Decisions:** New feature requests evaluated in <5 minutes
3. **Agent Consistency:** Feature Values Advisor and Orchestrator used for all "Must Have" requests
4. **Clean Backlog:** FEATURE_REGISTRY.md stays up-to-date, <50 total backlog issues
5. **Launch Success:** MVP ships April 30, 2026 with all Tier 1-2 features complete
6. **Post-Launch Ready:** 10-15 approved v1.0.0 features ready to implement in Month 2

---

## 📝 Work Log

**January 7, 2026:**
- Created initial plan based on research (3 agents: roadmap analysis, best practices, GitHub issue patterns)
- Identified 6 critical gaps in current process
- Designed 3-tier intake workflow (Triage → Agent Review → Monthly Grooming)
- Ready for implementation

**Next Session:**
- Execute Phase 1 (Setup) - create labels, FEATURE_REGISTRY.md, tag existing issues
- Test workflow with next feature idea
- Document learnings

---

## 🔗 Resources

**Agent IDs (for resuming research):**
- Roadmap Research: `afe178d`
- Best Practices Research: `aa77b3a`
- GitHub Issue Analysis: `a808350`

**Related Plans:**
- Sprint 4 Planning (Templates & Travel)
- Beta Testing Strategy
- Post-MVP Roadmap (to be created)

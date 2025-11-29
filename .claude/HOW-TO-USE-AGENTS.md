# How to Use Claude Subagents - Quick Start Guide

This guide shows you how to effectively use the specialized Claude agents for the Shareless Calendar project.

## Quick Reference

| Task | Agent to Use | Example Prompt |
|------|-------------|----------------|
| Implement iOS feature | 🍎 iOS Developer | "Following iOS Developer agent guidelines, implement the voting UI..." |
| Create database table | 🗄️ Supabase Database | "Using Supabase Database agent patterns, create a table for..." |
| Set up CI/CD | ⚙️ Systems Engineer | "Following Systems Engineer agent, set up GitHub Actions for..." |
| Evaluate new feature | 🎯 Product Vision | "Using Product Vision agent, evaluate if we should add..." |
| Automate sprint workflow | 🤖 GitHub Automation | "Following GitHub Automation agent, create a script to..." |

## Method 1: Single Agent Invocation (Simple Tasks)

For straightforward tasks that fit one domain:

```
Prompt: "Using the iOS Developer agent guidelines from .claude/agents/ios-developer.md,
implement the calendar sync feature with EventKit. Follow the MVVM pattern and include
error handling."
```

Claude will:
1. Read the iOS Developer agent file
2. Follow the patterns and guidelines
3. Implement according to best practices
4. Include tests and documentation

## Method 2: Multi-Agent Workflow (Complex Features)

For features that span multiple domains, chain agents:

```
Prompt: "I want to add a 'Surprise Party' template feature. Use the following workflow:

1. Product Vision agent - Validate this aligns with our differentiators
2. Supabase Database agent - Design the schema changes needed
3. iOS Developer agent - Implement the UI and business logic
4. Systems Engineer agent - Add monitoring for this feature
5. GitHub Automation agent - Create the PR with proper labeling"
```

Claude will execute each step in sequence, using the appropriate agent's expertise.

## Method 3: Agent Consultation (Decision Making)

For decisions that need expert input:

```
Prompt: "I'm considering adding Zoom integration for virtual events.
Consult the Product Vision agent to determine if this aligns with our
friend-groups-not-businesses positioning."
```

Claude will:
1. Review Product Vision agent guidelines
2. Analyze the request against core principles
3. Provide a recommendation with reasoning

## Real-World Examples

### Example 1: Implementing Event Creation Flow

**Task:** Build the event creation screen with privacy controls

**Multi-Agent Approach:**
```
1. Product Vision agent:
   - Verify privacy levels (Private/Busy-Only/Shared) align with Shadow Calendar vision
   - Confirm UX flow matches NotionMD/Complete UI Flows/FLOW 2

2. iOS Developer agent:
   - Create EventCreationViewModel with @Published properties
   - Build EventCreationView with SwiftUI
   - Add haptic feedback and animations
   - Write unit tests for ViewModel

3. Supabase Database agent:
   - Verify 'events' table schema supports visibility enum
   - Ensure RLS policies respect privacy settings

4. GitHub Automation agent:
   - Create PR with "feat: event creation flow" title
   - Link to issue #45
   - Add testing instructions
```

### Example 2: Optimizing Database Queries

**Task:** Slow group availability query needs optimization

**Single Agent Approach:**
```
Prompt: "Using the Supabase Database agent expertise, optimize this query
that fetches group member availability. Currently taking 800ms, target is <50ms:

SELECT e.*, u.username
FROM events e
JOIN users u ON e.created_by = u.id
WHERE e.created_by IN (
  SELECT user_id FROM group_members WHERE group_id = 'abc123'
)
AND e.visibility IN ('shared_with_name', 'busy_only')
AND e.start_time BETWEEN '2025-01-01' AND '2025-01-31'

Follow the Supabase Database agent's query optimization patterns."
```

### Example 3: Evaluating Feature Request

**Task:** User requested "recurring event templates"

**Product Vision Agent:**
```
Prompt: "A user requested 'recurring event templates' (e.g., Weekly Game Night).
Using the Product Vision agent's feature prioritization framework, evaluate:

1. Does this solve the core problem (group coordination chaos)?
2. Does this strengthen our differentiation?
3. What tier should this be (1/2/3)?
4. Should we build it now or post-MVP?

Reference: NotionMD/SharelessFeatures/Core Features.md"
```

## Sprint Workflow with GitHub Automation Agent

### Daily Workflow

**Morning (Auto-pull next issue):**
```bash
# Run the GitHub Automation agent's auto-pull script
.github/scripts/pull-next-issue.sh

# This will:
# 1. Check if previous PR is merged
# 2. Verify no issues are "in-progress"
# 3. Pull next highest-priority issue from current milestone
# 4. Create feature branch
# 5. Update issue labels
```

**During Development:**
```
Prompt: "Using the iOS Developer agent, implement the feature from issue #47
(Group Calendar Heatmap). Follow MVVM, include tests, respect privacy settings."
```

**End of Day (Create PR):**
```bash
# Run the GitHub Automation agent's PR creation script
.github/scripts/create-pr.sh

# This will:
# 1. Run quality checks (tests, SwiftLint)
# 2. Commit changes
# 3. Push branch
# 4. Create PR with template
# 5. Add labels and milestone
```

## Advanced: Agent Chaining with Context

For complex tasks, you can chain agents with shared context:

```
Prompt: "Implement the 'Smart Time Suggestions' feature (issue #52) using this workflow:

CONTEXT FOR ALL AGENTS:
- Feature: Analyze group availability, suggest top 3 times
- Algorithm: Count free members per time slot, rank by availability
- Privacy: Must respect busy-only settings (don't reveal who's busy)

WORKFLOW:
1. Product Vision agent:
   - Confirm this is a Tier 2 feature (Strong Differentiator)
   - Validate UX aligns with "Minimal & Focused" principle

2. Supabase Database agent:
   - Design query to aggregate availability across group
   - Ensure RLS policies are respected
   - Optimize for <50ms query time

3. iOS Developer agent:
   - Implement AvailabilityAnalyzer service class
   - Create SmartSuggestionsViewModel
   - Build UI with suggested time slots
   - Add shimmer loading state
   - Write unit tests (70% coverage)

4. Systems Engineer agent:
   - Add performance monitoring for query time
   - Set up alert if suggestions take >100ms

5. GitHub Automation agent:
   - Create PR with issue #52
   - Include before/after performance metrics
   - Add testing instructions for edge cases
"
```

## Tips for Effective Agent Use

### 1. Be Specific About Which Agent to Use
❌ "Build the voting feature"
✅ "Using the iOS Developer agent, build the voting UI following MVVM pattern"

### 2. Reference Agent Guidelines Explicitly
❌ "Make it privacy-friendly"
✅ "Following the Product Vision agent's privacy-first principles, ensure..."

### 3. Provide Context from Documentation
✅ "Reference NotionMD/Complete UI Flows/FLOW 5 for voting flow, then use iOS Developer agent to implement"

### 4. Use Agent Chaining for Complexity
Simple task → Single agent
Complex feature → Chain multiple agents
Strategic decision → Start with Product Vision agent

### 5. Trust Agent Expertise
Each agent has deep knowledge of best practices. Don't override their patterns unless you have a specific reason.

## Common Agent Combinations

| Task Type | Agent Combination |
|-----------|-------------------|
| New Feature | Product Vision → iOS Developer → Supabase Database → Systems Engineer → GitHub Automation |
| Bug Fix | iOS Developer OR Supabase Database → GitHub Automation |
| Performance Issue | Systems Engineer → Supabase Database OR iOS Developer |
| Feature Evaluation | Product Vision (alone) |
| Sprint Setup | GitHub Automation (alone) |
| Infrastructure | Systems Engineer (alone) |

## Troubleshooting

**"Agent isn't following the guidelines"**
- Ensure you explicitly reference the agent file path
- Use phrase "Following the [Agent Name] agent guidelines from .claude/agents/..."

**"Agent missing project-specific context"**
- Point agent to relevant NotionMD/ documentation
- Provide CLAUDE.md context if needed

**"Multiple agents giving conflicting advice"**
- Start with Product Vision agent for alignment
- Let it set the constraints for technical agents

**"Agent workflow too slow"**
- Use single agent for simple tasks
- Only chain agents for truly complex features

---

## Getting Started Checklist

- [ ] Read `.claude/agents/README.md` for agent overview
- [ ] Familiarize yourself with each agent's expertise
- [ ] Review example prompts in this guide
- [ ] Try a simple single-agent task
- [ ] Try a multi-agent workflow
- [ ] Set up GitHub Automation scripts (when code repo exists)

**Next Steps:**
1. Pick a task from your current sprint
2. Identify which agent(s) to use
3. Craft a specific prompt referencing the agent
4. Review output against agent guidelines
5. Iterate if needed

For questions or improvements to agents, update the relevant `.claude/agents/[agent-name].md` file.

# Claude Subagents for Shareless Calendar

This directory contains specialized Claude Code agents, each with expertise in a specific domain of the Shareless Calendar project.

## Available Agents

### 🍎 iOS SwiftUI Architect (`ios-swiftui-architect.md`)
**Expertise:** Swift, SwiftUI, EventKit, MVVM architecture, Combine, iOS best practices
**Use for:**
- Implementing iOS features with SwiftUI
- Writing ViewModels and Views
- EventKit calendar integration
- State management patterns (@State, @Binding, @ObservedObject, @StateObject)
- UI/UX implementation
- Performance optimization
- Navigation and data flow

**Invoke when:** Building iOS app features, debugging Swift code, implementing UI flows, state management issues

---

### 🔗 Supabase iOS Integration (`supabase-ios-integration.md`)
**Expertise:** Supabase Swift SDK, PostgreSQL, Row Level Security, real-time subscriptions, authentication
**Use for:**
- Supabase project setup and configuration
- Authentication flows (email/password, OAuth, magic links)
- Database operations from Swift
- RLS policy design and testing
- Real-time subscriptions with Combine
- Supabase Storage integration
- Offline-first patterns
- Query optimization and caching

**Invoke when:** Integrating Supabase with iOS, working on authentication, database queries, real-time features, debugging connection issues

---

### 🔄 Dev Sync Coordinator (`dev-sync-coordinator.md`)
**Expertise:** Cross-platform coordination, iOS-Backend alignment, integration verification
**Use for:**
- Verifying iOS and Supabase implementations are aligned
- Detecting potential misalignment between frontend and backend
- Coordinating feature work across platforms
- Sprint checkpoint reviews
- Integration testing coordination

**Invoke when:** After significant iOS or Supabase work, before starting cross-platform features, during sprint reviews, when detecting misalignment

---

### 💎 Feature Values Advisor (`feature-values-advisor.md`)
**Expertise:** Product values, privacy-first principles, feature evaluation, UX principles
**Use for:**
- Evaluating new feature proposals against core values
- Ensuring privacy-first design
- Assessing feature alignment with product mission
- Reviewing UX decisions for value consistency
- Preventing feature creep or value drift

**Invoke when:** Designing new features, evaluating feature requests, making product decisions, reviewing UX flows

---

### 🎯 Feature Orchestrator (`feature-orchestrator.md`)
**Expertise:** Feature lifecycle management, MVP planning, market research, roadmap coordination
**Use for:**
- Planning which features to build before launch
- Tracking feature implementation status (Tier 1/2/3)
- Conducting market research for new features
- Breaking down approved features into GitHub issues
- Sprint/milestone assignment
- Feature prioritization and timeline planning

**Invoke when:** Planning feature roadmap, evaluating new feature ideas, tracking MVP progress, creating development tasks from features

---

### 🤖 GitHub Workflow Manager (`github-workflow-manager.md`)
**Expertise:** GitHub project management, issue creation, PR management, sprint planning, workflow automation
**Use for:**
- Creating well-structured issues with labels and milestones
- Setting up sprints and project boards
- Pulling issues to work on with context
- Creating comprehensive pull requests
- Managing branching strategies
- Release cycles and version tagging

**Invoke when:** Starting work on features, creating PRs, planning sprints, managing GitHub workflow, organizing releases

---

## How to Use Agents

### Method 1: Direct Invocation in Claude Code
When working in Claude Code, you can reference an agent's guidelines by mentioning:
```
"Following the iOS Developer agent guidelines, implement the calendar sync feature..."
```

### Method 2: Context Injection
Copy relevant sections from an agent file into your prompt:
```
Using the Supabase Database agent's RLS policy patterns, create a policy for...
```

### Method 3: Agent Chaining
Combine multiple agents for complex tasks:
```
1. Product Vision agent: Validate this feature aligns with our differentiators
2. iOS Developer agent: Implement the feature
3. Supabase Database agent: Create necessary backend support
4. Systems Engineer agent: Set up monitoring
5. GitHub Automation agent: Create PR and track progress
```

## Agent Interaction Patterns

### Feature Implementation Workflow
```
Feature Values Advisor → validates alignment with core values
    ↓
Feature Orchestrator → breaks down into tasks, assigns to sprint
    ↓
iOS SwiftUI Architect → implements UI/logic
    ↓
Supabase iOS Integration → creates backend support
    ↓
Dev Sync Coordinator → verifies iOS and Supabase are aligned
    ↓
GitHub Workflow Manager → creates PR
```

### New Feature Evaluation
```
Feature Values Advisor → evaluates fit with product values
    ↓ (if approved)
Feature Orchestrator → conducts market research, estimates complexity
    ↓
iOS SwiftUI Architect + Supabase iOS Integration → technical assessment
    ↓
Feature Orchestrator → creates GitHub issues, assigns to sprint
```

### Sprint Planning Workflow
```
Feature Orchestrator → identifies next features to build
    ↓
GitHub Workflow Manager → creates sprint milestone, organizes issues
    ↓
Developer starts sprint → GitHub Workflow Manager pulls next issue
    ↓
Dev Sync Coordinator → periodic alignment checks throughout sprint
```

### Cross-Platform Feature Development
```
GitHub Workflow Manager → pulls feature issue
    ↓
iOS SwiftUI Architect → implements frontend
    ↓
Supabase iOS Integration → implements backend integration
    ↓
Dev Sync Coordinator → verifies alignment (RLS policies, API contracts, data models)
    ↓
GitHub Workflow Manager → creates comprehensive PR
```

## Best Practices

### When to Use Which Agent

**Use iOS SwiftUI Architect when:**
- Writing Swift/SwiftUI code
- Debugging UI issues or state management problems
- Implementing EventKit integration
- Optimizing iOS performance
- Designing MVVM architecture
- Handling navigation and data flow

**Use Supabase iOS Integration when:**
- Setting up Supabase authentication in iOS
- Implementing database queries from Swift
- Creating or testing RLS policies
- Setting up real-time subscriptions with Combine
- Debugging Supabase connection issues
- Implementing offline-first patterns

**Use Dev Sync Coordinator when:**
- After completing iOS or Supabase features
- Before starting cross-platform work
- During sprint checkpoints
- When you suspect frontend/backend misalignment
- Verifying integration contracts

**Use Feature Values Advisor when:**
- Proposing new features
- Evaluating feature requests
- Making UX/privacy decisions
- Ensuring features align with core values
- Reviewing product direction

**Use Feature Orchestrator when:**
- Planning the feature roadmap
- Tracking MVP progress
- Conducting market research for features
- Breaking features into development tasks
- Prioritizing what to build next

**Use GitHub Workflow Manager when:**
- Starting work on a new feature
- Creating pull requests
- Planning sprints and milestones
- Managing GitHub project boards
- Organizing releases

### Agent Collaboration

Agents are designed to work together. For complex tasks:

1. **Start with Feature Values Advisor** to ensure alignment with core values
2. **Use Feature Orchestrator** to plan and break down the work
3. **Involve technical agents** (iOS SwiftUI Architect, Supabase iOS Integration) for implementation
4. **Use Dev Sync Coordinator** to verify frontend/backend alignment
5. **Let GitHub Workflow Manager** handle PRs and sprint workflow

### Customization

Each agent can be customized for your workflow:
- Add project-specific patterns
- Update technology versions
- Add new tools/frameworks
- Adjust coding standards

## File Structure

```
.claude/
└── agents/
    ├── README.md (this file)
    ├── ios-swiftui-architect.md
    ├── supabase-ios-integration.md
    ├── dev-sync-coordinator.md
    ├── feature-values-advisor.md
    ├── feature-orchestrator.md
    └── github-workflow-manager.md
```

## Maintenance

These agent files should be updated when:
- Technology stack changes (new libraries, frameworks)
- Development practices evolve
- New patterns emerge
- Project requirements shift

Last updated: November 29, 2024

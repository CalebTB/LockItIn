# Claude Subagents for Shareless Calendar

This directory contains specialized Claude Code agents, each with expertise in a specific domain of the Shareless Calendar project.

## Available Agents

### 🍎 iOS Developer (`ios-developer.md`)
**Expertise:** Swift, SwiftUI, EventKit, MVVM architecture
**Use for:**
- Implementing iOS features
- Writing ViewModels and Views
- EventKit calendar integration
- UI/UX implementation
- Performance optimization

**Invoke when:** Building iOS app features, debugging Swift code, implementing UI flows

---

### 🗄️ Supabase Database (`supabase-database.md`)
**Expertise:** PostgreSQL, Row Level Security, Supabase platform, real-time subscriptions
**Use for:**
- Database schema design
- RLS policy creation
- Query optimization
- Database migrations
- Supabase Edge Functions
- Real-time WebSocket setup

**Invoke when:** Working on backend, database changes, privacy enforcement, real-time features

---

### ⚙️ Systems Engineer (`systems-engineer.md`)
**Expertise:** CI/CD, DevOps, monitoring, deployment, infrastructure
**Use for:**
- GitHub Actions workflows
- Fastlane automation
- TestFlight deployment
- Monitoring setup (Sentry, analytics)
- Performance monitoring
- Security hardening

**Invoke when:** Setting up deployment pipelines, monitoring, infrastructure, or debugging production issues

---

### 🎯 Product Vision (`product-vision.md`)
**Expertise:** Product strategy, UX principles, feature prioritization, competitive positioning
**Use for:**
- Feature prioritization decisions
- UX/UI design validation
- Competitive analysis
- User feedback evaluation
- Messaging and tone
- Ensuring alignment with core differentiators

**Invoke when:** Making product decisions, evaluating new features, reviewing UX, ensuring vision alignment

---

### 🤖 GitHub Automation (`github-automation.md`)
**Expertise:** GitHub workflows, issue management, PR automation, sprint tracking
**Use for:**
- Auto-pulling next sprint issue
- Creating pull requests
- Sprint progress tracking
- Automated testing workflows
- Daily standup reports

**Invoke when:** Managing sprints, automating GitHub workflows, tracking progress

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
Product Vision → validates alignment
    ↓
iOS Developer → implements UI/logic
    ↓
Supabase Database → creates backend support
    ↓
Systems Engineer → adds monitoring
    ↓
GitHub Automation → creates PR
```

### Bug Fix Workflow
```
Systems Engineer → diagnoses via monitoring
    ↓
iOS Developer OR Supabase Database → implements fix
    ↓
GitHub Automation → creates PR with fix
    ↓
Systems Engineer → verifies fix in production
```

### New Feature Evaluation
```
Product Vision → evaluates fit with strategy
    ↓ (if approved)
iOS Developer + Supabase Database → estimate complexity
    ↓
Product Vision → final prioritization decision
```

## Best Practices

### When to Use Which Agent

**Use iOS Developer when:**
- Writing Swift/SwiftUI code
- Debugging UI issues
- Implementing EventKit integration
- Optimizing performance

**Use Supabase Database when:**
- Designing database schema
- Creating RLS policies
- Optimizing queries
- Setting up real-time features

**Use Systems Engineer when:**
- Setting up CI/CD
- Deploying to TestFlight
- Configuring monitoring
- Investigating production issues

**Use Product Vision when:**
- Evaluating new feature requests
- Making prioritization decisions
- Reviewing UX designs
- Ensuring alignment with mission

**Use GitHub Automation when:**
- Managing sprint workflow
- Automating repetitive tasks
- Tracking progress
- Creating standardized PRs

### Agent Collaboration

Agents are designed to work together. For complex tasks:

1. **Start with Product Vision** to ensure alignment
2. **Involve technical agents** (iOS, Database) for implementation
3. **Use Systems Engineer** for deployment and monitoring
4. **Let GitHub Automation** handle workflow

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
    ├── ios-developer.md
    ├── supabase-database.md
    ├── systems-engineer.md
    ├── product-vision.md
    └── github-automation.md
```

## Maintenance

These agent files should be updated when:
- Technology stack changes (new libraries, frameworks)
- Development practices evolve
- New patterns emerge
- Project requirements shift

Last updated: November 29, 2024

# PHASE 0: PRE-MAC PREPARATION

### **December 1-25 (4 weeks)**

This is critical time - don't waste it! You can make HUGE progress before touching code.

### **Week 1 (Dec 1-7): Market Research & Validation**

**Goals:**

- Validate the problem exists
- Understand competitive landscape
- Define MVP scope

**Tasks:**

```markdown
□ Interview 10 people from friend groups (30 min each)
  - How do they currently plan group events?
  - What's most frustrating about it?
  - Would they pay $5/month to solve it?
  - What features matter most?

□ Competitive analysis
  - Download & use: Doodle, When2Meet, Calendly, Fantastical
  - Document: What they do well, what sucks
  - Find the gaps your app will fill

□ Create user personas (2-3 profiles)
  Example: "Sarah, 24, organizes monthly game nights, 
   frustrated with group chat chaos"

□ Define success metrics
  - Week 1: 50 users
  - Month 1: 200 users, 10 active groups
  - Month 3: 1,000 users, 5% conversion to premium
```

**Deliverables:**

- Interview notes document
- Competitive analysis spreadsheet
- User persona slides
- Success metrics dashboard design

---

### **Week 2 (Dec 8-14): Design & Wireframing**

**Goals:**

- Finalize UI/UX flows
- Create detailed wireframes
- Plan database schema

Tasks:

```markdown
□ Sketch all screens on paper (use our UI flow from earlier)
  - Main calendar view
  - Event creation
  - Group proposal flow
  - Voting interface
  - Group calendar overlay

□ Create digital wireframes (use Figma - free tier)
  - Import sketches
  - Add navigation flows
  - Define color palette (keep it simple: 3-4 colors)
  - Choose typography (SF Pro for iOS consistency)

□ Design key interactions
  - How does swiping between views feel?
  - What happens when you vote?
  - Loading states, empty states, error states

□ Finalize database schema
  - Review the schema we designed
  - Add any missing fields
  - Plan indexes for performance
```

**Deliverables:**

- Figma wireframes (all screens)
- Interaction flow videos (use Figma prototype)
- Database schema diagram (use dbdiagram.io)
- Asset list (icons, images needed)

**Tools to set up:**

- Figma account (free)
- dbdiagram.io account
- Notion or similar for project management

---

### **Week 3 (Dec 15-21): Learning Swift & SwiftUI**

**Goals:**

- Build Swift/SwiftUI foundation
- Understand iOS development basics
- Get comfortable with Xcode (via browser)

**Tasks:**

```markdown
□ Complete Swift basics (3-4 hours/day)
  - Day 1-2: Swift Playgrounds (variables, functions, optionals)
    Resource: https://www.apple.com/swift/playgrounds/
  
  - Day 3-4: SwiftUI fundamentals (views, state, binding)
    Resource: 100 Days of SwiftUI - Days 1-15
    https://www.hackingwithswift.com/100/swiftui
  
  - Day 5-6: Lists, navigation, data flow
    Resource: 100 Days of SwiftUI - Days 16-25
  
  - Day 7: Build a mini project
    Task: "Simple To-Do List App"
    Features: Add items, delete items, mark complete
    (Practice: Lists, Forms, State, Binding)

□ Study EventKit framework
  - Read Apple's EventKit documentation
  - Watch WWDC sessions on calendar integration
  - Understand calendar permissions flow

□ Learn about Supabase
  - Watch: "Supabase in 100 seconds" video
  - Read: Supabase Swift SDK docs
  - Tutorial: Build a simple CRUD app with Supabase

□ Set up development accounts (prepare for Mac arrival)
  - Create Apple Developer account ($99/year)
    Note: Don't pay yet, just create account
  - Create Supabase account (free tier)
  - Create Stripe account (for future monetization)
```

**Deliverables:**

- Completed to-do list app (shows you understand SwiftUI)
- Notes on EventKit capabilities & limitations
- Supabase test project with basic CRUD operations
- Developer accounts created

**Daily Schedule (recommended):**

- Morning (1-2 hrs): Swift tutorials
- Afternoon (1 hr): Supabase/backend learning
- Evening (30 min): Review notes, plan tomorrow

---

### **Week 4 (Dec 22-25): Architecture & Setup Planning**

**Goals:**

- Plan technical architecture
- Prepare for Day 1 coding
- Final design refinements

**Tasks:**

```markdown
□ Refine technical architecture
  - Review the architecture we designed
  - Create project structure diagram
  - List all dependencies needed
  - Plan API endpoints (what data flows where)

□ Break down MVP into tasks
  - Use our UI flows & architecture
  - Create GitHub issues/Trello cards
  - Estimate hours for each task
  - Prioritize: Must-have vs Nice-to-have

□ Set up project tracking
  - Create GitHub repo (don't commit yet, no Mac)
  - Set up Trello/Linear board with all tasks
  - Define sprints/milestones
  - Create daily development schedule

□ Prepare Day 1 checklist
  - Xcode installation steps
  - Project setup commands
  - Dependencies to install
  - First features to build

□ Final design polish
  - Review Figma designs
  - Get feedback from 2-3 friends
  - Make final adjustments
  - Export assets (icons, colors as Swift code)

□ Christmas prep
  - Clear schedule for Dec 26-27 (dedicated coding time)
  - Set up workspace (desk, monitor if you have one)
  - Plan meals/minimize distractions
```

**Deliverables:**

- Complete task breakdown (100+ tasks)
- GitHub repo created (empty, ready for code)
- Project board set up with all tasks
- Day 1 setup checklist
- Assets ready to import

---

## **CHRISTMAS DAY (Dec 25): MAC MINI SETUP**

### **The Big Day - Setup Checklist:**

```markdown
□ 8:00 AM - Unbox Mac Mini
  - Connect to monitor, keyboard, mouse
  - Complete macOS setup

□ 8:30 AM - Essential software installation
  - Xcode (18GB download - start this FIRST)
    While downloading, do other tasks:
  
  - Install Homebrew
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
  - Install useful tools
    brew install git
    brew install cocoapods (if using pods)
  
  - Install VS Code (optional, good for editing config files)

□ 10:00 AM - Developer setup (Xcode still downloading)
  - Sign in to Apple Developer account
  - Configure Xcode once installed
  - Connect GitHub account
  
□ 11:00 AM - Create first project
  - File → New → Project → iOS App
  - Name: "CalendarApp"
  - Interface: SwiftUI
  - Language: Swift
  - Run on simulator (⌘+R)
  - See "Hello, World!" - you're ready!

□ 12:00 PM - Dependency setup
  - Add Supabase package dependency
  - Configure info.plist for calendar access
  - Set up project structure (folders we designed)

□ 2:00 PM - First commit
  - git init
  - git add .
  - git commit -m "Initial project setup"
  - git push to GitHub

□ 3:00 PM - Build first feature
  - Create simple calendar view (just dates)
  - Goal: See something on screen!

□ 5:00 PM - Celebrate & plan tomorrow
  - You've written your first iOS code!
  - Review Day 1 plan for tomorrow
  - Get good sleep, tomorrow starts the real work
```
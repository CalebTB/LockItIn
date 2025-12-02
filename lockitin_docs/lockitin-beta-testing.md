# LockItIn Beta Testing Guide

Complete documentation for beta testing the LockItIn app, including philosophy, phases, recruitment, feedback collection, bug reporting, success metrics, and sprint-by-sprint timeline.

**Last Updated:** December 1, 2025

---

## Table of Contents

1. [Beta Testing Overview & Philosophy](#beta-testing-overview--philosophy)
2. [Testing Phases](#testing-phases)
3. [Tester Recruitment Strategy](#tester-recruitment-strategy)
4. [Testing Rules & Guidelines](#testing-rules--guidelines)
5. [Feedback Collection Methods](#feedback-collection-methods)
6. [Bug Reporting Process](#bug-reporting-process)
7. [Success Metrics & Checkpoints](#success-metrics--checkpoints)
8. [Sprint-by-Sprint Timeline](#sprint-by-sprint-timeline)
9. [Phase 1: Alpha Testing (Feb 20 - Mar 5)](#phase-1-alpha-testing-feb-20---mar-5)
10. [Phase 2: Beta Testing (Mar 6 - Mar 19)](#phase-2-beta-testing-mar-6---mar-19)
11. [Phase 3: Public Beta & Pre-Launch (Mar 20 - Apr 2)](#phase-3-public-beta--pre-launch-mar-20---apr-2)
12. [Survey & Question Templates](#survey--question-templates)

---

## Beta Testing Overview & Philosophy

### Core Principles

**Your friend group is gold.** They're invested, they'll give honest feedback, and they're the exact use case you're solving for. Don't waste this by asking vague questions like "what do you think?"

The beta testing process is structured in three waves, each with a specific purpose:
- **Alpha:** Find breaking bugs, validate core flows
- **Beta 1:** Real-world group dynamics, extended network testing
- **Beta 2:** Onboarding with no hand-holding, scale testing, launch readiness

### Timeline Overview

| Timeline | Phase | Dates | Duration | Focus |
|----------|-------|-------|----------|-------|
| **Phase 2** | Alpha | Feb 20 - Mar 5 | 2 weeks | Core bugs, basic flows |
| | Beta 1 | Late Feb - Early Mar | 2-3 weeks | Real usage, group dynamics |
| | Beta 2 | Mar 6 - Mar 19 | 2-3 weeks | Onboarding, scale, launch readiness |
| **Phase 3** | Public Launch Prep | Mar 20 - Apr 2 | 2 weeks | Final polish, App Store submission |

---

## Testing Phases

### Phase Summary Table

| Phase | When | Who | Size | Focus | Duration |
|-------|------|-----|------|-------|----------|
| **Alpha** | Late Feb | Close friends | 5-10 | Does it work? Core bugs, basic UX | 1-2 weeks |
| **Beta 1** | Early March | Friends of friends | 15-25 | Real-world usage, group dynamics | 2-3 weeks |
| **Beta 2** | Late March | Waitlist strangers | 50-100 | Onboarding, scale, launch readiness | 2 weeks |

---

## Tester Recruitment Strategy

### Phase 1: Alpha Recruitment (5-10 Testers)

**Target:** Your closest friends who will actually use it and tell you when something sucks

**Recruitment Method:**
- Personal invitation via text/phone call
- High-touch onboarding
- Emphasize this is early-stage and will have bugs
- Offer exclusive early access + lifetime premium

**Onboarding:**
- Create a dedicated Slack/Discord channel or group chat
- Send TestFlight invite link
- Send welcome message with what to test and how to report feedback
- Schedule weekly 15-minute sync calls

**Incentives:**
- Free premium for 1 year
- Exclusive "founding member" badge
- Public credit on launch day

---

### Phase 2: Beta 1 Recruitment (15-25 Testers)

**Target:** Your alpha testers' friends + personal network

**Recruitment Methods:**
- Ask your alpha testers to invite 2-3 of their friends each
- Personal DMs to friends who aren't in alpha
- LinkedIn/Twitter posts about beta testing

**Onboarding:**
- Same TestFlight process as alpha
- Less hand-holding than alpha
- Still accessible via group chat for questions

**Incentives:**
- Free premium for 1 year
- Mention in launch announcement
- First access to new features

---

### Phase 3: Beta 2 Recruitment (50-100 Testers)

**Target:** General public from waitlist + beta communities

**Recruitment Methods:**
- Post on Product Hunt (as "Coming Soon")
- Post on r/SideProject, r/EntrepreneurRideAlong, r/iOSBeta
- Post on r/productivity
- Share on Twitter/LinkedIn
- Add to beta.family, betabound.com
- Create landing page for waitlist signups

**Onboarding:**
- Automated TestFlight invite emails
- In-app tutorial for first-time setup
- Support email for questions
- Minimal hand-holding (this is intentional - test onboarding clarity)

**Incentives:**
- Free premium for 1 year
- Entry into product feature naming contest
- Exclusive launch day swag (if budget allows)

---

## Testing Rules & Guidelines

### What Alpha Testers Should Do

**Must Test:**
- Sign up and authentication
- Apple Calendar sync (does it sync correctly?)
- Create a personal event
- Create a group
- Invite friends to group
- Create an event proposal
- Vote on event proposal
- Receive and check notifications
- Event confirmation flow

**Should Report:**
- Any crashes or freezes
- Unexpected behavior
- Confusing UI flows
- Missing features you expected
- Performance issues (slow to load, etc.)
- Notification timing/content issues

**Should NOT Do:**
- Share outside their immediate circle without permission
- Post screenshots on public social media
- Stress test the server (we'll do that later)
- Test features not in the core flows yet

---

### What Beta 1 Testers Should Do

**Must Test:**
- Everything in Alpha (with fresh perspective)
- Invite flow (do the links work? Do people actually join?)
- Multiple groups (create more than one group)
- Notifications (do they actually get them?)
- Privacy controls (test shadow calendar)
- Use the app for 1-2 weeks to build habits

**Should Report:**
- All bug types (same as Alpha)
- Notification timing issues
- Group coordination confusion
- Features that feel missing
- Where they get stuck in onboarding

**Should NOT Do:**
- Same restrictions as Alpha
- Invite people outside agreed-upon network

---

### What Beta 2 Testers Should Do

**Must Test:**
- Complete onboarding without guidance
- Understand what the app does from first impression
- Create or join a group
- Use the app for 1-2 weeks
- Complete feedback survey at end

**Should Report:**
- Critical bugs using in-app feedback button
- Places where onboarding was unclear
- Where they got stuck
- Why they didn't complete actions

**Should NOT Do:**
- Same restrictions as previous phases
- Contact developer directly unless critical issue

---

## Feedback Collection Methods

### Recommended Approach by Phase

| Method | Alpha | Beta 1 | Beta 2 | Best For |
|--------|-------|--------|--------|----------|
| **Group chat** | Primary | Secondary | N/A | Fast updates, casual tone |
| **Voice memos** | Good | Optional | N/A | Rich detail, low effort |
| **Weekly calls** | Primary | N/A | N/A | Deep insights |
| **Surveys** | End of phase | End of phase | End of phase | Structured feedback |
| **In-app feedback** | N/A | Optional | Primary | Context capture |
| **1:1 calls** | Optional | Optional | N/A | Key testers only |

### Detailed Methods

#### Group Chat (Alpha & Beta 1)
- Create dedicated Slack/Discord channel
- Encourage real-time feedback
- Share daily or weekly summaries
- Easy for testers to share bugs immediately

**Pros:** Fast, casual, easy to clarify
**Cons:** Unstructured, things get lost

#### Voice Memos (Alpha)
- Ask testers to record quick voice memos
- Share via voice notes in group chat
- Transcribe key insights
- Rich detail with low effort from tester

**Pros:** Rich detail, natural language, low barrier
**Cons:** Hard to organize, need transcription

#### Weekly Calls (Alpha)
- 15-minute sync calls with each tester or group
- Ask open-ended questions
- Take notes on insights
- Build relationship

**Pros:** Deep insights, real conversation
**Cons:** Time consuming

#### Surveys (All Phases)
- Google Form or Typeform
- Send at end of each phase
- Mix of multiple choice and open-ended
- Structured for easy analysis

**Pros:** Structured, comparable, scalable
**Cons:** Lower response rate, people rush answers

#### In-App Feedback Button (Beta 2)
- Simple "Send Feedback" button in settings
- Captures context (which screen, what were they doing?)
- Routes to email or form
- Low friction for testers

**Pros:** Context-aware, low friction
**Cons:** Requires building UI

---

## Bug Reporting Process

### Bug Report Template

Make it easy for testers to report bugs. Pin this in your feedback channel or create a form:

```
**What happened:**
[Description of what you saw]

**What I expected:**
[Description of what should have happened]

**Steps to reproduce:**
1. [First step]
2. [Second step]
3. [Third step]

**Screenshot:**
[Attach if possible]

**Device:**
[iPhone model, iOS version]

**Severity:**
[ ] Critical (app crashes)
[ ] High (core feature broken)
[ ] Medium (workaround exists)
[ ] Low (cosmetic or nice-to-have)
```

### Bug Triage Process

**Daily (Alpha & Beta 1):**
1. Check feedback channel first thing
2. Sort by severity
3. Critical bugs: Fix immediately, deploy new build
4. High bugs: Fix by end of day if possible
5. Medium/Low bugs: Batch into weekly update

**Weekly (Beta 2):**
1. Collect all feedback
2. Categorize by issue type
3. Prioritize top 10 issues
4. Deploy weekly build with fixes

### Severity Levels

| Severity | Examples | Response Time |
|----------|----------|----------------|
| **Critical** | App crashes, login broken, can't create events | Same day |
| **High** | Feature completely non-functional, major UI break | Within 24 hours |
| **Medium** | Feature works but with issues, confusing UX | By end of week |
| **Low** | Typos, cosmetic issues, minor design tweaks | As time allows |

---

## Success Metrics & Checkpoints

### Overall Success Criteria

**Phase 2 Success (by April 2):**
- 100+ beta testers across all phases
- 50+ daily active users during Beta 2
- 40%+ Day-7 retention
- 4.0+ star rating from tester feedback
- 5+ testimonials/reviews for launch
- Zero critical bugs in final week

**Detailed Metrics by Phase:**

### Alpha Phase Success

| Metric | Target | Why It Matters |
|--------|--------|----------------|
| Core flows complete without crashing | 100% | Validates MVP is stable |
| Friends understand app purpose | 80%+ | Shows value is clear |
| At least 1 real event planned | Yes | Proves concept works |
| No loss of friend relationships | Yes | Haven't broken anything important |
| Initial feature feedback | Collected | Know what to polish |

### Beta 1 Success

| Metric | Target | Why It Matters |
|--------|--------|----------------|
| Invite conversion rate | >50% | People actually want to use it |
| Real events planned | 3+ across test groups | Concept scales to strangers |
| Users open app multiple times per week | 80%+ | Showing habit-forming potential |
| Retention after Day 3 | >60% | Not just novelty |
| Clear signal on confusing features | Identified | Know what to improve |

### Beta 2 Success

| Metric | Target | Why It Matters |
|--------|--------|----------------|
| Complete onboarding without guidance | 70%+ | App is self-explanatory |
| Understand purpose from first impression | 70%+ | Value prop is clear |
| Create or join a group | 50%+ | Core action is discoverable |
| Day-7 retention | 40%+ | Healthy retention for pre-launch |
| App Store readiness | Yes | Safe to submit |
| Survey response rate | >50% | Good feedback signal |

### Critical Checkpoints

**Checkpoint 5 (Mar 19 - Before App Store Submission):**
- Beta testers love it (4+ star average)?
- Retention >40% after Day 7?
- Zero critical bugs in last week?
- If no to any: Delay launch, polish more

---

## Sprint-by-Sprint Timeline

### High-Level Timeline

```
PHASE 2: BETA TESTING & ITERATION
Feb 20 - Apr 2 (6 weeks)

├─ SPRINT 5: Internal Beta (Feb 20 - Mar 5, 2 weeks)
│  ├─ TestFlight setup
│  ├─ Wave 1: 10 close friends
│  └─ First iteration based on feedback
│
├─ SPRINT 6: Public Beta & Polish (Mar 6 - Mar 19, 2 weeks)
│  ├─ Wave 2: 100+ from waitlist
│  ├─ Feature freeze (no new features)
│  └─ Polish and stabilize
│
└─ SPRINT 7: Pre-Launch (Mar 20 - Apr 2, 2 weeks)
   ├─ App Store submission
   ├─ Launch preparation
   └─ Final testing & fixes
```

---

## Phase 1: Alpha Testing (Feb 20 - Mar 5)

### Week 9: TestFlight Setup & Wave 1 Recruitment (Feb 20 - Feb 26)

#### Day 57 (Feb 20): TestFlight Setup
- Create App Store Connect listing
- Upload first build to TestFlight
- Configure beta testing info (description, build notes, etc.)
- Test internal installation (install on your own device)
- **Target:** TestFlight infrastructure working

#### Day 58 (Feb 21): Recruit Wave 1 (10 People)
- Invite your closest friend group
- Invite 1-2 other friend groups you trust
- Send them TestFlight invite links
- Create feedback Google Form with initial questions
- Set expectations: "This is early-stage, will have bugs"
- **Target:** 10 testers successfully installed app

#### Days 59-63 (Feb 22-26): Daily Support & Monitoring
- **Daily routine:**
  - Check for crash reports in TestFlight
  - Review feedback form submissions
  - Fix critical bugs immediately
  - Answer questions in group chat
  - Track metrics: DAU (daily active users), events created, proposals made
- **Goal:** 5+ active users daily
- **Cadence:** Deploy new build if critical bugs found

#### Weekend (Feb 29 - Mar 2): First Iteration
- Compile all feedback from Week 9
- Prioritize top 10 issues (bugs + UX improvements)
- Fix bugs
- Make UX improvements based on feedback
- Deploy build #2 to TestFlight
- **Target:** Improved build showing you listen to feedback

### Week 10: Wave 2 Recruitment & Continued Testing (Feb 27 - Mar 5)

#### Day 64 (Feb 27): Recruit Wave 2 (30 People Total)
- Ask your Wave 1 testers to invite 2-3 of their friends each
- Post in relevant communities:
  - r/iOSBeta
  - r/productivity
  - Personal Twitter/LinkedIn
- Offer incentive: "Free premium for 1 year"
- **Target:** 30 beta testers total

#### Days 65-69 (Feb 28 - Mar 4): Monitor & Fix
- Watch analytics closely
- Fix bugs reported by new testers
- Improve unclear UX flows
- Add minor features if frequently requested
- Deploy daily builds if needed
- **Target:** Smooth experience for all testers

#### Day 70 (Mar 5): Data Analysis & Planning
- Analyze usage patterns:
  - What features get used most?
  - Where do users drop off?
  - What flows are confusing?
- Survey testers directly about experience
- Create prioritized improvement list for next sprint
- **Target:** Clear roadmap for polish phase

---

## Phase 2: Beta Testing (Mar 6 - Mar 19)

### Week 11: Public Beta Launch (Mar 6 - Mar 12)

#### Day 71 (Mar 6): Public Beta Launch - Wave 3 (100+ Testers)
- Open TestFlight to public link
- Post on Product Hunt (as "Coming Soon" link)
- Post on communities:
  - r/SideProject
  - r/EntrepreneurRideAlong
  - r/iOSBeta
- Create one-page landing page
- Add to beta directories: beta.family, betabound.com
- **Target:** 100+ beta tester signups

#### Days 72-76 (Mar 7-11): Support & Polish Phase
- Triage feedback daily (prioritize by theme)
- Fix bugs as they're reported
- Improve most complained-about UX issues
- Add "Report Bug" button in settings (in-app feedback)
- Deploy weekly builds with improvements
- **Target:** 50+ active daily users

#### Day 77 (Mar 12): Feature Freeze ❄️
- NO new features from this point forward
- Only bug fixes and polish
- Focus entirely on stability
- Prepare for App Store submission
- **Target:** Locked feature set, stable app

### Week 12: Final Polish & App Store Prep (Mar 13 - Mar 19)

#### Days 78-80 (Mar 13-15): Final Polish
- UI tweaks based on feedback
- Performance optimization (fast app launch, smooth scrolling)
- Accessibility improvements (VoiceOver testing)
- Localization prep (if planning international launch)
- **Target:** Production-ready app

#### Days 81-82 (Mar 16-17): App Store Assets
- Take beautiful screenshots for all device sizes:
  - iPhone 16 Pro Max
  - iPhone 16
  - iPhone SE
- Write App Store description (keyword-optimized)
- Record App Preview video (30 seconds, optional but recommended)
- Get 10 beta testers to pre-write App Store reviews
- **Target:** App Store assets ready

#### Days 83-84 (Mar 18-19): Legal & Compliance
- Write Privacy Policy (template: Termly, iubenda)
- Write Terms of Service
- GDPR compliance check
- Set up support email address
- Create help documentation / FAQ
- **Target:** Legal compliance complete

---

## Phase 3: Public Beta & Pre-Launch (Mar 20 - Apr 2)

### Week 13: App Store Submission (Mar 20 - Mar 26)

#### Day 85 (Mar 20): App Store Submission
- Create final build
- Test one more time on every device
- Submit for App Store Review
- Expected review time: 24-48 hours
- **Target:** Submitted to Apple

#### Days 86-87 (Mar 21-22): Launch Preparation
- Set up analytics (Mixpanel or PostHog)
- Prepare launch announcements:
  - Twitter thread
  - LinkedIn post
  - Product Hunt submission
- Create press kit (1-pager about the app)
- Line up 20+ beta testers for Day 1 reviews
- **Target:** Launch materials ready

#### Day 88 (Mar 23): Hopeful Approval!
- **If approved:** Set release date (April 1)
- **If rejected:** Fix issues immediately, resubmit same day
- Send "We're launching!" message to beta testers
- **Target:** App approved and scheduled

#### Days 89-91 (Mar 24-26): Marketing Ramp-Up
- Schedule social media posts for launch day
- Reach out to micro-influencers in planning/calendar space
- Post in niche communities (with permission)
- Prepare launch day schedule/checklist
- **Target:** Buzz and awareness building

### Week 14: Final Testing & Launch Day (Mar 27 - Apr 2)

#### Days 92-97 (Mar 27-31): Final Testing
- Test payment flow thoroughly (Stripe integration)
- Test on every device you can borrow/access
- Test in low connectivity scenarios (airplane mode, 3G)
- Run through every user flow end-to-end
- Have friends do complete walkthroughs
- **Target:** Zero critical bugs, payment works

#### Day 98 (Apr 1): LAUNCH DAY!
- 8:00 AM: App goes live on App Store
- 8:15 AM: Post on Product Hunt
- 9:00 AM: Twitter announcement
- 10:00 AM: LinkedIn post
- 12:00 PM: Reddit posts (relevant communities)
- All day: Respond to comments/questions
- Evening: Thank beta testers publicly
- **Target:** Top 5 on Product Hunt

#### Day 99 (Apr 2): Post-Launch Monitoring
- Monitor crash reports in Xcode Organizer
- Fix any critical bugs immediately
- Respond to App Store reviews
- Thank everyone who shared/reviewed
- Analyze Day 1 metrics (downloads, retention)
- **Target:** Smooth launch, no fires

---

## Survey & Question Templates

### Phase 1 (Alpha) - Questions

Ask these to your 5-10 close friends after 1-2 weeks of testing:

| Area | Questions | Why It Matters |
|------|-----------|----------------|
| **First Impression** | "What did you think this app does when you first opened it?" | Validates value prop clarity |
| **Onboarding** | "Was anything confusing during signup or first use?" | Identifies onboarding friction |
| **Core Action** | "Create a real event proposal for this weekend. What was frustrating?" | Tests core workflow |
| **Bugs** | "Did anything break, freeze, or look wrong?" | Catches critical bugs |
| **Missing** | "What did you expect to be able to do but couldn't?" | Identifies feature gaps |
| **Overall** | "Would your friend group actually use this?" | Validates market fit |

#### Collection Method
- **Primary:** Weekly 15-minute calls or voice memos
- **Secondary:** Dedicated group chat for real-time feedback
- **Structured:** Email survey at end of week

#### Success Criteria (Alpha)
- Core flows complete without crashing
- Friends understand what app does
- At least 1 real event planned through app
- Clear bugs identified and logged

---

### Phase 2 (Beta 1) - Questions

Ask these to your 15-25 extended network testers after 2-3 weeks:

| Area | Questions | Why It Matters |
|------|-----------|----------------|
| **Invite Experience** | "How did it feel to receive an invite? Was it clear what to do?" | Tests viral loop |
| **Daily Usage** | "How often did you open the app this week? Why or why not?" | Gauges habit formation |
| **Notifications** | "Were notifications helpful or annoying? What did you miss?" | Validates notification strategy |
| **Group Dynamics** | "Did your group actually plan something? What helped or blocked that?" | Tests real-world usage |
| **Comparison** | "How does this compare to how you normally plan hangouts?" | Gauges competitive advantage |
| **Premium** | "Would you pay $3.99/month for this? Why or why not?" | Validates pricing |
| **Retention** | "Will you keep using this? What would make you stop?" | Predicts churn risk |

#### Collection Method
- **Primary:** Dedicated group chat + weekly form submission
- **Secondary:** End-of-phase survey
- **Depth:** Optional 1:1 calls with power users

#### Success Criteria (Beta 1)
- Invite conversion rate >50%
- 3+ real events planned across test groups
- Users opening app 3-5x per week
- Clear signal on what's confusing for new users
- Testimonials for App Store launch

---

### Phase 3 (Beta 2) - Questions

Ask these to your 50-100 public beta testers after 2 weeks:

| Area | Questions | Why It Matters |
|------|-----------|----------------|
| **Onboarding** | "Rate the tutorial/onboarding 1-5. What would you change?" | Validates onboarding clarity |
| **Value Clarity** | "In one sentence, what does LockItIn do?" | Checks value prop understanding |
| **Activation** | "Did you create or join a group? If not, why?" | Identifies activation barriers |
| **Retention** | "Will you keep using this? What would make you stop?" | Predicts retention rate |
| **Bugs** | "Did you encounter any bugs or crashes?" | Uses standard bug report form |
| **Feature Requests** | "What's one feature you wish existed?" | Captures product direction |
| **Recommendation** | "Would you recommend this to a friend? Why or why not?" | Net Promoter Score proxy |

#### Collection Method
- **Primary:** In-app feedback button (simple form)
- **Secondary:** Short survey after 1 week of use
- **Depth:** Optional interviews with power users
- **Incentive:** Entry into product naming contest

#### Success Criteria (Beta 2)
- 70%+ complete onboarding without guidance
- 50%+ create or join a group
- App Store readiness confirmed
- 40%+ Day-7 retention
- 4.0+ star rating from testers
- 5+ written testimonials for launch

---

### Email Templates

#### Alpha Tester Welcome Email

```
Subject: You're in! LockItIn Alpha Access

Hi [Name],

You're now in the alpha testing group for LockItIn. This is EARLY-stage software—
it will have bugs, things will break, and that's ok. That's why we need you.

Here's what we need from you:
1. Install the app from TestFlight (link: [LINK])
2. Create a real event proposal this week
3. Tell us what breaks, confuses, or surprises you
4. Join our feedback channel: [SLACK/DISCORD LINK]

What to focus on:
- Does signup work?
- Can you find friends and create a group?
- Can you create an event proposal?
- Can you vote and see results?

How to report bugs:
- Screenshot + description in the feedback channel
- Or use this template: [BUG REPORT TEMPLATE]

We'll jump on critical bugs same day. Other feedback we'll iterate on weekly.

Weekly call: [TIME/LINK] if you want to chat live.

Thanks for being early believers in this.

[Your Name]
```

#### Beta 1 Tester Welcome Email

```
Subject: Beta Access: LockItIn (Coming Soon)

Hi [Name],

[Your Alpha Tester] invited you to test LockItIn—an app for coordinating events
with friends without the 30-message thread.

Install from TestFlight: [LINK]

This is still beta (features will change, bugs exist), but we're looking for
real feedback on:
- Is onboarding clear?
- Do you understand what the app does?
- Would your friend group actually use it?

Feedback: Use the button in-app or reply to this email.
We're moving fast and responding to feedback daily.

Try it for a week and let us know what you think.

[Your Name]
```

#### Beta 2 Tester Welcome Email

```
Subject: Test LockItIn Beta on TestFlight

Hi,

Thanks for signing up to beta test LockItIn. Install here: [TESTFLIGHT LINK]

One quick request: As you use it, if anything is confusing or breaks, hit the
feedback button and let us know. We ship improvements every few days.

We're launching on April 1 and your feedback helps us ship something great.

Thanks,
[Your Name]
```

---

### Sample Survey Forms

#### Alpha Phase Survey (Google Form)

```
LockItIn Alpha Feedback Survey

1. First Impression (Open-ended)
   What did you think the app does when you first opened it?

2. Onboarding (Multiple choice + open)
   - Very clear
   - Mostly clear
   - Confusing - because: [open]

3. Core Flows (Open-ended)
   What was frustrating about creating an event proposal?

4. Bugs (Open-ended)
   Did anything crash, freeze, or look broken?

5. Missing Features (Open-ended)
   What did you expect to be able to do but couldn't?

6. Overall Assessment (1-5 scale)
   Would your friend group actually use this?
   1 = No way, 5 = Absolutely

7. Testimonial (Open-ended)
   Any quote I can use in marketing? (optional)
```

#### Beta 2 Phase Survey (Google Form)

```
LockItIn Beta Testing Feedback

1. Onboarding (1-5 scale)
   How clear was the tutorial?
   1 = Very confusing, 5 = Perfect

2. Value Clarity (Open-ended)
   In one sentence, what does LockItIn do?

3. Activation (Yes/No + open)
   Did you create or join a group?
   If no, why not?

4. Usage (Multiple choice)
   How many times per week did you open the app?
   - Every day
   - 3-5 times
   - 1-2 times
   - Didn't really use it

5. Retention (Yes/No + open)
   Will you keep using this after launch?
   Why or why not?

6. Feature Request (Open-ended)
   What's one feature you wish existed?

7. Bugs (Open-ended)
   Did you encounter any bugs or crashes?

8. Recommendation (1-10 scale)
   How likely are you to recommend this to a friend?

9. Testimonial (Open-ended)
   Any quote I can use in the App Store?
```

---

## Key Takeaways

### Don't Ask These Questions

| Bad Question | Why | Better Version |
|--------------|-----|-----------------|
| "Do you like it?" | Yes/no, no insight | "What would you change?" |
| "Is it easy to use?" | Leading, they'll say yes | "Where did you get stuck?" |
| "Would you use this?" | Hypothetical, unreliable | "Did you plan a real event? Why/why not?" |
| "Any feedback?" | Too broad | "What frustrated you most?" |

### Testing Workflow

1. **Alpha (Feb 20 - Mar 5):** Small group, high touch, daily communication
2. **Beta 1 (Late Feb - Early Mar):** Extended friends, weekly check-ins
3. **Beta 2 (Mar 6 - Mar 19):** General public, in-app feedback, no hand-holding
4. **Pre-Launch (Mar 20 - Apr 2):** Final polish, App Store submission, launch prep

### Critical Success Metrics

| Phase | Metric | Target |
|-------|--------|--------|
| **Alpha** | Core flows work without crashing | 100% |
| **Beta 1** | Real events planned | 3+ groups |
| **Beta 2** | Day-7 retention | 40%+ |
| **All** | Star rating from testers | 4.0+ |

---

## Related Documentation

- [PHASE 2 BETA TESTING & ITERATION](NotionMD/DETAILED%20DEVELOPMENT%20TIMELINE%20&%20ROADMAP/PHASE%202%20BETA%20TESTING%20&%20ITERATION.md) - Detailed sprint-by-sprint breakdown
- [DETAILED DEVELOPMENT TIMELINE & ROADMAP](NotionMD/DETAILED%20DEVELOPMENT%20TIMELINE%20&%20ROADMAP.md) - Overall project timeline with checkpoints
- [Beta Testing.md](Beta%20Testing.md) - Original philosophy and feedback collection methods (references this file)

---

*Last updated: December 1, 2025*
*Consolidated from: Beta Testing.md + PHASE 2 BETA TESTING & ITERATION.md*

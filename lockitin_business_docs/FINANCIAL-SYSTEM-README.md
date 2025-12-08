# LockItIn Financial Tracking System
**Optimized for Solo Developers**

---

## What Changed (December 2025 Consolidation)

### DELETED (Redundant Files):
- ❌ `LockItIn-Financial-Tracker.csv` - 18-month projections (merged into Dashboard)
- ❌ `LockItIn-Budget-Template.csv` - Empty template with instructions (merged)
- ❌ `LockItIn-Accounting-Ledger.csv` - Transaction log (replaced with cleaner version)
- ❌ `LockItIn-Monthly-Summary.csv` - Monthly summaries (merged into Dashboard)
- ❌ `LockItIn-DIY-Accounting-System.csv` - 316 lines of instructions (moved to Tax Guide)

**Result:** 5 files → 3 files (40% reduction)
**Time saved:** ~45 min/month → ~15 min/month

---

## Your New System (3 Files Only)

### 1. LockItIn-Transaction-Log.csv
**Purpose:** Record every dollar in/out
**Update frequency:** Weekly (5 min)
**What to track:**
- Date, description, category, amount
- Whether it's income or expense
- If it's tax deductible
- Notes for context

**When to use:**
- Bought a software subscription? Log it.
- Got revenue from Stripe? Log it.
- Paid quarterly taxes? Log it.

**Example:**
```
Date,Description,Category,Amount,Type,Tax_Deductible
2026-04-01,App revenue Month 1,Revenue,17.46,Income,No
2026-04-01,Stripe fees,Payment Processing,-0.25,Expense,Yes
```

---

### 2. LockItIn-Monthly-Dashboard.csv
**Purpose:** High-level view of business health
**Update frequency:** Monthly (10 min)
**What it shows:**
- Monthly Active Users (MAU) and premium conversions
- Revenue after Apple's 30% cut
- All expenses (fixed + variable)
- Profit/loss for the month
- Cumulative cash position
- 30% tax reserve calculation

**When to use:**
- End of each month to see how you're doing
- Compare actual vs projected growth
- Decide if you can afford to upgrade Supabase or add marketing spend

**Key Metrics:**
- Break-even month: Jun 2026 (Month 3)
- Profitability month: Aug 2026 (Month 5)
- Year 1 net profit (after tax): ~$21,500

---

### 3. LockItIn-Tax-Planning-Guide.md
**Purpose:** Reference guide for tax obligations
**Update frequency:** Read once, reference as needed
**What it covers:**
- Quarterly estimated tax payment schedule
- What counts as a deductible expense
- How much to set aside (30% of profit)
- Section 179 deduction for Mac Mini
- When to hire a CPA
- Business structure decisions (sole prop → LLC → S-Corp)
- Year 1 tax estimate (~$7,400 total)

**When to use:**
- Before making a purchase (is this deductible?)
- Every quarter to calculate tax payments
- End of year for tax prep
- When deciding whether to hire a CPA

---

## Your Simple Routine

### Weekly (5 minutes)
- [ ] Update Transaction Log with any purchases or revenue
- [ ] Save receipts to organized folder

### Monthly (10 minutes - first week of month)
- [ ] Export Stripe revenue report
- [ ] Download Supabase/other service invoices
- [ ] Screenshot user metrics (MAU, premium count)
- [ ] Update Monthly Dashboard with actuals
- [ ] Calculate profit and move 30% to tax savings account

### Quarterly (30 minutes)
- [ ] Sum up quarterly profit from Dashboard
- [ ] Calculate estimated tax payment (30% of profit)
- [ ] Pay via IRS Direct Pay (irs.gov/payments)
- [ ] Save payment confirmation

### Annually (Hire a CPA)
- [ ] Gather all receipts and revenue reports (February)
- [ ] Meet with CPA to file taxes (March)
- [ ] File by April 15

---

## Quick Start Guide

### Step 1: Set Up Tax Savings Account
Open a separate savings account labeled "LockItIn Tax Reserve"
- Every month, move 30% of profit here
- DO NOT TOUCH except for quarterly tax payments
- Example: Made $500 profit? Move $150 to tax savings immediately

### Step 2: Organize Digital Receipts
Create this folder structure:
```
LockItIn-Business/
├── 2025/
│   └── Receipts/
│       ├── Mac-Mini-Receipt.pdf
│       ├── Apple-Developer-2025.pdf
│       └── Domain-Receipt.pdf
├── 2026/
│   ├── Receipts/
│   │   ├── Q1/ (Jan-Mar)
│   │   ├── Q2/ (Apr-Jun)
│   │   ├── Q3/ (Jul-Sep)
│   │   └── Q4/ (Oct-Dec)
│   └── Revenue-Reports/
│       ├── Stripe/
│       └── Apple-Connect/
```

### Step 3: First Month Setup (April 2026)
1. Log initial investment expenses (Mac Mini, Apple Dev, Domain)
2. When first revenue hits, log it in Transaction Log
3. End of month, update Monthly Dashboard
4. Calculate profit × 30% and move to tax savings

---

## Key Financial Projections (Conservative)

### Month-by-Month Growth
- **Month 1 (Apr 2026):** 200 MAU, 5 premium, $17 net revenue
- **Month 3 (Jun 2026):** 1,000 MAU, 50 premium, $175 net revenue → BREAK-EVEN
- **Month 5 (Aug 2026):** 3,000 MAU, 210 premium, $678 net profit → PROFITABLE
- **Month 9 (Dec 2026):** 10,000 MAU, 1,100 premium, $3,598 net profit
- **Month 12 (Mar 2027):** 15,000 MAU, 1,500 premium, $5,040 net profit

### Year 1 Totals (Apr 2026 - Mar 2027)
- **Total Revenue (Net after Apple):** $31,962
- **Total Costs:** $1,252
- **Total Profit (Before Tax):** $30,710
- **Estimated Taxes:** $7,437
- **Net Profit (After Tax):** $21,496

### Key Assumptions
- Conversion rate: 2.5% → 10% (gradual increase)
- Apple commission: 30% Year 1
- Supabase: Free tier → Pro ($25) → Team ($75) as users scale
- Email marketing: Start Month 5 ($20/month)
- Analytics: Start Month 7 ($20/month)
- No paid advertising (organic growth only)

---

## When to Upgrade Your Financial System

### You're Fine with This System If:
- Revenue < $60,000/year
- Solo developer, no employees
- Spending <15 min/month on bookkeeping
- Simple expense categories

### Consider Real Accounting Software When:
- Revenue > $60,000/year consistently
- You hire contractors (need to issue 1099 forms)
- You want automated bank sync
- You're spending >2 hours/month on bookkeeping
- You need formal financial statements for investors

### Recommended Upgrades (in order):
1. **Wave (Free):** Simple invoicing + expense tracking, bank sync
2. **QuickBooks Self-Employed ($15/month):** Auto-categorization, mileage tracking, TurboTax integration
3. **FreshBooks ($17/month):** If you need client invoicing + proposals
4. **Hire Bookkeeper ($100-300/month):** When revenue >$100K and you want to focus on product

---

## Common Questions

### Q: Do I really need to set aside 30% for taxes?
**A:** Yes. Here's why:
- Self-employment tax: 15.3% (Social Security + Medicare)
- Federal income tax: ~12-22% (depends on your bracket)
- State tax: 0-10% (depends on state)
- Total: 25-40% (30% is a safe middle ground)

### Q: Can I deduct the full $699 Mac Mini cost in 2025?
**A:** Yes, using Section 179 deduction. OR you can depreciate it over 5 years ($140/year). Section 179 gives you a bigger upfront deduction. Talk to a CPA to decide.

### Q: Apple takes 30%, do I deduct that separately?
**A:** No. You only report NET revenue (after Apple's cut). User pays $4.99, Apple takes $1.50, you report $3.49 as income.

### Q: When should I hire a CPA?
**A:**
- **Definitely hire when:** Revenue >$50K, changing business structure, or facing an audit
- **Maybe hire when:** Revenue >$20K and you want tax optimization advice
- **Don't need yet when:** Revenue <$20K and you're comfortable with TurboTax Self-Employed

### Q: Should I form an LLC?
**A:**
- **Year 1 (2026):** No, stay sole proprietorship. Simple and free.
- **Year 2 (2027):** If revenue >$50K, consider LLC for liability protection ($50-300 to set up)
- **Year 3 (2028):** If revenue >$100K, consider S-Corp election (talk to CPA)

### Q: What if I don't hit these revenue projections?
**A:** These are CONSERVATIVE estimates. If you hit 50% of these numbers, you're still profitable by Month 6. The key is tracking actual vs projected so you can adjust.

---

## Red Flags to Watch For

### Financial Health Issues:
- Revenue declining month-over-month for 2+ months
- Expenses growing faster than revenue
- Not profitable by Month 6 (something's wrong with product-market fit)
- Running out of cash reserve

### Tax Compliance Issues:
- Not setting aside tax money (you'll owe thousands with no cash)
- Missing receipts (no receipt = no deduction in an audit)
- Not paying quarterly estimated taxes (IRS penalties add up)
- Mixing personal and business expenses (audit red flag)

### System Issues:
- Haven't updated Transaction Log in 2+ weeks
- Can't find a receipt from last month
- Don't know your current cash position
- Spending >30 min/month on bookkeeping (system too complex)

---

## Next Steps

### Before Launch (Dec 2025 - Mar 2026):
- [x] Set up financial tracking system (THIS!)
- [ ] Open business savings account for tax reserve
- [ ] Create digital receipt folder structure
- [ ] Log Mac Mini, Apple Developer, Domain purchases
- [ ] Read Tax Planning Guide thoroughly

### After Launch (Apr 2026+):
- [ ] Week 1: Export first revenue report, update Transaction Log
- [ ] End of Month 1: Update Monthly Dashboard, calculate tax reserve
- [ ] June 15: Pay first quarterly estimated tax (Q2)
- [ ] End of Month 3: Celebrate break-even!
- [ ] End of Month 5: Celebrate profitability!

### End of Year 1 (Feb-Apr 2027):
- [ ] Gather all receipts and revenue reports
- [ ] Consider hiring CPA if revenue >$50K
- [ ] File 2026 taxes by April 15, 2027

---

**Questions or Issues?**
- Review the Tax Planning Guide for detailed explanations
- Search IRS.gov for free publications (Pub 535, Pub 587)
- Ask in app developer communities (r/iOSProgramming, Indie Hackers)
- Hire a CPA if revenue exceeds $50K or complexity increases

**Good luck with the launch!**

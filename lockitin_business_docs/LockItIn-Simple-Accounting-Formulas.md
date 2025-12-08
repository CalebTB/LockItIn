# LockItIn Simple Accounting System - Google Sheets Setup

## Quick Setup (15 minutes)

### Step 1: Create Google Sheet with 4 tabs

1. **Transactions** - Log every transaction
2. **Monthly Summary** - Auto-calculated monthly totals
3. **Dashboard** - Visual overview
4. **Tax Planning** - Quarterly tax estimates

---

## Tab 1: TRANSACTIONS (Main log)

### Columns:
```
A: Date
B: ID (auto-number)
C: Type (Income/Expense)
D: Category (dropdown)
E: Description
F: Amount
G: Payment Method
H: Tax Deductible? (Y/N)
I: Receipt? (Y/N)
J: Notes
```

### Sample Data:
```
Date        | ID | Type    | Category     | Description            | Amount  | Method      | Deduct | Receipt | Notes
12/15/2025  | 1  | Expense | Software     | Apple Developer        | $99.00  | Credit Card | Y      | Y       | Annual
04/01/2026  | 2  | Income  | Subscriptions| Month 1 revenue        | $17.46  | Stripe      | N      | Y       | 5 users
04/01/2026  | 3  | Expense | Processing   | Stripe fees            | $0.25   | Stripe      | Y      | Y       | Transaction
```

### Formulas to add:

**Auto-increment ID (Cell B2):**
```
=IF(A2="","",COUNTA($B$1:B1))
```

**Category Dropdown (Cell D2):**
```
Create Data Validation:
- Subscriptions
- Equipment
- Software
- Hosting
- Processing
- Marketing
- Other
```

---

## Tab 2: MONTHLY SUMMARY

### Setup:

```
        A              B            C
1   Month/Year    Total Income   Total Expenses   Net Profit   Tax Reserve (30%)
2   Jan 2026      $0.00          $0.00            $0.00        $0.00
3   Feb 2026      $0.00          $0.00            $0.00        $0.00
```

### Formulas (for January 2026 - Row 2):

**Total Income (B2):**
```
=SUMIFS(Transactions!F:F, Transactions!C:C, "Income", Transactions!A:A, ">=1/1/2026", Transactions!A:A, "<=1/31/2026")
```

**Total Expenses (C2):**
```
=SUMIFS(Transactions!F:F, Transactions!C:C, "Expense", Transactions!A:A, ">=1/1/2026", Transactions!A:A, "<=1/31/2026")
```

**Net Profit (D2):**
```
=B2-C2
```

**Tax Reserve 30% (E2):**
```
=IF(D2>0, D2*0.3, 0)
```

**Cumulative Profit (F2):**
```
=SUM($D$2:D2)
```

---

## Tab 3: DASHBOARD (Visual overview)

### Key Metrics Display:

```
Current Month: [Formula: =TEXT(TODAY(),"MMMM YYYY")]

=== THIS MONTH ===
Income:         [Formula from Monthly Summary]
Expenses:       [Formula from Monthly Summary]
Profit:         [Formula from Monthly Summary]
Tax Reserve:    [Formula from Monthly Summary]

=== YEAR TO DATE ===
Total Income:   =SUM('Monthly Summary'!B:B)
Total Expenses: =SUM('Monthly Summary'!C:C)
Total Profit:   =SUM('Monthly Summary'!D:D)
Tax Set Aside:  =SUM('Monthly Summary'!E:E)

=== BUSINESS HEALTH ===
Months Profitable:     [Count months with profit > 0]
Average Monthly Profit: =AVERAGE('Monthly Summary'!D:D)
Profit Margin:         =(Total Income - Total Expenses) / Total Income
Break-even Month:      [First month profit > 0]
```

### Charts to add:

1. **Income vs Expenses by Month** (Line chart)
   - Data: Monthly Summary columns B & C

2. **Cumulative Profit** (Area chart)
   - Data: Monthly Summary column F

3. **Expense Breakdown** (Pie chart)
   - Data: SUMIF by category from Transactions

---

## Tab 4: TAX PLANNING

### Quarterly Summary:

```
        A                B              C             D              E
1   Quarter        Income         Expenses      Net Profit    Tax Due (30%)
2   Q1 2026 (Jan-Mar)  =SUM(Jan:Mar income)   =SUM(Jan:Mar expenses)   =B2-C2   =D2*0.30
3   Q2 2026 (Apr-Jun)
4   Q3 2026 (Jul-Sep)
5   Q4 2026 (Oct-Dec)
```

### Tax Payment Tracker:

```
Quarter | Due Date    | Amount Owed | Amount Paid | Balance | Status
Q1 2026 | Apr 15 2026 | [Calc]      | $0          | [Calc]  | Pending
Q2 2026 | Jun 15 2026 | [Calc]      | $0          | [Calc]  | Pending
Q3 2026 | Sep 15 2026 | [Calc]      | $0          | [Calc]  | Pending
Q4 2026 | Jan 15 2027 | [Calc]      | $0          | [Calc]  | Pending
```

---

## Advanced Formulas (Optional)

### Expense by Category Report:

```
Category          | Total        | % of Total
Equipment         | =SUMIF       | =B2/SUM($B$2:$B$10)
Software          | =SUMIF       | =B3/SUM($B$2:$B$10)
Hosting           | =SUMIF       | =B4/SUM($B$2:$B$10)
```

Formula for Equipment total:
```
=SUMIF(Transactions!D:D, "Equipment", Transactions!F:F)
```

### Running Balance:

Add to Transactions tab (Column K):
```
=IF(C2="Income", K1+F2, K1-F2)
```
(Assumes starting balance in K1)

### Profit Margin:

```
=IF(B2=0, 0, (B2-C2)/B2)
```

---

## Conditional Formatting Rules

### In Transactions tab:
- **Income rows**: Green background
- **Expense rows**: Light red background
- **Missing receipts (I column = N)**: Yellow warning

### In Monthly Summary:
- **Negative profit**: Red text
- **Positive profit**: Green text
- **Tax reserve**: Orange background

---

## Weekly Routine (5 minutes)

**Every Monday:**
1. Open Transactions tab
2. Add any transactions from last week
3. Check Dashboard for current status
4. Verify bank balance matches running total

**Month-end (15 minutes):**
1. Export revenue reports (Apple Connect, Stripe)
2. Add all transactions
3. Reconcile bank statement
4. Screenshot Dashboard
5. File receipts in Google Drive folder

**Quarterly (30 minutes):**
1. Review Tax Planning tab
2. Calculate estimated tax payment
3. Make payment on IRS website
4. Record payment in Transactions
5. Update Tax Payment Tracker

---

## Backup Strategy

1. **Google Sheets auto-saves** ✓
2. **Monthly export to CSV** (File → Download → CSV)
3. **Store CSV in Google Drive folder**: LockItIn-Business/Accounting-Backups/
4. **Quarterly full spreadsheet backup** (File → Make a copy)

---

## When to Review

### Daily (2 min):
- Nothing - focus on building!

### Weekly (5 min):
- Add transactions
- Quick dashboard glance

### Monthly (15 min):
- Full reconciliation
- Review profit/loss
- Adjust forecasts

### Quarterly (1 hour):
- Deep dive into metrics
- Calculate and pay estimated taxes
- Review business health
- Adjust strategy if needed

---

## Cost Comparison: DIY vs Software

### DIY (Google Sheets):
- **Cost**: $0/month
- **Time**: 30 min/month
- **Best for**: Revenue < $5K/month, simple business

### Wave (Free):
- **Cost**: $0/month
- **Time**: 15 min/month
- **Best for**: Want polished reports, bank connection

### QuickBooks Self-Employed:
- **Cost**: $15/month
- **Time**: 10 min/month
- **Best for**: Revenue > $5K/month, want automation

---

## The 80/20 Rule

**Focus on these 20% of tasks that give 80% of value:**

1. ✅ Log every transaction (2 min each)
2. ✅ Reconcile monthly (15 min)
3. ✅ Set aside 30% for taxes (automatic with formulas)
4. ✅ Keep receipts organized (1 min each)

**Don't stress about:**
- ❌ Perfect categorization
- ❌ Complex reports
- ❌ Daily tracking
- ❌ Forecasting accuracy

---

## Red Flags (When to upgrade)

🚩 Spending > 2 hours/month on bookkeeping
🚩 Revenue > $5K/month consistently
🚩 Missing transactions regularly
🚩 Tax season causes anxiety
🚩 Need investor-ready financials

**→ Time to use Wave or hire bookkeeper**

---

## Sample Folder Structure

```
Google Drive: LockItIn-Business/
├── Accounting/
│   └── LockItIn-Accounting-2026.gsheet
├── Receipts/
│   ├── 2025-Equipment/
│   ├── 2026-Q1/
│   ├── 2026-Q2/
│   ├── 2026-Q3/
│   └── 2026-Q4/
├── Revenue-Reports/
│   ├── Apple-Connect/
│   └── Stripe/
├── Bank-Statements/
│   └── 2026/
└── Tax-Documents/
    ├── Quarterly-Estimates/
    └── Annual-Returns/
```

---

## Quick Reference Card

**Add a transaction:**
1. Open Transactions tab
2. Add row: Date, Type, Category, Amount
3. Upload receipt to Drive
4. Done!

**Check profit this month:**
1. Open Dashboard
2. Look at "This Month" section
3. Done!

**Quarterly tax payment:**
1. Open Tax Planning tab
2. Check amount owed
3. Pay at irs.gov/payments
4. Record in Transactions
5. Done!

**That's it!**

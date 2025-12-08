# LockItIn Landing Page - Quick Reference

Fast answers to common tasks and questions.

---

## Common Tasks

### Update Headline Text

**File:** `E:\Claude\Shareless\Shareless-EverythingCalendar\lockitin_landing_page\components\Hero.tsx`

**Line:** ~50

```tsx
<h1 className="text-5xl sm:text-6xl lg:text-7xl font-bold mb-6">
  Stop the{' '}
  <span className="gradient-text">30-Message</span>
  <br />
  Planning Hell  {/* ← Change this */}
</h1>
```

---

### Update Features List

**File:** `E:\Claude\Shareless\Shareless-EverythingCalendar\lockitin_landing_page\components\Features.tsx`

**Line:** ~12

```tsx
const features = [
  {
    icon: "📅",
    title: "Apple Calendar Sync",  // ← Edit these
    description: "Seamlessly syncs with your iPhone calendar...",
    color: "from-blue-500 to-blue-600"
  },
  // Add more features here
]
```

---

### Change Testimonials

**File:** `E:\Claude\Shareless\Shareless-EverythingCalendar\lockitin_landing_page\components\SocialProof.tsx`

**Line:** ~12

```tsx
const testimonials = [
  {
    name: "Sarah Mitchell",  // ← Edit name
    role: "College Student",  // ← Edit role
    avatar: "bg-gradient-to-br from-pink-400 to-pink-600",
    text: "I used to waste an HOUR...",  // ← Edit testimonial
    rating: 5
  },
  // Add more testimonials
]
```

---

### Update Launch Date

**Search and replace:** "April 2026" → your new date

**Files to update:**
- `components/Hero.tsx` (line ~43)
- `components/Footer.tsx` (line ~137)
- `app/layout.tsx` (metadata description)

---

### Change Brand Colors

**File:** `E:\Claude\Shareless\Shareless-EverythingCalendar\lockitin_landing_page\tailwind.config.ts`

**Line:** ~15

```typescript
colors: {
  primary: {
    DEFAULT: '#007AFF',  // ← Change primary color
    dark: '#0051D5',     // ← Change dark variant
  },
  // ...
}
```

**After changing, restart dev server:**

```bash
npm run dev
```

---

### Add a New Section

**File:** `E:\Claude\Shareless\Shareless-EverythingCalendar\lockitin_landing_page\app\page.tsx`

**Line:** ~13

```tsx
export default function Home() {
  return (
    <main className="overflow-hidden">
      <Hero />
      <Problem />
      <Solution />
      <Features />
      <HowItWorks />
      <SocialProof />
      <Waitlist />
      <YourNewSection />  {/* ← Add here */}
      <Footer />
    </main>
  )
}
```

Then create `components/YourNewSection.tsx` following the pattern of other components.

---

### Configure Email Signup

**File:** `E:\Claude\Shareless\Shareless-EverythingCalendar\lockitin_landing_page\app\api\waitlist\route.ts`

**Replace the TODO section (line ~15) with your service:**

**Mailchimp:**
```typescript
import mailchimp from '@mailchimp/mailchimp_marketing'

mailchimp.setConfig({
  apiKey: process.env.MAILCHIMP_API_KEY,
  server: 'us1',
})

const response = await mailchimp.lists.addListMember(
  process.env.MAILCHIMP_LIST_ID!,
  {
    email_address: email,
    status: 'subscribed',
    merge_fields: { FNAME: name },
  }
)
```

**ConvertKit:**
```typescript
const response = await fetch(
  `https://api.convertkit.com/v3/forms/${process.env.CONVERTKIT_FORM_ID}/subscribe`,
  {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      api_key: process.env.CONVERTKIT_API_KEY,
      email,
      first_name: name,
    }),
  }
)
```

---

## File Locations

| What | Where |
|------|-------|
| **Headline** | `components/Hero.tsx` |
| **Problem section** | `components/Problem.tsx` |
| **Features** | `components/Features.tsx` |
| **Testimonials** | `components/SocialProof.tsx` |
| **Form** | `components/Waitlist.tsx` |
| **Footer links** | `components/Footer.tsx` |
| **Colors** | `tailwind.config.ts` |
| **Fonts** | `app/globals.css` |
| **SEO metadata** | `app/layout.tsx` |
| **Email API** | `app/api/waitlist/route.ts` |

---

## Common Commands

```bash
# Development
npm install          # Install dependencies
npm run dev          # Start dev server (localhost:3000)

# Production
npm run build        # Build for production
npm run start        # Run production server

# Deployment
git add .            # Stage changes
git commit -m "..."  # Commit changes
git push             # Push to GitHub (triggers Vercel deploy)
```

---

## Component Props

### Most components accept these for animations:

```tsx
// In components like Hero, Problem, etc.
const ref = useRef(null)
const isInView = useInView(ref, { once: true, margin: "-100px" })

<motion.div
  initial={{ opacity: 0, y: 30 }}
  animate={isInView ? { opacity: 1, y: 0 } : {}}
  transition={{ duration: 0.6 }}
>
  {/* Content */}
</motion.div>
```

---

## Styling Classes

```css
/* Primary button */
.btn-primary

/* Secondary button */
.btn-secondary

/* Card/container */
.card

/* Section wrapper */
.section-container

/* Gradient text */
.gradient-text

/* Feature icon */
.feature-icon
```

**Defined in:** `app/globals.css`

---

## Responsive Breakpoints

```css
/* Tailwind breakpoints */
sm:   640px  /* Small tablets and up */
md:   768px  /* Tablets and up */
lg:   1024px /* Laptops and up */
xl:   1280px /* Desktops and up */
2xl:  1536px /* Large desktops */

/* Usage example */
className="text-lg md:text-xl lg:text-2xl"
```

---

## Troubleshooting

### Problem: Changes not showing

**Solution:**
```bash
# Stop dev server (Ctrl+C)
rm -rf .next
npm run dev
```

### Problem: Build fails

**Solution:**
```bash
# Check for errors
npm run build

# If error is in components, check:
# - All imports are correct
# - No typos in component names
# - All files saved
```

### Problem: Form not submitting

**Solution:**
1. Check browser console for errors
2. Verify API route exists: `app/api/waitlist/route.ts`
3. Test API directly: `curl -X POST http://localhost:3000/api/waitlist -H "Content-Type: application/json" -d '{"email":"test@example.com","name":"Test"}'`

### Problem: Animations not working

**Solution:**
```bash
# Ensure Framer Motion is installed
npm install framer-motion

# Restart dev server
npm run dev
```

### Problem: Styles not applying

**Solution:**
```bash
# Rebuild Tailwind
npm run dev

# Check tailwind.config.ts includes all files:
content: [
  './pages/**/*.{js,ts,jsx,tsx,mdx}',
  './components/**/*.{js,ts,jsx,tsx,mdx}',
  './app/**/*.{js,ts,jsx,tsx,mdx}',
],
```

---

## Environment Variables

**File:** `.env.local` (create this file)

```env
# API
NEXT_PUBLIC_API_URL=https://api.lockitin.app

# Analytics
NEXT_PUBLIC_GA_MEASUREMENT_ID=G-XXXXXXXXXX

# Email service
MAILCHIMP_API_KEY=your_key_here
MAILCHIMP_LIST_ID=your_list_id_here
```

**After adding variables:**
```bash
# Restart dev server
# Ctrl+C then npm run dev
```

---

## Testing Checklist

Before deploying:

- [ ] All text proofread
- [ ] All links work
- [ ] Form submits successfully
- [ ] Mobile responsive (test on real device)
- [ ] Dark mode looks good
- [ ] Images load correctly
- [ ] No console errors
- [ ] Build succeeds (`npm run build`)

---

## Performance Tips

### Optimize Images

```tsx
import Image from 'next/image'

// Before
<img src="/screenshot.png" alt="App" />

// After
<Image
  src="/screenshot.png"
  alt="App"
  width={1200}
  height={800}
  quality={90}
  priority={true} // For above-fold images
/>
```

### Lazy Load Components

```tsx
import dynamic from 'next/dynamic'

const Features = dynamic(() => import('@/components/Features'))
const SocialProof = dynamic(() => import('@/components/SocialProof'))
```

### Check Performance

```bash
# Build and analyze
npm run build

# Run Lighthouse
# Open Chrome DevTools > Lighthouse > Run
```

---

## Need More Help?

- **Full Documentation:** See `README.md`
- **Deployment:** See `DEPLOYMENT_GUIDE.md`
- **Project Overview:** See `PROJECT_SUMMARY.md`
- **Next.js Docs:** https://nextjs.org/docs
- **Tailwind Docs:** https://tailwindcss.com/docs
- **Framer Motion:** https://www.framer.com/motion/

---

## Quick Wins for Conversion

1. **Add scarcity:** "Only 100 spots left in early access"
2. **Show proof:** Screenshot of testimonials from beta users
3. **Create urgency:** "Launch price available until April 1"
4. **Reduce friction:** One-field email form (remove name field)
5. **Add exit intent:** Popup with offer when user tries to leave

---

*This is your cheat sheet. Bookmark it!*

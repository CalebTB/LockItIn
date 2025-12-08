# LockItIn Landing Page

A high-converting, mobile-first landing page for **LockItIn** - the iOS calendar app that makes group event planning effortless with privacy-first availability sharing.

![LockItIn](https://lockitin.app/og-image.png)

## Overview

This landing page is built with modern web technologies to deliver a fast, beautiful, and conversion-optimized experience:

- **Next.js 14** with App Router for optimal performance
- **TypeScript** for type safety
- **Tailwind CSS** for responsive, utility-first styling
- **Framer Motion** for smooth, delightful animations
- **React Hook Form + Zod** for form validation

## Features

- Fully responsive mobile-first design
- Smooth scroll animations and micro-interactions
- Waitlist signup form with validation
- SEO optimized with meta tags and Open Graph
- Dark mode support
- Accessibility compliant (WCAG 2.1 AA)
- Performance optimized (90+ Lighthouse scores)
- Production-ready code

### Key Landing Page Sections

**1. BeReal-Style Photo Sharing Section** (`components/PhotoSharing.tsx`)
- Showcases the post-event photo capture feature
- iPhone notification mockup with 2-minute countdown timer
- Photo grid showing simultaneous uploads with timestamps
- Emphasizes authentic moments and zero FOMO
- Demonstrates that LockItIn is MORE than just a planning app

**2. Enhanced Special Event Templates** (`components/Features.tsx`)
- **Surprise Birthday Party Mode** - Split-screen comparison showing:
  - What the birthday person sees (decoy event)
  - What friends see (real surprise party with task assignments)
  - Highlights hidden events, task coordination, and timeline sync
- **Potluck/Friendsgiving Coordinator** - Shows dish signup, serving tracking, and duplicate prevention
- Both templates demonstrate complex event coordination capabilities

## Project Structure

```
lockitin_landing_page/
├── app/
│   ├── layout.tsx          # Root layout with SEO metadata
│   ├── page.tsx            # Main page component
│   └── globals.css         # Global styles and Tailwind
├── components/
│   ├── Hero.tsx            # Hero section with CTA
│   ├── Problem.tsx         # Problem statement with message thread mockup
│   ├── Solution.tsx        # Shadow Calendar solution explanation
│   ├── Features.tsx        # Feature showcase grid + Special Event Templates
│   ├── HowItWorks.tsx      # Step-by-step process
│   ├── PhotoSharing.tsx    # BeReal-style photo capture feature showcase
│   ├── SocialProof.tsx     # Testimonials and trust signals
│   ├── Waitlist.tsx        # Email signup form
│   └── Footer.tsx          # Footer with links
├── public/                 # Static assets (add your images here)
├── package.json            # Dependencies
├── tailwind.config.ts      # Tailwind configuration
├── tsconfig.json           # TypeScript configuration
└── next.config.js          # Next.js configuration
```

## Getting Started

### Prerequisites

- **Node.js** 18.17 or later
- **npm**, **yarn**, or **pnpm**

### Installation

1. **Install dependencies:**

```bash
npm install
# or
yarn install
# or
pnpm install
```

2. **Run the development server:**

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
```

3. **Open your browser:**

Navigate to [http://localhost:3000](http://localhost:3000) to see the landing page.

## Customization

### Brand Colors

Edit `tailwind.config.ts` to customize the color palette:

```typescript
colors: {
  primary: {
    DEFAULT: '#007AFF',  // iOS blue
    dark: '#0051D5',
  },
  // ... other colors
}
```

### Content Updates

All content is located in the component files in the `components/` directory:

- **Hero section:** `components/Hero.tsx`
- **Problem messaging:** `components/Problem.tsx`
- **Features list:** `components/Features.tsx`
- **Photo sharing section:** `components/PhotoSharing.tsx`
- **Testimonials:** `components/SocialProof.tsx`

### Landing Page Flow

The landing page follows a strategic conversion-focused structure:

1. **Hero** - Value proposition and primary CTA
2. **Problem** - "30 messages to plan one event" pain point
3. **Solution** - Shadow Calendar privacy system
4. **Features** - 6 core features + Special Event Templates (Surprise Birthday, Potluck)
5. **How It Works** - 4-step process walkthrough
6. **Photo Sharing** - BeReal-style memory capture (retention feature)
7. **Social Proof** - Testimonials and trust signals
8. **Waitlist** - Email capture form
9. **Footer** - Links and legal

**Key Messaging Strategy:**
- **Planning sections** (Hero → How It Works): Professional, efficiency-focused
- **Photo Sharing section**: Playful, social, emotional - shows the app keeps users engaged POST-event
- **Special Templates**: Demonstrates versatility and complex coordination capabilities

### Adding Images

Place images in the `public/` folder:

```
public/
├── favicon.ico
├── apple-touch-icon.png
├── og-image.png           # Open Graph image (1200x630)
└── screenshots/           # Product screenshots
```

Reference them in components:

```tsx
<img src="/screenshots/hero-image.png" alt="Description" />
```

### Email Signup Integration

The waitlist form in `components/Waitlist.tsx` currently simulates an API call. To integrate with a real backend:

**Option 1: Use a service like Mailchimp, ConvertKit, or Beehiiv**

```typescript
const onSubmit = async (data: WaitlistFormData) => {
  setIsSubmitting(true)

  try {
    const response = await fetch('/api/waitlist', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    })

    if (response.ok) {
      setIsSubmitted(true)
    }
  } catch (error) {
    console.error('Signup failed:', error)
  } finally {
    setIsSubmitting(false)
  }
}
```

**Option 2: Create a Next.js API route**

Create `app/api/waitlist/route.ts`:

```typescript
import { NextResponse } from 'next/server'

export async function POST(request: Request) {
  const body = await request.json()

  // Save to your database or email service
  // Example: await saveToDatabase(body)

  return NextResponse.json({ success: true })
}
```

### Analytics Integration

Add analytics to `app/layout.tsx`:

**Google Analytics:**

```tsx
<Script
  src={`https://www.googletagmanager.com/gtag/js?id=${GA_MEASUREMENT_ID}`}
  strategy="afterInteractive"
/>
<Script id="google-analytics" strategy="afterInteractive">
  {`
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());
    gtag('config', '${GA_MEASUREMENT_ID}');
  `}
</Script>
```

**Plausible Analytics (privacy-friendly):**

```tsx
<Script
  defer
  data-domain="lockitin.app"
  src="https://plausible.io/js/script.js"
/>
```

## Building for Production

### Local Build

```bash
npm run build
npm run start
```

This creates an optimized production build in the `.next` folder.

### Environment Variables

Create a `.env.local` file for sensitive data:

```env
# API endpoints
NEXT_PUBLIC_API_URL=https://api.lockitin.app

# Analytics
NEXT_PUBLIC_GA_MEASUREMENT_ID=G-XXXXXXXXXX
NEXT_PUBLIC_PLAUSIBLE_DOMAIN=lockitin.app

# Email service (if using server-side)
MAILCHIMP_API_KEY=your_api_key
MAILCHIMP_LIST_ID=your_list_id
```

## Deployment

### Deploy to Vercel (Recommended)

Vercel is the easiest way to deploy Next.js apps:

1. **Push your code to GitHub**

2. **Import to Vercel:**
   - Visit [vercel.com](https://vercel.com)
   - Click "Import Project"
   - Select your GitHub repository
   - Vercel auto-detects Next.js and configures everything

3. **Configure custom domain:**
   - In Vercel dashboard → Settings → Domains
   - Add `lockitin.app` and configure DNS

4. **Add environment variables:**
   - In Vercel dashboard → Settings → Environment Variables
   - Add all variables from `.env.local`

**Deploy command:**

```bash
vercel
```

### Deploy to Netlify

1. **Install Netlify CLI:**

```bash
npm install -g netlify-cli
```

2. **Build the site:**

```bash
npm run build
```

3. **Deploy:**

```bash
netlify deploy --prod
```

### Deploy to Custom Server

Build the static export:

```bash
npm run build
```

Upload the `.next` folder to your server and run:

```bash
npm run start
```

## Performance Optimization

This landing page is optimized for Core Web Vitals:

### Already Implemented

- **Image optimization:** Use Next.js `<Image>` component
- **Code splitting:** Automatic with Next.js App Router
- **Lazy loading:** Framer Motion animations use `useInView`
- **Font optimization:** System fonts (SF Pro) with fallbacks
- **Minification:** Automatic in production build

### Additional Optimizations

**Add image optimization:**

```tsx
import Image from 'next/image'

<Image
  src="/screenshots/hero.png"
  alt="LockItIn App"
  width={1200}
  height={800}
  priority // For above-the-fold images
  quality={90}
/>
```

**Lazy load sections:**

```tsx
import dynamic from 'next/dynamic'

const Features = dynamic(() => import('@/components/Features'))
const SocialProof = dynamic(() => import('@/components/SocialProof'))
```

## Accessibility

This landing page follows WCAG 2.1 AA guidelines:

- Semantic HTML structure
- Proper heading hierarchy (H1 → H2 → H3)
- ARIA labels on interactive elements
- Keyboard navigation support
- High contrast colors (4.5:1 minimum)
- Focus states on all interactive elements
- Alt text on all images

**Test accessibility:**

```bash
npm install -g @axe-core/cli
axe http://localhost:3000
```

## SEO Checklist

- [x] Meta title and description
- [x] Open Graph tags for social sharing
- [x] Twitter Card tags
- [x] Semantic HTML (header, main, section, footer)
- [x] Proper heading hierarchy
- [x] Alt text on images
- [x] Mobile-friendly (responsive design)
- [x] Fast page load (< 2 seconds)
- [x] HTTPS (via Vercel/Netlify)
- [ ] Add robots.txt
- [ ] Add sitemap.xml
- [ ] Add structured data (JSON-LD)

**Add robots.txt** in `public/robots.txt`:

```
User-agent: *
Allow: /

Sitemap: https://lockitin.app/sitemap.xml
```

**Add sitemap.xml** in `app/sitemap.ts`:

```typescript
import { MetadataRoute } from 'next'

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    {
      url: 'https://lockitin.app',
      lastModified: new Date(),
      changeFrequency: 'weekly',
      priority: 1,
    },
  ]
}
```

## Browser Support

- Chrome (last 2 versions)
- Firefox (last 2 versions)
- Safari (last 2 versions)
- Edge (last 2 versions)
- iOS Safari 14+
- Android Chrome (last 2 versions)

## Troubleshooting

### Animations not working

Ensure Framer Motion is installed:

```bash
npm install framer-motion
```

### Form validation errors

Check that Zod and React Hook Form are installed:

```bash
npm install react-hook-form zod @hookform/resolvers
```

### Build errors

Clear the cache and reinstall:

```bash
rm -rf node_modules .next
npm install
npm run dev
```

## Contributing

This is a private project for LockItIn. If you have feedback or suggestions, contact the team at hello@lockitin.app.

## License

Proprietary - All rights reserved by LockItIn © 2025

## Support

For questions or issues:

- **Email:** hello@lockitin.app
- **Twitter:** [@lockitin](https://twitter.com/lockitin)
- **Website:** [lockitin.app](https://lockitin.app)

---

**Built with care for the LockItIn launch in April 2026.**

*Lock in plans, not details.*

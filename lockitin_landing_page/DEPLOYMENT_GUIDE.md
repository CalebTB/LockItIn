# LockItIn Landing Page - Deployment Guide

Complete step-by-step guide to deploy your LockItIn landing page to production.

## Pre-Deployment Checklist

Before deploying, ensure you have:

- [ ] Updated all content in components (testimonials, features, etc.)
- [ ] Added your logo and images to `/public`
- [ ] Created Open Graph image (1200x630px) at `/public/og-image.png`
- [ ] Configured email signup integration (Mailchimp/ConvertKit/etc.)
- [ ] Set up analytics (Google Analytics or Plausible)
- [ ] Tested the site locally
- [ ] Registered your domain (lockitin.app)

## Option 1: Deploy to Vercel (Recommended)

Vercel is the easiest deployment option for Next.js apps and is **free** for personal projects.

### Step 1: Push to GitHub

```bash
cd lockitin_landing_page
git init
git add .
git commit -m "Initial commit: LockItIn landing page"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/lockitin-landing.git
git push -u origin main
```

### Step 2: Import to Vercel

1. Visit [vercel.com/signup](https://vercel.com/signup)
2. Sign up with your GitHub account
3. Click "Import Project"
4. Select your GitHub repository
5. Vercel will auto-detect Next.js settings
6. Click "Deploy"

### Step 3: Configure Custom Domain

1. In Vercel Dashboard → Your Project → Settings → Domains
2. Add `lockitin.app`
3. Vercel provides nameservers or DNS records

**Update your domain registrar:**

Add these DNS records at your domain registrar (e.g., Namecheap, GoDaddy):

```
Type: A
Name: @
Value: 76.76.21.21

Type: CNAME
Name: www
Value: cname.vercel-dns.com
```

### Step 4: Add Environment Variables

In Vercel Dashboard → Settings → Environment Variables:

```
NEXT_PUBLIC_API_URL=https://api.lockitin.app
NEXT_PUBLIC_GA_MEASUREMENT_ID=G-XXXXXXXXXX
MAILCHIMP_API_KEY=your_api_key
MAILCHIMP_LIST_ID=your_list_id
```

### Step 5: Redeploy

After adding environment variables, trigger a redeploy:

```bash
git commit --allow-empty -m "Trigger redeploy"
git push
```

Or click "Redeploy" in the Vercel dashboard.

**Done!** Your site is live at `https://lockitin.app`

---

## Option 2: Deploy to Netlify

### Step 1: Build Configuration

Create `netlify.toml` in the root:

```toml
[build]
  command = "npm run build"
  publish = ".next"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

### Step 2: Deploy via Netlify CLI

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Login
netlify login

# Initialize
netlify init

# Deploy
netlify deploy --prod
```

### Step 3: Configure Domain

1. In Netlify Dashboard → Domain Settings
2. Add custom domain: `lockitin.app`
3. Update DNS records at your registrar

---

## Option 3: Deploy to AWS Amplify

### Step 1: Install Amplify CLI

```bash
npm install -g @aws-amplify/cli
amplify configure
```

### Step 2: Initialize Amplify

```bash
amplify init
amplify add hosting
amplify publish
```

### Step 3: Configure Domain

```bash
amplify console
# Navigate to App Settings → Domain Management
# Add lockitin.app
```

---

## Option 4: Self-Hosted (VPS/Server)

### Step 1: Prepare Server

Requirements:
- Ubuntu 20.04+ or similar
- Node.js 18+
- Nginx
- SSL certificate (Let's Encrypt)

### Step 2: Clone and Build

```bash
# SSH into your server
ssh user@your-server-ip

# Clone repository
git clone https://github.com/YOUR_USERNAME/lockitin-landing.git
cd lockitin-landing

# Install dependencies
npm install

# Build
npm run build

# Install PM2 for process management
npm install -g pm2

# Start the app
pm2 start npm --name "lockitin" -- start
pm2 save
pm2 startup
```

### Step 3: Configure Nginx

Create `/etc/nginx/sites-available/lockitin.app`:

```nginx
server {
    listen 80;
    server_name lockitin.app www.lockitin.app;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/lockitin.app /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### Step 4: Add SSL with Let's Encrypt

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d lockitin.app -d www.lockitin.app
```

---

## Post-Deployment Tasks

### 1. Test the Site

Visit your live URL and test:

- [ ] All sections load correctly
- [ ] Animations work smoothly
- [ ] Forms submit successfully
- [ ] Mobile responsiveness
- [ ] Dark mode works
- [ ] All links work

### 2. Set Up Monitoring

**Uptime Monitoring (Free):**
- [UptimeRobot](https://uptimerobot.com) - Free plan monitors every 5 minutes
- [Pingdom](https://pingdom.com) - Free tier available

**Performance Monitoring:**
- Google PageSpeed Insights: https://pagespeed.web.dev/
- GTmetrix: https://gtmetrix.com/
- WebPageTest: https://www.webpagetest.org/

### 3. Configure Analytics

**Google Analytics:**

Add to `app/layout.tsx`:

```tsx
import Script from 'next/script'

// In the <head> section
<Script
  src={`https://www.googletagmanager.com/gtag/js?id=${process.env.NEXT_PUBLIC_GA_MEASUREMENT_ID}`}
  strategy="afterInteractive"
/>
<Script id="google-analytics" strategy="afterInteractive">
  {`
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());
    gtag('config', '${process.env.NEXT_PUBLIC_GA_MEASUREMENT_ID}');
  `}
</Script>
```

**Plausible (Privacy-Friendly):**

```tsx
<Script
  defer
  data-domain="lockitin.app"
  src="https://plausible.io/js/script.js"
  strategy="afterInteractive"
/>
```

### 4. Set Up Email Collection

**Option A: Mailchimp**

```typescript
// app/api/waitlist/route.ts
import mailchimp from '@mailchimp/mailchimp_marketing'

mailchimp.setConfig({
  apiKey: process.env.MAILCHIMP_API_KEY,
  server: 'us1', // Your server prefix
})

export async function POST(request: Request) {
  const { email, name } = await request.json()

  try {
    const response = await mailchimp.lists.addListMember(
      process.env.MAILCHIMP_LIST_ID!,
      {
        email_address: email,
        status: 'subscribed',
        merge_fields: {
          FNAME: name.split(' ')[0],
          LNAME: name.split(' ')[1] || '',
        },
      }
    )

    return Response.json({ success: true })
  } catch (error) {
    return Response.json({ error: 'Failed to subscribe' }, { status: 500 })
  }
}
```

**Option B: ConvertKit**

```bash
npm install @convertkit/convertkit-node
```

```typescript
import ConvertKit from '@convertkit/convertkit-node'

const convertkit = new ConvertKit(process.env.CONVERTKIT_API_KEY!)

export async function POST(request: Request) {
  const { email, name } = await request.json()

  await convertkit.addSubscriberToForm(
    process.env.CONVERTKIT_FORM_ID!,
    {
      email,
      first_name: name,
    }
  )

  return Response.json({ success: true })
}
```

### 5. Submit to Search Engines

**Google Search Console:**
1. Visit [search.google.com/search-console](https://search.google.com/search-console)
2. Add property: `lockitin.app`
3. Verify ownership (DNS or HTML file)
4. Submit sitemap: `https://lockitin.app/sitemap.xml`

**Bing Webmaster Tools:**
1. Visit [bing.com/webmasters](https://www.bing.com/webmasters)
2. Add site
3. Submit sitemap

### 6. Social Media Setup

Create social media accounts:
- Twitter: [@lockitin](https://twitter.com)
- Instagram: [@lockitin](https://instagram.com)
- Update footer links in `components/Footer.tsx`

### 7. Set Up Redirects

If you have an old domain or want to redirect www → non-www:

**In Vercel:**
- Automatically handled

**In Netlify:**
Add to `netlify.toml`:

```toml
[[redirects]]
  from = "https://www.lockitin.app/*"
  to = "https://lockitin.app/:splat"
  status = 301
  force = true
```

---

## Performance Optimization

### Enable Image Optimization

Replace `<img>` tags with Next.js `<Image>`:

```tsx
import Image from 'next/image'

<Image
  src="/screenshots/app-preview.png"
  alt="LockItIn App Preview"
  width={1200}
  height={800}
  priority={true} // For above-the-fold images
/>
```

### Add Caching Headers

In `next.config.js`:

```javascript
module.exports = {
  async headers() {
    return [
      {
        source: '/:all*(svg|jpg|png|webp)',
        headers: [
          {
            key: 'Cache-Control',
            value: 'public, max-age=31536000, immutable',
          },
        ],
      },
    ]
  },
}
```

### Compress Images

Use [TinyPNG](https://tinypng.com) or [Squoosh](https://squoosh.app) to compress images before uploading.

---

## Troubleshooting

### Build Fails on Vercel/Netlify

**Error:** `Module not found`

**Solution:** Ensure all dependencies are in `package.json`:

```bash
npm install
npm run build  # Test locally first
```

### Form Submissions Not Working

**Error:** 500 error on `/api/waitlist`

**Solution:** Check environment variables are set in deployment platform.

### Images Not Loading

**Error:** 404 on images

**Solution:** Ensure images are in `/public` folder and paths start with `/`:

```tsx
<img src="/logo.png" alt="Logo" />  // Correct
<img src="logo.png" alt="Logo" />   // Wrong
```

### Slow Performance

**Solution:**

1. Check Lighthouse scores: [web.dev/measure](https://web.dev/measure)
2. Optimize images (use WebP format, compress)
3. Lazy load components below the fold
4. Enable Vercel/Netlify CDN (automatic)

---

## Maintenance

### Regular Updates

```bash
# Update dependencies quarterly
npm update

# Check for security vulnerabilities
npm audit
npm audit fix
```

### Monitor Metrics

Track these KPIs:
- Waitlist signups per day
- Page views
- Bounce rate
- Conversion rate (visitors → signups)
- Page load time

### A/B Testing

Test variations of:
- Headline copy
- CTA button text and color
- Hero image
- Form placement

Use tools like:
- Google Optimize
- Vercel Edge Config
- Posthog (with feature flags)

---

## Support

If you encounter issues:

1. Check the [Next.js documentation](https://nextjs.org/docs)
2. Search [GitHub Issues](https://github.com/vercel/next.js/issues)
3. Ask in [Next.js Discord](https://nextjs.org/discord)

For LockItIn-specific questions:
- Email: hello@lockitin.app
- Twitter: [@lockitin](https://twitter.com/lockitin)

---

**Congratulations!** Your LockItIn landing page is now live and ready to collect waitlist signups for the April 2026 launch.

*Lock in plans, not details.*

# Open Graph Image Instructions

Create a professional Open Graph image for social media sharing.

## Required Specifications

- **Dimensions:** 1200 x 630 pixels (exact)
- **Format:** PNG or JPG
- **File size:** Under 1MB (ideally under 500KB)
- **File name:** `og-image.png`
- **Location:** Save in `/public/` folder

## What to Include

Your OG image should contain:

1. **LockItIn logo** (top or center)
2. **Main headline:** "Stop the 30-Message Planning Hell"
3. **Subheadline:** "Lock in plans, not details."
4. **Visual element:**
   - Screenshot of the app calendar view, OR
   - Mockup of the voting interface, OR
   - Abstract graphic showing availability heatmap
5. **Launch badge:** "Launching April 2026"
6. **Brand colors:** #007AFF (primary blue), purple accent

## Design Tips

### Typography
- Use SF Pro font (or similar system font)
- Headline: Bold, large (60-80px)
- Subheadline: Regular, medium (40-50px)
- Keep text legible at small sizes (preview will be ~300px wide)

### Layout
- Leave ~10% margin on all edges (safe zone)
- Center important elements
- Use high contrast (dark text on light background or vice versa)

### Color Palette
```
Primary: #007AFF (iOS Blue)
Secondary: #8B5CF6 (Purple)
Background: #FFFFFF or #F9FAFB
Text: #000000 or #1F2937
```

## Where This Image Appears

When someone shares `lockitin.app` on:
- **Twitter/X** - Shows in tweet card
- **Facebook** - Shows in post preview
- **LinkedIn** - Shows in article preview
- **Slack/Discord** - Shows in link unfurl
- **iMessage** - Shows in rich link preview

## Tools to Create It

### Option 1: Canva (Easiest)
1. Visit [canva.com](https://canva.com)
2. Create custom size: 1200 x 630
3. Use "Facebook Post" template and resize
4. Export as PNG

### Option 2: Figma (Recommended for Designers)
1. Create 1200 x 630 frame
2. Design your image
3. Export as PNG at 2x resolution

### Option 3: Online Generator
- [og-image.vercel.app](https://og-image.vercel.app)
- Quick template-based generator

## Example Layout

```
┌──────────────────────────────────────────────┐
│                                              │
│         [LockItIn Logo]                      │
│                                              │
│    Stop the 30-Message Planning Hell        │
│                                              │
│         Lock in plans, not details.          │
│                                              │
│    [Screenshot or Graphic Element]           │
│                                              │
│         Launching April 2026                 │
│                                              │
└──────────────────────────────────────────────┘
```

## Testing Your Image

After creating, test it:

1. **Local test:**
   - Place `og-image.png` in `/public/` folder
   - Start dev server: `npm run dev`
   - Visit: `http://localhost:3000`
   - View page source and verify: `<meta property="og:image" content="/og-image.png">`

2. **Preview tools:**
   - [Twitter Card Validator](https://cards-dev.twitter.com/validator)
   - [Facebook Sharing Debugger](https://developers.facebook.com/tools/debug/)
   - [LinkedIn Post Inspector](https://www.linkedin.com/post-inspector/)

3. **After deployment:**
   - Share link in Slack/Discord to see preview
   - Check on mobile (iMessage, WhatsApp)

## Fallback

If you don't have time to create a custom image, you can:

1. **Use a screenshot** of the hero section from the landing page
2. **Use AI generation:**
   - Prompt: "Create a modern app marketing hero image with text 'LockItIn - Stop the 30-Message Planning Hell'. iOS style, blue and purple gradient, clean and minimal."
   - Tools: Midjourney, DALL-E, Stable Diffusion

## Current Status

- [ ] OG image created
- [ ] Saved as `og-image.png` in `/public/`
- [ ] Tested with preview tools
- [ ] Confirmed dimensions (1200x630)
- [ ] File size optimized (<500KB)

---

**Need help?** Contact your designer or use Canva with the specifications above.

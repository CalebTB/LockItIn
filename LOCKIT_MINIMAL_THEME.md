# LockItIn Design System: Minimal Theme

> Complete specification for the Minimal color scheme in both Dark and Light modes.
> A clean, neutral theme with no color accents — pure grayscale for a distraction-free experience.

---

## Table of Contents

1. [Theme Overview](#theme-overview)
2. [Color Palettes](#color-palettes)
3. [Dark Mode Specifications](#dark-mode-specifications)
4. [Light Mode Specifications](#light-mode-specifications)
5. [Component Patterns](#component-patterns)
6. [Member Colors](#member-colors)
7. [Typography](#typography)
8. [Shadows & Effects](#shadows--effects)
9. [Icons & Status Indicators](#icons--status-indicators)
10. [Animation & Transitions](#animation--transitions)
11. [Accessibility](#accessibility)
12. [Code Snippets](#code-snippets)

---

## Theme Overview

**Minimal** is LockItIn's cleanest theme. It uses only neutral grays — no color accents whatsoever. The focus is entirely on content and functionality without any visual distraction.

### Personality
- **Clean** — Zero color distraction
- **Professional** — Suitable for any context
- **Focused** — Content takes center stage
- **Modern** — True black for OLED screens

### Primary Colors
```
Grayscale only — no accent colors
```

### When to Use
- Users who prefer zero color distraction
- Professional/work environments
- OLED screens (true black saves battery)
- Accessibility preference for reduced visual stimulation
- When you want member event colors to be the only color on screen

---

## Color Palettes

### Dark Mode Palette

| Name | Hex | Tailwind | Usage |
|------|-----|----------|-------|
| Black | #000000 | `black` | Page background (OLED) |
| Neutral 950 | #0A0A0A | `neutral-950` | Phone frame, primary surface |
| Neutral 900 | #171717 | `neutral-900` | Cards, elevated surfaces |
| Neutral 800 | #262626 | `neutral-800` | Borders, input backgrounds |
| Neutral 700 | #404040 | `neutral-700` | Hover states, dividers |
| Neutral 600 | #525252 | `neutral-600` | Disabled text, placeholders |
| Neutral 500 | #737373 | `neutral-500` | Muted text |
| Neutral 400 | #A3A3A3 | `neutral-400` | Secondary text |
| Neutral 300 | #D4D4D4 | `neutral-300` | Primary text |
| Neutral 200 | #E5E5E5 | `neutral-200` | Emphasized text |
| White | #FFFFFF | `white` | Headings, buttons, home indicator |

### Light Mode Palette

| Name | Hex | Tailwind | Usage |
|------|-----|----------|-------|
| White | #FFFFFF | `white` | Page background, surfaces |
| Gray 50 | #FAFAFA | `gray-50` | Secondary background |
| Gray 100 | #F5F5F5 | `gray-100` | Cards, input backgrounds |
| Gray 200 | #E5E5E5 | `gray-200` | Borders |
| Gray 300 | #D4D4D4 | `gray-300` | Hover borders, dividers |
| Gray 400 | #A3A3A3 | `gray-400` | Disabled text, placeholders |
| Gray 500 | #737373 | `gray-500` | Muted text |
| Gray 600 | #525252 | `gray-600` | Secondary text |
| Gray 700 | #404040 | `gray-700` | Primary text |
| Gray 800 | #262626 | `gray-800` | Headings |
| Gray 900 | #171717 | `gray-900` | Emphasized text, buttons |
| Black | #000000 | `black` | Home indicator |

### Semantic Colors (Functional Only)

These colors appear only for status indicators — they're functional, not decorative:

| Purpose | Dark Mode | Light Mode |
|---------|-----------|------------|
| Success/Available | `emerald-400` | `emerald-500` |
| Error/Conflict | `red-400` | `red-500` |
| Warning/Pending | `amber-400` | `amber-500` |

---

## Dark Mode Specifications

### Background Layers

```jsx
// Page background (true black for OLED)
className="bg-black"

// Phone frame / main container
className="bg-neutral-950"

// NO ambient glow effects — keep it pure
```

### Surface Colors

| Element | Class |
|---------|-------|
| Primary surface | `bg-neutral-950` |
| Elevated surface | `bg-neutral-900` |
| Card background | `bg-neutral-900` |
| Input background | `bg-neutral-800` |
| Modal/Sheet background | `bg-neutral-900` |
| Hover surface | `bg-neutral-800` |
| Active surface | `bg-neutral-700` |

### Border Colors

| Element | Class |
|---------|-------|
| Primary border | `border-neutral-800` |
| Subtle border | `border-neutral-800/60` |
| Hover border | `border-neutral-700` |
| Focus border | `border-neutral-600` |
| Divider | `border-neutral-800` |

### Text Colors

| Purpose | Class |
|---------|-------|
| Primary text | `text-white` |
| Secondary text | `text-neutral-300` |
| Tertiary text | `text-neutral-400` |
| Muted text | `text-neutral-500` |
| Disabled text | `text-neutral-600` |
| Placeholder | `placeholder-neutral-600` |

### Interactive States

```jsx
// Button - Primary (white on dark)
className="bg-white text-neutral-900 hover:bg-neutral-200 active:scale-[0.98]"

// Button - Secondary
className="bg-neutral-800 border border-neutral-700 hover:bg-neutral-700 text-white"

// Button - Ghost
className="hover:bg-neutral-800 text-neutral-400 hover:text-white"

// Icon button
className="p-2 hover:bg-neutral-800 rounded-xl transition-colors"

// Card hover
className="hover:bg-neutral-800/50 transition-colors"

// Input focus
className="focus:outline-none focus:border-neutral-600 focus:ring-2 focus:ring-neutral-700"

// Link
className="text-neutral-300 hover:text-white underline"
```

### Phone Frame (Dark)

```jsx
className="bg-neutral-950 rounded-[3rem] shadow-2xl overflow-hidden border-[6px] border-neutral-800"
```

---

## Light Mode Specifications

### Background Layers

```jsx
// Page background
className="bg-gray-100"

// Phone frame / main container
className="bg-white"

// NO ambient glow effects
```

### Surface Colors

| Element | Class |
|---------|-------|
| Primary surface | `bg-white` |
| Secondary surface | `bg-gray-50` |
| Card background | `bg-white` |
| Input background | `bg-gray-100` |
| Modal/Sheet background | `bg-white` |
| Hover surface | `bg-gray-50` |
| Active surface | `bg-gray-100` |

### Border Colors

| Element | Class |
|---------|-------|
| Primary border | `border-gray-200` |
| Subtle border | `border-gray-100` |
| Hover border | `border-gray-300` |
| Focus border | `border-gray-400` |
| Divider | `border-gray-200` |

### Text Colors

| Purpose | Class |
|---------|-------|
| Primary text | `text-gray-900` |
| Secondary text | `text-gray-700` |
| Tertiary text | `text-gray-600` |
| Muted text | `text-gray-500` |
| Disabled text | `text-gray-400` |
| Placeholder | `placeholder-gray-400` |

### Interactive States

```jsx
// Button - Primary (dark on light)
className="bg-gray-900 text-white hover:bg-gray-800 active:scale-[0.98]"

// Button - Secondary
className="bg-white border border-gray-300 hover:border-gray-400 hover:bg-gray-50 text-gray-900"

// Button - Ghost
className="hover:bg-gray-100 text-gray-600 hover:text-gray-900"

// Icon button
className="p-2 hover:bg-gray-100 rounded-xl transition-colors"

// Card hover
className="hover:shadow-lg hover:shadow-gray-200/50 transition-all"

// Input focus
className="focus:outline-none focus:border-gray-400 focus:ring-2 focus:ring-gray-200"

// Link
className="text-gray-700 hover:text-gray-900 underline"
```

### Phone Frame (Light)

```jsx
className="bg-white rounded-[3rem] shadow-2xl shadow-gray-300/50 overflow-hidden border-[6px] border-gray-200"
```

---

## Component Patterns

### Status Bar

**Dark Mode:**
```jsx
<div className="px-6 py-2 flex items-center justify-between text-xs text-white">
  <span className="font-semibold">9:41</span>
  <div className="flex items-center gap-1.5">
    <div className="flex gap-0.5">
      {[1,2,3,4].map(i => (
        <div key={i} className={`w-1 h-1 rounded-full ${i < 4 ? 'bg-white' : 'bg-neutral-600'}`} />
      ))}
    </div>
    <span className="ml-0.5">5G</span>
    <div className="w-5 h-2.5 border border-white rounded-sm ml-0.5 relative">
      <div className="absolute inset-0.5 bg-white rounded-sm" style={{width: '65%'}} />
    </div>
  </div>
</div>
```

**Light Mode:**
```jsx
<div className="px-6 py-2 flex items-center justify-between text-xs text-gray-900">
  <span className="font-semibold">9:41</span>
  <div className="flex items-center gap-1.5">
    <div className="flex gap-0.5">
      {[1,2,3,4].map(i => (
        <div key={i} className={`w-1 h-1 rounded-full ${i < 4 ? 'bg-gray-900' : 'bg-gray-300'}`} />
      ))}
    </div>
    <span className="ml-0.5">5G</span>
    <div className="w-5 h-2.5 border border-gray-900 rounded-sm ml-0.5 relative">
      <div className="absolute inset-0.5 bg-gray-900 rounded-sm" style={{width: '65%'}} />
    </div>
  </div>
</div>
```

### Navigation Header

**Dark Mode:**
```jsx
<div className="px-5 py-3 flex items-center justify-between">
  <button className="w-9 h-9 flex items-center justify-center hover:bg-neutral-800 rounded-xl transition-colors">
    <ChevronLeft size={22} className="text-white" />
  </button>
  <h1 className="font-bold text-lg text-white">
    Title
  </h1>
  <button className="w-9 h-9 flex items-center justify-center hover:bg-neutral-800 rounded-xl transition-colors">
    <Plus size={22} className="text-white" />
  </button>
</div>
```

**Light Mode:**
```jsx
<div className="px-5 py-3 flex items-center justify-between border-b border-gray-200">
  <button className="w-9 h-9 flex items-center justify-center hover:bg-gray-100 rounded-xl transition-colors">
    <ChevronLeft size={22} className="text-gray-700" />
  </button>
  <h1 className="font-bold text-lg text-gray-900">
    Title
  </h1>
  <button className="w-9 h-9 flex items-center justify-center hover:bg-gray-100 rounded-xl transition-colors">
    <Plus size={22} className="text-gray-700" />
  </button>
</div>
```

### Cards

**Dark Mode:**
```jsx
<div className="bg-neutral-900 rounded-2xl p-4 border border-neutral-800">
  <h3 className="font-semibold text-white">Card Title</h3>
  <p className="text-neutral-400 text-sm mt-1">Card description text</p>
</div>

// Hoverable card
<button className="w-full bg-neutral-900 rounded-2xl p-4 border border-neutral-800 hover:bg-neutral-800 hover:border-neutral-700 transition-all text-left">
  ...
</button>
```

**Light Mode:**
```jsx
<div className="bg-white rounded-2xl p-4 border border-gray-200">
  <h3 className="font-semibold text-gray-900">Card Title</h3>
  <p className="text-gray-500 text-sm mt-1">Card description text</p>
</div>

// Hoverable card
<button className="w-full bg-white rounded-2xl p-4 border border-gray-200 hover:shadow-lg hover:border-gray-300 transition-all text-left">
  ...
</button>
```

### Input Fields

**Dark Mode:**
```jsx
<div>
  <label className="text-xs font-medium text-neutral-500 uppercase tracking-wide mb-1.5 block">
    Label
  </label>
  <input
    type="text"
    placeholder="Placeholder"
    className="w-full px-4 py-3 bg-neutral-800 border border-neutral-700 rounded-xl text-white placeholder-neutral-500 focus:outline-none focus:border-neutral-600 focus:ring-2 focus:ring-neutral-700 transition-all"
  />
</div>
```

**Light Mode:**
```jsx
<div>
  <label className="text-xs font-medium text-gray-500 uppercase tracking-wide mb-1.5 block">
    Label
  </label>
  <input
    type="text"
    placeholder="Placeholder"
    className="w-full px-4 py-3 bg-gray-100 border border-gray-200 rounded-xl text-gray-900 placeholder-gray-400 focus:outline-none focus:border-gray-400 focus:ring-2 focus:ring-gray-200 focus:bg-white transition-all"
  />
</div>
```

### Toggles/Switches

**Dark Mode:**
```jsx
<button 
  onClick={() => setEnabled(!enabled)}
  className={`w-11 h-6 rounded-full transition-colors relative ${
    enabled ? 'bg-white' : 'bg-neutral-700'
  }`}
>
  <div className={`absolute top-1 w-4 h-4 rounded-full shadow transition-transform ${
    enabled ? 'left-6 bg-neutral-900' : 'left-1 bg-neutral-400'
  }`} />
</button>
```

**Light Mode:**
```jsx
<button 
  onClick={() => setEnabled(!enabled)}
  className={`w-11 h-6 rounded-full transition-colors relative ${
    enabled ? 'bg-gray-900' : 'bg-gray-300'
  }`}
>
  <div className={`absolute top-1 w-4 h-4 bg-white rounded-full shadow transition-transform ${
    enabled ? 'left-6' : 'left-1'
  }`} />
</button>
```

### Pills/Chips

**Dark Mode:**
```jsx
// Active pill
<button className="px-3 py-1.5 rounded-full text-xs font-semibold bg-white text-neutral-900">
  Active
</button>

// Inactive pill
<button className="px-3 py-1.5 rounded-full text-xs font-medium bg-neutral-800 text-neutral-400 hover:text-white transition-colors">
  Inactive
</button>
```

**Light Mode:**
```jsx
// Active pill
<button className="px-3 py-1.5 rounded-full text-xs font-semibold bg-gray-900 text-white">
  Active
</button>

// Inactive pill
<button className="px-3 py-1.5 rounded-full text-xs font-medium bg-gray-100 text-gray-600 hover:bg-gray-200 transition-colors">
  Inactive
</button>
```

### Primary Buttons

**Dark Mode:**
```jsx
<button className="w-full py-4 bg-white text-neutral-900 font-bold rounded-2xl hover:bg-neutral-200 active:scale-[0.98] transition-all">
  Button Text
</button>
```

**Light Mode:**
```jsx
<button className="w-full py-4 bg-gray-900 text-white font-bold rounded-2xl hover:bg-gray-800 active:scale-[0.98] transition-all">
  Button Text
</button>
```

---

## Member Colors

In the Minimal theme, members are distinguished through **grayscale shades** rather than colorful gradients. This keeps the interface clean while still allowing users to identify different people's events.

### Dark Mode Member Colors

| Member | Color | Background Class | Text Class |
|--------|-------|------------------|------------|
| You | White | `bg-white` | `text-neutral-900` |
| Member 2 | Light Gray | `bg-neutral-300` | `text-neutral-900` |
| Member 3 | Medium Gray | `bg-neutral-400` | `text-neutral-900` |
| Member 4 | Gray | `bg-neutral-500` | `text-white` |
| Member 5 | Dark Gray | `bg-neutral-600` | `text-white` |
| Member 6 | Darker Gray | `bg-neutral-700` | `text-white` |

### Light Mode Member Colors

| Member | Color | Background Class | Text Class |
|--------|-------|------------------|------------|
| You | Black | `bg-gray-900` | `text-white` |
| Member 2 | Dark Gray | `bg-gray-700` | `text-white` |
| Member 3 | Gray | `bg-gray-600` | `text-white` |
| Member 4 | Medium Gray | `bg-gray-500` | `text-white` |
| Member 5 | Light Gray | `bg-gray-400` | `text-gray-900` |
| Member 6 | Lighter Gray | `bg-gray-300` | `text-gray-900` |

### Member Data Structure

```jsx
// Dark Mode
const membersDark = [
  { id: 1, name: 'You', avatar: 'Y', bg: 'bg-white', text: 'text-neutral-900' },
  { id: 2, name: 'Sarah', avatar: 'S', bg: 'bg-neutral-300', text: 'text-neutral-900' },
  { id: 3, name: 'Mike', avatar: 'M', bg: 'bg-neutral-400', text: 'text-neutral-900' },
  { id: 4, name: 'Emma', avatar: 'E', bg: 'bg-neutral-500', text: 'text-white' },
  { id: 5, name: 'Alex', avatar: 'A', bg: 'bg-neutral-600', text: 'text-white' },
  { id: 6, name: 'Jordan', avatar: 'J', bg: 'bg-neutral-700', text: 'text-white' },
];

// Light Mode
const membersLight = [
  { id: 1, name: 'You', avatar: 'Y', bg: 'bg-gray-900', text: 'text-white' },
  { id: 2, name: 'Sarah', avatar: 'S', bg: 'bg-gray-700', text: 'text-white' },
  { id: 3, name: 'Mike', avatar: 'M', bg: 'bg-gray-600', text: 'text-white' },
  { id: 4, name: 'Emma', avatar: 'E', bg: 'bg-gray-500', text: 'text-white' },
  { id: 5, name: 'Alex', avatar: 'A', bg: 'bg-gray-400', text: 'text-gray-900' },
  { id: 6, name: 'Jordan', avatar: 'J', bg: 'bg-gray-300', text: 'text-gray-900' },
];
```

### Member Avatar

**Dark Mode:**
```jsx
<div className={`w-6 h-6 rounded-full ${member.bg} flex items-center justify-center text-[9px] ${member.text} font-bold`}>
  {member.avatar}
</div>
```

**Light Mode:**
```jsx
<div className={`w-6 h-6 rounded-full ${member.bg} flex items-center justify-center text-[9px] ${member.text} font-bold`}>
  {member.avatar}
</div>
```

### Event Block Styling

**Dark Mode:**
```jsx
<div className={`${member.bg} rounded-xl p-2`}>
  <div className="flex items-center gap-1">
    <span className="text-sm">{event.emoji}</span>
    <span className={`text-[11px] font-semibold ${member.text}`}>{event.title}</span>
  </div>
  <span className={`text-[9px] ${member.text} opacity-70`}>{event.location}</span>
</div>
```

**Light Mode:**
```jsx
<div className={`${member.bg} rounded-xl p-2`}>
  <div className="flex items-center gap-1">
    <span className="text-sm">{event.emoji}</span>
    <span className={`text-[11px] font-semibold ${member.text}`}>{event.title}</span>
  </div>
  <span className={`text-[9px] ${member.text} opacity-70`}>{event.location}</span>
</div>
```

### Busy Block Styling

**Dark Mode:**
```jsx
<div className="bg-neutral-800/50 border border-dashed border-neutral-700 rounded-xl p-2">
  <div className="flex items-center gap-1.5">
    <div className={`w-4 h-4 rounded-full ${member.bg} flex items-center justify-center`}>
      <span className={`text-[6px] font-bold ${member.text}`}>{member.avatar}</span>
    </div>
    <span className="text-[11px] font-medium text-neutral-500">{member.name}</span>
  </div>
  <span className="text-[10px] text-neutral-600">Busy</span>
</div>
```

**Light Mode:**
```jsx
<div className="bg-gray-50 border border-dashed border-gray-300 rounded-xl p-2">
  <div className="flex items-center gap-1.5">
    <div className={`w-4 h-4 rounded-full ${member.bg} flex items-center justify-center`}>
      <span className={`text-[6px] font-bold ${member.text}`}>{member.avatar}</span>
    </div>
    <span className="text-[11px] font-medium text-gray-500">{member.name}</span>
  </div>
  <span className="text-[10px] text-gray-400">Busy</span>
</div>
```

### Member Filter Pills

**Dark Mode:**
```jsx
// Selected
<button className={`flex items-center gap-1.5 pl-1 pr-2.5 py-1 rounded-full ${member.bg}`}>
  <div className={`w-5 h-5 rounded-full bg-neutral-900/20 flex items-center justify-center text-[9px] ${member.text} font-bold`}>
    {member.avatar}
  </div>
  <span className={`text-xs font-medium ${member.text}`}>{member.name}</span>
</button>

// Unselected
<button className="flex items-center gap-1.5 pl-1 pr-2.5 py-1 rounded-full bg-neutral-800 hover:bg-neutral-700">
  <div className={`w-5 h-5 rounded-full ${member.bg} flex items-center justify-center text-[9px] ${member.text} font-bold`}>
    {member.avatar}
  </div>
  <span className="text-xs font-medium text-neutral-400">{member.name}</span>
</button>
```

**Light Mode:**
```jsx
// Selected
<button className={`flex items-center gap-1.5 pl-1 pr-2.5 py-1 rounded-full ${member.bg}`}>
  <div className={`w-5 h-5 rounded-full bg-white/20 flex items-center justify-center text-[9px] ${member.text} font-bold`}>
    {member.avatar}
  </div>
  <span className={`text-xs font-medium ${member.text}`}>{member.name}</span>
</button>

// Unselected
<button className="flex items-center gap-1.5 pl-1 pr-2.5 py-1 rounded-full bg-gray-100 hover:bg-gray-200">
  <div className={`w-5 h-5 rounded-full ${member.bg} flex items-center justify-center text-[9px] ${member.text} font-bold`}>
    {member.avatar}
  </div>
  <span className="text-xs font-medium text-gray-600">{member.name}</span>
</button>
```

---

## Typography

### Font Stack
```css
font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Segoe UI', Roboto, sans-serif;
```

### Scale

| Element | Size | Weight | Class |
|---------|------|--------|-------|
| Page title | 18px | Bold | `text-lg font-bold` |
| Section header | 16px | Semibold | `text-base font-semibold` |
| Card title | 14px | Semibold | `text-sm font-semibold` |
| Body text | 14px | Regular | `text-sm` |
| Small text | 12px | Medium | `text-xs font-medium` |
| Caption | 11px | Medium | `text-[11px] font-medium` |
| Micro | 10px | Medium | `text-[10px] font-medium` |
| Tiny | 9px | Bold | `text-[9px] font-bold` |

---

## Shadows & Effects

### Dark Mode

Shadows are minimal in dark mode — depth is created through surface colors instead.

| Element | Class |
|---------|-------|
| Phone frame | `shadow-2xl` |
| Cards | — (no shadow) |
| Buttons | — (no shadow) |
| Modals | `shadow-2xl` |

### Light Mode

| Element | Class |
|---------|-------|
| Phone frame | `shadow-2xl shadow-gray-300/50` |
| Cards | `shadow-sm` (optional) |
| Card hover | `shadow-lg shadow-gray-200/50` |
| Buttons | — (no shadow) |
| Modals | `shadow-2xl` |

### Backdrop Blur

```jsx
// Modal overlay - Dark
className="bg-black/70 backdrop-blur-sm"

// Modal overlay - Light
className="bg-black/40 backdrop-blur-sm"
```

---

## Icons & Status Indicators

### Icon Sizes

| Context | Size |
|---------|------|
| Navigation | 22px |
| Card action | 20px |
| Inline | 16px |
| Small | 14px |
| Tiny | 12px |

### Icon Colors

**Dark Mode:**

| Context | Class |
|---------|-------|
| Primary | `text-white` |
| Secondary | `text-neutral-400` |
| Muted | `text-neutral-500` |
| Disabled | `text-neutral-600` |

**Light Mode:**

| Context | Class |
|---------|-------|
| Primary | `text-gray-700` |
| Secondary | `text-gray-500` |
| Muted | `text-gray-400` |
| Disabled | `text-gray-300` |

### Status Dots (Functional Color Only)

**Dark Mode:**
```jsx
// Available (only functional color)
<div className="w-2.5 h-2.5 rounded-full bg-emerald-400" />

// Busy (grayscale)
<div className="w-2.5 h-2.5 rounded-full bg-neutral-600" />
```

**Light Mode:**
```jsx
// Available
<div className="w-2.5 h-2.5 rounded-full bg-emerald-500" />

// Busy
<div className="w-2.5 h-2.5 rounded-full bg-gray-400" />
```

### "Free Time" Indicator

**Dark Mode:**
```jsx
<div className="bg-neutral-800/50 border border-dashed border-neutral-700 rounded-xl flex items-center justify-center">
  <span className="text-[11px] font-medium text-neutral-500">Free</span>
</div>
```

**Light Mode:**
```jsx
<div className="bg-gray-50 border border-dashed border-gray-300 rounded-xl flex items-center justify-center">
  <span className="text-[11px] font-medium text-gray-500">Free</span>
</div>
```

### Current Time Line

**Dark Mode:**
```jsx
<div className="flex items-center">
  <div className="w-2 h-2 rounded-full bg-white" />
  <div className="flex-1 h-[2px] bg-gradient-to-r from-white to-white/0" />
</div>
```

**Light Mode:**
```jsx
<div className="flex items-center">
  <div className="w-2 h-2 rounded-full bg-gray-900" />
  <div className="flex-1 h-[2px] bg-gradient-to-r from-gray-900 to-gray-900/0" />
</div>
```

---

## Animation & Transitions

### Standard Transitions

```jsx
className="transition-colors"      // Color changes
className="transition-all"         // All properties
className="transition-transform"   // Scale/translate
```

### Interactive Animations

```jsx
// Button press
className="active:scale-[0.98]"

// Card hover (light mode)
className="hover:shadow-lg"

// Subtle hover
className="hover:bg-neutral-800" // dark
className="hover:bg-gray-100"    // light
```

---

## Accessibility

### Color Contrast

All combinations meet WCAG 2.1 AA:

| Combination | Ratio | Pass |
|-------------|-------|------|
| White on neutral-900 | 15.1:1 | ✅ AAA |
| neutral-300 on neutral-950 | 10.8:1 | ✅ AAA |
| neutral-400 on neutral-900 | 6.3:1 | ✅ AA |
| gray-900 on white | 21:1 | ✅ AAA |
| gray-600 on white | 5.7:1 | ✅ AA |

### Focus States

```jsx
// Dark mode
className="focus:outline-none focus:ring-2 focus:ring-neutral-600 focus:ring-offset-2 focus:ring-offset-neutral-950"

// Light mode
className="focus:outline-none focus:ring-2 focus:ring-gray-400 focus:ring-offset-2"
```

### Touch Targets

- Minimum: 44x44px
- Icon buttons: `w-9 h-9` (36px) with adequate padding

---

## Code Snippets

### Complete Dark Mode Page

```jsx
<div className="min-h-screen bg-black flex items-center justify-center p-4">
  {/* Phone Frame */}
  <div className="relative w-full max-w-sm bg-neutral-950 rounded-[3rem] shadow-2xl overflow-hidden h-[750px] border-[6px] border-neutral-800">
    
    {/* Status Bar */}
    <div className="px-6 py-2 flex items-center justify-between text-xs text-white">
      <span className="font-semibold">9:41</span>
      <div className="flex items-center gap-1.5">
        <div className="flex gap-0.5">
          {[1,2,3,4].map(i => (
            <div key={i} className={`w-1 h-1 rounded-full ${i < 4 ? 'bg-white' : 'bg-neutral-600'}`} />
          ))}
        </div>
        <span className="ml-0.5">5G</span>
        <div className="w-5 h-2.5 border border-white rounded-sm ml-0.5 relative">
          <div className="absolute inset-0.5 bg-white rounded-sm" style={{width: '65%'}} />
        </div>
      </div>
    </div>

    {/* Content */}
    <div className="px-4 py-4">
      {/* Your content here */}
    </div>

    {/* Home Indicator */}
    <div className="absolute bottom-2 left-1/2 -translate-x-1/2 w-28 h-1 bg-white rounded-full" />
  </div>
</div>
```

### Complete Light Mode Page

```jsx
<div className="min-h-screen bg-gray-100 flex items-center justify-center p-4">
  {/* Phone Frame */}
  <div className="relative w-full max-w-sm bg-white rounded-[3rem] shadow-2xl shadow-gray-300/50 overflow-hidden h-[750px] border-[6px] border-gray-200">
    
    {/* Status Bar */}
    <div className="px-6 py-2 flex items-center justify-between text-xs text-gray-900">
      <span className="font-semibold">9:41</span>
      <div className="flex items-center gap-1.5">
        <div className="flex gap-0.5">
          {[1,2,3,4].map(i => (
            <div key={i} className={`w-1 h-1 rounded-full ${i < 4 ? 'bg-gray-900' : 'bg-gray-300'}`} />
          ))}
        </div>
        <span className="ml-0.5">5G</span>
        <div className="w-5 h-2.5 border border-gray-900 rounded-sm ml-0.5 relative">
          <div className="absolute inset-0.5 bg-gray-900 rounded-sm" style={{width: '65%'}} />
        </div>
      </div>
    </div>

    {/* Content */}
    <div className="px-4 py-4">
      {/* Your content here */}
    </div>

    {/* Home Indicator */}
    <div className="absolute bottom-2 left-1/2 -translate-x-1/2 w-28 h-1 bg-black rounded-full" />
  </div>
</div>
```

### Theme Label Badge

**Dark Mode:**
```jsx
<div className="absolute bottom-6 left-1/2 -translate-x-1/2">
  <div className="flex items-center gap-2 bg-neutral-900 border border-neutral-800 px-4 py-2 rounded-full">
    <LockItInLogo size={18} />
    <span className="text-sm font-medium text-white">Minimal Dark</span>
  </div>
</div>
```

**Light Mode:**
```jsx
<div className="absolute bottom-6 left-1/2 -translate-x-1/2">
  <div className="flex items-center gap-2 bg-white border border-gray-200 px-4 py-2 rounded-full shadow-lg">
    <LockItInLogo size={18} />
    <span className="text-sm font-medium text-gray-900">Minimal Light</span>
  </div>
</div>
```

---

## Quick Reference

### Dark Mode Essentials
```
Background:     black
Surface:        neutral-950, neutral-900
Border:         neutral-800, neutral-700
Text:           white, neutral-300, neutral-400, neutral-500
Button:         bg-white text-neutral-900
Focus:          neutral-600
```

### Light Mode Essentials
```
Background:     gray-100
Surface:        white, gray-50
Border:         gray-200, gray-300
Text:           gray-900, gray-700, gray-600, gray-500
Button:         bg-gray-900 text-white
Focus:          gray-400
```

### Member Distinction
```
Dark Mode:      white → neutral-300 → neutral-400 → neutral-500 → neutral-600 → neutral-700
Light Mode:     gray-900 → gray-700 → gray-600 → gray-500 → gray-400 → gray-300
Status:         emerald (available only) — everything else grayscale
```

---

*Last updated: December 2024*
*Version: 1.0*
*Theme: Minimal (Dark & Light)*
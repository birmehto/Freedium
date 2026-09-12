# 📱 Freedium — Google Play Store Listing Pack

Everything you need to publish **Freedium** on Google Play — verified against Play Console requirements (2026). Copy the text straight into Play Console, and use the prompts below to generate on-brand graphics.

---

## 1️⃣ Basic Info

| Field | Value |
|---|---|
| **App name / Title** (max **30** chars) | `Freedium – Medium Reader` (23 chars) |
| **Developer name** | Bir Mehto |
| **Category** | News & Magazines |
| **App type** | App |
| **Content rating** | Everyone (no mature content, general audience) |
| **Contact email** | birmehto@gmail.com |
| **Privacy policy URL** | Required for publishing — host a simple page, e.g. GitHub Pages of this repo |
| **Default language** | English (US) |

> 🚫 Play policy bans: `Free`, `#1`, `Best`, `Top`, `Install now`, `New`, `Discount`, emojis in the title, ALL-CAPS, and comparisons to other apps. Keep the title clean.

---

## 2️⃣ Short Description (max **80** chars)

```
Read Medium articles free, past the paywall — clean reader, offline favorites.
```

**Count:** 78 ✓ (within 80-char limit)

> Lead with the keyword, state the benefit, stay under 80. Don't repeat the title.

---

## 3️⃣ Full Description (max **4,000** chars — this is ~1,550)

Copy below. Unicode bullets ✓ (Play doesn't render HTML lists). Keywords woven in naturally: *medium reader, medium articles, paywall, read articles, offline, favorites* (~2-3% density, no stuffing).

```
Freedium is a free, open-source Medium reader that unlocks the stories you actually want to read. Paste any Medium article link and read the full article instantly — no paywall, no "your free articles ran out" wall, no 20 popups blocking the text.

WHY FREEDIUM?

★ Read any Medium article with one tap
Just paste a link or share it into Freedium from any app. The app fetches the full article through the Freedium mirror and shows it to you right away.

★ A clean, distraction-free reader
Forget cluttered web pages. Freedium strips away nav bars, dialogs, popovers and popups, leaving a beautifully typeset page you control. Adjust font size, switch between Inter, Roboto, Merriweather and Open Sans, and flip between dark and light themes — your reading, your way.

★ Reading progress bar
A live progress indicator in the app bar shows exactly where you are in every article.

★ Resume where you left off
Freedium remembers your scroll position per article. Close a story and come back hours later — you start right where you stopped.

★ Offline favorites
Bookmark any article and it's saved on your device — no account, no sign-up. Search favorites by title, author or source, swipe to delete, and re-open stories in one tap.

★ Share-to-read
Reading Medium on your phone? Hit Share → Freedium and the article opens instantly. Works with any text that contains a URL.

Freedium is free, open-source and built with love for readers like you. If you enjoy respectful reading, support the writers you love — and enjoy Freedium.

Have feedback? Reach out at birmehto@gmail.com — we read everything.
```

> **Optional intro line** (keeps keyword density healthy):
> > *"Looking for a fast, ad-free Medium reader? Freedium is a free paywall reader for Medium articles — paste a link, read the full story, save favorites offline."*

---

## 4️⃣ What's New (release notes style)

```
🎉 Freedium 1.1.0
• New app name & icon — meet Freedium!
• Smoother reading experience
• Faster article loading
• Bug fixes & performance improvements
```

---

## 5️⃣ Graphics — Required Assets

### App Icon — must be regenerated (see prompt below)

| Spec | Value |
|---|---|
| Size | **512 × 512 px** (exact, full square) |
| Format | 32-bit PNG **with alpha** |
| Max file size | **1 MB** |
| Shape | Full square — Google applies the 30% corner radius; **do not round corners yourself** |
| Safe zone | Keep the logo inside the central ~80%; key lines ~15-18% from edge |

### Feature Graphic — required

| Spec | Value |
|---|---|
| Size | **1024 × 500 px** (exact) |
| Format | JPEG or 24-bit PNG (**no alpha**) |
| Max file size | 1 MB |
| Safe zone | Keep text/logo in center ~80% (cropped on TV/small widgets) |
| Rule | No device phone frame, minimal text, strong focal point |

### Screenshots — required (min 2)

| Spec | Value |
|---|---|
| Count | 2 minimum → **use 4-8** (recommended 1080×1920 portrait) |
| Format | JPEG or 24-bit PNG, no alpha |
| Sizes | each side 320–3840 px, aspect between 1:2 and 2:1 |
| Rule | Show the **real app** — no fake features (rejection risk) |

Use the 5 existing screenshots: `screenshots/home.png`, `article.png`, `article_settings.png`, `favorites.png`, `settings.png`. Re-shoot at 1080×1920 for the phone portrait slot.

### Promo video (highly recommended)
- YouTube URL, 30 seconds, phone screen demo of pasting a link → reading a clean article → saving favorite.

---

## 6️⃣ App Icon Generation Prompt 🎨 (better colors + premium look)

> **Design direction:** Replace the flat indigo with a **rich royal-indigo → violet gradient** (`#3A3B8F` → `#7B6CF6`), warm **amber `#FFB94E`** accent for the book/spark motif, and a soft warm paper-cream background layer for readable contrast. Glossy-but-premium: subtle radial lighting, no harsh shadows (Google adds its own).

### Play Store icon (512×512) — copy into any image generator:

```
Square app icon, 512x512, full-bleed. A clean, open book shape in warm
paper-cream white (#F5EFE6) floating centered, its pages slightly fanned,
atop a rich royal-indigo to violet gradient background (#3A3B8F top-left
→ #7B6CF6 bottom-right). A small amber spark/star (#FFB94E) sits above
the right page where a lock opens — symbolizing a story "unlocked."
Soft, diffused radial lighting from the upper left, gentle 3D depth on the
book, minimal and flat, premium minimalism, generous negative space.
No text, no badge, no rounded corners, no drop shadow — full square canvas,
key motif within central safe zone. Modern Material 3 style, crisp edges,
icon looks clean at 16px and 512px.
```

### Feature graphic (1024×500) — copy into any image generator:

```
Wide banner, 1024x500, landscape. Left side: bold headline in clean
sans-serif "READ MEDIUM. FREEDIUM." with the amber spark (#FFB94E)
between the words. Right side: the same open-book glyph floating over a
soft royal-indigo (#4A4BB0) to violet (#7B6CF6) gradient, with faint
floating page wisps. Background subtle deep-indigo, one strong focal
point, high contrast, generous margins, no phone frame, no small text.
```

> After generating: export icon as full square PNG and run it through the [Play App Icon resizer](https://www.appicon.co/) to confirm 512×512 < 1 MB. Test the adaptive (launcher) icon in Android Studio — keep the glyph inside the **66×66 dp safe zone** of a 108×108 dp layer.

---

## 7️⃣ Android Launcher (Adaptive) Icon — sizes Cheat-sheet

| Density | Launcher px | Adaptive layer px |
|---|---|---|
| mdpi | 48 | 108 |
| hdpi | 72 | 162 |
| xhdpi | 96 | 216 |
| xxhdpi | 144 | 324 |
| xxxhdpi | 192 | 432 |

Safe zone: 66×66 dp (logo 48–66 dp). Background layer fully opaque. Add monochrome layer for Android 13+ themed icons.

---

## 8️⃣ Pre-publish Checklist ✅

- [ ] No emojis / ALL-CAPS / "$ / # / best" in title & short description
- [ ] Full description reflects the **real** app screenshots
- [ ] Icon is full square, 512×512, PNG < 1 MB — no pre-rounded corners
- [ ] Feature graphic 1024×500, no alpha
- [ ] 4+ phone screenshots at 1080×1920 from the actual app
- [ ] Privacy policy URL live (required)
- [ ] Data safety form + content rating questionnaire completed in console
- [ ] Tested the blank form on an emulator (release build) before submission

---

Resource: [Google Play best practices](https://support.google.com/googleplay/android-developer/answer/13393723), [Icon specs](https://developer.android.com/distribute/google-play/resources/icon-design-specifications), [Preview assets](https://support.google.com/googleplay/android-developer/answer/9866151).
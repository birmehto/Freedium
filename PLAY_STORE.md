# Play Store assets & ASO copy

Listing text and AI image prompts for the redesigned v1.3.0 app.

> The currently published Play Store screenshots show the **old** purple/card UI. Do **not** use them as visual references. Use only the live listing's metadata (package, category, support email) and the current UI described here.

## Store listing

| Field | Copy |
|---|---|
| **App name** (keep the already-approved title) | Freedium – Medium Reader |
| **Short description** (73/80) | Read Medium stories free: clean reader, offline saves, 5 sources, no ads. |
| **Category** | Books & Reference |
| **Content rating** | Everyone |
| **Support email** | birmehto@gmail.com |

### Full description

Read the Medium stories you care about — without the paywall, the pop-ups, or the clutter.

Freedium is a free, open-source Medium reader. Paste a link or share one from another app, and the full story opens in a calm, typographic reading view. No account, no subscription, no ads.

WHY FREEDIUM

• Read freely — member-only Medium stories open in a clean reader.
• Just the words — site chrome, overlays and paywall prompts are stripped out.
• Make it yours — System, Light, Dark, Sepia and OLED reader themes, plus font family and text size controls.
• Save for later — favoriting a story keeps a copy on your device, so it stays readable offline.
• Keep reading — five sources with automatic fallback and health tracking: Freedium Mirror, Freedium Web, Freedium backup, Archive.ph and Archive.is.
• Share to read — send a Medium link from any Android app straight into Freedium.
• Quiet by design — consistent, low-distraction motion and a minimal editorial interface.

PRIVACY FIRST

Favorites, settings and saved articles are stored locally. Freedium has no analytics, no ads, no background tracking and no login. The reader only fetches the story you ask for.

FREE AND OPEN SOURCE

MIT licensed and built in spare time. An optional "buy me a coffee" on the home screen supports the mirrors.

Freedium is not affiliated with, endorsed by, or connected to Medium. All article content remains the property of its original authors.

---

## Master visual style (include in every image prompt)

> Premium Android Play Store image, 1080 x 1920 portrait. Near-black backdrop with a very deep green tint (#05110A to #000000) and only faint, out-of-focus leaf shadows. Large off-white editorial headline at the top left: bold sans first line, vivid spring-green second line (#0BF766, exactly the green in the app icon), followed by a short muted off-white subtitle. The app icon is a solid black square with a large white serif capital F, a vivid green circle at the lower right of the F, and a tiny grey four-point sparkle in the bottom-right corner — use this exact icon wherever an icon appears. A single slim-bezel modern Android phone centered below the headline showing the redesigned Freedium app. Marketing backdrop only — the app UI itself is paper-white or near-black, with a restrained Medium-green accent used only for small dots, links, switches and progress; hairline dividers; generous 24 px margins; Source Serif 4 headlines; Inter body text; Lucide line icons; no elevated cards. Crisp high-detail render, clean Play Store safe margins, natural soft lighting.

**Negative prompt (use for all images):**
> purple, lavender, violet, blue buttons, rounded card tiles, colorful gradients on UI surfaces, heavy drop shadows, handwriting annotations, cluttered toolbars, gibberish text, misspelled words, open book, paper pages, book illustration, extra logos, real Medium branding, paywall logos, subscription badges, ads, distorted phone, extra buttons, watermarks, low resolution

Do not copy the layout, colors or UI from the published screenshots. The only constants are: headline block at the top, phone centered below it, and the black / white / vivid-green icon palette.

---

## Feature graphic — 1024 x 500

> Wide Play Store feature graphic, 1024 x 500, no phone mockup. Near-black background with a very deep green tint (#05110A to #000000) and faint leaf shadows. On the left, a large two-line headline: "Read Medium." in bold off-white, "Freely." in vivid green (#0BF766) below it, with a small subtitle "Paste a link. Read the whole story." On the right, the Freedium app icon enlarged and reproduced exactly: a solid black square with a large white serif capital F, a vivid green circle (#0BF766) at the lower right of the F, and a tiny grey four-point sparkle in the bottom-right corner. Premium minimal editorial style, generous negative space, crisp vector-like detail, no small UI text, no purple.

---

## Phone screenshot prompts

### 1. Home — unlock a story

> [MASTER STYLE]. Headline: "Read Medium." / "Freely." Subtitle: "Paste a link. Read the whole story — no paywall, no clutter." Phone screen shows the redesigned Home page: a tiny green dot and uppercase eyebrow "READ WITHOUT NOISE", a large serif "Freedium" wordmark, a one-line muted tagline, uppercase label "ARTICLE URL", a single underline input with placeholder "https://medium.com/…" and a small clipboard button, and a solid near-black full-width "Unlock story" button. Below it, a three-step list ("Copy a link", "Paste it here", "Read in peace") separated by thin hairlines. Bottom tab bar: Home active with a small green dot, Library, Settings. No cards, no purple.

### 2. Reader — clean reading

> [MASTER STYLE]. Headline: "Just the words." / "Nothing else." Subtitle: "A calm, typographic reader built for long-form stories." Phone screen shows the reader on warm paper (#fbfaf7): a serif article headline and body text, a thin green reading-progress line directly under the top app bar, a top bar with a back arrow, "5 min read" and a filled green heart, and a bottom action strip with four Lucide icons labeled Style, Share, Browser, Refresh. Generous margins, no cards, no purple, no pop-ups.

### 3. Library — saved stories

> [MASTER STYLE]. Headline: "Save today." / "Read anytime." Subtitle: "Favorites stay on your device, ready without a connection." Phone screen shows the redesigned Library: uppercase eyebrow "SAVED STORIES", serif title "Your library", a single hairline search field with a small magnifier and placeholder "Search your library", then four or five simple list rows separated by hairlines — each row has a serif title, one muted metadata line (author · domain · date) and a small trash icon. Bottom tab bar: Library active with a green dot. No thumbnails, no cards, no purple.

### 4. Settings — make it yours

> [MASTER STYLE]. Headline: "Read your way." / "Every time." Subtitle: "Five reader themes, fonts and five sources — all under your control." Phone screen shows the redesigned Settings page: serif "Settings" title, uppercase section labels APPEARANCE, SOURCE and ABOUT, hairline rows with no cards. Rows: "Dark Mode" with a green switch, "Theme", "Reader Appearance", "Preferred Mirror" with the readable subtitle "Auto", "Automatic Fallback" with a green switch, "Send Feedback", "GitHub", "Version", "Licenses & Credits". Small Lucide chevrons on tappable rows. Bottom tab bar: Settings active with a green dot. No purple.

### 5. Reliability — five sources and offline copies

> [MASTER STYLE]. Headline: "Five ways in." / "Always a way through." Subtitle: "Automatic fallback and offline copies keep stories available." Phone screen shows the redesigned reader with a thin amber "Offline copy" banner near the top and a small "Retry" action, serif article text on warm paper below it, and the four-action bottom strip. A subtle secondary side note reads "Never lose a story". No cards, no purple, no error-page red.

---

## Image generation workflow

1. Generate the feature graphic first and use it only as a color/style reference for the phone images.
2. Generate each phone image separately so the on-screen text stays legible.
3. Do not attach the old published screenshots as references. If the generator requires a reference, describe the current UI in words instead.
4. Export phone images as PNG at 1080 x 1920 and the feature graphic at 1024 x 500.
5. Keep the headline inside the top 35% and the phone body centered — Play Store thumbnails crop to a square.

## Listing update notes

- Remove the old "Reading progress" and "Resume reading" claims: that feature is no longer in the app.
- Keep "Books & Reference" as the category unless you deliberately want to reposition to "News & Magazines".
- The trademark in the title is already approved on the live listing; keep it, and keep "Medium" in the short description and full description for ASO.

## Before you publish the update

- **Data safety:** the live listing currently says "no data collected / no data shared". Opening a story does send its URL to the selected mirror so it can fetch the article — that is necessary for the feature, not analytics. Declare that article URLs are shared with mirror providers for the core functionality, and keep "no data collected for advertising or analytics". This is more accurate and builds trust.
- **Privacy policy:** the Play listing links to a GitLab policy document. Make sure it matches `PRIVACY_POLICY.md` in this repo, including the mirror-URL detail above.
- **Support email:** this doc uses `birmehto@gmail.com`, which is the address the app uses for feedback. The live listing uses `birmehtodev@gmail.com`; pick one and make both match.
- **Release name:** keep the already-approved app name, but update the short and full descriptions together with the v1.3.0 APK so new users see the redesigned feature set immediately.

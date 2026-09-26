# Privacy Policy

**App:** Freedium
**Last updated:** September 26, 2026

Freedium is built around a simple principle: **your reading stays on your device.** We do not collect, sell, or share your personal data. We run no servers.

## What Freedium does

Freedium is a reader for Medium. You paste or share a Medium article URL, and Freedium loads the article through the **Freedium mirror network** (a third-party, publicly available reader service) to display it in a clean, ad-free reader.

You can optionally sign in to your Medium account to see your own profile on the Home screen. That is the only account feature, and it is entirely optional — the app works exactly the same without it.

## Data we do NOT collect

- ❌ No analytics, tracking, or crash-reporting SDKs
- ❌ No location data
- ❌ No advertising identifiers
- ❌ No unsolicited data uploads
- ❌ **We never see your Medium password.** Signing in happens on Medium's own page.

## Signing in to Medium

Medium does not offer an API for this, so sign-in happens on **Medium's own sign-in page**, inside the app.

- You type your credentials directly into Medium's page. They go to Medium and are never visible to Freedium.
- Medium then issues its normal session cookie. Freedium stores that cookie **on your device only** so you stay signed in between launches, and re-uses it to show your profile. It is never sent anywhere except back to Medium.
- Freedium reads only your **public** profile information to draw the card: display name, handle, bio, profile photo, follower count and post count.
- Signing out deletes the stored cookie and cached profile from your device. Medium's own session on their website is unaffected.
- Medium's sign-in page runs Medium's own scripts inside the app, exactly as it would in a browser. Medium's privacy policy applies to that.

## Data stored locally on your device

Everything below is saved **only on your device** in the app's local SQLite database (managed by Drift). Nothing is transmitted to us or to any server:

| What | Why it's stored |
|------|-----------------|
| Favorite articles (title, URL, author, domain) | So your favorites list is available without refetching |
| Cached article metadata (title, author, publication, word count, reading time) | So a favorited article renders instantly when you reopen it |
| Theme, reader theme, font family, and font size preferences | To remember your reading setup |
| Preferred mirror source and auto-fallback flag | So article loading behaves the way you configured it |
| App version | Displayed in the Settings screen |
| Medium session cookie (only if you sign in) | So you stay signed in and your profile card can load |
| Your cached Medium profile (only if you sign in) | So the Home screen can show your name, bio, photo and stats without refetching |

Article text and HTML are **not** stored — the reader loads each article over the network and discards it when you leave.

You can clear all of this anytime by removing favorites in the app, signing out of Medium, uninstalling it, or clearing the app data. Android cloud backup and device transfer are disabled, so this data does not leave the device.

## Data sent to third parties

- **Article URLs (Freedium mirror):** The article URL you choose to open is sent to the Freedium mirror network to fetch the article content. Freedium is an independent, open-source project **not affiliated with the mirror service**; its terms and privacy practices apply to that request.
- **Medium:** If you choose to sign in, your session goes to Medium and only to Medium. Freedium has no server of its own and never sees it.
- **Email / donations:** If you contact us by email or click "Buy me a coffee", you are sharing that information directly with the relevant service (email provider / Buy Me a Coffee) under their own terms.

## Third-party services

| Service | Purpose |
|---------|---------|
| Freedium mirror network | Fetching the article you requested |
| Medium | Signing in to your Medium account, if you choose to (under Medium's own privacy policy) |
| Buy Me a Coffee | Optional donations (via link in the app) |

We do not control and are not responsible for the privacy practices of these third parties.

## Permissions

Freedium requests the permissions it needs to work (e.g., sharing/receiving content from other apps) and nothing more. No permissions are used to access contacts, location, or media beyond what the app's core reading function requires.

## Children's privacy

Freedium does not knowingly collect any personal information from children. Signing in to a Medium account is optional and is not intended for children.

## Changes to this policy

We may update this policy occasionally. Any changes will be reflected on this page with a new "Last updated" date.

## Contact

Questions or concerns? Email us at **birmehto@gmail.com** or open a [GitHub issue](https://github.com/birmehto/Freedium/issues).
# Privacy Policy

**App:** Freedium
**Last updated:** September 15, 2026

Freedium is built around a simple principle: **your reading stays on your device.** We do not collect, sell, or share your personal data.

## What Freedium does

Freedium is a reader for Medium. You paste or share a Medium article URL, and Freedium loads the article through the **Freedium mirror network** (a third-party, publicly available reader service) to display it in a clean, ad-free reader.

## Data we do NOT collect

- ❌ No accounts, no sign-ups, no profiles
- ❌ No analytics, tracking, or crash-reporting SDKs
- ❌ No location data
- ❌ No advertising identifiers
- ❌ No unsolicited data uploads

## Data stored locally on your device

Everything below is saved **only on your device** in the app's local SQLite database (managed by Drift). Nothing is transmitted to us or to any server:

| What | Why it's stored |
|------|-----------------|
| Favorite articles (title, URL, author, domain) | So your favorites list is available without refetching |
| Cached article metadata (title, author, publication, word count, reading time) | So a favorited article renders instantly when you reopen it |
| Article text of the articles you read | So you can read them again without a connection (see below) |
| How far you got through each article, and when | So the app can offer to continue where you stopped |
| Theme, reader theme, font family, and font size preferences | To remember your reading setup |
| Preferred mirror source and auto-fallback flag | So article loading behaves the way you configured it |
| App version | Displayed in the Settings screen |

Saved article text never leaves your device. The offline copies are capped at 24 MB in total and 2 MB per article, and the oldest ones are dropped automatically as you read more — your favorites are never dropped. You can clear all saved articles at any time in **Settings → Offline Articles**, which leaves your favorites and reading positions untouched.

You can clear all of this anytime by removing favorites in the app, clearing offline articles in Settings, uninstalling, or clearing the app data. Android cloud backup and device transfer are disabled, so this data does not leave the device.

## Data sent to third parties

- **Article URLs (Freedium mirror):** The only data that ever leaves your device is the article URL you choose to open. It is sent to the Freedium mirror network to fetch the article content. Freedium is an independent, open-source project **not affiliated with the mirror service**; its terms and privacy practices apply to that request.
- **Email / donations:** If you contact us by email or click "Buy me a coffee", you are sharing that information directly with the relevant service (email provider / Buy Me a Coffee) under their own terms.

## Third-party services

| Service | Purpose |
|---------|---------|
| Freedium mirror network | Fetching the article you requested |
| Buy Me a Coffee | Optional donations (via link in the app) |

We do not control and are not responsible for the privacy practices of these third parties.

## Permissions

Freedium requests the permissions it needs to work (e.g., sharing/receiving content from other apps) and nothing more. No permissions are used to access contacts, location, or media beyond what the app's core reading function requires.

## Children's privacy

Freedium does not knowingly collect any personal information from children.

## Changes to this policy

We may update this policy occasionally. Any changes will be reflected on this page with a new "Last updated" date.

## Contact

Questions or concerns? Email us at **birmehto@gmail.com** or open a [GitHub issue](https://github.com/birmehto/Freedium/issues).
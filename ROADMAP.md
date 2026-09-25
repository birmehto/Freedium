# Freedium — Improvement Roadmap

This document defines the planned improvements for Freedium.

The goal is to make Freedium a reliable, polished, privacy-friendly, cross-platform reading application while keeping the existing **GetX-based state management architecture**.

---

## 1. Product Goals

Freedium should provide:

* Fast article loading
* Clean distraction-free reading
* Reliable mirror/source resolution
* Reading history
* Favorites and bookmarks
* Offline reading
* Reading progress
* Better search
* Better desktop experience
* Reliable error handling
* Good accessibility
* Strong automated testing
* Maintainable and future-proof code

---

## 2. Architecture Improvements

Keep the existing:

```text
GetX
Controllers
Models
Services
Views
Widgets
```

Improve consistency rather than replacing the architecture.

Recommended feature structure:

```text
lib/
├── app/
│   ├── bindings/
│   ├── routes/
│   └── theme/
│
├── core/
│   ├── config/
│   ├── constants/
│   ├── errors/
│   ├── extensions/
│   ├── network/
│   ├── storage/
│   ├── utils/
│   └── widgets/
│
├── features/
│   ├── home/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── services/
│   │   ├── views/
│   │   └── widgets/
│   │
│   ├── reader/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── services/
│   │   ├── views/
│   │   └── widgets/
│   │
│   ├── favorites/
│   ├── history/
│   ├── search/
│   ├── settings/
│   └── mirrors/
│
└── main.dart
```

### Architecture rules

* Controllers handle UI/application state.
* Services handle external operations.
* Models represent application data.
* Views should remain lightweight.
* Reusable UI belongs in widgets.
* Avoid putting networking logic directly inside widgets.
* Avoid large "god controllers".
* Keep platform-specific code isolated.
* Keep business logic testable.

---

## 3. Reader Improvements

### 3.1 Article Metadata

Display:

```text
Title
Author
Publication
Published date
Reading time
Word count
Reading progress
```

Example:

```text
The Future of Flutter

John Doe
Medium · Sep 18, 2026

8 min read

██████████░░ 78%
```

---

### 3.2 Reader Settings

Add:

* Font size
* Font family
* Line height
* Paragraph spacing
* Content width
* Text alignment
* Theme

Reader themes:

```text
System
Light
Dark
Sepia
OLED
```

---

### 3.3 Reading Progress

Track:

```text
Article
├── progress
├── scrollPosition
├── startedAt
├── lastReadAt
└── completedAt
```

When reopening an article:

```text
Continue from where you stopped?
```

---

### 3.4 Reader Actions

Add:

```text
Save
Favorite
Share
Copy link
Copy text
Open original
Find in article
```

---

## 4. Offline Reading

Implement article caching.

Flow:

```text
Open Article
      ↓
Fetch Article
      ↓
Process HTML
      ↓
Save Locally
      ↓
Display
```

When offline:

```text
Open Article
      ↓
Check Local Cache
      ↓
Available → Open
Unavailable → Show Offline Message
```

Cached article should contain:

```text
Article
├── HTML/content
├── title
├── author
├── source URL
├── thumbnail
├── savedAt
└── lastReadAt
```

---

## 5. Library

Create a dedicated Library screen.

```text
Library
├── Continue Reading
├── Favorites
├── Saved Articles
└── History
```

Example:

```text
Continue Reading

Building Scalable Flutter Apps
████████████░░░ 72%
Continue →

-------------------------

Favorites

Article 1
Article 2
Article 3
```

---

## 6. Reading History

Track recently opened articles.

Each history item:

```text
title
author
url
openedAt
lastReadAt
progress
completed
```

Actions:

```text
Open
Remove
Clear history
```

Add:

```text
Today
Yesterday
This Week
Earlier
```

---

## 7. Search Improvements

Improve search across local content.

Search:

* Article title
* Author
* Publication
* URL
* Tags

Example:

```text
Search articles...

Flutter architecture

Results

Building Scalable Flutter Apps
Advanced Riverpod Patterns
Flutter Performance Guide
```

Add:

```text
Recent searches
Clear search
No results state
Search loading state
```

---

## 8. Mirror / Source System

Improve mirror handling.

Create a dedicated source resolver:

```text
ArticleResolver
       │
       ├── Mirror A
       ├── Mirror B
       ├── Mirror C
       └── Future sources
```

Each source should provide:

```text
name
URL
availability
response time
last successful request
failure count
```

Resolver flow:

```text
Request Article
      ↓
Select Available Source
      ↓
Request
      ↓
Success → Return Article
      ↓
Failure
      ↓
Try Next Source
```

Avoid hardcoding mirror selection throughout controllers.

---

## 9. Error Handling

Create consistent application errors.

Examples:

```text
NetworkError
TimeoutError
InvalidUrlError
ArticleNotFoundError
MirrorUnavailableError
ParsingError
StorageError
```

User-facing states should be useful.

Example:

```text
Unable to load this article

The current source is unavailable.

[ Try Again ]
[ Try Another Source ]
```

Avoid showing raw exceptions to users.

---

## 10. Loading States

Replace generic loading wherever possible with contextual loading.

Examples:

```text
Fetching article...
Processing content...
Trying another source...
Saving article...
```

Use skeleton loading for:

* Article metadata
* Library
* History
* Search results

---

## 11. Empty States

Create consistent empty states.

Examples:

### No Favorites

```text
No favorites yet

Articles you save will appear here.

[ Browse Articles ]
```

### No History

```text
No reading history

Articles you read will appear here.
```

### No Search Results

```text
No articles found

Try another search term.
```

---

## 12. Share Flow

Improve sharing.

Support:

```text
Medium URL
Freedium URL
Article title
```

When receiving a shared Medium URL:

```text
Share
 ↓
Freedium
 ↓
Detect URL
 ↓
Resolve Article
 ↓
Open Reader
```

Handle:

* Invalid URLs
* Empty shares
* Multiple URLs
* Unsupported websites

---

## 13. URL Handling

Create a dedicated URL parser.

Support common Medium formats:

```text
medium.com/...
*.medium.com/...
medium.com/@user/...
```

Normalize URLs before processing.

Example:

```text
Original URL
      ↓
Remove tracking parameters
      ↓
Normalize
      ↓
Resolve
```

Add tests for URL parsing.

---

## 14. Performance

Focus on:

* Faster article loading
* WebView lifecycle management
* Avoid unnecessary rebuilds
* Dispose controllers correctly
* Avoid duplicate network requests
* Cache expensive operations
* Lazy-load large lists
* Avoid storing large HTML strings unnecessarily in reactive state
* Optimize image loading
* Reduce startup work

Measure before optimizing.

---

## 15. WebView Improvements

Improve the article WebView.

Handle:

```text
JavaScript
Navigation
External links
Downloads
Images
Text selection
Find in page
Back navigation
Loading progress
Errors
```

Prevent unwanted navigation where appropriate.

Provide:

```text
Open externally
```

for links that should leave the reader.

---

## 16. Accessibility

Improve accessibility across the app.

Support:

* Semantic labels
* Screen readers
* Large text
* Keyboard navigation
* Minimum touch target sizes
* Good contrast
* Reduced motion where possible
* Focus management on desktop

Avoid relying only on icons.

Example:

```text
❌ Icon only

✓ Icon + tooltip/semantic label
```

---

## 17. Desktop Experience

Support:

```text
Linux
macOS
Windows
```

Desktop should use a desktop-friendly layout rather than simply stretching the mobile UI.

Example:

```text
┌───────────────────────────────────────────────┐
│ Freedium                         Search  ⚙    │
├──────────────┬────────────────────────────────┤
│              │                                │
│ Home         │        Article                 │
│ Library      │                                │
│ History      │        Article content         │
│ Favorites    │                                │
│              │                                │
│ Settings     │                                │
│              │                                │
└──────────────┴────────────────────────────────┘
```

Use responsive breakpoints:

```text
Mobile
Tablet
Desktop
Large Desktop
```

---

## 19. Settings

Organize settings into sections.

```text
Settings

Appearance
├── Theme
├── Font
├── Font size
└── Reader width

Reading
├── Reading progress
├── Auto-save
└── Default reader settings

Network
├── Preferred source
├── Auto fallback
└── Cache

Storage
├── Cached articles
├── Cache size
└── Clear cache

About
├── Version
├── GitHub
├── Licenses
└── Privacy
```

---

## 20. Storage Improvements

Separate storage responsibilities.

Example:

```text
DeviceStorage
├── preferences
├── settings
└── lightweight values

ArticleStorage
├── cached articles
├── history
├── favorites
└── reading progress
```

Avoid putting all application data into one storage class.

---

## 21. Analytics

Keep analytics privacy-friendly.

Track only what is actually needed.

Potential metrics:

```text
Articles opened
Articles completed
Searches
Mirror success/failure
Average reading duration
```

Separate:

```text
App analytics
Reading statistics
GitHub repository traffic
Website traffic
```

Do not mix these numbers.

If a public counter is required, expose a clearly defined metric such as:

```text
Total article reads
```

rather than an ambiguous:

```text
Total visits
```

---

## 22. Privacy

Document clearly:

* What data is stored locally
* What data leaves the device
* Which external services are contacted
* Whether analytics are enabled
* How cached articles are stored
* How users can clear local data

Add a privacy policy if external analytics are introduced.

---

## 23. Testing

Increase automated coverage.

## Unit tests

Test:

```text
URL parser
Mirror resolver
Article parser
Reading progress
Storage
Search
Settings
```

## Controller tests

Test:

```text
loading
success
error
retry
fallback
empty states
```

## Widget tests

Test:

```text
Home
Reader
Library
Favorites
History
Search
Settings
```

## Integration tests

Important flows:

```text
Open shared URL
      ↓
Resolve article
      ↓
Open reader
      ↓
Save article
      ↓
Close
      ↓
Reopen from Library
```

---

## 24. Logging

Add structured logging.

Example:

```text
[Reader] Loading article
[Resolver] Trying Mirror A
[Resolver] Mirror A failed
[Resolver] Trying Mirror B
[Resolver] Mirror B succeeded
[Reader] Article loaded
```

Use different levels:

```text
debug
info
warning
error
```

Disable verbose production logging.

Never log sensitive user information unnecessarily.

---

## 25. Crash / Error Monitoring

Consider production monitoring for:

* Crashes
* WebView failures
* Network failures
* Platform-specific errors
* Unexpected exceptions

Make sure logs do not expose private article URLs or user data unless necessary.

---

## 26. UI Consistency

Create a consistent design system.

Centralize:

```text
Colors
Typography
Spacing
Radius
Elevation
Animations
Icons
Buttons
Cards
Dialogs
Empty states
Loading states
```

Avoid repeatedly defining values inside individual screens.

Example:

```text
AppButton
AppCard
AppDialog
AppEmptyState
AppLoader
AppErrorState
AppSection
```

---

## 27. Animations

Use subtle animations for:

* Page transitions
* Favorite changes
* Bookmark changes
* Loading
* Library updates
* Progress changes

Avoid animations that slow down reading.

---

## 28. Security

Review:

* URL validation
* WebView navigation
* JavaScript usage
* External links
* Local storage
* API endpoints
* Secrets
* Debug logging

Never put private API keys directly into the Flutter application.

---

## 29. CI/CD

Maintain automated checks for pull requests:

```text
flutter analyze
flutter test
flutter format --set-exit-if-changed
flutter build
```

Recommended pipeline:

```text
Pull Request
     ↓
Format check
     ↓
Analyze
     ↓
Unit tests
     ↓
Widget tests
     ↓
Build
```

Release:

```text
Tag
 ↓
CI
 ↓
Build platforms
 ↓
Create release
```

---

## 30. Documentation

Improve project documentation.

Add:

```text
README.md
CONTRIBUTING.md
ARCHITECTURE.md
PRIVACY.md
CHANGELOG.md
```

Document:

* Architecture
* GetX conventions
* Mirror system
* Article processing
* Storage
* Platform setup
* Development setup
* Release process

---

# Development Priority

## Phase 1 — Foundation

* [x] Clean existing GetX architecture
* [x] Standardize controllers
* [x] Standardize services
* [x] Standardize models
* [x] Improve error handling
* [x] Improve logging
* [x] Add missing tests

## Phase 2 — Reader

* [x] Article metadata
* [x] Better reader controls
* [x] Reader themes
* [ ] Find in article
* [x] Better WebView handling
* [x] Improved reading progress

## Phase 3 — Library

* [x] Favorites
* [ ] Bookmarks
* [ ] History
* [ ] Continue reading
* [ ] Reading progress
* [x] Search

## Phase 4 — Offline

* [ ] Article cache
* [ ] Offline reader
* [ ] Cache management
* [ ] Offline states
* [ ] Background cache cleanup

## Phase 5 — Reliability

* [x] Mirror resolver
* [x] Mirror health tracking
* [x] Automatic fallback
* [x] Retry system
* [x] Timeout handling
* [x] Better network states

## Phase 6 — Desktop

* [x] Responsive layout
* [x] Desktop navigation
* [ ] Window size handling
* [x] Desktop-specific reader
* [ ] Linux/macOS/Windows testing

## Phase 7 — Polish

* [x] Accessibility
* [ ] Animations
* [x] Loading states
* [x] Empty states
* [x] Error states
* [x] Performance optimization

---

# Definition of Done

A feature is considered complete when:

* [ ] UI is implemented
* [ ] Loading state exists
* [ ] Empty state exists
* [ ] Error state exists
* [ ] Retry behavior exists where applicable
* [x] GetX controller logic is separated from UI
* [x] Models/services are testable
* [ ] Android is tested
* [x] Desktop behavior is considered
* [x] Accessibility is considered
* [x] Documentation is updated
* [x] Tests pass
* [x] `flutter analyze` passes

---

# Long-Term Product Direction

Freedium should evolve from a simple article-opening utility into a complete reading application:

```text
                 Freedium
                    │
       ┌────────────┼────────────┐
       │            │            │
     Reader      Library      Discovery
       │            │            │
    Offline      History       Search
       │            │            │
    Progress     Favorites     Sources
       │            │            │
       └────────────┼────────────┘
                    │
              Cross Platform
                    │
       Android · Linux
       (desktop)
```

The existing **GetX + Controllers + Services + Models + Views + Widgets** approach should remain the foundation. The priority is to make that architecture more consistent, modular, testable, and scalable rather than replacing the state-management solution.
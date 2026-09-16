# Release Notes - v1.1.1

## ✨ What's New in v1.1.1

- **🏛️ Clean Architecture & Feature-First Separation** — Restructured all modules into Domain, Data, and Presentation subdirectories to ensure maximum modularity and standard codebase cleanliness.
- **📱 Native Share Intent Integration** — Integrated the cross-platform `receive_sharing_intent` package and fully cleaned up the Android/iOS native files to standard defaults.
- **🎨 Material 3 Expressive UI** — Every screen rebuilt on the `material_3_expressive` design system: dynamic color, expressive navigation bar, M3E app bars, text fields, cards, buttons, dialogs and switches.
- **🛠️ Automated release script** — `./scripts/release.sh` builds the universal APK plus all per-ABI splits and publishes the GitHub release in one command.
- **⚡ Advanced Reading Features**:
  - **💾 Persistent Scroll Position** — Remembers and resumes reading coordinates upon page loads.
  - **🔄 Engine Auto-Failover** — Integrated three mirror bypass servers with automatic error redirection.
  - **📊 Active Reading Progress** — Displays real-time reading progress indicators.
- **🐛 Fixes** — Settings tests now properly mock storage; CI-compatible testing across environments.
# CLAUDE.md

## Project Overview

Janell's Run is an iOS app for tracking running workouts, race results, and personal records. Named for a specific user (Janell) -- the app display name is "Janell's Run".

## Build & Run

- Open `JanellsRunApp.xcodeproj` in Xcode (no SPM dependencies, no CocoaPods)
- Build: `xcodebuild -project JanellsRunApp.xcodeproj -scheme JanellsRunApp -sdk iphonesimulator build`
- Test: `xcodebuild test -project JanellsRunApp.xcodeproj -scheme JanellsRunApp -destination 'platform=iOS Simulator,name=<an installed iPhone>' -only-testing:JanellsRunAppTests`
- `JanellsRunAppTests` holds unit tests (Swift Testing) for the utilities and preferences; CI runs them on every PR
- `JanellsRunAppUITests` is an Athlinks import smoke test that calls the live Athlinks site; it is not run in CI
- The Xcode project uses file-system-synchronized groups, so new files are picked up without editing `project.pbxproj`
- HealthKit requires a physical device -- it is unavailable in the Simulator

## Tech Stack

- **UI:** SwiftUI (no UIKit except in Theme.swift for dynamic trait colors)
- **Persistence:** SwiftData with CloudKit sync (`cloudKitDatabase: .automatic`)
- **Auth:** Sign in with Apple, credentials stored in Keychain
- **Health:** HealthKit (read-only -- running workouts and distance)
- **Athlinks:** race results fetched from an undocumented athlinks.com endpoint (`AthlinksService`, `AthlinksImporter`)
- **Feedback:** in-app bug reports and feature requests go to a Cloudflare Worker (`cloudflare-worker/`) that files them as issues in this public repo
- **Language:** Swift 5, iOS 17+

## Architecture

No third-party dependencies in the app. The project uses a flat, feature-based structure:

```
Models/       SwiftData @Model classes: Run, RaceEvent, HealthKitWorkout
Views/        SwiftUI views grouped by feature (Add, Auth, History, Records, Runs, Shared)
Services/     AuthService (Apple sign-in + Keychain), HealthKitService, AthlinksService,
              FeedbackService, UserPreferences (UserDefaults-backed settings)
Utilities/    CSVImporter, CSVExporter, AthlinksImporter, DuplicateChecker, DistancePresets,
              PersonalRecords, EventSearch, SampleData, TimeFormatter
```

Outside the app target: `cloudflare-worker/` (feedback Worker, deployed by hand with `wrangler deploy`) and `docs/privacy-policy.html` (the published privacy policy -- update it when the app starts sending data anywhere new).

### Key patterns
- `@Observable` classes for services (AuthService, HealthKitService)
- `@Model` classes for persisted data (Run, RaceEvent). CloudKit sync requires every stored property to be optional or have a default
- SwiftData `ModelContainer` is created in the App struct and injected via `.modelContainer()`. If it can't be opened the app shows `StoreUnavailableView` with a retry instead of crashing
- Theme colors are defined in `Views/Shared/Theme.swift`

### Data model
- **Run** -- core model. Tracks distance (miles), duration (seconds), date, isRace flag, optional notes, optional link to RaceEvent, HealthKit workout ID and Athlinks result ID
- **RaceEvent** -- groups runs by named race with location and typical distance. Has inverse relationship to Run
- **HealthKitWorkout** -- lightweight struct (not persisted) used as a DTO when importing from HealthKit

### Distances
All distances are in **miles**. Standard race presets are defined in `Utilities/DistancePresets.swift` (5K=3.1, 8K=4.97, 10K=6.2, Half=13.1, Marathon=26.2).

## Entitlements

The app uses these capabilities (configured in `JanellsRunApp.entitlements`):
- Sign in with Apple
- HealthKit
- CloudKit (iCloud)
- Push Notifications (remote-notification background mode)

## Style Guide

- Follow existing SwiftUI/SwiftData conventions in the codebase
- Use `Theme.*` colors rather than hardcoded color values
- Views should be small -- extract subviews when body grows beyond ~40 lines
- Distances are always in miles at the data layer

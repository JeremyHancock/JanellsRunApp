# CLAUDE.md

## Project Overview

Janell's Run is an iOS app for tracking running workouts, race results, and personal records. Named for a specific user (Janell) -- the app display name is "Janell's Run".

## Build & Run

- Open `JanellsRunApp.xcodeproj` in Xcode (no SPM dependencies, no CocoaPods)
- Build: `xcodebuild -project JanellsRunApp.xcodeproj -scheme JanellsRunApp -sdk iphonesimulator build`
- No test target exists yet
- HealthKit requires a physical device -- it is unavailable in the Simulator

## Tech Stack

- **UI:** SwiftUI (no UIKit except in Theme.swift for dynamic trait colors)
- **Persistence:** SwiftData with CloudKit sync (`cloudKitDatabase: .automatic`)
- **Auth:** Sign in with Apple, credentials stored in Keychain
- **Health:** HealthKit (read-only -- running workouts and distance)
- **Language:** Swift 5, iOS 17+

## Architecture

No third-party dependencies. The project uses a flat, feature-based structure:

```
Models/       SwiftData @Model classes: Run, RaceEvent, HealthKitWorkout
Views/        SwiftUI views grouped by feature (Add, Auth, History, Records, Runs, Shared)
Services/     AuthService (Apple sign-in + Keychain), HealthKitService
Utilities/    CSVImporter, DistancePresets, SampleData, TimeFormatter
```

### Key patterns
- `@Observable` classes for services (AuthService, HealthKitService)
- `@Model` classes for persisted data (Run, RaceEvent)
- SwiftData `ModelContainer` is created in the App struct and injected via `.modelContainer()`
- Theme colors are defined in `Views/Shared/Theme.swift`

### Data model
- **Run** -- core model. Tracks distance (miles), duration (seconds), date, isRace flag, optional notes, optional link to RaceEvent and HealthKit workout ID
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

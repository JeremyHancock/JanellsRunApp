# Janell's Run

An iOS app for tracking running workouts, race results, and personal records. Built with SwiftUI and SwiftData.

## Features

- **Log Runs** -- manually add training runs and races with distance, time, and notes
- **Import Runs** -- bring in data via CSV or Apple HealthKit
- **Personal Records** -- automatically tracks PRs across standard distances
- **Race History** -- view past race events with detailed results
- **iCloud Sync** -- data syncs across devices via CloudKit
- **Sign in with Apple** -- authentication with secure Keychain credential storage

## Requirements

- iOS 17.0+
- Xcode 15.0+
- An Apple Developer account (for Sign in with Apple, HealthKit, and CloudKit entitlements)

## Getting Started

1. Clone the repository:
   ```
   git clone https://github.com/JeremyHancock/JanellsRunApp.git
   ```
2. Open `JanellsRunApp.xcodeproj` in Xcode.
3. Select your development team under **Signing & Capabilities**.
4. Build and run on a simulator or device.

> **Note:** HealthKit is not available in the Simulator. Use a physical device to test workout imports.

## Architecture

The app uses SwiftUI with SwiftData for persistence and follows a straightforward structure:

```
JanellsRunApp/
  Models/         # SwiftData models (Run, RaceEvent, HealthKitWorkout)
  Views/          # SwiftUI views organized by feature
    Add/          #   Adding and importing runs
    Auth/         #   Login and profile
    History/      #   Race event history
    Records/      #   Personal records
    Runs/         #   Run list and detail
    Shared/       #   Theme, reusable components
  Services/       # AuthService, HealthKitService
  Utilities/      # CSV importer, distance presets, formatting
```

## Contributing

See [CONTRIBUTING.md](.github/CONTRIBUTING.md) for guidelines on how to contribute.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

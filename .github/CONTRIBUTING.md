# Contributing to Janell's Run

Thanks for your interest in contributing! Here's how to get started.

## Setting Up

1. Fork the repository and clone your fork.
2. Open `JanellsRunApp.xcodeproj` in Xcode 15+.
3. Set your development team under **Signing & Capabilities**.
4. Build and run to make sure everything works before making changes.

## Making Changes

1. Create a branch from `main`:
   ```
   git checkout -b your-branch-name
   ```
2. Make your changes, keeping commits focused and descriptive.
3. Test on both a simulator and a physical device when possible (HealthKit requires a real device).
4. Push your branch and open a pull request.

## Pull Request Guidelines

- Keep PRs focused on a single change.
- Describe **what** changed and **why** in the PR description.
- Include screenshots for any UI changes.
- Make sure the project builds without warnings.

## Reporting Bugs

Use the [Bug Report](https://github.com/JeremyHancock/JanellsRunApp/issues/new?template=bug_report.md) issue template. Include:

- Steps to reproduce
- Expected vs. actual behavior
- Device, iOS version, and app version

## Requesting Features

Use the [Feature Request](https://github.com/JeremyHancock/JanellsRunApp/issues/new?template=feature_request.md) issue template. Describe the problem you're solving and your proposed solution.

## Code Style

- Follow standard Swift conventions and the existing patterns in the codebase.
- Use SwiftUI and SwiftData APIs (no UIKit unless necessary).
- Keep views small -- extract subviews when a body exceeds ~40 lines.

## Questions?

Open a [discussion](https://github.com/JeremyHancock/JanellsRunApp/discussions) or file an issue.

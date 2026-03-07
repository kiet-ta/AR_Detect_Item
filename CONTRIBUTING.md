# Contributing to Magic Doodle

Thank you for your interest in contributing! This guide will help you get started.

## Development Setup

1. Ensure you have [Flutter 3.27.0](https://flutter.dev/docs/get-started/install) installed.
2. Fork and clone the repository.
3. Copy `.env.example` to `.env` and fill in your Firebase credentials.
4. Run `flutter pub get` to install dependencies.
5. Run `dart run build_runner build --delete-conflicting-outputs` for code generation.

## Branching Strategy

- `main` — stable release branch.
- `develop` — integration branch for upcoming releases.
- Feature branches — `feature/<short-description>` off `develop`.
- Bug fix branches — `fix/<short-description>` off `develop`.

## Making Changes

1. Create a feature or fix branch from `develop`.
2. Make your changes following the existing code style and architecture.
3. Ensure all tests pass: `flutter test`.
4. Verify formatting: `dart format --output=none --set-exit-if-changed lib/ test/`.
5. Run analysis: `flutter analyze --fatal-infos`.
6. Commit using [Conventional Commits](https://www.conventionalcommits.org/):
   - `feat:` for new features
   - `fix:` for bug fixes
   - `docs:` for documentation changes
   - `refactor:` for code refactoring
   - `test:` for adding/updating tests
   - `chore:` for maintenance tasks

## Architecture Rules

- **Domain layer** must have zero external dependencies (no Flutter, Firebase, or TFLite imports).
- **Data layer** implements domain repository contracts.
- **Presentation layer** consumes domain use cases via BLoC.
- Never import upward in the dependency chain.

## Pull Requests

1. Fill in the PR template with a clear description of your changes.
2. Link any related issues.
3. Ensure CI passes before requesting review.
4. Keep PRs focused — one feature or fix per PR.

## Reporting Issues

- Use the provided issue templates for bug reports and feature requests.
- Include reproduction steps for bugs.
- Search existing issues before creating a new one.

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

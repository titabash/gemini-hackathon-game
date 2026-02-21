# Frontend

A new Flutter project with clean architecture and modern state management.

## Features

- **Clean Architecture**: Following the feature-sliced design pattern
- **State Management**: Using Riverpod for global state management
- **Hooks**: Using Flutter Hooks for widget state and side effects
- **Code Generation**: Automated provider generation with Riverpod

## Architecture Rules

- **No StatefulWidget**: Use HookConsumerWidget instead
- **State Management**: Use Riverpod providers for all state
- **Side Effects**: Use flutter_hooks (useEffect, useAnimationController, etc.)

## Dependencies

- `hooks_riverpod`: State management with Riverpod
- `flutter_hooks`: React-style hooks for Flutter
- `riverpod_annotation`: Annotations for code generation
- `riverpod_generator`: Code generation for providers

## Getting started

1. Install dependencies:
```bash
flutter pub get
```

2. Generate provider code:
```bash
dart run build_runner build
```

3. Run the app:
```bash
flutter run
```

## Code Generation

When adding new Riverpod providers with annotations, run:
```bash
dart run build_runner build --delete-conflicting-outputs
```

## Project Structure

```
lib/
├── app/           # App-level configuration
├── entities/      # Business entities
├── features/      # Feature modules
├── pages/         # Screen pages
├── shared/        # Shared utilities
└── widgets/       # Reusable widgets
```

This project is a starting point for a Flutter application.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

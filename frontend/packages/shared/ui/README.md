# shared_ui

Shared UI components for all applications.

## Features

- Material Design components
- Consistent theming across apps
- Reusable widgets

## Components

### AppButton
Customizable button widget with consistent styling.

```dart
AppButton(
  text: 'Click me',
  onPressed: () {},
)
```

### AppTheme
Material Design theme configuration.

```dart
MaterialApp(
  theme: AppTheme.lightTheme,
  // ...
)
```

## Installation

This package is part of the monorepo and is automatically linked via Melos.

```yaml
dependencies:
  shared_ui:
```

## Development

```bash
# Run tests
cd packages/shared/ui
flutter test

# Run with coverage
flutter test --coverage
```

## Dependencies

- Flutter SDK
- Material Design

## License

[Your License]

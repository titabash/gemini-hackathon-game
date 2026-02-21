---
name: flutter-feature
description: Create new features following Feature Sliced Design (FSD) architecture. Use when scaffolding a new feature with api/model/ui segments in the Flutter monorepo.
---

# Flutter Feature Creation Skill

Create a new feature following Feature Sliced Design (FSD) architecture in the Flutter monorepo.

## Task

You will create a new feature in `frontend/apps/web/lib/features/{feature_name}/` with the following FSD structure:

### Directory Structure

```
features/{feature_name}/
├── api/              # External API integrations and data fetching
├── model/            # State management, business logic, domain services
└── ui/               # UI components, widgets, presentation layer
```

## Implementation Steps

1. **Gather Requirements**:
   - Ask the user for the feature name (e.g., "profile", "settings", "notifications")
   - Ask what functionality this feature should provide
   - Ask if it needs API integration, state management, or both

2. **Create Directory Structure**:
   ```bash
   mkdir -p frontend/apps/web/lib/features/{feature_name}/api
   mkdir -p frontend/apps/web/lib/features/{feature_name}/model
   mkdir -p frontend/apps/web/lib/features/{feature_name}/ui
   ```

3. **Create Model Layer** (if state management is needed):
   - Create Freezed models in `model/` for data classes
   - Create Riverpod providers in `model/` for state management
   - Use `riverpod_annotation` with code generation

4. **Create API Layer** (if backend integration is needed):
   - Create API service functions in `api/`
   - Use Dio/Retrofit from `core_api` package
   - Return Future or Stream types

5. **Create UI Layer**:
   - Create main feature screen/page
   - Create reusable widgets specific to this feature
   - Use Riverpod hooks for state consumption

6. **Code Generation**:
   ```bash
   cd frontend/apps/web
   dart run build_runner build --delete-conflicting-outputs
   ```

7. **Quality Checks**:
   ```bash
   make check-flutter
   ```

## Example: Creating a "Profile" Feature

### Model Layer Example (`model/profile_provider.dart`):

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_provider.g.dart';

@riverpod
class Profile extends _$Profile {
  @override
  Future<UserProfile> build() async {
    // Load user profile
    return ref.watch(userProfileProvider);
  }

  Future<void> updateProfile(UserProfile profile) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // Update profile logic
      return profile;
    });
  }
}
```

### UI Layer Example (`ui/profile_screen.dart`):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProfileScreen extends HookConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        data: (profile) => ProfileContent(profile: profile),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
```

### API Layer Example (`api/profile_service.dart`):

```dart
import 'package:core_api/core_api.dart';

class ProfileService {
  const ProfileService(this._apiClient);

  final BackendApiClient _apiClient;

  Future<UserProfile> getProfile(String userId) async {
    final response = await _apiClient.getProfile(userId);
    return UserProfile.fromJson(response.data);
  }

  Future<void> updateProfile(String userId, UserProfile profile) async {
    await _apiClient.updateProfile(userId, profile.toJson());
  }
}
```

## Best Practices

1. **FSD Segment Rules**:
   - `api/`: External integrations, data fetching, backend communication
   - `model/`: Business logic, state management, domain services
   - `ui/`: Presentation layer, widgets, screens

2. **Dependencies**:
   - Features can depend on `entities/` (shared business entities)
   - Features can depend on `shared/` (shared utilities)
   - Features should NOT depend on other features
   - Features should use core packages (`core_api`, `core_auth`, etc.)

3. **State Management**:
   - Use Riverpod with `riverpod_annotation` for code generation
   - Use `AsyncValue` for async operations
   - Keep state management in `model/` layer

4. **Testing**:
   - Create `test/features/{feature_name}/` directory
   - Test model layer with unit tests
   - Test UI layer with widget tests
   - Mock external dependencies

5. **Code Generation**:
   - Always run `dart run build_runner build` after creating providers/models
   - Check for `.g.dart` and `.freezed.dart` files

## Common Pitfalls

- ❌ Don't put business logic in UI layer
- ❌ Don't create circular dependencies between features
- ❌ Don't forget to run code generation
- ❌ Don't hardcode strings (use i18n from `core_i18n`)
- ❌ Don't skip quality checks

## Notes

- This skill follows the Feature Sliced Design (FSD) methodology
- See CLAUDE.md for complete architecture guidelines
- Always check existing features for reference implementations

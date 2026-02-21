---
name: flutter-model
description: Create type-safe immutable data models using Freezed. Use when creating domain models, DTOs, or state classes with JSON serialization support.
---

# Flutter Model Creation Skill

Create type-safe immutable data models using Freezed for Flutter applications.

## Task

You will create a Freezed model class with the following capabilities:
- Immutable data classes with copyWith
- JSON serialization/deserialization
- Union types and sealed classes (if needed)
- Equality and hashCode generation

## Implementation Steps

1. **Gather Requirements**:
   - Ask for the model name (e.g., "UserProfile", "Product", "Order")
   - Ask for the fields and their types
   - Ask if JSON serialization is needed
   - Ask if union types are needed (for state modeling)

2. **Create Model File**:
   - Location: `{package}/lib/models/{model_name}.dart`
   - Use snake_case for file names
   - Use PascalCase for class names

3. **Implement Freezed Model**:
   ```dart
   import 'package:freezed_annotation/freezed_annotation.dart';

   part '{model_name}.freezed.dart';
   part '{model_name}.g.dart'; // Only if JSON serialization is needed

   @freezed
   class ModelName with _$ModelName {
     const factory ModelName({
       required String id,
       required String name,
       String? description,
     }) = _ModelName;

     factory ModelName.fromJson(Map<String, dynamic> json) =>
         _$ModelNameFromJson(json);
   }
   ```

4. **Run Code Generation**:
   ```bash
   cd frontend
   dart run build_runner build --delete-conflicting-outputs
   ```

5. **Verify Generated Files**:
   - Check for `.freezed.dart` file (always generated)
   - Check for `.g.dart` file (only if JSON serialization)

6. **Quality Checks**:
   ```bash
   make check-flutter
   ```

## Example: User Profile Model

### Basic Model with JSON Serialization:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

/// User profile data model
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    /// User ID (Supabase User ID)
    required String id,

    /// User email
    required String email,

    /// Display name
    String? displayName,

    /// Avatar URL
    String? avatarUrl,

    /// Account creation timestamp
    required DateTime createdAt,

    /// Last update timestamp
    DateTime? updatedAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
```

### Union Type for State Modeling:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

/// Authentication state union type
@freezed
class AuthState with _$AuthState {
  /// User is not authenticated
  const factory AuthState.unauthenticated() = _Unauthenticated;

  /// User is authenticated
  const factory AuthState.authenticated({
    required String userId,
    required String email,
  }) = _Authenticated;

  /// Authentication is in progress
  const factory AuthState.loading() = _Loading;

  /// Authentication error occurred
  const factory AuthState.error({
    required String message,
  }) = _Error;
}
```

### Model with Default Values:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_settings.freezed.dart';
part 'notification_settings.g.dart';

@freezed
class NotificationSettings with _$NotificationSettings {
  const factory NotificationSettings({
    /// Enable push notifications
    @Default(true) bool pushEnabled,

    /// Enable email notifications
    @Default(true) bool emailEnabled,

    /// Enable in-app notifications
    @Default(true) bool inAppEnabled,

    /// Notification categories
    @Default([]) List<String> categories,
  }) = _NotificationSettings;

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingsFromJson(json);
}
```

### Model with Custom JSON Keys:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

@freezed
class Product with _$Product {
  const factory Product({
    required String id,

    required String name,

    /// Custom JSON key mapping
    @JsonKey(name: 'product_price') required double price,

    /// Custom JSON key with default value
    @JsonKey(name: 'is_available', defaultValue: true) required bool available,

    /// Exclude from JSON serialization
    @JsonKey(includeFromJson: false, includeToJson: false) String? localCache,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}
```

## Usage Examples

### Creating Instances:

```dart
// Create instance
final profile = UserProfile(
  id: 'user-123',
  email: 'user@example.com',
  displayName: 'John Doe',
  createdAt: DateTime.now(),
);

// CopyWith (immutable updates)
final updated = profile.copyWith(
  displayName: 'Jane Doe',
  updatedAt: DateTime.now(),
);
```

### JSON Serialization:

```dart
// From JSON
final json = {
  'id': 'user-123',
  'email': 'user@example.com',
  'created_at': '2024-01-15T00:00:00Z',
};
final profile = UserProfile.fromJson(json);

// To JSON
final jsonData = profile.toJson();
```

### Pattern Matching (Union Types):

```dart
final authState = AuthState.authenticated(
  userId: 'user-123',
  email: 'user@example.com',
);

// Pattern matching with when
authState.when(
  unauthenticated: () => print('Not logged in'),
  authenticated: (userId, email) => print('Logged in as $email'),
  loading: () => print('Loading...'),
  error: (message) => print('Error: $message'),
);

// Pattern matching with map
final message = authState.map(
  unauthenticated: (_) => 'Please log in',
  authenticated: (state) => 'Welcome ${state.email}',
  loading: (_) => 'Loading...',
  error: (state) => 'Error: ${state.message}',
);
```

## Best Practices

1. **Field Documentation**:
   - Add documentation comments for each field
   - Use `///` doc comments, not `//`
   - Describe the purpose and constraints

2. **Required vs Optional**:
   - Use `required` for mandatory fields
   - Use `Type?` for optional fields
   - Use `@Default(value)` for default values

3. **JSON Serialization**:
   - Only add `.g.dart` part if JSON serialization is needed
   - Use `@JsonKey` for custom mapping
   - Handle DateTime/Duration/custom types appropriately

4. **Union Types**:
   - Use for state modeling (loading, success, error)
   - Use for mutually exclusive variants
   - Use `when()` for exhaustive pattern matching

5. **Naming Conventions**:
   - Model classes: PascalCase (e.g., `UserProfile`)
   - Fields: camelCase (e.g., `createdAt`)
   - Files: snake_case (e.g., `user_profile.dart`)

6. **Location**:
   - Core models: `packages/core/{package}/lib/models/`
   - Feature models: `apps/web/lib/features/{feature}/model/`
   - Entity models: `apps/web/lib/entities/{entity}/model/`

## Common Pitfalls

- ❌ Don't forget to add `part` directives
- ❌ Don't forget to run code generation after creating models
- ❌ Don't use mutable fields (no setters)
- ❌ Don't put business logic in models (use services/providers)
- ❌ Don't create models for everything (simple types don't need Freezed)

## Code Generation Issues

If code generation fails:

1. **Missing part files**:
   ```dart
   part 'model_name.freezed.dart';
   part 'model_name.g.dart'; // Only if JSON serialization
   ```

2. **Analyzer errors after generation**:
   - Add to `analysis_options.yaml`:
   ```yaml
   errors:
     non_abstract_class_inherits_abstract_member: ignore
   ```

3. **Regenerate if needed**:
   ```bash
   cd frontend
   dart run build_runner clean
   dart run build_runner build --delete-conflicting-outputs
   ```

## Notes

- Freezed is the standard for immutable data classes in this project
- All domain models should use Freezed
- See existing models in `packages/core/polar/lib/models/` for reference
- Check `analysis_options.yaml` for Freezed-specific analyzer suppressions

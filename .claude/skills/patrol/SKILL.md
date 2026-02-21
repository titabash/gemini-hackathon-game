---
name: patrol
description: Patrol E2E testing framework for Flutter. Use when writing E2E tests, testing OTP authentication flows, or setting up Patrol test infrastructure.
---

# Patrol E2E Testing Skill

Patrol is a powerful, open-source UI testing framework designed specifically for Flutter apps. This skill provides guidance on writing and running E2E tests with Patrol in this Flutter boilerplate project.

## Overview

Patrol is equivalent to Maestro for React/React Native projects, providing:

- **Native Automation**: Interact with permission dialogs, notifications, and system settings
- **Cross-Platform**: Supports iOS, Android, macOS, and Web
- **Flutter-First**: Built specifically for Flutter with full widget testing support
- **Hot Restart**: Faster test execution during development
- **Type-Safe**: Write tests in Dart with full IDE support

## Prerequisites

### Install Patrol CLI

Patrol CLIは`make init`で自動的にインストールされます。

手動でインストール/再インストールする場合:

```bash
# Install patrol_cli globally
make patrol-install

# Or manually:
flutter pub global activate patrol_cli

# Verify installation
patrol doctor
```

### Ensure PATH Configuration

Add Flutter's global pub cache to your PATH:

```bash
# Add to ~/.bashrc or ~/.zshrc
export PATH="$PATH:$HOME/.pub-cache/bin"
```

## Test Structure

```
frontend/apps/web/patrol_test/
├── auth_otp_test.dart          # OTP認証E2Eテスト
├── smoke_test.dart             # スモークテスト
├── helpers/
│   └── mailpit_client.dart     # Mailpit APIクライアント
└── scripts/
    └── otp_server.js           # CORSプロキシサーバー
```

## CRITICAL: Supabase Initialization

**重要**: Patrol テストでは `main()` を呼ばず直接 `App()` をpumpするため、`Supabase.initialize()` が実行されません。テスト内で明示的に初期化する必要があります。

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'http://127.0.0.1:54321',
);
const _supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'your-anon-key',
);

void main() {
  patrolTest(
    'Test description',
    ($) async {
      // ✅ REQUIRED: Initialize Supabase first
      await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);

      // Then pump the app
      await $.pumpWidgetAndSettle(
        ProviderScope(
          child: TranslationProvider(child: const AuthListener(child: App())),
        ),
      );

      // ... test code
    },
  );
}
```

## Running Tests

### Web Platform

```bash
cd frontend/apps/web

# 基本実行
patrol test --device chrome --target patrol_test/auth_otp_test.dart \
  --dart-define-from-file=../../../env/frontend/local.json

# Verbose モード（デバッグ用）
patrol test --device chrome --target patrol_test/auth_otp_test.dart \
  --dart-define-from-file=../../../env/frontend/local.json --verbose
```

### Mobile/Desktop

```bash
# macOS
patrol test -d macos --target patrol_test/auth_otp_test.dart \
  --dart-define-from-file=../../../env/frontend/local.json

# iOS Simulator
patrol test -d ios --target patrol_test/auth_otp_test.dart \
  --dart-define-from-file=../../../env/frontend/local.json
```

---

## OTP Authentication Testing

### Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Patrol Test    │────▶│  Supabase Auth  │────▶│    Mailpit      │
│  (Browser)      │     │  (localhost:    │     │  (localhost:    │
│                 │     │   54321)        │     │   54324)        │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │                                               │
         │         ┌─────────────────┐                   │
         └────────▶│  OTP Proxy      │◀──────────────────┘
                   │  (localhost:    │
                   │   54399)        │
                   └─────────────────┘
```

### CORS Issue on Web

Web ブラウザでは CORS により、テストコードから直接 Mailpit API (localhost:54324) にアクセスできません。

**解決策**: Node.js プロキシサーバーを経由して CORS ヘッダーを追加

### Setup

#### 1. Start Supabase (with Mailpit)

```bash
make run
```

Mailpit UI: http://localhost:54324

#### 2. Start OTP Proxy Server

```bash
cd frontend/apps/web
node patrol_test/scripts/otp_server.js
```

Output:
```
OTP proxy server running on http://localhost:54399
Endpoints:
  GET  /otp?email=xxx    - Wait for and return OTP
  DELETE /emails?email=xxx - Delete emails for recipient
```

#### 3. Run Test

```bash
cd frontend/apps/web
patrol test --device chrome --target patrol_test/auth_otp_test.dart \
  --dart-define-from-file=../../../env/frontend/local.json
```

### OTP Test Flow

1. **Initialize Supabase** - テスト開始時にSupabaseを初期化
2. **Navigate to Login** - ログインページへ遷移
3. **Enter Email** - メールアドレス入力
4. **Send OTP** - 「認証コードを送信」ボタンをタップ
5. **Wait for Email** - Mailpitからメール受信を待機
6. **Extract OTP** - メール本文から6桁コードを抽出
7. **Enter OTP** - OTPコードを入力
8. **Verify Login** - ログインボタンをタップし、認証完了を確認

### MailpitClient Usage

```dart
import 'helpers/mailpit_client.dart';

final mailpit = MailpitClient(proxyUrl: 'http://localhost:54399');

// Wait for OTP (uses proxy to avoid CORS)
final otp = await mailpit.waitForOtp(
  email: 'test@example.com',
  timeout: const Duration(seconds: 30),
  useProxy: true,  // Use proxy for web, false for native
);

// Delete test emails (cleanup)
await mailpit.deleteEmailsForRecipient('test@example.com', useProxy: true);
```

### Complete OTP Test Example

```dart
import 'package:core_auth/core_auth.dart';
import 'package:core_i18n/core_i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:patrol/patrol.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web_app/app/app.dart';

import 'helpers/mailpit_client.dart';

const _testEmail = 'patrol-test@example.com';
const _proxyUrl = 'http://localhost:54399';

const _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'http://127.0.0.1:54321',
);
const _supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'your-anon-key',
);

void main() {
  patrolTest(
    'OTP Authentication - Complete login flow',
    tags: ['auth', 'web', 'e2e'],
    ($) async {
      // Initialize Supabase (REQUIRED)
      await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);

      final mailpit = MailpitClient(proxyUrl: _proxyUrl);

      // Start the app
      await $.pumpWidgetAndSettle(
        ProviderScope(
          child: TranslationProvider(child: const AuthListener(child: App())),
        ),
      );

      // Navigate to login page
      final loginButton = $(find.text('ログイン'));
      if (loginButton.exists) {
        await loginButton.tap();
        await $.pumpAndSettle();
      }

      // Enter email
      final emailField = $(find.byType(TextField)).first;
      await emailField.enterText(_testEmail);
      await $.pumpAndSettle();

      // Send OTP
      final sendOtpButton = $(find.text('認証コードを送信'));
      await sendOtpButton.tap();
      await $.pumpAndSettle();
      await $.pump(const Duration(seconds: 3));

      // Get OTP from Mailpit
      final otp = await mailpit.waitForOtp(
        email: _testEmail,
        timeout: const Duration(seconds: 30),
        useProxy: true,
      );
      expect(otp, isNotNull, reason: 'OTP not received');

      // Enter OTP
      final otpField = $(find.byType(TextField)).first;
      await otpField.enterText(otp!);
      await $.pumpAndSettle();

      // Verify login
      final verifyButton = $(find.text('ログイン'));
      await verifyButton.tap();
      await $.pumpAndSettle();
      await $.pump(const Duration(seconds: 3));

      // Assert: No longer on login page
      final loginPageIndicator = $(find.text('メールアドレスでログイン'));
      expect(loginPageIndicator.exists, isFalse);
    },
  );
}
```

---

## Helper Files

### patrol_test/helpers/mailpit_client.dart

Mailpit API を操作するための Dart クライアント:

```dart
class MailpitClient {
  MailpitClient({String? baseUrl, String? proxyUrl, Dio? dio});

  // Get latest email message
  Future<MailpitMessage?> getLatestMessage();

  // Search emails by recipient
  Future<List<MailpitMessageSummary>> searchByRecipient(String email);

  // Extract OTP from latest email
  Future<String?> extractOtpFromLatestEmail({String pattern = r'\b(\d{6})\b'});

  // Wait for OTP email and extract code (with proxy support)
  Future<String?> waitForOtp({
    required String email,
    Duration timeout = const Duration(seconds: 30),
    bool useProxy = true,
  });

  // Delete all emails
  Future<void> deleteAllEmails();

  // Delete emails for specific recipient
  Future<void> deleteEmailsForRecipient(String email, {bool useProxy = true});
}
```

### patrol_test/scripts/otp_server.js

CORS を回避するための Node.js プロキシサーバー:

```javascript
// Endpoints:
// GET  /otp?email=xxx     - Poll Mailpit and return OTP when found
// DELETE /emails?email=xxx - Delete emails for recipient

// Features:
// - CORS headers enabled
// - 30-second timeout for OTP polling
// - Regex extraction of 6-digit OTP codes
```

---

## Writing Tests

### Basic Test Structure

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:web_app/app/app.dart';

void main() {
  patrolTest(
    'Test description',
    tags: ['smoke', 'mobile'],
    ($) async {
      // Step 1: Launch app
      await $.pumpWidgetAndSettle(
        const App(),
      );

      // Step 2: Interact with UI
      await $.tap(find.text('Button'));

      // Step 3: Verify results
      expect($('Expected Text'), findsOneWidget);
    },
  );
}
```

### Test Tags

Use tags to organize and filter tests:

- `smoke`: Quick smoke tests for basic functionality
- `mobile`: Mobile platform tests (iOS/Android)
- `web`: Web platform tests
- `auth`: Authentication flow tests
- `e2e`: End-to-end tests

### Common Test Patterns

#### Finding Widgets

```dart
// By text
$('Button Text')
find.text('Button Text')

// By type
find.byType(ElevatedButton)

// By key
find.byKey(const Key('submit-button'))

// By icon
find.byIcon(Icons.add)
```

#### User Interactions

```dart
// Tap on widget
await $.tap(find.text('Login'));

// Enter text
await $.enterText(find.byKey(const Key('email-input')), 'test@example.com');

// Using PatrolFinder
final emailField = $(find.byType(TextField)).first;
await emailField.enterText('test@example.com');

// Scroll
await $.scrollUntilVisible(
  finder: find.text('Target'),
);

// Native interactions (mobile only)
await $.native.pressHome();
await $.native.openNotifications();
```

#### Assertions

```dart
// Verify widget exists
expect(find.text('Success'), findsOneWidget);

// Verify widget doesn't exist
expect(find.text('Error'), findsNothing);

// Verify multiple widgets
expect(find.byType(ListTile), findsNWidgets(5));

// Using PatrolFinder
final button = $(find.text('Submit'));
expect(button.exists, isTrue);
```

### Skipping Tests

```dart
patrolTest(
  'Test that needs implementation',
  tags: ['auth'],
  skip: true,
  ($) async {
    // Test code...
  },
);
```

---

## Platform-Specific Considerations

### Web Platform

- **No native automation** (permission dialogs, etc.)
- **CORS restrictions** - Use proxy for external API calls
- **Focus on UI** interactions and navigation
- **Browser DevTools** for debugging

### Mobile Platforms (iOS/Android)

- **Native automation** available (permissions, notifications)
- **No CORS** - Can call APIs directly
- Requires physical device or simulator/emulator
- Can interact with system settings

### macOS

- Desktop application testing
- Native automation available
- Requires macOS runner

---

## Best Practices

### 1. Always Initialize Supabase

```dart
// ✅ ALWAYS do this in tests
await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
```

### 2. Use Environment Variables

```dart
// ✅ Good: Use --dart-define-from-file
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');

// ❌ Bad: Hardcode values
const _supabaseUrl = 'http://localhost:54321';
```

### 3. Test Isolation

- Each test should be independent
- Clean up test data (delete test emails, etc.)
- Don't rely on test execution order

### 4. Reliable Selectors

```dart
// ✅ Good: Use semantic finders
find.text('Login')
find.byKey(const Key('email-input'))

// ❌ Bad: Use index-based finders
find.byType(TextField).at(0)
```

### 5. Wait for Asynchronous Operations

```dart
// Wait for UI to settle
await $.pumpAndSettle();

// Wait with specific duration
await $.pump(const Duration(seconds: 3));

// Wait for specific widget
await $.waitUntilVisible(find.text('Success'));
```

---

## Troubleshooting

### patrol command not found

```bash
flutter pub global activate patrol_cli
export PATH="$PATH:$HOME/.pub-cache/bin"
```

### OTP not received

1. Check Supabase is running: `make run`
2. Check Mailpit UI: http://localhost:54324
3. Check proxy server is running: `node patrol_test/scripts/otp_server.js`
4. Verify Supabase is initialized in test

### Supabase API not working

```
Error: OTPの送信に失敗しました
```

**Cause**: Supabase not initialized
**Fix**: Add `await Supabase.initialize(...)` at start of test

### CORS error on Web

```
XMLHttpRequest error
```

**Cause**: Direct Mailpit access from browser blocked by CORS
**Fix**: Use proxy server with `useProxy: true`

### Web server timeout

```
Timeout waiting for web server to start
```

**Fix**: Re-run the test, or use `--verbose` to see detailed logs

---

## References

- [Patrol Official Documentation](https://patrol.leancode.co/)
- [Patrol GitHub Repository](https://github.com/leancodepl/patrol)
- [Patrol pub.dev Package](https://pub.dev/packages/patrol)
- [Mailpit Documentation](https://mailpit.axllent.org/)

---

**Last Updated**: 2026-01-26

**Patrol Version**: 4.1.0

**Compatible with**: Flutter 3.35.6, Dart 3.8.0

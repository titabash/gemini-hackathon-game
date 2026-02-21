import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:web_app/app/app.dart';

/// Mobile Home Screen Smoke Test
///
/// Basic verification that app launches and home screen loads.
/// Equivalent to Maestro's mobile/smoke/home-screen.yaml
void main() {
  patrolTest(
    'Mobile app launches and home screen loads',
    tags: ['smoke', 'mobile'],
    ($) async {
      // Step 1: Launch app with clean state
      await $.pumpWidgetAndSettle(
        const App(),
      );

      // Step 2: Wait for app to load (Patrol handles this automatically with pumpAndSettle)
      // Verify that home page elements are visible
      expect($('Flutter Demo Home Page'), findsOneWidget);

      // Step 3: Verify counter button is present
      expect($('You have pushed the button this many times:'), findsOneWidget);
    },
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:web_app/app/app.dart';

/// Web Home Page Smoke Test
///
/// Basic verification that web app launches and home page loads.
/// Equivalent to Maestro's web/smoke/home-page.yaml
void main() {
  patrolTest('Web app launches and home page loads', tags: ['smoke', 'web'], (
    $,
  ) async {
    // Step 1: Launch app
    await $.pumpWidgetAndSettle(const App());

    // Step 2: Verify that home page elements are visible
    expect($('Flutter Demo Home Page'), findsOneWidget);

    // Step 3: Verify counter display
    expect($('0'), findsOneWidget);
    expect($('You have pushed the button this many times:'), findsOneWidget);
  });
}

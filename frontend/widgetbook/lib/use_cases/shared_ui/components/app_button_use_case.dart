import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'package:shared_ui/shared_ui.dart';

/// Default AppButton use case
@widgetbook.UseCase(
  name: 'Default',
  type: AppButton,
  path: '[Packages]/[Shared UI]/[Components]',
)
Widget defaultAppButton(BuildContext context) {
  return Center(
    child: AppButton(
      text: 'Click me',
      onPressed: () {},
    ),
  );
}

/// Disabled AppButton use case
@widgetbook.UseCase(
  name: 'Disabled',
  type: AppButton,
  path: '[Packages]/[Shared UI]/[Components]',
)
Widget disabledAppButton(BuildContext context) {
  return const Center(
    child: AppButton(
      text: 'Disabled Button',
      onPressed: null,
    ),
  );
}

/// Custom styled AppButton use case
@widgetbook.UseCase(
  name: 'Custom Style',
  type: AppButton,
  path: '[Packages]/[Shared UI]/[Components]',
)
Widget customStyleAppButton(BuildContext context) {
  return Center(
    child: AppButton(
      text: 'Custom Button',
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    ),
  );
}

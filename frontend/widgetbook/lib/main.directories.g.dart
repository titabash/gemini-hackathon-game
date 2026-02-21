// dart format width=80
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:widgetbook/widgetbook.dart' as _widgetbook;
import 'package:widgetbook_workspace/use_cases/shared_ui/components/app_button_use_case.dart'
    as _widgetbook_workspace_use_cases_shared_ui_components_app_button_use_case;

final directories = <_widgetbook.WidgetbookNode>[
  _widgetbook.WidgetbookCategory(
    name: 'Packages',
    children: [
      _widgetbook.WidgetbookCategory(
        name: 'Shared UI',
        children: [
          _widgetbook.WidgetbookCategory(
            name: 'Components',
            children: [
              _widgetbook.WidgetbookComponent(
                name: 'AppButton',
                useCases: [
                  _widgetbook.WidgetbookUseCase(
                    name: 'Custom Style',
                    builder:
                        _widgetbook_workspace_use_cases_shared_ui_components_app_button_use_case
                            .customStyleAppButton,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Default',
                    builder:
                        _widgetbook_workspace_use_cases_shared_ui_components_app_button_use_case
                            .defaultAppButton,
                  ),
                  _widgetbook.WidgetbookUseCase(
                    name: 'Disabled',
                    builder:
                        _widgetbook_workspace_use_cases_shared_ui_components_app_button_use_case
                            .disabledAppButton,
                  ),
                ],
              )
            ],
          )
        ],
      )
    ],
  )
];

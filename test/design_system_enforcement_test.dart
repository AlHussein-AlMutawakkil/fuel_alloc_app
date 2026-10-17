import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_alloc_app/core/constants/app_colors.dart';
import 'package:fuel_alloc_app/core/constants/app_dimensions.dart';
import 'package:fuel_alloc_app/core/constants/app_icons.dart';
import 'package:fuel_alloc_app/core/constants/app_strings.dart';
import 'package:fuel_alloc_app/core/constants/app_typography.dart';
import 'package:fuel_alloc_app/core/widgets/widgets.dart';

void main() {
  group('Design System Automated Enforcement Tests', () {
    test('1. Centralized Design Tokens are fully defined and non-empty', () {
      // AppColors
      expect(AppColors.primary, isNotNull);
      expect(AppColors.background, isNotNull);
      expect(AppColors.surface, isNotNull);
      expect(AppColors.supplyGreen, isNotNull);
      expect(AppColors.dispenseRed, isNotNull);
      expect(AppColors.textPrimary, isNotNull);
      expect(AppColors.textSecondary, isNotNull);
      expect(AppColors.textTertiary, isNotNull);
      expect(AppColors.textMuted, isNotNull);
      expect(AppColors.border, isNotNull);
      expect(AppColors.borderLight, isNotNull);
      expect(AppColors.charcoal, isNotNull);
      expect(AppColors.actionEdit, isNotNull);
      expect(AppColors.actionDelete, isNotNull);
      expect(AppColors.actionArchive, isNotNull);
      expect(AppColors.searchBackground, isNotNull);

      // AppDimensions
      expect(AppDimensions.spaceM, greaterThan(0));
      expect(AppDimensions.spaceL, greaterThan(AppDimensions.spaceM));
      expect(AppDimensions.buttonHeight, greaterThan(0));
      expect(AppDimensions.inputHeight, greaterThan(0));
      expect(AppDimensions.radiusCard, greaterThan(0));
      expect(AppDimensions.iconMedium, greaterThan(0));
      expect(AppDimensions.handleWidth, greaterThan(0));
      expect(AppDimensions.handleHeight, greaterThan(0));
      expect(AppDimensions.paddingScreen, isNotNull);

      // AppIcons
      expect(AppIcons.navHome, isNotNull);
      expect(AppIcons.navAccounts, isNotNull);
      expect(AppIcons.navReports, isNotNull);
      expect(AppIcons.navSettings, isNotNull);
      expect(AppIcons.add, isNotNull);
      expect(AppIcons.edit, isNotNull);
      expect(AppIcons.delete, isNotNull);
      expect(AppIcons.archive, isNotNull);
      expect(AppIcons.gasStation, isNotNull);

      // AppStrings
      expect(AppStrings.appTitle.isNotEmpty, isTrue);
      expect(AppStrings.navHome.isNotEmpty, isTrue);
      expect(AppStrings.navAccounts.isNotEmpty, isTrue);
      expect(AppStrings.save.isNotEmpty, isTrue);
      expect(AppStrings.cancel.isNotEmpty, isTrue);
      expect(AppStrings.confirm.isNotEmpty, isTrue);
      expect(AppStrings.delete.isNotEmpty, isTrue);
      expect(AppStrings.edit.isNotEmpty, isTrue);
      expect(AppStrings.searchHere.isNotEmpty, isTrue);

      // AppTypography
      expect(AppTypography.heading1.fontSize, greaterThan(0));
      expect(AppTypography.body.fontSize, greaterThan(0));
      expect(AppTypography.caption.fontSize, greaterThan(0));
      expect(AppTypography.button.fontSize, greaterThan(0));
    });

    test('2. Shared Components instantiate and consume design tokens', () {
      final button = CustomButton(
        text: AppStrings.save,
        onPressed: () {},
      );
      expect(button.text, equals(AppStrings.save));

      const textField = CustomTextField(
        label: AppStrings.accountName,
        hint: AppStrings.search,
      );
      expect(textField.label, equals(AppStrings.accountName));

      const emptyState = EmptyStateWidget(
        icon: AppIcons.accountOutline,
        title: AppStrings.noAccountsFound,
      );
      expect(emptyState.title, equals(AppStrings.noAccountsFound));

      final filterChip = AppFilterChip(
        label: AppStrings.allFilter,
        isSelected: true,
        onTap: () {},
      );
      expect(filterChip.label, equals(AppStrings.allFilter));

      const loading = AppLoadingIndicator();
      expect(loading, isNotNull);
    });

    test('3. Enforce zero raw Color(0x...) calls in lib/views/', () {
      final viewsDir = Directory('lib/views');
      expect(viewsDir.existsSync(), isTrue,
          reason: 'lib/views directory must exist');

      final dartFiles = viewsDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();

      final colorRegex = RegExp(r'Color\(0x[0-9a-fA-F]+\)');
      final violations = <String>[];

      for (final file in dartFiles) {
        final lines = file.readAsLinesSync();
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (colorRegex.hasMatch(line)) {
            violations.add('${file.path}:${i + 1}: ${line.trim()}');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Forbidden raw Color() instantiations found in views! All colors must use AppColors:\n${violations.join('\n')}',
      );
    });

    test('4. Enforce centralized file existence across project', () {
      final requiredFiles = [
        'lib/core/constants/app_colors.dart',
        'lib/core/constants/app_dimensions.dart',
        'lib/core/constants/app_icons.dart',
        'lib/core/constants/app_strings.dart',
        'lib/core/constants/app_typography.dart',
        'lib/core/theme/app_theme.dart',
        'lib/core/widgets/widgets.dart',
        'lib/core/widgets/custom_button.dart',
        'lib/core/widgets/custom_text_field.dart',
        'lib/core/widgets/custom_dialog.dart',
        'lib/core/widgets/custom_dropdown.dart',
        'lib/core/widgets/custom_modal_sheet.dart',
        'lib/core/widgets/one_ui_card.dart',
        'lib/core/widgets/empty_state_widget.dart',
        'lib/core/widgets/app_loading_indicator.dart',
        'lib/core/widgets/filter_chip_widget.dart',
        'lib/core/widgets/app_snackbar.dart',
        '.agents/rules/design.md',
      ];

      for (final path in requiredFiles) {
        final file = File(path);
        expect(file.existsSync(), isTrue,
            reason: 'Required file must exist: $path');
        expect(file.lengthSync(), greaterThan(0),
            reason: 'File must not be empty: $path');
      }
    });

    testWidgets(
        '5. CustomModalSheet.showItemPicker renders correctly with search and item list',
        (tester) async {
      String? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  selectedValue = await CustomModalSheet.showItemPicker<String>(
                    context: ctx,
                    title: AppStrings.account,
                    items: ['حساب الأمانة', 'حساب النقل'],
                    itemLabel: (item) => item,
                    searchHint: AppStrings.searchHere,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      // Open bottom sheet
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify Title and Search placeholder are rendered
      expect(find.text(AppStrings.account), findsOneWidget);
      expect(find.text(AppStrings.searchHere), findsOneWidget);
      expect(find.text('حساب الأمانة'), findsOneWidget);
      expect(find.text('حساب النقل'), findsOneWidget);

      // Tap on an item
      await tester.tap(find.text('حساب الأمانة'));
      await tester.pumpAndSettle();

      // Verify item was selected and sheet closed
      expect(selectedValue, equals('حساب الأمانة'));
      expect(find.text(AppStrings.account), findsNothing);
    });
  });
}

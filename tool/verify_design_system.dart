import 'dart:io';

void main() {
  stdout.writeln('=== Running Centralized Design System Audit ===');

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

  bool hasError = false;

  for (final path in requiredFiles) {
    final file = File(path);
    if (!file.existsSync() || file.lengthSync() == 0) {
      stderr.writeln('FAIL: Missing or empty file: $path');
      hasError = true;
    }
  }

  // Scan lib/views for raw Color() instantiations
  final viewsDir = Directory('lib/views');
  if (viewsDir.existsSync()) {
    final colorRegex = RegExp(r'Color\(0x[0-9a-fA-F]+\)');
    final dartFiles = viewsDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final lines = file.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (colorRegex.hasMatch(line)) {
          stderr.writeln(
              'FAIL: Raw Color() instantiation at ${file.path}:${i + 1}');
          hasError = true;
        }
      }
    }
  }

  if (hasError) {
    stderr.writeln('=== Design System Audit Failed ===');
    exit(1);
  } else {
    stdout.writeln(
        'SUCCESS: Centralized Design System Audit Passed with 0 violations.');
    exit(0);
  }
}

import 'package:flutter/material.dart';
import '../../../core/widgets/custom_export_bottom_sheet.dart';

export '../../../core/widgets/custom_export_bottom_sheet.dart';

/// نافذة تصدير التقرير السفلية الموجهة للمكون المشترك الموحد CustomExportBottomSheet
class ExportOptionsSheet {
  ExportOptionsSheet._();

  static Future<ExportFormat?> show({
    required BuildContext context,
    String? title,
  }) {
    return CustomExportBottomSheet.show(context: context, title: title);
  }
}

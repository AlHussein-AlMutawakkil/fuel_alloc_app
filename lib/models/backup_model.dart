import 'package:intl/intl.dart';
import '../core/constants/app_strings.dart';

/// نوع النسخة الاحتياطية
enum BackupType { full, archive, incremental }

/// دورية النسخ التزايدي الكامل
enum IncrementalFrequency { days7, monthly }

/// وتيرة الجدولة
enum ScheduleFrequency { daily, weekly, hourly }

/// نموذج عنصر النسخة الاحتياطية المحفوظة
class BackupModel {
  final String id;
  final String fileName;
  final DateTime createdAt;
  final int sizeBytes;
  final BackupType type;
  final bool isCloud;

  const BackupModel({
    required this.id,
    required this.fileName,
    required this.createdAt,
    required this.sizeBytes,
    required this.type,
    this.isCloud = false,
  });

  /// الحجم بتنسيق مقروء (كيلوبايت / ميجابايت)
  String get formattedSize {
    if (sizeBytes < 1024) {
      return '$sizeBytes بايت';
    } else if (sizeBytes < 1024 * 1024) {
      final kb = (sizeBytes / 1024).toStringAsFixed(1);
      return '$kb ك.ب';
    } else {
      final mb = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
      return '$mb م.ب';
    }
  }

  /// تاريخ ووقت النسخة بتنسيق عربي نظيف
  String get formattedDate {
    final dateStr = DateFormat('yyyy/MM/dd').format(createdAt);
    final hour = createdAt.hour > 12
        ? createdAt.hour - 12
        : (createdAt.hour == 0 ? 12 : createdAt.hour);
    final minute = createdAt.minute.toString().padLeft(2, '0');
    final period = createdAt.hour >= 12 ? AppStrings.pmSuffix : AppStrings.amSuffix;
    return '$dateStr  $hour:$minute $period';
  }

  /// تسمية نوع النسخة
  String get typeTitle {
    switch (type) {
      case BackupType.full:
        return AppStrings.backupFullTitle;
      case BackupType.archive:
        return AppStrings.backupArchiveTitle;
      case BackupType.incremental:
        return AppStrings.backupIncrementalTitle;
    }
  }

  /// الشارة المختصرة
  String get typeBadge {
    switch (type) {
      case BackupType.full:
        return AppStrings.backupFullBadge;
      case BackupType.archive:
        return AppStrings.backupArchiveBadge;
      case BackupType.incremental:
        return AppStrings.backupIncrementalBadge;
    }
  }
}

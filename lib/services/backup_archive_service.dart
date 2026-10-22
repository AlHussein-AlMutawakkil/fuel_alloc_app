import 'dart:io';
import 'package:archive/archive.dart';

/// خدمة ضغط وتشفير ملفات النسخ الاحتياطية بصيغة ZIP
class BackupArchiveService {
  BackupArchiveService._();

  /// فحص هل الملف مضغوط بصيغة ZIP
  static Future<bool> isZipFile(File file) async {
    if (!await file.exists()) return false;
    final length = await file.length();
    if (length < 4) return false;
    try {
      final bytes = await file.openRead(0, 4).first;
      // ترويسة ملفات ZIP القياسية: PK\x03\x04
      return bytes.length >= 4 &&
          bytes[0] == 0x50 &&
          bytes[1] == 0x4B &&
          bytes[2] == 0x03 &&
          bytes[3] == 0x04;
    } catch (_) {
      return false;
    }
  }

  /// ضغط ملف قاعدة البيانات إلى ملف ZIP مع إمكانية التشفير بكلمة مرور
  static Future<File> compressDatabaseFile({
    required File sourceDbFile,
    required File targetZipFile,
    String? password,
  }) async {
    final bytes = await sourceDbFile.readAsBytes();
    final archive = Archive();

    // إضافة ملف قاعدة البيانات إلى الأرشيف
    final archiveFile = ArchiveFile(
      'fuel_allocation.db',
      bytes.length,
      bytes,
    );
    archive.addFile(archiveFile);

    final zipEncoder = ZipEncoder(password: password?.isNotEmpty == true ? password : null);
    final encodedData = zipEncoder.encode(archive);
    await targetZipFile.writeAsBytes(encodedData, flush: true);
    return targetZipFile;
  }

  /// فك ضغط ملف ZIP واستخراج قاعدة البيانات مع كلمة المرور إن كان مشفراً
  static Future<File> extractDatabaseFile({
    required File sourceZipFile,
    required File targetDbFile,
    String? password,
  }) async {
    final bytes = await sourceZipFile.readAsBytes();
    final zipDecoder = ZipDecoder();
    final archive = zipDecoder.decodeBytes(
      bytes,
      password: password?.isNotEmpty == true ? password : null,
    );

    ArchiveFile? dbFile;
    for (final file in archive) {
      if (file.isFile && (file.name.endsWith('.db') || file.name == 'fuel_allocation.db')) {
        dbFile = file;
        break;
      }
    }

    dbFile ??= archive.files.firstWhere(
      (f) => f.isFile,
      orElse: () => throw Exception('الملف المضغوط لا يحتوي على قاعدة بيانات صالحة'),
    );

    final content = dbFile.content;
    await targetDbFile.writeAsBytes(content, flush: true);
    return targetDbFile;
  }
}

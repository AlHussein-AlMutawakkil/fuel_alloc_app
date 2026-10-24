import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

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

  /// ضغط ملف قاعدة البيانات والملفات الإضافية إلى ملف ZIP مع إمكانية التشفير بكلمة مرور
  static Future<File> compressDatabaseFile({
    required File sourceDbFile,
    required File targetZipFile,
    String? password,
    List<File>? extraFiles,
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

    // إضافة الملفات الإضافية (مثل الشعار والختم والتوقيع)
    if (extraFiles != null) {
      for (final extra in extraFiles) {
        if (await extra.exists()) {
          final extraBytes = await extra.readAsBytes();
          final fileName = 'personal_assets/${p.basename(extra.path)}';
          archive.addFile(ArchiveFile(fileName, extraBytes.length, extraBytes));
        }
      }
    }

    final zipEncoder = ZipEncoder(password: password?.isNotEmpty == true ? password : null);
    final encodedData = zipEncoder.encode(archive);
    await targetZipFile.writeAsBytes(encodedData, flush: true);
    return targetZipFile;
  }

  /// فك ضغط ملف ZIP واستخراج قاعدة البيانات والملفات الإضافية مع كلمة المرور إن كان مشفراً
  static Future<File> extractDatabaseFile({
    required File sourceZipFile,
    required File targetDbFile,
    String? password,
    Directory? targetAssetsDir,
  }) async {
    final bytes = await sourceZipFile.readAsBytes();
    final zipDecoder = ZipDecoder();
    final archive = zipDecoder.decodeBytes(
      bytes,
      password: password?.isNotEmpty == true ? password : null,
    );

    ArchiveFile? dbFile;
    for (final file in archive) {
      if (file.isFile) {
        if (file.name.endsWith('.db') || file.name == 'fuel_allocation.db') {
          dbFile = file;
        } else if (file.name.startsWith('personal_assets/') && targetAssetsDir != null) {
          try {
            if (!await targetAssetsDir.exists()) {
              await targetAssetsDir.create(recursive: true);
            }
            final outFilePath = p.join(targetAssetsDir.path, p.basename(file.name));
            final outFile = File(outFilePath);
            await outFile.writeAsBytes(file.content as List<int>, flush: true);
          } catch (_) {}
        }
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

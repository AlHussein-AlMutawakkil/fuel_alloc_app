import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import '../models/backup_model.dart';

/// عميل HTTP مصادق عليه يمرر ترويسات OAuth لحساب Google تلقائياً
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
    super.close();
  }
}

/// خدمة الربط والمزامنة السحابية مع Google Drive
class GoogleDriveService extends ChangeNotifier {
  static final GoogleDriveService instance = GoogleDriveService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope,
    ],
  );

  drive.DriveApi? _driveApi;
  String? _appFolderId;

  GoogleDriveService._internal();

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
  bool get isSignedIn => _googleSignIn.currentUser != null;

  /// تهيئة تسجيل الدخول الصامت عند فتح التطبيق
  Future<GoogleSignInAccount?> initSilentSignIn() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        await _initDriveApi(account);
        notifyListeners();
      }
      return account;
    } catch (_) {
      return null;
    }
  }

  /// تسجيل الدخول الفعلي بحساب Google
  Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        await _initDriveApi(account);
        notifyListeners();
      }
      return account;
    } catch (e) {
      return null;
    }
  }

  /// تسجيل الخروج من Google Drive
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // التعامل المرن عند انقطاع الاتصال أو بيئات الاختبار
    } finally {
      _driveApi = null;
      _appFolderId = null;
      notifyListeners();
    }
  }

  Future<void> _initDriveApi(GoogleSignInAccount account) async {
    final headers = await account.authHeaders;
    final authClient = GoogleAuthClient(headers);
    _driveApi = drive.DriveApi(authClient);
  }

  /// الحصول على معرف مجلد التطبيق المخصص FuelAlloc_Backups أو إنشائه إن لم يكن موجوداً
  Future<String> getOrCreateAppFolder() async {
    if (_appFolderId != null) return _appFolderId!;
    if (_driveApi == null) {
      throw StateError('Google Drive API غير مهيأ. يرجى تسجيل الدخول أولاً.');
    }

    // البحث عن المجلد بالاسم داخل Drive
    final search = await _driveApi!.files.list(
      q: "name = 'FuelAlloc_Backups' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
      spaces: 'drive',
      $fields: 'files(id, name)',
    );

    if (search.files != null && search.files!.isNotEmpty) {
      _appFolderId = search.files!.first.id!;
      return _appFolderId!;
    }

    // إنشاء المجلد إذا لم يكن موجوداً
    final folderMeta = drive.File()
      ..name = 'FuelAlloc_Backups'
      ..mimeType = 'application/vnd.google-apps.folder';

    final createdFolder = await _driveApi!.files.create(
      folderMeta,
      $fields: 'id',
    );

    _appFolderId = createdFolder.id!;
    return _appFolderId!;
  }

  /// رفع ملف النسخة الاحتياطية المحلي (.db) مباشرة إلى مجلد التطبيق
  Future<drive.File> uploadBackupFile({
    required File localFile,
    required String backupFileName,
    String? description,
  }) async {
    if (_driveApi == null) {
      throw StateError('يجب تسجيل الدخول بحساب Google أولاً.');
    }

    final folderId = await getOrCreateAppFolder();
    final fileLength = await localFile.length();
    final mediaStream = drive.Media(localFile.openRead(), fileLength);

    final driveFile = drive.File()
      ..name = backupFileName
      ..parents = [folderId]
      ..mimeType = 'application/x-sqlite3'
      ..description = description;

    return await _driveApi!.files.create(
      driveFile,
      uploadMedia: mediaStream,
      $fields: 'id, name, size, createdTime',
    );
  }

  /// استرجاع قائمة ملفات النسخ السحابية المحفوظة في Google Drive
  Future<List<BackupModel>> fetchCloudBackups() async {
    if (_driveApi == null) return [];

    final folderId = await getOrCreateAppFolder();

    final result = await _driveApi!.files.list(
      q: "'$folderId' in parents and trashed = false",
      spaces: 'drive',
      orderBy: 'createdTime desc',
      $fields: 'files(id, name, size, createdTime, description)',
    );

    final List<BackupModel> backups = [];
    if (result.files != null) {
      for (final f in result.files!) {
        final name = f.name ?? 'backup.db';
        BackupType type = BackupType.full;
        if (name.contains('arch')) {
          type = BackupType.archive;
        } else if (name.contains('incr')) {
          type = BackupType.incremental;
        }

        backups.add(
          BackupModel(
            id: f.id ?? UniqueKey().toString(),
            fileName: name,
            createdAt: f.createdTime?.toLocal() ?? DateTime.now(),
            sizeBytes: int.tryParse(f.size ?? '0') ?? 0,
            type: type,
            isCloud: true,
          ),
        );
      }
    }
    return backups;
  }

  /// تنزيل ملف نسخة سحابية إلى مسار محلي
  Future<File> downloadCloudBackup({
    required String fileId,
    required String targetLocalPath,
  }) async {
    if (_driveApi == null) {
      throw StateError('يجب تسجيل الدخول أولاً لتنزيل النسخة السحابية.');
    }

    final media = await _driveApi!.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final targetFile = File(targetLocalPath);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    await targetFile.create(recursive: true);

    final sink = targetFile.openWrite();
    await media.stream.pipe(sink);
    await sink.flush();
    await sink.close();

    return targetFile;
  }

  /// حذف نسخة سحابية من Google Drive
  Future<void> deleteCloudBackup(String fileId) async {
    if (_driveApi == null) return;
    await _driveApi!.files.delete(fileId);
  }

  /// تنظيف وحذف كافة النسخ المتطابقة المتكررة من Google Drive والإبقاء على الأحدث
  Future<int> deleteDuplicateCloudBackups() async {
    if (_driveApi == null) return 0;
    try {
      final folderId = await getOrCreateAppFolder();
      final List<drive.File> allFiles = [];
      String? pageToken;

      do {
        final res = await _driveApi!.files.list(
          q: "'$folderId' in parents and trashed = false",
          spaces: 'drive',
          orderBy: 'createdTime desc',
          $fields: 'nextPageToken, files(id, name, size, createdTime, md5Checksum)',
          pageSize: 1000,
          pageToken: pageToken,
        );
        if (res.files != null) {
          allFiles.addAll(res.files!);
        }
        pageToken = res.nextPageToken;
      } while (pageToken != null && pageToken.isNotEmpty);

      if (allFiles.isEmpty) return 0;

      // تجميع الملفات المتطابقة بناءً على md5Checksum أو الحجم
      final Map<String, List<drive.File>> groups = {};
      for (final file in allFiles) {
        final key = (file.md5Checksum != null && file.md5Checksum!.isNotEmpty)
            ? file.md5Checksum!
            : '${file.size ?? 0}_${file.name?.split('.').last}';
        groups.putIfAbsent(key, () => []).add(file);
      }

      int deletedCount = 0;
      for (final entry in groups.entries) {
        final duplicates = entry.value;
        if (duplicates.length > 1) {
          // ترتيب تنازلي حسب تاريخ الإنشاء لضمان الحفاظ على أحدث نسخة
          duplicates.sort((a, b) {
            final timeA = a.createdTime ?? DateTime.fromMillisecondsSinceEpoch(0);
            final timeB = b.createdTime ?? DateTime.fromMillisecondsSinceEpoch(0);
            return timeB.compareTo(timeA);
          });

          // حذف كل النسخ القديمة المتطابقة والإبقاء على أحدث نسخة (duplicates.first)
          for (int i = 1; i < duplicates.length; i++) {
            final fileToDelete = duplicates[i];
            if (fileToDelete.id != null) {
              try {
                await _driveApi!.files.delete(fileToDelete.id!);
                deletedCount++;
              } catch (_) {}
            }
          }
        }
      }
      return deletedCount;
    } catch (_) {
      return 0;
    }
  }

  /// تطبيق سياسة التنظيف التلقائي على نسخ Google Drive
  Future<int> applyCloudRetention({
    required RetentionPolicy policy,
    required int maxDays,
    required int maxCount,
  }) async {
    if (_driveApi == null || policy == RetentionPolicy.none) return 0;
    try {
      final folderId = await getOrCreateAppFolder();
      final res = await _driveApi!.files.list(
        q: "'$folderId' in parents and trashed = false",
        spaces: 'drive',
        orderBy: 'createdTime desc',
        $fields: 'files(id, name, size, createdTime)',
        pageSize: 1000,
      );

      final files = res.files ?? [];
      if (files.isEmpty) return 0;

      int deletedCount = 0;
      if (policy == RetentionPolicy.days) {
        final cutoff = DateTime.now().subtract(Duration(days: maxDays));
        for (int i = 1; i < files.length; i++) {
          final f = files[i];
          if (f.createdTime != null && f.createdTime!.isBefore(cutoff) && f.id != null) {
            try {
              await _driveApi!.files.delete(f.id!);
              deletedCount++;
            } catch (_) {}
          }
        }
      } else if (policy == RetentionPolicy.count) {
        if (files.length > maxCount) {
          final toDelete = files.skip(maxCount);
          for (final f in toDelete) {
            if (f.id != null) {
              try {
                await _driveApi!.files.delete(f.id!);
                deletedCount++;
              } catch (_) {}
            }
          }
        }
      }
      return deletedCount;
    } catch (_) {
      return 0;
    }
  }
}

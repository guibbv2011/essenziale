import 'dart:convert';
import 'dart:io';

import 'package:essenziale_storage/admins_extract/admin_ext.dart';
import 'package:essenziale_storage/database/crud.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_multipart/shelf_multipart.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:googleapis/storage/v1.dart';

Router filesUpload(StorageApi gcsClient, String bucketName) {
  final handler = Router();
  handler.post('/media', (Request request) async {
    final adminId = request.headers['x-adminId'];
    final index = request.headers['x-index'];

    const maxTotalSize = 500 * 1024 * 1024; // 500MB total for request

    final totalContentLength = request.headers['content-length'];
    final totalSize = int.tryParse(totalContentLength ?? '0');
    if (totalSize != null && totalSize > maxTotalSize) {
      return Response(
        413,
        body: jsonEncode({
          'error': 'Total upload size exceeds $maxTotalSize bytes',
        }),
      );
    }

    final admin = AdminUserExt.fromId(adminId!);
    if (admin == null) {
      return Response(
        403,
        body: jsonEncode({'error': 'Unauthorized admin: $adminId'}),
      );
    }

    final intIndex = int.tryParse(index!);
    if (intIndex == null || intIndex < 1) {
      return Response(
        400,
        body: jsonEncode({
          'error': 'Invalid index: $index (must be positive integer)',
        }),
      );
    }

    List<String> fileNames = [];
    if (request.formData() case var formData?) {
      await for (final field in formData.formData) {
        if (field.name == 'file') {
          final contentDisposition = field.part.headers['content-disposition'];
          if (contentDisposition == null) continue;
          RegExp r = RegExp(r'filename="([^"]+)"');
          Match? match = r.firstMatch(contentDisposition);

          if (match == null || match.group(1) == null) {
            continue;
          }
          final nameFile = match.group(1)!;

          final File file = File(
            '/tmp/${admin.id}/$index/${nameFile.replaceFirst('/', '.')}',
          );
          await file.parent.create(recursive: true);

          final sink = file.openWrite();
          await field.part.pipe(sink);
          await sink.close();

          fileNames.add(nameFile);
        }
      }

      print('filenames to upload: $fileNames');

      if (fileNames.isEmpty) {
        return Response(400, body: 'No file uploaded');
      }

      final String remotePath = '/${admin.id}/$index/';

      final Directory dir = Directory('/tmp/${admin.id}/$index/');
      final String localFolder = dir.path;

      try {
        await GcsStorageService(
          gcsClient,
          bucketName,
        ).uploadDirectory(localFolder, remotePath);

        await dir.delete(recursive: true);
        print('Successfully deleted folder: $remotePath');
        return Response.ok('uploaded file\'s: $remotePath');
      } catch (e) {
        print('Failed to delete folder $remotePath: $e');
        return Response.internalServerError(body: e);
      }
    }
  });

  return handler;
}

import 'dart:convert';

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

          final String remoteNameFile =
              '${admin.id}-$index-${nameFile.replaceFirst('/', '.')}';

          try {
            await GcsStorageService(gcsClient, bucketName).insertFileFromBytes(
              await field.part.readBytes(),
              remoteNameFile,
              nameFile,
            );
          } catch (e) {
            return Response.internalServerError(body: e);
          }

          fileNames.add(nameFile);
        }
      }

      if (fileNames.isEmpty) {
        return Response(400, body: 'No file uploaded');
      }

      return Response.ok('uploaded file\'s: $fileNames');
    }
  });

  return handler;
}

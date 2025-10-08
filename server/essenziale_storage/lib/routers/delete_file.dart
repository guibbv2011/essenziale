import 'dart:convert';

import 'package:essenziale_storage/admins_extract/admin_ext.dart';
import 'package:essenziale_storage/database/crud.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:googleapis/storage/v1.dart' as storage;

Router deleteFileRequest(storage.StorageApi gcsClient, String bucketName) {
  final handler = Router();
  handler.delete('/deleteFile', (Request req) async {
    final adminId = req.headers['x-adminId'];
    final index = req.headers['x-index'];
    final file = req.headers['x-path'];

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

    final String remotePathFile = '${admin.id}/$index/$file';

    // NOTE : need a return
    GcsStorageService(gcsClient, bucketName).deleteFile(remotePathFile);

    return Response.ok('Response: $file successful deleted');
  });
  return handler;
}

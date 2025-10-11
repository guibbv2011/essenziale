import 'dart:convert';

import 'package:essenziale_storage/admins_extract/admin_ext.dart';
import 'package:essenziale_storage/database/crud.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:googleapis/storage/v1.dart';

Router deleteIndexRequest(StorageApi gcsClient, String bucketName) {
  final handler = Router();
  handler.delete('/deleteIndex', (Request req) async {
    final adminId = req.headers['x-adminId'];
    final index = req.headers['x-index'];

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

    final String remotePath = '/${admin.id}/$index';

    // NOTE : need a return
    GcsStorageService(gcsClient, bucketName).deleteFolder(remotePath);

    return Response.ok('Response: $remotePath successful deleted');
  });
  return handler;
}

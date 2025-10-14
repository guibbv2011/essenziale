import 'dart:convert';

import 'package:essenziale_storage/admins_extract/admin_ext.dart';
import 'package:essenziale_storage/database/crud.dart';
import 'package:googleapis/storage/v1.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Router fileRequest(StorageApi gcsClient, String bucketName) {
  final handler = Router();
  handler.get('/.*', (Request request) async {
    final adminId = request.headers['x-adminId'];
    final index = request.headers['x-index'];
    final file = request.headers['x-path'];

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

    final String remotePathFile = '/${admin.id}/$index/$file';

    try {
      final item = await GcsStorageService(
        gcsClient,
        bucketName,
      ).getFile(remotePathFile);

      return Response.ok(item);
    } catch (e) {
      return Response.internalServerError(body: e);
    }
  });
  return handler;
}

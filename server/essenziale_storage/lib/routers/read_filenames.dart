import 'dart:convert';

import 'package:essenziale_storage/admins_extract/admin_ext.dart';
import 'package:essenziale_storage/database/crud.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:googleapis/storage/v1.dart';

Router filenamesRequest(StorageApi gcsClient, String bucketName) {
  final handler = Router();
  handler.get('/filenames', (Request req) async {
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

    try {
      final items = await GcsStorageService(
        gcsClient,
        bucketName,
      ).listFiles(remotePath);
      return Response.ok('Return: $items');
    } catch (e) {
      return Response.internalServerError(body: e);
    }
  });
  return handler;
}

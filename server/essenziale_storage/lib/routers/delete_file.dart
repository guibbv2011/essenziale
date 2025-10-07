import 'dart:convert';
import 'dart:io';

import 'package:essenziale_storage/admins_extract/admin_ext.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Router get deleteFileRequest {
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

    String media = '';

    File el = File('./assets/${admin.id}/$index/$file');
    if (!await el.exists()) {
      return Response(
        403,
        body: jsonEncode({'error': 'File not found: $file'}),
      );
    }
    media = el.toString();

    el.deleteSync();
    if (!await el.exists()) {
      return Response.ok('Response: $media successful deleted');
    }
  });
  return handler;
}

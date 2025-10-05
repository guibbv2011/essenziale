import 'dart:convert';
import 'dart:io';

import 'package:essenziale_storage/admins_extract/admin_ext.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Router get fileRequest {
  final handler = Router();
  handler.get('/file', (Request request) async {
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

    File el = File('./assets/${admin.id}/$index/$file');
    if (!await el.exists()) {
      return Response(
        403,
        body: jsonEncode({'error': 'File not found: $file'}),
      );
    }
    return Response.ok(el.openRead());
  });

  return handler;
}

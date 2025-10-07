import 'dart:convert';
import 'dart:io';

import 'package:essenziale_storage/admins_extract/admin_ext.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Router get deleteIndexRequest {
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

    String dirname = '';

    Directory dir = Directory('./assets/${admin.id}/$index');
    if (!await dir.exists()) {
      return Response(403, body: jsonEncode({'error': 'Dir not found: $dir'}));
    }

    dirname = dir.path.toString();

    dir.deleteSync(recursive: true);
    if (!await dir.exists()) {
      return Response.ok('Response: $dirname successful deleted');
    }
  });
  return handler;
}

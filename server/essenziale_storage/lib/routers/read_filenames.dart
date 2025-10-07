import 'dart:convert';
import 'dart:io';

import 'package:essenziale_storage/admins_extract/admin_ext.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Router get filenamesRequest {
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

    List<String> media = [];

    Directory dir = Directory('./assets/${admin.id}/$index');
    await for (var el in dir.list(recursive: true, followLinks: false)) {
      media.add(el.uri.path.replaceAll('assets/${admin.id}/$index/', ''));
    }
    return Response.ok('Response: $media');
  });
  return handler;
}

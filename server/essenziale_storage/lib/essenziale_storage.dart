import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_multipart/shelf_multipart.dart';

enum AdminUsers { admin1, admin2, admin3, admin4, admin5 }

extension AdminUserExt on AdminUsers {
  String get id => name;

  static AdminUsers? fromId(String id) {
    return AdminUsers.values.firstWhereOrNull((admin) => admin.id == id);
  }
}

void main() async {
  bool dir = await Directory('./assets').exists();
  if (!dir) {
    await Directory('./assets').create();
  }

  final router = Router();

  router.get('/api/photos', (Request request) {
    // TODO : get all photos of user and send back
    final List<String> photos = [];
    return Response.ok(photos);
  });

  router.get('/api/videos', (Request request) {
    // TODO : get all photos of user and send back
    final List<String> videos = [];
    return Response.ok(videos);
  });
  router.post('/api/<adminId>/<index>/media', (
    Request request,
    String adminId,
    String index,
  ) async {
    const maxTotalSize = 250 * 1024 * 1024; // 250MB total for request

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

    final admin = AdminUserExt.fromId(adminId);
    if (admin == null) {
      return Response(
        403,
        body: jsonEncode({'error': 'Unauthorized admin: $adminId'}),
      );
    }

    final intIndex = int.tryParse(index);
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
            'assets/${admin.id}/$index/${nameFile.replaceFirst('/', '.')}',
          );
          await file.parent.create(recursive: true);

          final sink = file.openWrite();
          await field.part.pipe(sink);
          await sink.close();

          fileNames.add(nameFile);
        }
      }

      if (fileNames.isEmpty) {
        return Response(400, body: 'No file uploaded');
      }

      return Response.ok('Received file\'s: $fileNames');
    }
  });

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);

  await serve(handler, 'localhost', 8080);
}

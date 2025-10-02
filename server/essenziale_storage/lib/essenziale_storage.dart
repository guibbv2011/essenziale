import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_multipart/shelf_multipart.dart';

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

  router.post('/api/upload/photos', (Request request) async {
    if (request.formData() case var formData?) {
      List<int>? fileBytes;
      String? nameFile;

      await for (final field in formData.formData) {
        if (field.name == 'file') {
          RegExp r = RegExp(r'filename="([^"]+)"');
          Match? match = r.firstMatch(
            field.part.headers['content-disposition']!,
          );

          if (match != null && match.group(1) != null) {
            nameFile = match.group(1)!;
          }

          fileBytes = await field.part.readBytes();
          break;
        }
      }

      if (fileBytes == null) {
        return Response(400, body: 'No file uploaded');
      }

      final File file = File('assets/${nameFile!.replaceFirst('/', '.')}');

      await file.parent.create(recursive: true);
      await file.writeAsBytes(fileBytes);

      return Response.ok('Received file: $fileBytes');
    }
  });

  router.post('/api/upload/videos', (Request request) async {
    final body = await request.readAsString();
    return Response.ok('Received: $body');
  });

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);

  final server = await serve(handler, 'localhost', 8080);
}


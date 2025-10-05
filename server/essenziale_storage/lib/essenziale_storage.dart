import 'dart:io';

import 'package:essenziale_storage/routers/get_file.dart';
import 'package:essenziale_storage/routers/get_filenames.dart';
import 'package:essenziale_storage/routers/post_files.dart';
// import 'package:googleapis/storage/v1.dart';
// import 'package:googleapis_auth/auth_io.dart' as auth;
// import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

final filenamesHandler = filenamesRequest;
Router get router {
  final handler = Router();

  handler.all('/api/<adminId>/<index>/<path>', (
    Request request,
    String adminId,
    String index,
    String path,
  ) async {
    final newHeaders = {
      ...request.headers,
      'x-adminId': adminId,
      'x-index': index,
      'x-path': path,
    };

    final originalUri = request.requestedUri;
    final newUri = originalUri.replace(
      scheme: originalUri.scheme,
      userInfo: originalUri.userInfo,
      host: originalUri.host,
      port: originalUri.port,

      pathSegments: [path],
      queryParameters: originalUri.queryParameters,

      fragment: originalUri.fragment,
    );
    final subReq = Request(
      request.method,
      newUri,
      headers: newHeaders,
      body: await request.read(),
      context: request.context,
    );
    return switch (path) {
      'filenames' => await filenamesHandler(subReq),
      'media' => await filesUpload(subReq),
      _ when RegExp(r'.*').hasMatch(path) => fileRequest(subReq),
      _ => Response.notFound('error'),
    };
  });

  return handler;
}

void main() async {
  bool dir = await Directory('./assets').exists();
  if (!dir) {
    await Directory('./assets').create();
  }

  // final client = await auth.clientViaMetadataServer();
  // final bucket = StorageApi(client);

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router);

  await serve(handler, 'localhost', 8080);
}



import 'dart:io';

import 'package:essenziale_storage/routers/delete_file.dart';
import 'package:essenziale_storage/routers/delete_index.dart';
import 'package:essenziale_storage/routers/get_file.dart';
import 'package:essenziale_storage/routers/post_files.dart';
import 'package:essenziale_storage/routers/read_filenames.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_dynamic_forwarder/shelf_dynamic_forwarder.dart';

final Map<String, Handler> dynamicRoutes = {
  'deleteIndex': deleteIndexRequest,
  'deleteFile': deleteFileRequest,
  'filenames': filenamesRequest,
  'media': filesUpload,
  '.*': fileRequest,
};

Handler get router {
  final dynamicRouter = createDynamicRouter(
    routePattern: '/api/<adminId>/<index>/<path|.*>',
    routes: dynamicRoutes,
  );

  return dynamicRouter;
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

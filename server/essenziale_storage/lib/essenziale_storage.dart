import 'dart:io';

import 'package:essenziale_storage/routers/delete_file.dart';
import 'package:essenziale_storage/routers/delete_index.dart';
import 'package:essenziale_storage/routers/get_file.dart';
import 'package:essenziale_storage/routers/post_files.dart';
import 'package:essenziale_storage/routers/read_filenames.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_dynamic_forwarder/shelf_dynamic_forwarder.dart';
import 'package:googleapis/storage/v1.dart' as storage;
import 'package:googleapis_auth/auth_io.dart' as auth;

late final auth.AuthClient authenticatedClient;
late final storage.StorageApi gcsClient;

const String bucketName = 'essenziale-bucket-server1';
const List<String> _scopes = [storage.StorageApi.cloudPlatformScope];

Future<void> initializeGcsClient(String projectId, String bucketName) async {
  authenticatedClient = await auth.clientViaApplicationDefaultCredentials(
    scopes: _scopes,
  );
  gcsClient = storage.StorageApi(authenticatedClient);
}

final Map<String, Handler> dynamicRoutes = {
  'deleteIndex': deleteIndexRequest(gcsClient, bucketName),
  'deleteFile': deleteFileRequest(gcsClient, bucketName),
  'filenames': filenamesRequest(gcsClient, bucketName),
  'media': filesUpload(gcsClient, bucketName),
  '.*': fileRequest(gcsClient, bucketName),
};

Handler get router {
  final dynamicRouter = createDynamicRouter(
    routePattern: '/api/<adminId>/<index>/<path|.*>',
    routes: dynamicRoutes,
  );

  return dynamicRouter;
}

void main() async {
  initializeGcsClient('essenziale-server', bucketName);

  bool dir = await Directory('./tmp').exists();
  if (!dir) {
    await Directory('./tmp').create();
  }

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router);

  await serve(handler, '0.0.0.0', 8080);
  print('Server listening on port: 8080');
}

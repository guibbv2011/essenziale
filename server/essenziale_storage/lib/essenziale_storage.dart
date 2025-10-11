import 'dart:convert';
import 'dart:io';

import 'package:essenziale_storage/routers/delete_file.dart';
import 'package:essenziale_storage/routers/delete_index.dart';
import 'package:essenziale_storage/routers/get_file.dart';
import 'package:essenziale_storage/routers/post_files.dart';
import 'package:essenziale_storage/routers/read_filenames.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_dynamic_forwarder/shelf_dynamic_forwarder.dart';
import 'package:googleapis/storage/v1.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart';

late StorageApi gcsClient;

const String projectId = 'essenziale-server';
const String bucketName = 'essenziale-bucket-server1';
final _scopes = [StorageApi.devstorageReadWriteScope];

Future<auth.AuthClient> getStorageClient() async {
  try {
    final readFile = await File(
      './essenziale-server-33738a9b4d37.json',
    ).readAsString();
    final jsonfile = jsonDecode(readFile) as Map<String, dynamic>;

    final accountCredentials = auth.ServiceAccountCredentials.fromJson(
      jsonfile,
    );
    final Client client = Client();

    auth.AuthClient authClient = await clientViaServiceAccount(
      accountCredentials,
      _scopes,
    );

    client.close();
    return authClient;
  } catch (e) {
    print('Failed to authenticate client: $e');
    rethrow;
  }
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
  final authClient = await getStorageClient();
  gcsClient = StorageApi(authClient);

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

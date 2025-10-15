import 'package:essenziale_storage/routers/delete_file.dart';
import 'package:essenziale_storage/routers/delete_index.dart';
import 'package:essenziale_storage/routers/get_file.dart';
import 'package:essenziale_storage/routers/post_files.dart';
import 'package:essenziale_storage/routers/read_filenames.dart';
import 'package:googleapis/storage/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_dynamic_forwarder/shelf_dynamic_forwarder.dart';

late StorageApi gcsClient;

const String projectId = 'essenziale-server';
const String bucketName = 'essenziale-bucket-server1';
final _scopes = [StorageApi.cloudPlatformScope];

Future<AutoRefreshingAuthClient> getStorageClient() async {
  try {
    final Client client = Client();

    final authClient = await clientViaApplicationDefaultCredentials(
      scopes: _scopes,
    );

    client.close();
    return authClient;
  } catch (e) {
    print('Failed to authenticate client: $e');
    rethrow;
  }
}

final Map<String, Handler> dynamicRoutes = {
  '.*': fileRequest(gcsClient, bucketName),
  'media': filesUpload(gcsClient, bucketName),
  'filenames': filenamesRequest(gcsClient, bucketName),
  'deleteFile': deleteFileRequest(gcsClient, bucketName),
  'deleteIndex': deleteIndexRequest(gcsClient, bucketName),
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

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router);

  await serve(handler, '0.0.0.0', 8080);
  print('Server listening on port: 8080');
}

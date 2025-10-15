import 'dart:typed_data';
import 'package:googleapis/storage/v1.dart' as gcs;
import 'package:path/path.dart' as p;

class GcsStorageService {
  final gcs.StorageApi _storage;
  final String _bucket;

  GcsStorageService(this._storage, this._bucket);

  Future<void> insertFileFromBytes(
    Uint8List file,
    String remoteFilePath,
    String filename, {
    Map<String, String>? metadata,
  }) async {
    final contenType = _guessContentType(p.extension(filename));

    final object = gcs.Object()
      ..contentType = contenType
      ..metadata = metadata;

    try {
      await _storage.objects.insert(
        object,
        _bucket,
        name: remoteFilePath,
        uploadMedia: gcs.Media(
          Stream<List<int>>.value(file),
          file.length,
          contentType: contenType,
        ),
        uploadOptions: gcs.UploadOptions.resumable,
      );

      print('File uploaded from bytes: $filename');
    } catch (e) {
      print('Error uploading file from bytes: $e');
      rethrow;
    }
  }

  Future<Uint8List> getFile(String filePath) async {
    try {
      final media =
          await _storage.objects.get(
                _bucket,
                filePath,
                downloadOptions: gcs.DownloadOptions.fullMedia,
              )
              as gcs.Media;

      final builder = BytesBuilder(copy: false);
      await for (final chunk in media.stream) {
        builder.add(chunk);
      }

      final bytes = builder.takeBytes();
      print('File retrieved: $filePath (${bytes.length} bytes)');
      return bytes;
    } catch (e) {
      print('Error getting file: $e');
      rethrow;
    }
  }

  Future<List<String>> listFiles(String indexPath) async {
    try {
      final listing = await _storage.objects.list(_bucket, prefix: indexPath);

      final items = <String>[];

      if (listing.items == null) return [];

      for (var item in listing.items!) {
        if (item.name!.startsWith(indexPath) &&
            item.name!.length > indexPath.length) {
          items.add(item.name!);
        }
      }

      print('Files found: $items');
      return items;
    } catch (e, stackTrace) {
      print('Error listing folder: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> deleteFile(String filePath) async {
    try {
      await _storage.objects.delete(_bucket, filePath);
      print('File deleted: $filePath');
    } catch (e) {
      print('Error deleting file: $e');
      rethrow;
    }
  }

  Future<void> deleteIndex(String indexPath) async {
    List<String> listingFiles = await listFiles(indexPath);

    try {
      for (String file in listingFiles) {
        await deleteFile(file);
      }
      print('Folder deleted: $indexPath');
    } catch (e) {
      print('Error deleting folder: $e');
      rethrow;
    }
  }

  String _guessContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
        return 'image/jpeg';
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.svg':
        return 'image/svg+xml';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      case '.mp4':
        return 'video/mp4';
      default:
        return 'application/octet-stream';
    }
  }
}

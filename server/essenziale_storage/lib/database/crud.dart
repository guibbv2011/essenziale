// import 'dart:io';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:googleapis/storage/v1.dart' as gcs;
import 'package:path/path.dart' as p;

class GcsStorageService {
  final gcs.StorageApi _storage;
  final String _bucket;

  GcsStorageService(this._storage, this._bucket);

  Future<void> createFolder(String folderPath, bool recursive) async {
    String path = _normalizePath(folderPath);

    final bool fe = await folderExists(folderPath);

    if (!fe) {
      final folder = gcs.Folder()..name = path.endsWith('/') ? path : '$path/';
      try {
        await _storage.folders.insert(folder, _bucket, recursive: recursive);
        print('Folder created: $path');
      } catch (e) {
        print(e);
      }
    }
  }

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
    final path = _normalizePath(filePath).replaceAll(RegExp(r'/$'), '');

    try {
      final media =
          await _storage.objects.get(
                _bucket,
                path,
                downloadOptions: gcs.DownloadOptions.fullMedia,
              )
              as gcs.Media;

      final builder = BytesBuilder(copy: false);
      await for (final chunk in media.stream) {
        builder.add(chunk);
      }

      final bytes = builder.takeBytes();
      print('File retrieved: $path (${bytes.length} bytes)');
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

  Future<List<String>> listFolder(String folderPath) async {
    final path = _normalizePath(folderPath);
    final prefix = path.isEmpty ? '' : (path.endsWith('/') ? path : '$path/');

    try {
      final listing = await _storage.objects.list(
        _bucket,
        prefix: prefix,
        delimiter: '/',
        includeFoldersAsPrefixes: true,
      );

      final items = <String>[];

      if (listing.prefixes != null) {
        for (var subPrefix in listing.prefixes!) {
          final folderName = subPrefix.substring(prefix.length);
          if (folderName.isNotEmpty) {
            final cleanName = folderName.endsWith('/')
                ? folderName.substring(0, folderName.length - 1)
                : folderName;
            if (cleanName.isNotEmpty) {
              items.add(cleanName);
            }
          }
        }
      }

      return items;
    } catch (e, stackTrace) {
      print('Error listing folder: $e');
      print('Stack trace: $stackTrace');
      print('Attempted path: $prefix');
      rethrow;
    }
  }

  Future<void> uploadDirectory(
    String localDirPath,
    String remoteBasePath,
  ) async {
    final localDir = Directory(localDirPath);
    if (!await localDir.exists()) {
      throw FileSystemException(
        'Local directory does not exist: $localDirPath',
      );
    }

    // final basePrefix = _normalizePath(remoteBasePath);
    await _uploadRecursive(localDir, remoteBasePath);
    print('Directory uploaded: $localDirPath -> $remoteBasePath');
  }

  Future<void> _uploadRecursive(Directory dir, String remotePrefix) async {
    for (final entity in dir.listSync(followLinks: false)) {
      final filename = p.relative(entity.path, from: dir.path);
      // final remotePath = p.join(remotePrefix, filename);

      if (entity is File) {
        print('entity absolute: ${entity.parent.path}');

        await createFolder(entity.parent.path, true);

        final Uint8List file = await File(entity.uri.path).readAsBytes();
        await insertFileFromBytes(file, entity.parent.path, filename);
      }
    }
  }

  String _normalizePath(String path) {
    String normalized = path;

    if (normalized.startsWith('/tmp/')) {
      normalized = normalized.substring(5);
    }

    normalized = p.normalize(normalized);

    if (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }

    return normalized;
  }

  String _guessContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.txt':
        return 'text/plain';
      case '.html':
      case '.htm':
        return 'text/html';
      case '.css':
        return 'text/css';
      case '.js':
        return 'application/javascript';
      case '.json':
        return 'application/json';
      case '.xml':
        return 'application/xml';
      case '.jpg':
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
      case '.zip':
        return 'application/zip';
      case '.tar':
        return 'application/x-tar';
      case '.gz':
        return 'application/gzip';
      case '.mp4':
        return 'video/mp4';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      default:
        return 'application/octet-stream';
    }
  }

  Future<Uint8List> readFile(String filePath) async {
    String? path;
    if (filePath.startsWith('/tmp/')) {
      path = p.normalize(filePath.substring(5));
    }

    path!.replaceAll(RegExp(r'/$'), '');
    final media =
        await _storage.objects.get(
              _bucket,
              path,
              downloadOptions: gcs.DownloadOptions.fullMedia,
            )
            as gcs.Media;
    final data = <int>[];
    await for (final chunk in media.stream) {
      data.addAll(chunk);
    }
    return Uint8List.fromList(data);
  }

  Future<List<String>> listFolder(String folderPath) async {
    String? path;
    if (folderPath.startsWith('/tmp/')) {
      path = p.normalize(folderPath.substring(5));
    }
    final listing = await _storage.objects.list(
      _bucket,
      prefix: path,
      delimiter: '/',
      includeFoldersAsPrefixes: true,
    );
    final items = <String>[];
    for (var item in listing.items ?? []) {
      items.add(p.basename(item.name!));
    }
    for (var subPrefix in listing.prefixes ?? []) {
      items.add(p.basename(subPrefix.substring(0, subPrefix.length - 1)));
    }
    return items;
  }

  Future<void> deleteFile(String filePath) async {
    String? path;
    if (filePath.startsWith('/tmp/')) {
      path = p.normalize(filePath.substring(5));
    }

    path!.replaceAll(RegExp(r'/$'), '');
    await _storage.objects.delete(_bucket, path);
  }

  Future<void> deleteFolder(String folderPath) async {
    String? path;
    if (folderPath.startsWith('/tmp/')) {
      path = p.normalize(folderPath.substring(5));
  /// Checks if a folder exists
  Future<bool> folderExists(String folderPath) async {
    try {
      final _ = await listFolder(folderPath);
      return true;
    } catch (e) {
      return false;
    }

    await _deleteRecursive(path!);
    await _storage.folders.delete(_bucket, path);
  }

  Future<void> _deleteRecursive(String prefix) async {
    String? nextPageToken;
    do {
      final listing = await _storage.objects.list(
        _bucket,
        prefix: prefix,
        delimiter: '/',
        includeFoldersAsPrefixes: true,
        pageToken: nextPageToken,
      );

      for (var item in listing.items ?? []) {
        await _storage.objects.delete(_bucket, item.name!);
      }

      for (var subPrefix in listing.prefixes ?? []) {
        await _deleteRecursive(subPrefix!);
      }

      nextPageToken = listing.nextPageToken;
    } while (nextPageToken != null);
  /// Checks if a folder exists
  Future<bool> folderExists(String folderPath) async {
    final result = await listFolder(folderPath);
    return result.equals([]) ? false : true;
  }
}
